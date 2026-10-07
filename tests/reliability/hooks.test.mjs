import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, cpSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../../', import.meta.url));
function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), 'pelizzai-reliability-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  for (const args of [['init', '-b', 'main'], ['config', 'user.email', 'fixture@example.invalid'], ['config', 'user.name', 'Fixture'], ['commit', '--allow-empty', '-m', 'fixture']]) {
    const r = spawnSync('git', args, { cwd: dir, encoding: 'utf8' });
    assert.equal(r.status, 0, r.stderr);
  }
  return dir;
}
function hook(dir, tool_name, tool_input) {
  return spawnSync(process.execPath, [join(root, '.claude/hooks/pelizzai-writegate.mjs')], {
    cwd: dir, input: JSON.stringify({ cwd: dir, tool_name, tool_input }), encoding: 'utf8',
  });
}
test('Codex patch checks add, update, delete and BOTH sides of move', t => {
  const dir = fixture(t);
  for (const header of ['*** Add File: src/new.ts', '*** Update File: src/old.ts', '*** Delete File: src/old.ts', '*** Update File: pelizzai/note.md\n*** Move to: src/moved.ts', '*** Update File: src/old.ts\n*** Move to: pelizzai/note.md']) {
    const r = hook(dir, 'apply_patch', { command: `*** Begin Patch\n${header}\n+hello\n*** End Patch` });
    assert.equal(r.status, 2, `${header}: ${r.stderr}`);
  }
  assert.equal(hook(dir, 'apply_patch', { command: '*** Begin Patch\n*** Add File: pelizzai/note.md\n+hello\n*** End Patch' }).status, 0);
  assert.equal(hook(dir, 'Bash', { command: 'git status --short' }).status, 0);
});
test('patch paths are literals; consumer kickoff still gates task branches', t => {
  const dir = fixture(t);
  assert.equal(hook(dir, 'apply_patch', { command: '*** Begin Patch\n*** Add File: $HOME.ts\n+hello\n*** End Patch' }).status, 2);
  spawnSync('git', ['switch', '-c', 'task'], { cwd: dir });
  mkdirSync(join(dir, 'pelizzai/data'), { recursive: true });
  const input = { command: '*** Begin Patch\n*** Add File: src/a.ts\n+hello\n*** End Patch' };
  assert.equal(hook(dir, 'apply_patch', input).status, 2);
  writeFileSync(join(dir, 'pelizzai/data/state.md'), 'kickoff: ratified\n');
  assert.equal(hook(dir, 'apply_patch', input).status, 0);
});
test('unified exec cmd and workdir are understood', t => {
  const dir = fixture(t);
  assert.equal(hook(dir, 'exec_command', { cmd: 'Set-Content -LiteralPath src/a.ts -Value x', workdir: dir }).status, 2);
});

test('Windows short paths remain inside the physical Git root', {skip:process.platform!=='win32'}, t => {
  const dir=fixture(t);
  const alias=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-Command',
    '[Console]::InputEncoding=[Text.UTF8Encoding]::new($false); [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); $p=[Console]::In.ReadToEnd(); (New-Object -ComObject Scripting.FileSystemObject).GetFolder($p).ShortPath'],
    {input:dir,encoding:'utf8',windowsHide:true});
  assert.equal(alias.status,0,alias.stderr);
  const short=alias.stdout.trim();
  if (!short.includes('~')) {t.skip('This filesystem has no 8.3 aliases');return;}
  for(const path of ['src/a.ts','$HOME.ts']) {
    const result=hook(short,'apply_patch',{command:`*** Begin Patch\n*** Add File: ${path}\n+x\n*** End Patch`});
    assert.equal(result.status,2,result.stderr);
  }
  assert.equal(hook(short,'exec_command',{cmd:'Set-Content -LiteralPath src/a.ts -Value x',workdir:short}).status,2);
  assert.equal(hook(short,'apply_patch',{command:'*** Begin Patch\n*** Add File: pelizzai/a.md\n+x\n*** End Patch'}).status,0);
});

