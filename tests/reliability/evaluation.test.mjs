import test from 'node:test';
import assert from 'node:assert/strict';
import {assessRun,completedClaudeWrites} from '../baseline/outcome.mjs';
test('messages and an error cannot be priced as a successful run',()=>{
 const assistant={type:'assistant',message:{content:[{type:'text',text:'I will fix it'}]}};
 const run=events=>({status:0,stdout:events.map(x=>JSON.stringify(x)).join('\n')});
 assert.equal(assessRun(run([assistant])).runCompleted,false);
 assert.equal(assessRun(run([assistant,{type:'result',subtype:'error_max_turns',is_error:true}])).runCompleted,false);
 const result=assessRun(run([assistant,{type:'result',subtype:'success',is_error:false}]));
 assert.equal(result.runCompleted,true);assert.equal(result.taskSucceeded,null);
 assert.equal(assessRun({status:0,stdout:'{broken'}).runCompleted,false);
 assert.equal(assessRun({status:0,stdout:'null'}).runCompleted,false);
 assert.equal(assessRun(run([{type:'result',subtype:'success'},{type:'error'}])).runCompleted,false);
 assert.equal(assessRun(run([{type:'turn.completed'}]),'codex').runCompleted,true);
 assert.equal(assessRun(run([{type:'turn.failed'}]),'codex').runCompleted,false);
});
test('failed or unfinished tool writes are not evidence',()=>{
 const call={type:'assistant',message:{content:[{type:'tool_use',id:'1',name:'Write',input:{file_path:'review.md',content:'pass'}}]}};
 const result=is_error=>({type:'user',message:{content:[{type:'tool_result',tool_use_id:'1',is_error,content:is_error?'Permission denied':'Written'}]}});
 assert.deepEqual(completedClaudeWrites([call]),[]);
 assert.deepEqual(completedClaudeWrites([call,result(true)]),[]);
 assert.equal(completedClaudeWrites([call,result(false)]).length,1);
});
