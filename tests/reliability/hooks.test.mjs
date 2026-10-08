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
    assert.match(result.stderr,/review this hook in your platform's hook settings/);
    assert.doesNotMatch(result.stderr,/\.claude\/settings\.json/);
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
  const legacy=JSON.parse(installed);
  for(const group of legacy.hooks.PreToolUse) for(const handler of group.hooks) {
    if(handler.command.includes('pelizzai-writegate.mjs')) handler.command=`node "${dir.replace(/\\/g,'/')}/.claude/hooks/pelizzai-writegate.mjs"`;
  }
  writeFileSync(manifest,JSON.stringify(legacy));
  assert.equal(run('--check','--only','writegate').status,1);
  assert.equal(run('--only','writegate').status,0);
  assert.equal(readFileSync(manifest,'utf8'),installed);
  config.hooks.PreToolUse.find(x => x.matcher === 'apply_patch').matcher = 'NeverRuns';
  writeFileSync(manifest, JSON.stringify(config));
  assert.equal(run('--check').status, 1);
  assert.equal(run('--check', '--only', 'writegate').status, 1);
  assert.equal(run('--remove', '--only', 'writegate').status, 0);
  assert.deepEqual(JSON.parse(readFileSync(manifest)).hooks.PreToolUse, [other]);
});

test('Codex commands survive another checkout and a nested session cwd',t=>{
  const dir=fixture(t), other=join(fixture(t),'checkout é $x %PATH%');mkdirSync(other);
  assert.equal(spawnSync('git',['init','-b','main'],{cwd:other}).status,0);
  cpSync(join(root,'.claude/hooks'),join(dir,'.claude/hooks'),{recursive:true});
  const result=spawnSync(process.execPath,[join(root,'scripts/install-hooks.mjs'),'--project',dir,'--platform','codex','--only','guardrails'],{encoding:'utf8'});
  assert.equal(result.status,0,result.stderr);
  const command=JSON.parse(readFileSync(join(dir,'.codex/hooks.json'),'utf8')).hooks.PreToolUse[0].hooks[0].command;
  assert.ok(!command.includes(dir.replace(/\\/g,'/')),'registration must not embed its original checkout');
  const nested=join(other,'sub pasta é $x %PATH%');mkdirSync(nested);
  mkdirSync(join(other,'.claude/hooks'),{recursive:true});
  writeFileSync(join(other,'.claude/hooks/pelizzai-guardrails.mjs'),"import {readFileSync} from 'node:fs'; console.log('RELOCATED:'+JSON.parse(readFileSync(0,'utf8')).marker); process.exitCode=2;\n");
  const run=process.platform==='win32'
    ? spawnSync('pwsh',['-NoProfile','-NonInteractive','-Command',command+'; exit $LASTEXITCODE'],{cwd:nested,input:'{"marker":"stdin-preserved"}',encoding:'utf8'})
    : spawnSync('sh',['-c',command],{cwd:nested,input:'{"marker":"stdin-preserved"}',encoding:'utf8'});
  assert.equal(run.status,2,run.stderr);
  assert.match(run.stdout,/RELOCATED:stdin-preserved/);
});

test('Codex installation needs the Git root; check/remove remain available without Git',t=>{
  const dir=fixture(t), nested=join(dir,'nested');mkdirSync(nested);
  cpSync(join(root,'.claude/hooks'),join(nested,'.claude/hooks'),{recursive:true});
  const run=(...args)=>spawnSync(process.execPath,[join(root,'scripts/install-hooks.mjs'),'--project',nested,'--platform','codex',...args],{encoding:'utf8'});
  assert.equal(run().status,1);
  assert.match(run().stderr,/Git root/);
  assert.equal(existsSync(join(nested,'.codex/hooks.json')),false);
  assert.equal(run('--check').status,0);
  assert.equal(run('--remove').status,0);
});

test('real advisory hooks find the root memory from a nested session',t=>{
  const dir=fixture(t), nested=join(dir,'src/nested');mkdirSync(nested,{recursive:true});
  mkdirSync(join(dir,'pelizzai/data'),{recursive:true});
  writeFileSync(join(dir,'pelizzai/domain-skills.md'),'# Catalog\n');
  writeFileSync(join(dir,'pelizzai/data/state.md'),'- slug: active-fixture\n- phase: exec\n');
  writeFileSync(join(dir,'pelizzai/data/review-domain-skills.md'),'last-review: 2000-01-01\nlast-full-scan: 2000-01-01\n');
  const state=join(dir,'pelizzai/data/.cadence-state.json');
  const input=JSON.stringify({cwd:nested});
  cpSync(join(root,'.claude/hooks'),join(dir,'.claude/hooks'),{recursive:true});
  const install=spawnSync(process.execPath,[join(root,'scripts/install-hooks.mjs'),'--project',dir,'--platform','codex','--only','session-start,cadence'],{encoding:'utf8'});
  assert.equal(install.status,0,install.stderr);
  const settings=JSON.parse(readFileSync(join(dir,'.codex/hooks.json'),'utf8'));
  for(const [name,event] of [['session-start','SessionStart'],['cadence','UserPromptSubmit']]) {
    const command=settings.hooks[event][0].hooks[0].command;
    const variants=[process.platform==='win32'?['pwsh',['-NoProfile','-Command',command+'; exit $LASTEXITCODE']]:['sh',['-c',command]],
      ['pwsh',['-NoProfile','-File',join(dir,`.claude/hooks/pelizzai-${name}.ps1`)]]];
    for(const [executable,args] of variants) {
      writeFileSync(state,'{"count":9,"snoozeUntil":0}');
      const result=spawnSync(executable,args,{cwd:nested,input,encoding:'utf8'});
      assert.equal(result.status,0,result.stderr);
      if(name==='session-start') {
        assert.match(result.stdout,/ACTIVE task.*active-fixture/);
        assert.doesNotMatch(result.stdout,/no domain-skill catalog/);
      } else {
        assert.match(result.stdout,/PelizzAI \(cadence\)/);
        assert.equal(JSON.parse(readFileSync(state,'utf8').replace(/^\uFEFF/,'')).count,10);
      }
      assert.equal(existsSync(join(nested,'pelizzai')),false);
    }
  }
});
