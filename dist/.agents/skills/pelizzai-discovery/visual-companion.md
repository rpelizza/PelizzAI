# Visual Companion Guide

Browser-based discovery visual companion for showing mockups, diagrams, and options.

## When to Use

Decide per question, not per session. The test is: **would the user understand better by seeing than by reading?**

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — two layouts, two color schemes, two design directions
- **Design polish** — when the question is about looks, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use the terminal** when the content is textual or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — choosing between approaches described in words
- **Trade-off lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question _about_ a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts looks right?" is visual — use the browser.

## How It Works

The server watches a directory for HTML files and serves the most recent one to the browser. You write HTML content to `screen_dir`; the user sees that content in the browser and can click to select options. Selections are recorded in `state_dir/events`, which you read on the next turn.

**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (only injecting the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, connection status, and all the interactive infrastructure. **Write content fragments by default.** Write full documents only when you need full control over the page.

## Starting a Session

```bash
# POSIX. Start AFTER the user approves the companion.
# --open opens the authenticated URL as soon as the server starts.
scripts/start-server.sh --project-dir /path/to/project --open

# Returns: {"type":"server-started","port":52341,
#           "url":"http://localhost:52341/?key=ab12…",
#           "screen_dir":"/path/to/project/pelizzai/data/mockups/12345-1706000000/content",
#           "state_dir":"/path/to/project/pelizzai/data/mockups/12345-1706000000/state"}
```

```powershell
# PowerShell 7+ (Windows)
pwsh scripts/start-server.ps1 -ProjectDir C:\path\to\project -Open
```

Save `screen_dir` and `state_dir` from the response. With `--open`/`-Open`, the browser opens as soon as the server starts — you do not need to ask the user to open it, but still share the URL as a fallback (headless/remote environments may not open automatically).

**The URL contains a session key (`?key=…`).** The server rejects any request without it, so always give the user the **complete** URL from the `url` field — never strip the query string and never hand out just `http://host:port`. The key gates HTTP and WebSocket access, so a stray browser tab or another machine on the network cannot read the screens or inject events. After the first load, the browser remembers the key via a cookie, so reloads and `/files/*` assets work without repeating it.

**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you started the server in the background and did not capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/pelizzai/data/mockups/` to find the session directory.

**Source mode (the PelizzAI source repo, by sentinel `scripts/pelizzai-source-repo.txt`):** never
pass `--project-dir`/`-ProjectDir` — it would create `pelizzai/` runtime, which source mode
forbids. Start the temporary session instead (omit the flag on either platform): the files live in
the temporary directory and are cleaned up with the session. The persistent examples above are for
a bootstrapped consumer with the ignore confirmed.

**Persistence and ignore:** The consumer bootstrap creates `pelizzai/.gitignore` with `data/mockups/`, but confirm the protection in the project with `git check-ignore` before using `--project-dir`/`-ProjectDir`. If the bootstrap does not exist or the ignore was not proven, use the temporary session (no project dir) or fix the bootstrap on the authorized task branch. With a project dir, that session's files persist in `pelizzai/data/mockups/`; without it, they stay in the temporary directory and are cleaned up. Each new run creates its own session, with a new port and a new URL — the persistent files do not revive the old session.

The default idle timeout is **4 hours (240 minutes)**. Adjust when needed with `--idle-timeout-minutes <n>` on POSIX or `-IdleTimeoutMinutes <n>` on PowerShell.

**Starting the server per platform:**

**Claude Code:**

```bash
# The default mode works — the script backgrounds the server on its own.
scripts/start-server.sh --project-dir /path/to/project --open
```

On Windows, the script auto-detects and switches to foreground mode (which blocks the tool call). Use `run_in_background: true` on the Bash tool call so the server survives across conversation turns; then read `$STATE_DIR/server-info` on the next turn to get the URL and port.

**Codex:**

```bash
# Codex kills background processes. The script detects CODEX_CI
# automatically and switches to foreground mode. Run it normally —
# no extra flag is needed.
scripts/start-server.sh --project-dir /path/to/project --open
```

**Gemini CLI:**

```bash
# Use --foreground and set is_background: true on the shell tool call
# so the process survives across turns
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**Copilot CLI:**

```bash
# Use --foreground and start the server via the bash tool with mode: "async"
# so the process survives across turns. Capture the returned shellId for
# read_bash / stop_bash if you need to interact with it later.
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**Other environments:** The server must keep running in the background across conversation turns. If your environment kills detached processes, use `--foreground` and run the command with your platform's background execution mechanism.

If the URL is unreachable from the browser (common in remote/containerized environments), prefer
an **SSH local forward** — it keeps the server bound to loopback and encrypts the whole path, with
no server flag at all:

```bash
ssh -L <port>:localhost:<port> <remote-host>
# then open the printed localhost URL in the local browser
```

Binding to a non-loopback host directly is refused by default: the session key and every event
would travel in cleartext. It is allowed only behind an **authenticated HTTPS tunnel** that
terminates TLS in front of the port, declared explicitly:

```bash
BRAINSTORM_REMOTE_TRANSPORT=tls-tunnel scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host <tunnel-host>
```

Use `--url-host` to control which hostname is printed in the returned URL JSON (advertised as
`https://` in this mode). It must be the tunnel address the USER's browser reaches. `localhost`
only works when the browser runs on the same machine as the server.

## The Loop

1. **Check that the server is up**, then **write HTML** to a new file inside `screen_dir`:
    - **Mandatory: confirm the server is up before mentioning the URL or pushing a screen.** Verify that `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does not. If it was shut down, start a new session. Even with the same project dir, a restart creates a new `state_dir`, a new port, and a new URL; save the new values and share the new complete URL. The server shuts down automatically after 4 idle hours by default, configurable per platform as described above.
    - Use semantic file names: `platform.html`, `visual-style.html`, `layout.html`
    - **Never reuse file names** — each screen gets a fresh file
    - Use your file-creation tool — **never use cat/heredoc** (it dumps noise into the terminal)
    - The server automatically serves the most recent file

2. **Tell the user what to expect and end your turn:**
    - Remind them of the URL (at every step, not just the first)
    - Give a brief textual summary of what is on screen (for example, "Showing 3 layout options for the homepage")
    - Ask them to reply in the terminal: "Take a look and tell me what you think. Click to select an option if you like."

3. **On the next turn** — after the user replies in the terminal:
    - Read `$STATE_DIR/events` if it exists — it contains the user's browser interactions (clicks, selections) as JSON lines
    - Combine it with the user's terminal text to get the full picture
    - The terminal message is the primary feedback; `state_dir/events` provides structured interaction data

4. **Iterate or advance** — if feedback changes the current screen, write a new file (for example, `layout-v2.html`). Move to the next question only when the current step is validated.

5. **Unload when returning to the terminal** — when the next step does not need the browser (for example, a clarifying question, a trade-off discussion), push a waiting screen to clear the old content:

    ```html
    <!-- filename: waiting.html (or waiting-2.html, etc.) -->
    <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
    	<p class="subtitle">Continuing in the terminal...</p>
    </div>
    ```

    This keeps the user from staring at an already-settled choice while the conversation has moved on. When the next visual question comes up, push a new content file as usual.

6. Repeat until done.

## Writing Content Fragments

Write only the content that goes inside the page. The server automatically wraps it in the frame template (header, theme CSS, connection status, and all the interactive infrastructure).

**Minimal example:**

```html
<h2>Which layout works best?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
	<div class="option" data-choice="a" onclick="toggleSelect(this)">
		<div class="letter">A</div>
		<div class="content">
			<h3>Single column</h3>
			<p>Clean, focused reading experience</p>
		</div>
	</div>
	<div class="option" data-choice="b" onclick="toggleSelect(this)">
		<div class="letter">B</div>
		<div class="content">
			<h3>Two columns</h3>
			<p>Side navigation with main content</p>
		</div>
	</div>
</div>
```

That's it. No `<html>`, CSS, or `<script>` tags needed. The server provides all of that.
Keyboard access comes wired: every `[data-choice]` element is made focusable (`tabindex`,
`role="button"`, `aria-pressed`), gets a visible focus outline, and Enter/Space select exactly
like a click — do not remove those attributes in custom full documents.

## Available CSS Classes

The frame template provides these CSS classes for your content:

### Options (A/B/C choices)

```html
<div class="options">
	<div class="option" data-choice="a" onclick="toggleSelect(this)">
		<div class="letter">A</div>
		<div class="content">
			<h3>Title</h3>
			<p>Description</p>
		</div>
	</div>
</div>
```

**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item's selected style.

```html
<div class="options" data-multiselect>
	<!-- same option markup — users can select/deselect several -->
</div>
```

### Cards (visual designs)

```html
<div class="cards">
	<div class="card" data-choice="design1" onclick="toggleSelect(this)">
		<div class="card-image"><!-- mockup content --></div>
		<div class="card-body">
			<h3>Name</h3>
			<p>Description</p>
		</div>
	</div>
</div>
```

### Mockup container

```html
<div class="mockup">
	<div class="mockup-header">Preview: Dashboard Layout</div>
	<div class="mockup-body"><!-- your mockup HTML --></div>
</div>
```

### Split view (side by side)

```html
<div class="split">
	<div class="mockup"><!-- left --></div>
	<div class="mockup"><!-- right --></div>
</div>
```

### Pros/Cons

```html
<div class="pros-cons">
	<div class="pros">
		<h4>Pros</h4>
		<ul>
			<li>Benefit</li>
		</ul>
	</div>
	<div class="cons">
		<h4>Cons</h4>
		<ul>
			<li>Drawback</li>
		</ul>
	</div>
</div>
```

### Mockup elements (wireframe blocks)

```html
<div class="mock-nav">Logo | Home | About | Contact</div>
<div style="display: flex;">
	<div class="mock-sidebar">Navigation</div>
	<div class="mock-content">Main content area</div>
</div>
<button class="mock-button">Action button</button>
<input class="mock-input" placeholder="Input field" />
<div class="placeholder">Placeholder area</div>
```

### Typography and sections

- `h2` — page title
- `h3` — section title
- `.subtitle` — secondary text below the title
- `.section` — content block with bottom margin
- `.label` — small uppercase label text

## Browser Event Format

When the user clicks options in the browser, their interactions are recorded in `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

The full event stream shows the user's exploration path — they may click several options before deciding. The last `choice` event is usually the final selection, but the click pattern can reveal hesitation or preferences worth asking about.

If `$STATE_DIR/events` does not exist, the user did not interact with the browser — use only their terminal text.

## Design Tips

- **Match fidelity to the question** — wireframes for layout questions, polish for polish questions
- **Explain the question on every page** — "Which layout looks more professional?", not just "Pick one"
- **Iterate before advancing** — if feedback changes the current screen, write a new version
- **At most 2–4 options** per screen
- **Use real content when it matters** — for a photography portfolio, use real images (Unsplash). Placeholder content hides design problems.
- **Keep mockups simple** — focus on layout and structure, not pixel-perfect design

## File Naming

- Use semantic names: `platform.html`, `visual-style.html`, `layout.html`
- Never reuse file names — each screen must be a new file
- For iterations: append a version suffix like `layout-v2.html`, `layout-v3.html`
- The server serves the most recent file by modification time

## Cleanup

```bash
scripts/stop-server.sh $SESSION_DIR
```

```powershell
pwsh scripts/stop-server.ps1 -SessionDir $SESSION_DIR
```

If the session used `--project-dir`, the mockup files persist in `pelizzai/data/mockups/` for later reference. Only sessions under the system temporary directory (`/tmp` on POSIX, `$env:TEMP` on Windows) are deleted on stop.

## Reference

- Frame template (CSS reference): `scripts/frame-template.html`
- Helper script (client-side): `scripts/helper.js`
