"""Independent complete-table same-byte reimport accounting. Read captured states only."""
import argparse,collections,datetime,hashlib,json
from pathlib import Path
from f4_semantic_compare import rows,diff,save
ALLOW={'catalogue_documents':{'last_successful_at','latest_successful_path','updated_at'}}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--before',required=True,type=Path);ap.add_argument('--after',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();b=json.loads(a.before.read_text());z=json.loads(a.after.read_text());checks=[];changes=[]
 def check(id,e,o):
  m=diff(e,o);checks.append({'id':id,'status':'PASS' if not m else 'FAIL','mismatches':m})
 check('table_inventory',sorted(b['tables']),sorted(z['tables']))
 for t in b['tables']:
  br=rows(b,t);ar=rows(z,t)
  if t=='import_logs':
   bid={r['id']:r for r in br};aid={r['id']:r for r in ar};check('import_logs_old_rows_unchanged',br,[aid[i] for i in bid]);new=[r for r in ar if r['id'] not in bid];check('new_log_count',446,len(new));check('new_log_all_success',['success']*446,[r['status'] for r in new]);check('new_log_document_coverage',sorted(r['id'] for r in rows(b,'catalogue_documents')),sorted(r['catalogue_document_id'] for r in new));continue
  check(t+'/row_identities',[r['id'] for r in br],[r['id'] for r in ar]);drop=ALLOW.get(t,set());norm=lambda rs:[{k:v for k,v in r.items() if k not in drop} for r in rs];check(t+'/all_nonexcluded_values',norm(br),norm(ar))
  if drop:
   for x,y in zip(br,ar):
    d={k:{'before':x[k],'after':y[k],'changed':x[k]!=y[k]} for k in sorted(drop)};changes.append({'table':t,'row_id':x['id'],'record_key':x['record_key'],'fields':d})
 for k in ['schema_metadata','schema_structure','schema']: 
  if k in b:check(k,b[k],z[k])
 # Every domain sequence must stay fixed. ImportLog append sequence changes separately.
 bs=b.get('sequences',{});zs=z.get('sequences',{})
 if isinstance(bs,dict):
  check('sequence_inventory',sorted(bs),sorted(zs))
  for name in bs:
   if 'import_logs' not in name:check('sequence/'+name,bs[name],zs[name])
 else:
  def name(v):return v.get('sequence_name') or v.get('name') or str(v)
  check('nonlog_sequences',[s for s in bs if 'import_logs' not in name(s)],[s for s in zs if 'import_logs' not in name(s)])
 precision=collections.Counter()
 for r in rows(b,'catalogue_documents')+rows(z,'catalogue_documents'):
  for k in ['last_successful_at','updated_at']:
   value=r[k];part=value.split('.',1)[1].rstrip('Z') if isinstance(value,str) and '.' in value else '';precision[len(part)]+=1
 summary={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PASS' if all(c['status']=='PASS' for c in checks) else 'FAIL','checks':len(checks),'passed':sum(c['status']=='PASS' for c in checks),'failed':sum(c['status']=='FAIL' for c in checks),'excluded_fields':{k:sorted(v) for k,v in ALLOW.items()},'exclusion_reason':'Approved same-byte success-attempt/provenance timestamps/path may change. Every other domain field, identity and association must remain exact. Existing logs append-only;446newsuccessattempts withoneperdocument.','timestamp_fractional_digits_observed':dict(precision),'inputs':[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [a.before,a.after]]};save(a.out/'reimport_checks.json',checks);save(a.out/'reimport_allowed_field_observations.json',changes);save(a.out/'reimport_summary.json',summary);print(json.dumps(summary,indent=2))
 raise SystemExit(0 if summary['status']=='PASS' else 1)
if __name__=='__main__':main()
