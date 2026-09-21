"""Replay five independent F4 evidence comparisons without any database access."""
import argparse,datetime,hashlib,json,pathlib,subprocess,sys
P=pathlib.Path

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--run',type=P,required=True);ap.add_argument('--out',type=P,required=True);a=ap.parse_args()
 run=a.run.resolve(strict=True);out=a.out.resolve();tools=P(__file__).resolve().parent;repo=tools.parents[1]
 if out.exists() or out==repo or repo in out.parents:raise SystemExit('Output must be new and outside application repository')
 freeze=json.loads((run/'acceptance/master_freeze_v1.json').read_text())
 for row in freeze['artifacts']:
  rel=P(row['path'])
  if rel.is_absolute() or '..' in rel.parts:raise SystemExit('Unsafe frozen artifact name')
  p=run/rel
  if p.is_symlink() or hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:raise SystemExit('Frozen artifact identity mismatch: '+str(rel))
 def path(s):return str(run/s)
 jobs=[
 ('census','f4_census_compare.py',['--census',path('acceptance/semantic_frozen/semantic_corpus_census_v1.json'),'--snapshot',path('validation/corpus_import_01/state_after_local_only.json')]),
 ('extension','f4_semantic_compare.py',['--units',path('acceptance/semantic_frozen/semantic_assertion_units_v2.json'),'--snapshot',path('validation/corpus_reimport_01/state_after_local_only.json'),'--api-observations',path('validation/semantic_api_bodies.json')]),
 ('historical','f4_historical_compare.py',['--cases',path('acceptance/semantic_frozen/semantic_historical_cases_v1.json'),'--source-facts',path('acceptance/semantic_frozen/semantic_legacy_source_facts_v1.json'),'--census',path('acceptance/semantic_frozen/semantic_corpus_census_v1.json'),'--snapshot',path('validation/corpus_reimport_01/state_after_local_only.json'),'--api-observations',path('validation/semantic_api_bodies.json')]),
 ('reimport','f4_reimport_compare.py',['--before',path('validation/corpus_reimport_01/state_before_local_only.json'),'--after',path('validation/corpus_reimport_01/state_after_local_only.json')]),
 ('reproduction','f4_reproduction_compare.py',['--candidate',path('validation/corpus_import_01/state_after_local_only.json'),'--replay',path('validation/reproduction_corpus_import_01/state_after_local_only.json')])]
 out.mkdir(mode=0o700,parents=True);results=[]
 for label,tool,args in jobs:
  command=[sys.executable,"-B",str(tools/tool),*args,'--out',str(out/label)];start=datetime.datetime.now(datetime.timezone.utc).isoformat();cp=subprocess.run(command,capture_output=True,text=True)
  (out/(label+'.stdout.log')).write_text(cp.stdout);(out/(label+'.stderr.log')).write_text(cp.stderr)
  results.append({'phase':label,'command':command,'start_utc':start,'end_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'exit_code':cp.returncode,'tool_sha256':hashlib.sha256((tools/tool).read_bytes()).hexdigest()})
 result={'status':'PASS' if all(r['exit_code']==0 for r in results) else 'FAIL','scope':'Offline retained evidence replay; no database/newsource/applicationexecution','results':results};(out/'result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));return 0 if result['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
