#!/usr/bin/env node
/**
 * PelizzAI — SessionStart hook (matcher startup|resume|clear|compact). OPT-IN.
 *
 * Emits a SHORT reminder at session start: load pelizzai-core before answering
 * anything (the 1% rule), go through core/router on project tasks, classify the
 * effect before acting and, if pelizzai/data/state.md has an active task
 * (slug != <none> and phase != done), warn that there is a resumption via pelizzai-router.
 *
 * Value note: in Claude Code, CLAUDE.md is already re-injected on startup and after
 * compact — the real gain of this hook is on `clear` (which wipes everything) and on
 * platforms that do NOT re-inject the always-loaded entry point.
 *
 * Guarantees: ALWAYS ends with exit 0; swallows any error; never blocks the session.
 *
 * Installation (opt-in), in the consumer project's .claude/settings.json:
 *   { "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-session-start.mjs\"" } ] } ] } }
 *
 * On fleets without Node, use the PowerShell variant pelizzai-session-start.ps1 (same matcher).
 */

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  let cwd = process.cwd();
  try {
    const data = JSON.parse(readStdin() || '{}');
    if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
  } catch {
    /* fall back to process.cwd() */
  }

  const lines = [
    'PelizzAI: before answering ANYTHING, load the pelizzai-core skill and honor the 1% rule — if a skill applies (even to a trivial tweak), invoke it.',
    'Every task that touches the project goes through pelizzai-core → pelizzai-router: classify effect, risk, uncertainty and surfaces before acting.',
    'Pick a head skill and proportional overlays; read-only initializes no state, and any write goes through the isolation gate first.',
  ];

  try {
    const statePath = join(cwd, 'pelizzai', 'data', 'state.md');
    if (existsSync(statePath)) {
      const state = readFileSync(statePath, 'utf8');
      const slug = (state.match(/^\s*-\s*slug:\s*(.+?)\s*$/m) || [])[1];
      const phase = (state.match(/^\s*-\s*phase:\s*(\S+)/m) || [])[1];
      // state.md is a VERSIONED file: whatever it carries lands in the agent's context on every
      // session start. Values are matched against the shape the template documents and the whole
      // line is DISCARDED on mismatch — untrusted text, not "a different policy" (second-order
      // prompt injection via a merged commit).
      const SLUG_SHAPE = /^[a-z0-9][a-z0-9._-]{0,63}$/;
      const PHASES = ['brainstorm', 'plan', 'exec', 'review', 'delivered', 'done', 'abandoned', 'blocked'];
      const active =
        slug && SLUG_SHAPE.test(slug) &&
        phase && PHASES.includes(phase) && phase !== 'done';
      if (active) {
        lines.push(
          `There is an ACTIVE task in pelizzai/data/state.md (slug: ${slug}, phase: ${phase}) — ` +
            'resume via pelizzai-router, validating the cursor against git before proceeding.'
        );
      }
    }
  } catch {
    /* no resumption warning — carry on with the basic reminder */
  }

  // Consumer without a domain-skill catalog: suggests ONCE the read-only bootstrap path
  // (propose→confirm; nothing is created without consent). In source mode (source repo)
  // it is a no-op — there is no consumer catalog there. Creating pelizzai/domain-skills.md
  // (even `_none for now_`) silences the nudge without requiring domain skills.
  try {
    // Dedicated sentinel: only the source repo has it (consumers have manifest/sync and are NOT the source).
    const sourceMode = existsSync(join(cwd, 'scripts', 'pelizzai-source-repo.txt'));
    if (!sourceMode && !existsSync(join(cwd, 'pelizzai', 'domain-skills.md'))) {
      lines.push(
        'Project has no domain-skill catalog (pelizzai/domain-skills.md missing). If you are ' +
          'going to work on the code, consider pelizzai-audit in scan-only → propose bootstrap-write. ' +
          'Nothing is created without your confirmation.'
      );
    }
  } catch {
    /* no bootstrap nudge — carry on */
  }

  // Recap of the already-ratified execution policy (anti-fatigue): when the profile records
  // §Ratified execution defaults, the router reapplies them as a 1-line recap instead of
  // re-asking. destination is NEVER a default: push/PR/publication remain per task.
  try {
    const profilePath = join(cwd, 'pelizzai', 'profile.md');
    if (existsSync(profilePath)) {
      const profile = readFileSync(profilePath, 'utf8');
      const iso = (profile.match(/isolation-default:\s*(\S+)/) || [])[1];
      const mode = (profile.match(/execution-mode-default:\s*(\S+)/) || [])[1];
      const commit = (profile.match(/commit-strategy-default:\s*(\S+)/) || [])[1];
      // Not ratified = raw `unset` OR any placeholder between <> (the bootstrap writes
      // `<unset>`, and the template ships the `<branch|worktree|unset>` menu) — same
      // convention as state.md above. Without this, the recap would fire on every freshly
      // bootstrapped consumer. The allowlist closes the same injection vector as the slug:
      // profile.md is versioned, so only the enum values the template documents are echoed.
      const isRatified = (value, allowed) =>
        Boolean(value) && value !== 'unset' && !value.startsWith('<') && allowed.includes(value);
      const ratified = [];
      if (isRatified(iso, ['branch', 'worktree'])) ratified.push(`isolation ${iso}`);
      if (isRatified(mode, ['inline', 'subagents', 'team'])) ratified.push(`mode ${mode}`);
      if (isRatified(commit, ['granular', 'squash-final'])) ratified.push(`commit ${commit}`);
      if (ratified.length) {
        lines.push(
          `Ratified execution policy for this project (pelizzai/profile.md): ${ratified.join(', ')} — ` +
            'reapply it as a 1-line recap; do not re-ask what has already been ratified (destination remains per task).'
        );
      }
    }
  } catch {
    /* no policy recap — carry on */
  }

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: lines.join('\n'),
      },
    })
  );
}

try {
  main();
} catch {
  /* never fail session start */
}
// process.exitCode instead of process.exit(0): piped stdout writes can be asynchronous and
// process.exit would truncate the JSON payload (silent, intermittent loss of the reminder).
process.exitCode = 0;
