#!/usr/bin/env python3
"""Offline F4 ZIP audit. Reads only the named ZIP/optional external allowlist.
Never extracts or executes payloads, connects to a database, or changes Git.
Usage: python3 audit_review.py REVIEW.zip --output REVIEW.validation.json
"""
from __future__ import annotations
import argparse,collections,csv,datetime,hashlib,io,json,re,stat,sys,zipfile
from pathlib import Path,PurePosixPath
DOCS=['F4_completion.md','F4_decisions.md','F4_checks.json','F4_acceptance_results.csv','F4_evaluation_protocol.md','F4_corpus_results.csv','F4_historical_assertion_results.csv','F4_semantic_extension_results.csv','F4_api_results.md','F4_operational_results.md','F4_developer_walkthrough.md','F4_report_notes.md','feedback_to_evidence_proposed.md']
DOMAIN={'catalogue_documents','catalogue_identifiers','composers','external_references','held_items','import_logs','instrumentations','movements','performances','source_descriptions','source_references','source_relations','work_classification_terms','work_titles','works'}
META={'packaging/allowlist.json','MANIFEST.sha256'}
MAX_MEMBER_BYTES=128*1024*1024
MAX_TOTAL_BYTES=1024*1024*1024
class AuditFailure(Exception):pass
def safe_name(name):
 p=PurePosixPath(name)
 return bool(name) and name==p.as_posix() and not p.is_absolute() and '..' not in p.parts and '\\' not in name and '\x00' not in name and not re.match(r'^[A-Za-z]:',name) and not name.endswith('/')
def forbidden(name):
 parts=PurePosixPath(name).parts;base=parts[-1]
 return any(x in {'.git','node_modules','__pycache__','.bundle','vendor','cache','app','reproduction_app'} for x in parts) or '_local_only' in name or base in {'before.json','after.json','initial_state.json','final_state.json','before_gets.json','after_gets.json'} or bool(re.search(r'(?:^|/)(?:snapshot|state)[_-](?:before|after)(?:[_\.]|$)',name)) or (name.startswith('validation/') and base.startswith('projection_')) or base.lower().endswith(('.zip','.dump','.sql.gz','.pyc','.key','.pem')) or bool(re.search(r'(?:^|/)(?:credentials|secrets?|private_participants?|consents?|\.env)(?:[./_]|$)',name,re.I))
def full_db_rows(value):
 if isinstance(value,dict):
  keys=set(value)&DOMAIN
  if len(keys)>=3 and all(isinstance(value[k],list) or isinstance(value[k],dict) and 'rows' in value[k] for k in keys):return True
  return any(full_db_rows(x) for x in value.values())
 if isinstance(value,list):return any(full_db_rows(x) for x in value)
 return False
