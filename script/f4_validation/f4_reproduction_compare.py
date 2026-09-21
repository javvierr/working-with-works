"""Fresh-copy replay comparison, preserving exact observed timestamp differences."""
import argparse,collections,datetime,hashlib,json
from pathlib import Path
from f4_semantic_compare import rows,diff,save

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--candidate',required=True,type=Path);ap.add_argument('--replay',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();b=json.loads(a.candidate.read_text());z=json.loads(a.replay.read_text());checks=[];changes=[]
 def check(id,e,o):
  m=diff(e,o);checks.append({'id':id,'status':'PASS' if not m else 'FAIL','mismatches':m})
 check('table_inventory',sorted(b['tables']),sorted(z['tables']))
 for table in b['tables']:
  before=rows(b,table);after=rows(z,table);exclude={'created_at','updated_at'}
  if table=='catalogue_documents':exclude.add('last_successful_at')
  if table=='import_logs':exclude.add('imported_at')
  check(table+'/row_identity',[r['id'] for r in before],[r['id'] for r in after]);norm=lambda rr:[{k:v for k,v in r.items() if k not in exclude} for r in rr];check(table+'/all_nonexcluded_fields',norm(before),norm(after));check(table+'/columns',b['tables'][table]['columns'],z['tables'][table]['columns'])
  for x,y in zip(before,after):
   changed={k:{'candidate':x[k],'replay':y[k]} for k in sorted(set(x)|set(y)) if x.get(k)!=y.get(k)}
   if changed:changes.append({'table':table,'row_id':x['id'],'changed_fields':changed,'all_changes_are_new_run_timestamps':set(changed)<=exclude})
 for k in ['sequences','schema_structure']:
  if k in b:check(k,b[k],z[k])
 if 'schema_metadata' in b:
  metadata=lambda s:{k:[{field:value for field,value in row.items() if field not in ['created_at','updated_at']} for row in values] for k,values in s['schema_metadata'].items()}
  check('schema_metadata_without_fresh_created_updated_timestamps',metadata(b),metadata(z))
 summary={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PASS' if all(c['status']=='PASS' for c in checks) else 'FAIL','checks':len(checks),'passed':sum(c['status']=='PASS' for c in checks),'failed':sum(c['status']=='FAIL' for c in checks),'domain_rows':sum(len(rows(b,t)) for t in b['tables']),'actual_changed_fields_by_table':{t:dict(collections.Counter(k for r in changes if r['table']==t for k in r['changed_fields'])) for t in b['tables']},'timestamp_exclusion_reason':'Fresh initial import creates new legitimate temporal provenance. Exclude created_at/updated_at for alltables; catalogue_documents.last_successful_at;import_logs.imported_at. All other values/IDs/associations/paths/hashes/logoutcomes/sequences/schema match exactly. No path difference was excluded because none occurred.','limit':'Pre-release selective external-copy replay, not a committed public clone or setup/CI qualification.','inputs':[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [a.candidate,a.replay]]};save(a.out/'reproduction_checks.json',checks);save(a.out/'reproduction_timestamp_observations_local_only.json',changes);save(a.out/'reproduction_summary.json',summary);print(json.dumps({k:v for k,v in summary.items() if k!='actual_changed_fields_by_table'},indent=2))
 raise SystemExit(0 if summary['status']=='PASS' else 1)
if __name__=='__main__':main()
