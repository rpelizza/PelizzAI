import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,writeFileSync,rmSync,existsSync,symlinkSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {buildIndex,searchMemory} from '../../scripts/project-memory.mjs';
test('retrieval reaches archives, keeps active rules, and revalidates changed knowledge',t=>{
 const dir=mkdtempSync(join(tmpdir(),'pelizzai-memory-'));t.after(()=>rmSync(dir,{recursive:true,force:true}));
 mkdirSync(join(dir,'pelizzai/data/history'),{recursive:true});
 writeFileSync(join(dir,'pelizzai/data/learnings.md'),'# Learnings\n## Active rules\n- Confirm storage ownership before deletion.\n## Incident log\nUnrelated incident.');
 writeFileSync(join(dir,'pelizzai/data/history/old.md'),'# Prior delivery\nOAuth picture reused a production bucket.\ncause: storage/ownership\n');
 const index=buildIndex(dir), result=searchMemory(index,'OAuth bucket');
 assert.equal(result.matches[0].path,'pelizzai/data/history/old.md');
 assert.equal(result.matches[0].kind,'historical');
 assert.match(result.activeRules,/Confirm storage/);assert.doesNotMatch(result.activeRules,/Unrelated/);
 assert.equal(searchMemory(index,'unfindable-term').matches.length,0);
 writeFileSync(join(dir,'pelizzai/data/history/new.md'),'# New incident\nOAuth failure\n');
 const updated=buildIndex(dir);assert.notEqual(updated.corpusHash,index.corpusHash);
 assert.equal(searchMemory(updated,'OAuth').matches.length,2);
 assert.equal(existsSync(join(dir,'pelizzai/data/memory-index.json')),false);
 writeFileSync(join(dir,'pelizzai/data/learnings.md'),'# Aprendizados\n## Regras ativas\n- Conferir propriedade antes de remover.\n## Incidentes\nOutro incidente.');
 const legacy=searchMemory(buildIndex(dir),'OAuth');
 assert.equal(legacy.activeRulesStatus,'recognized');
 assert.match(legacy.activeRules,/Conferir propriedade/);assert.doesNotMatch(legacy.activeRules,/Outro incidente/);
 writeFileSync(join(dir,'pelizzai/data/learnings.md'),'# Custom layout\nAlways preserve storage ownership.');
 const unknown=searchMemory(buildIndex(dir),'OAuth');
 assert.equal(unknown.activeRulesStatus,'unrecognized-heading-read-full-source');
 assert.match(unknown.activeRules,/Always preserve/);
 writeFileSync(join(dir,'pelizzai/data/learnings.md'),'# Learnings\n## Active rules\n- Preserve ownership through EOF.');
 const eof=searchMemory(buildIndex(dir),'OAuth');
 assert.equal(eof.activeRulesStatus,'recognized');
 assert.match(eof.activeRules,/Preserve ownership through EOF/);
});

test('history links cannot import data outside the project memory',t=>{
 const dir=mkdtempSync(join(tmpdir(),'pelizzai-memory-links-'));t.after(()=>rmSync(dir,{recursive:true,force:true}));
 mkdirSync(join(dir,'pelizzai/data/history'),{recursive:true});
 const outside=join(dir,'outside.md');writeFileSync(outside,'# Private outside corpus\nExternal confidential data.');
 try {symlinkSync(outside,join(dir,'pelizzai/data/history/linked.md'));}
 catch(error) {if(process.platform==='win32'&&['EPERM','EACCES'].includes(error.code)){t.skip('Host does not permit file symlinks');return;}throw error;}
 assert.equal(buildIndex(dir).entries.length,0);
});

test('a linked memory root is rejected',t=>{
 const dir=mkdtempSync(join(tmpdir(),'pelizzai-memory-root-'));t.after(()=>rmSync(dir,{recursive:true,force:true}));
 const outside=join(dir,'outside');mkdirSync(outside);writeFileSync(join(outside,'context.md'),'# External memory');
 symlinkSync(outside,join(dir,'pelizzai'),process.platform==='win32'?'junction':'dir');
 assert.throws(()=>buildIndex(dir),/Memory root must not be a link/);
});