def sha(data):return hashlib.sha256(data).hexdigest()
def run_audit(zip_path:Path,external_allowlist:Path|None=None):
 checks=[];facts={};errors=[]
 def require(label,value,detail=None):
  checks.append({'check':label,'status':'PASS' if value else 'FAIL',**({'detail':detail} if detail is not None else {})})
  if not value:raise AuditFailure(label)
 with zipfile.ZipFile(zip_path) as archive:
  infos=archive.infolist();names=[x.filename for x in infos];known=set(names)
  require('safe_unique_plain_entries',len(names)==len(known) and all(safe_name(n) for n in names))
  require('no_casefold_aliases',len({n.casefold() for n in names})==len(names))
  require('no_excluded_names',not [n for n in names if forbidden(n)])
  require('unencrypted_regular_payloads',all(not (x.flag_bits&1) and stat.S_IFMT(x.external_attr>>16) in {0,stat.S_IFREG} for x in infos))
  require('bounded_payload_sizes',all(x.file_size<=MAX_MEMBER_BYTES for x in infos) and sum(x.file_size for x in infos)<=MAX_TOTAL_BYTES)
  require('required_metadata',META<=known)
  def read_json(name):return json.loads(archive.read(name))
  allow=read_json('packaging/allowlist.json');entries=allow['files'];allow_names=[x['path'] for x in entries]
  require('explicit_allowlist_unique',len(allow_names)==len(set(allow_names)) and all(safe_name(x) for x in allow_names))
  require('exact_allowlisted_set',known==set(allow_names)|META and not set(allow_names)&META)
  if external_allowlist:
   external=json.loads(external_allowlist.read_text());require('external_allowlist_agrees',external==allow)
  manifest={}
  for line in archive.read('MANIFEST.sha256').decode('utf-8').splitlines():
   match=re.fullmatch(r'([0-9a-f]{64})  (.+)',line)
   require('manifest_line_safe',bool(match) and safe_name(match.group(2)))
   digest,name=match.groups();require('manifest_entry_unique',name not in manifest);manifest[name]=digest
  require('manifest_exact_payload_set',set(manifest)==known-{'MANIFEST.sha256'})
  allow_by={x['path']:x for x in entries};verified=[];guard_counts={}
  for info in infos:
   h=hashlib.sha256();size=0
   with archive.open(info) as member:
    while True:
     chunk=member.read(1024*1024)
     if not chunk:break
     h.update(chunk);size+=len(chunk)
   require('readback:'+info.filename,size==info.file_size and (info.filename=='MANIFEST.sha256' or h.hexdigest()==manifest[info.filename]))
   if info.filename in allow_by:
    row=allow_by[info.filename];require('allowlist_identity:'+info.filename,row['bytes']==size and row['sha256']==h.hexdigest())
   verified.append({'path':info.filename,'bytes':size,'sha256':h.hexdigest()})
   if info.filename.endswith('.jsonl') and 'guard' in PurePosixPath(info.filename).name:
    sequences=[];sql_count=0;no_literals=True;sql_shape=True
    with archive.open(info) as handle:
     for line in handle:
      if not line.strip():continue
      event=json.loads(line);no_literals=no_literals and 'sql' not in event and 'binds' not in event
      if 'sequence' in event:sequences.append(event['sequence'])
      if 'sql_type_prefix' in event:
       sql_count+=1;sql_shape=sql_shape and bool(re.fullmatch(r'[A-Z]+',event['sql_type_prefix'])) and bool(re.fullmatch(r'[0-9a-f]{64}',event.get('sql_sha256','')))
    require('guard_has_no_SQL_literals:'+info.filename,no_literals)
    require('guard_SQL_projection_shape:'+info.filename,sql_shape)
    require('guard_sequence_continuity:'+info.filename,not sequences or sequences==list(range(1,len(sequences)+1)))
    guard_counts[info.filename]={'events':len(sequences),'SQL_events':sql_count}
   elif info.filename.endswith('.json') and info.file_size<64*1024*1024:
    require('no_embedded_full_DB_rows:'+info.filename,not full_db_rows(read_json(info.filename)))
  def one(suffix):
   matches=[x for x in names if x==suffix or x.endswith('/'+suffix)];require('unique_required_member:'+suffix,len(matches)==1);return matches[0]
  docs={name:one('docs/final_submission/f4/'+name) for name in DOCS}
  for name in ['F4_Codex_Prompt.txt','F3Z1_Review.md','F4_Specification.md','F4_Acceptance.md']:one('input_contract/'+name)
  csv.field_size_limit(16*1024*1024)
  def csv_rows(name):return list(csv.DictReader(io.StringIO(archive.read(name).decode('utf-8'))))
  historical=csv_rows(docs['F4_historical_assertion_results.csv']);hist_frozen=read_json(one('acceptance/semantic_frozen/semantic_historical_cases_v1.json'))['cases'];hist_by={x['assertion_id']:x for x in hist_frozen}
  require('historical83_unique_frozen_IDs',len(historical)==83 and len({x['assertion_id'] for x in historical})==83 and {x['assertion_id'] for x in historical}==set(hist_by))
  require('historical_expectations_preserved',all(json.loads(x['original_expectation'])==hist_by[x['assertion_id']]['original_expectation'] for x in historical))
  require('legacy277_04_retained',sum(x['assertion_id']=='277-04' for x in historical)==1)
  corpus=csv_rows(docs['F4_corpus_results.csv']);profile=read_json(one('input_contract/context/source_profile.json'))['per_file'];by_file={x['filename']:x for x in profile}
  require('corpus446_exact_pinned_file_set',len(corpus)==446 and len({x['filename'] for x in corpus})==446 and {x['filename'] for x in corpus}==set(by_file))
  require('corpus_pinned_hash_sizes',all(x['sha256']==by_file[x['filename']]['sha256'] and int(x['bytes'])==by_file[x['filename']]['bytes'] for x in corpus))
  require('corpus_aggregate_bytes',sum(int(x['bytes']) for x in corpus)==26925115)
  semantic=csv_rows(docs['F4_semantic_extension_results.csv']);frozen=read_json(one('acceptance/semantic_frozen/semantic_assertion_units_v2.json'));units=frozen['units'];unit_by={x['assertion_id']:x for x in units}
  require('semantic_frozen_assertion_IDs',len(semantic)==len(units) and len({x['assertion_id'] for x in semantic})==len(semantic) and {x['assertion_id'] for x in semantic}==set(unit_by))
  require('semantic_rows_match_frozen_selection',all(all(row[k]==str(unit_by[row['assertion_id']][k] or '') for k in ['record_key','stratum','domain','target_pointer','source_filename','source_sha256']) for row in semantic))
  denominators=collections.Counter((x['stratum'],x['domain']) for x in semantic);frozen_denominators={(x['stratum'],x['domain']):x['eligible_units'] for x in frozen['denominators']}
  require('semantic_stratum_domain_denominators',dict(denominators)==frozen_denominators)
  summary=read_json(one('validation/semantic_extension_01/semantic_summary.json'))
  require('semantic_summary_total',summary['units']==len(semantic))
  for domain in summary['domains']:
   chosen=[x for x in semantic if x['stratum']==domain['stratum'] and x['domain']==domain['domain']];statuses=collections.Counter(x[domain['observation']+'_status'] for x in chosen)
   require('semantic_summary_denominator_and_status_counts',domain['eligible']==len(chosen) and all(domain.get(k,0)==v for k,v in statuses.items()))
  api=read_json(one('acceptance/api_f3_frozen/f3_api_cases_v1.json'));truth=read_json(one('acceptance/api_f3_frozen/f3_synthetic_truth_v1.json'))
  require('frozen_API234_truth48',len(api['cases'])==234 and len(truth['rows'])==48)
  api_freeze=read_json(one('acceptance/api_f3_frozen/f3_prospective_freeze_manifest.json'))
  for row in api_freeze['files']:
   path=one('acceptance/api_f3_frozen/'+row['path']);require('original_F3_freeze_payload:'+row['path'],sha(archive.read(path))==row['sha256'])
  completion=archive.read(docs['F4_completion.md']).decode();notes=archive.read(docs['F4_report_notes.md']).decode()
  require('participant_decision_separate','NOT_EVALUATED_BY_USER_DECISION' in completion and 'NOT_EVALUATED_BY_USER_DECISION' in notes)
  resource=read_json(one('evidence/postgres_resource.json'));require('owned_PostgreSQL_shutdown',resource.get('status')=='STOPPED')
  facts={'member_count':len(names),'verified_manifest_payloads':len(manifest),'payload_bytes':sum(x.file_size for x in infos),'required_documents':len(docs),'historical_rows':len(historical),'corpus_rows':len(corpus),'semantic_units':len(semantic),'semantic_observation_columns':2,'semantic_denominators':len(denominators),'frozen_API_cases':len(api['cases']),'frozen_synthetic_rows':len(truth['rows']),'guard_files':len(guard_counts),'guard_counts':guard_counts,'archive_readback_payload_identities':verified}
 return {'status':'PASS','scope':'OfflineZIPintegrity,explicitallowlist,forbiddenpayloadabsence,guardprojection,frozenidentity/denominator/reportconsistency. This doesnotindependentlyrerunapplicationtests or turnPARTIALtechnicaloutcomes intoPASS.','checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archive_path':str(zip_path.resolve()),'archive_bytes':zip_path.stat().st_size,'archive_sha256':sha(zip_path.read_bytes()),'facts':facts,'checks':checks}
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('zip',type=Path);parser.add_argument('--allowlist',type=Path);parser.add_argument('--output',type=Path);args=parser.parse_args()
 try:report=run_audit(args.zip,args.allowlist)
 except Exception as error:report={'status':'FAIL','checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archive_path':str(args.zip.resolve()),'error_class':type(error).__name__,'reason':str(error)}
 if args.output:
  with args.output.open('x') as handle:json.dump(report,handle,indent=2,ensure_ascii=False);handle.write('\n')
 print(json.dumps({k:v for k,v in report.items() if k not in ['facts','checks']},ensure_ascii=False));return 0 if report['status']=='PASS' else 1
if __name__=='__main__':sys.exit(main())