test('git guard understands unified exec without treating patch contents as commands', () => {
  for (const [executable,args] of [[process.execPath,[join(root, '.claude/hooks/pelizzai-guardrails.mjs')]],
    ['pwsh',['-NoProfile','-File',join(root,'.claude/hooks/pelizzai-guardrails.ps1')]]]) {
  const run = (tool_name, tool_input) => spawnSync(executable, args, {
    input: JSON.stringify({ tool_name, tool_input }), encoding: 'utf8',
  });
  assert.equal(run('exec_command', { cmd: 'git reset --hard' }).status, 2);
  assert.equal(run('apply_patch', { command: '*** Begin Patch\n*** Add File: guide.md\n+git reset --hard\n*** End Patch' }).status, 0);
  }
});

test('PowerShell writegate reads native Codex patch and exec payloads', t => {
  const dir=fixture(t);
  const run=(tool_name,tool_input)=>spawnSync('pwsh',['-NoProfile','-File',join(root,'.claude/hooks/pelizzai-writegate.ps1')],{
    cwd:dir,input:JSON.stringify({cwd:dir,tool_name,tool_input}),encoding:'utf8',
  });
  for (const header of ['*** Add File: $HOME.ts','*** Update File: pelizzai/note.md\n*** Move to: src/note.md','*** Delete File: src/note.md']) {
    const result=run('apply_patch',{command:`*** Begin Patch\n${header}\n*** End Patch`});
    assert.equal(result.status,2,result.stderr);
  }
  assert.equal(run('exec_command',{cmd:'Set-Content -LiteralPath src/a.ts -Value x',workdir:dir}).status,2);
});
test('Codex registration is idempotent, preserves other hooks, checks event and matcher', t => {
  const dir = fixture(t);
  cpSync(join(root, '.claude/hooks'), join(dir, '.claude/hooks'), { recursive: true });
  mkdirSync(join(dir, '.codex'), { recursive: true });
  const manifest = join(dir, '.codex/hooks.json');
  const other = { matcher: 'Bash', hooks: [{ type: 'command', command: 'echo unrelated' }] };
  writeFileSync(manifest, JSON.stringify({ hooks: { PreToolUse: [other] } }));
  const run = (...args) => spawnSync(process.execPath, [join(root, 'scripts/install-hooks.mjs'), '--project', dir, '--platform', 'codex', ...args], { encoding: 'utf8' });
  assert.equal(run('--only', 'writegate').status, 0);
  const installed = readFileSync(manifest, 'utf8');
  assert.equal(run('--only', 'writegate').status, 0);
  assert.equal(readFileSync(manifest, 'utf8'), installed);
  assert.equal(run('--check', '--only', 'writegate').status, 0);
  const config = JSON.parse(installed);
  assert.deepEqual(config.hooks.PreToolUse[0].hooks[0], other.hooks[0]);
  config.hooks.PreToolUse.find(x => x.matcher === 'apply_patch').matcher = 'NeverRuns';
  writeFileSync(manifest, JSON.stringify(config));
  assert.equal(run('--check').status, 1);
  assert.equal(run('--check', '--only', 'writegate').status, 1);
  assert.equal(run('--remove', '--only', 'writegate').status, 0);
  assert.deepEqual(JSON.parse(readFileSync(manifest)).hooks.PreToolUse, [other]);
});

test('Codex registration rejects percent paths before writing shell commands',t=>{
  const dir=join(fixture(t),'project%PATH%');mkdirSync(dir);
  cpSync(join(root,'.claude/hooks'),join(dir,'.claude/hooks'),{recursive:true});
  const result=spawnSync(process.execPath,[join(root,'scripts/install-hooks.mjs'),'--project',dir,'--platform','codex'],{encoding:'utf8'});
  assert.equal(result.status,1);
  assert.match(result.stderr,/shell interpolation characters/);
  assert.equal(existsSync(join(dir,'.codex/hooks.json')),false);
});
