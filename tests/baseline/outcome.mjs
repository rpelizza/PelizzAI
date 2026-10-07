// Runtime completion and task quality are different measurements.
export function assessRun(run, platform = 'claude') {
  if (!['claude', 'codex'].includes(platform)) throw new Error(`Unsupported trace platform: ${platform}`);
  const base = { runCompleted: false, taskSucceeded: null, quality: 'unmeasured' };
  if (run.error || run.status !== 0) return { ...base, reason: 'agent process failed or was interrupted' };
  const events = [];
  for (const line of String(run.stdout ?? '').split(/\r?\n/).filter(line => line.trim())) {
    try {
      const event=JSON.parse(line);
      if (!event || typeof event !== 'object' || Array.isArray(event) || typeof event.type !== 'string') {
        return { ...base, reason: 'malformed agent trace event' };
      }
      events.push(event);
    }
    catch { return { ...base, reason: 'malformed agent trace' }; }
  }
  if (!events.length) return { ...base, reason: 'empty agent trace' };
  if (platform === 'claude') {
    const result = events.at(-1);
    if (result.type !== 'result' || result.is_error || result.subtype !== 'success') return { ...base, reason: 'no successful terminal result' };
  } else {
    if (events.some(event => ['error', 'turn.failed'].includes(event.type)) || events.at(-1)?.type !== 'turn.completed') {
      return { ...base, reason: 'no successful terminal turn' };
    }
  }
  return { ...base, runCompleted: true, reason: 'runtime completed; delivery still needs its own oracle' };
}

// Candidate writes count only after the host returns a successful result. A pending call,
// an assistant claim and an explicit tool error are never evidence of a completed write.
export function completedClaudeWrites(events) {
  const pending = new Map(), writes = [];
  for (const event of events) {
    for (const block of event.message?.content ?? []) {
      if (event.type === 'assistant' && block.type === 'tool_use') {
        if (['Write', 'Edit', 'MultiEdit', 'NotebookEdit'].includes(block.name)) pending.set(block.id, block);
      } else if (event.type === 'user' && block.type === 'tool_result' && pending.has(block.tool_use_id)) {
        const call=pending.get(block.tool_use_id);pending.delete(block.tool_use_id);
        if (block.is_error) continue;
        const path=call.input?.file_path ?? call.input?.notebook_path;
        if (path) writes.push({ path, tool: call.name, toolUseId: call.id });
      }
    }
  }
  return writes;
}
