#!/usr/bin/env node
/**
 * PelizzAI — cadence hook (UserPromptSubmit).
 *
 * Reinforcement for domain-skill self-maintenance. It is NOT the source of truth:
 * the cadence core lives in the `pelizzai-writing-skills` skill (portable across IDEs)
 * and fires at task closeout (`pelizzai-finish-task` Step 5). This hook exists only in
 * Claude Code and acts as a safety net: it counts interactions and, every N,
 * reminds you to review the skills once the commit/day threshold has been crossed.
 *
 * Cadence (calibrated for active teams — see pelizzai-writing-skills →
 * references/domain-skill-maintenance.md):
 *  - Sampling: checks every 10 interactions (not on every message).
 *  - Review due: >= 10 commits OR > 10 days since last-review (the DAYS axis is the
 *    anchor — sprint cadence; commits only PULL IT FORWARD in a real burst of work).
 *  - Full repo-scan: > 15 days since last-full-scan.
 *  - Snooze: after nudging, stays silent for 7 days (avoids repeating every window
 *    while the user has not run the maintenance). "Nudge once, never block."
 *
 * Safety guarantees:
 *  - Silent no-op if the harness has not been initialized here (no ledger).
 *  - The expensive check (git) only runs every N interactions; the others just bump the counter.
 *  - ALWAYS ends with exit 0 — never blocks the user's prompt.
 *  - Swallows any error (missing git, FS, etc.) without noise.
 *  - At most one reminder per snooze window.
 *
 * Installation (opt-in, normally at bootstrap), in .claude/settings.json:
 *   { "hooks": { "UserPromptSubmit": [ { "hooks": [
 *       { "type": "command",
 *         "command": "node \"${CLAUDE_PROJECT_DIR}/.claude/hooks/pelizzai-cadence.mjs\"" } ] } ] } }
 *
 * On fleets without Node, use the PowerShell variant pelizzai-cadence.ps1 (same directory).
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';

const EVERY = 10;                 // check every N interactions (sampling, not the nudge frequency)
const COMMIT_THRESHOLD = 10;      // >= N commits since the last review (pulls forward in a real burst)
const DAY_THRESHOLD_REVIEW = 10;  // > N days since the last review (sprint anchor)
const DAY_THRESHOLD_SCAN = 15;    // > N days since the last full-scan
const SNOOZE_DAYS = 7;            // after nudging, stay silent for N days
const MS_PER_DAY = 86400000;

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function safeGit(cwd, args) {
  try {
    return execFileSync('git', args, {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 4000,
    }).trim();
  } catch {
    return '';
  }
}

function daysBetween(iso, now) {
  const then = Date.parse(iso + 'T00:00:00');
  if (Number.isNaN(then)) return 0;
  return Math.floor((now - then) / MS_PER_DAY);
}

function emit(context) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: context,
      },
    })
  );
}

function main() {
  let cwd = process.cwd();
  try {
    const input = readStdin();
    if (input) {
      const data = JSON.parse(input);
      if (data && typeof data.cwd === 'string' && data.cwd) cwd = data.cwd;
    }
  } catch {
    /* fall back to process.cwd() */
  }

  const ledgerPath = join(cwd, 'pelizzai', 'data', 'review-domain-skills.md');
  if (!existsSync(ledgerPath)) return; // harness not initialized in this project

  // state: interaction counter + snooze window (backward-compatible with { count })
  const statePath = join(cwd, 'pelizzai', 'data', '.cadence-state.json');
  let state = { count: 0, snoozeUntil: 0 };
  try {
    if (existsSync(statePath)) state = { ...state, ...JSON.parse(readFileSync(statePath, 'utf8')) };
  } catch {
    /* reset the state */
  }
  state.count = (state.count || 0) + 1;
  const persist = () => {
    try {
      mkdirSync(dirname(statePath), { recursive: true });
      writeFileSync(statePath, JSON.stringify(state));
    } catch {
      /* no persistence — carry on */
    }
  };
  persist();

  if (state.count % EVERY !== 0) return; // only check (and nudge) every N interactions

  const now = Date.now();
  if (state.snoozeUntil && now < state.snoozeUntil) return; // snoozed after a recent nudge

  // ledger dates (first YYYY-MM-DD found after each label)
  let ledger = '';
  try {
    ledger = readFileSync(ledgerPath, 'utf8');
  } catch {
    return;
  }
  const lastReview = (ledger.match(/last-review:\D*(\d{4}-\d{2}-\d{2})/) || [])[1];
  const lastScan = (ledger.match(/last-full-scan:\D*(\d{4}-\d{2}-\d{2})/) || [])[1];
  if (!lastReview) return;

  const commits = parseInt(
    safeGit(cwd, ['rev-list', '--count', `--since=${lastReview} 00:00`, 'HEAD']) || '0',
    10
  );
  const daysReview = daysBetween(lastReview, now);
  const daysScan = lastScan ? daysBetween(lastScan, now) : 0;

  const reviewDue = commits >= COMMIT_THRESHOLD || daysReview > DAY_THRESHOLD_REVIEW;
  const scanDue = lastScan && daysScan > DAY_THRESHOLD_SCAN;
  if (!reviewDue && !scanDue) return;

  const parts = [];
  if (reviewDue)
    parts.push(
      `${commits} commit(s) and ${daysReview} day(s) since the last domain-skill review`
    );
  if (scanDue) parts.push(`${daysScan} day(s) since the last full repo-scan`);

  emit(
    `PelizzAI (cadence): ${parts.join('; ')}. ` +
      `Consider invoking the pelizzai-writing-skills skill (maintenance mode) to review/update ` +
      `the domain skills. Suggest it to the user once; do not block the work.`
  );

  // snooze for the next SNOOZE_DAYS days so it does not repeat every window
  state.snoozeUntil = now + SNOOZE_DAYS * MS_PER_DAY;
  persist();
}

try {
  main();
} catch {
  /* never fail the user's prompt */
}
process.exit(0);
