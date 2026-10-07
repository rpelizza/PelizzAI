import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const validator=fileURLToPath(new URL('../../scripts/validate-skills.mjs',import.meta.url));
test('domain skills are validated without imposing harness H1 naming',t=>{
  const dir=mkdtempSync(join(tmpdir(),'pelizzai-skills-'));
  t.after(()=>rmSync(dir,{recursive:true,force:true}));
  const run=()=>spawnSync(process.execPath,[validator,'--skills-root',dir,'--json'],{encoding:'utf8'});
  assert.equal(run().status,1);
  mkdirSync(join(dir,'app-auth'));
  const file=join(dir,'app-auth/SKILL.md');
  writeFileSync(file,'---\nname: app-auth\ndescription: Use for login. Near miss: public pages.\n---\n# Authentication\n');
  assert.equal(run().status,1);
  writeFileSync(file,'---\nname: app-auth\ndescription: "Use for login. Near miss: public pages."\n---\n# Authentication\n');
  assert.equal(run().status,0);
  writeFileSync(file,'---\nname: app-auth\nname: app-auth\ndescription: Login\n---\n# Authentication\n');
  assert.equal(run().status,1);
  for (const value of ['"Use "auth": valid"', '[login, session]', '123', 'true']) {
    writeFileSync(file,`---\nname: app-auth\ndescription: ${value}\n---\n# Authentication\n`);
    assert.equal(run().status,1,value);
  }
  writeFileSync(file,'---\nname: app-auth\ndescription: >\n  Use for login.\n  Near miss: public pages.\n---\n# Authentication\n');
  assert.equal(run().status,0);
});
