import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const validator=fileURLToPath(new URL('../../scripts/validate-skills.mjs',import.meta.url));
const run=dir=>spawnSync(process.execPath,[validator,'--skills-root',dir,'--json'],{encoding:'utf8'});
function fixture(t) {
  const dir=mkdtempSync(join(tmpdir(),'pelizzai-skills-'));
  t.after(()=>rmSync(dir,{recursive:true,force:true}));
  return dir;
}
test('empty skills root reports the skills-root rule',t=>{
  const result=run(fixture(t));assert.equal(result.status,1);
  assert.deepEqual(JSON.parse(result.stdout).violations.map(x=>x.rule),['skills-root']);
});
test('missing and non-directory roots identify the selected CLI option',t=>{
  const dir=fixture(t),file=join(dir,'file');writeFileSync(file,'not a directory');
  for(const path of [join(dir,'missing'),file]) {
    const result=run(path);assert.equal(result.status,2);
    assert.match(result.stderr,/--skills-root.*not an existing directory/);
    assert.doesNotMatch(result.stderr,/at .*\.mjs/);
  }
});
for(const [label,fields,rule] of [
  ['unquoted colon','description: Use for login. Near miss: public pages.','frontmatter'],
  ['duplicate key','name: app-auth\ndescription: Login','frontmatter'],
  ['invalid inner quotes','description: "Use "auth": valid"','frontmatter'],
  ['sequence description','description: [login, session]','description'],
  ['numeric description','description: 123','description'],
  ['boolean description','description: true','description'],
  ['quoted description','description: "Use for login. Near miss: public pages."',null],
  ['folded description','description: >\n  Use for login.\n  Near miss: public pages.',null],
]) test('domain YAML: '+label,t=>{
  const dir=fixture(t);mkdirSync(join(dir,'app-auth'));
  writeFileSync(join(dir,'app-auth/SKILL.md'),'---\nname: app-auth\n'+fields+'\n---\n# Authentication\n');
  const result=run(dir);assert.equal(result.status,rule?1:0,result.stderr);
  assert.deepEqual(JSON.parse(result.stdout).violations.map(x=>x.rule),rule?[rule]:[]);
});
