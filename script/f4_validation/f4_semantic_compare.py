"""Offline independent comparisons of frozen XML oracle and captured SQL/API.
No application imports; no database connections; no source re-extraction at outcome time.
"""
import argparse,collections,copy,datetime,hashlib,json,csv
from pathlib import Path
MISSING={'__f4_missing__':True}
def pointer(d,p):
 try:
  for bit in p.split('/')[1:]:
   bit=bit.replace('~1','/').replace('~0','~');d=d[int(bit)] if isinstance(d,list) else d[bit]
  return d
 except (KeyError,IndexError,TypeError,ValueError):return MISSING

def diff(expected,actual,path=''):
 if type(expected)!=type(actual):return [{'path':path,'expected':expected,'actual':actual}]
 if isinstance(expected,dict):
  out=[]
  for k in sorted(set(expected)|set(actual)):
   if k not in expected or k not in actual:out.append({'path':path+'/'+k,'expected':expected.get(k,MISSING),'actual':actual.get(k,MISSING)})
   else:out.extend(diff(expected[k],actual[k],path+'/'+k))
  return out
 if isinstance(expected,list):
  out=[]
  if len(expected)!=len(actual):out.append({'path':path+'/length','expected':len(expected),'actual':len(actual)})
  for i,(e,a) in enumerate(zip(expected,actual)):out.extend(diff(e,a,path+'/'+str(i)))
  return out
 return [] if expected==actual else [{'path':path,'expected':expected,'actual':actual}]

def compare(unit,data):
 actual=pointer(data,unit['target_pointer']);op=unit['operation']
 if op=='array_length':actual=len(actual) if isinstance(actual,list) else actual
 elif op=='selected_keys_equal' and isinstance(actual,dict):actual={k:actual.get(k,MISSING) for k in unit['expected']}
 return diff(unit['expected'],actual,unit['target_pointer'])

def rows(snapshot,table):
 d=snapshot['tables'][table];return d['rows'] if isinstance(d,dict) else d

def sql_details(snapshot):
 """Storage-to-public vocabulary adapter only; all joins explicit and audited.
 It maps public names without invoking a model/serializer or computing semantic
 source expectations. Policy name is approved constant; stored display order/reason
 supplies observed selection. Domain values remain exact as captured SQL JSON.
 """
 tables={k:rows(snapshot,k) for k in snapshot['tables']};docby={d['id']:d for d in tables['catalogue_documents']};sources={s['id']:s for s in tables['source_descriptions']};composers={c['id']:c for c in tables['composers']};out={}
 ordered=lambda vals:sorted(vals,key=lambda v:(v['source_order'],v['id']))
 def attrs(row,keys):return {k:row.get(k) for k in keys}|{'attributes':row['source_attributes']}
 for w in tables['works']:
  d=docby[w['catalogue_document_id']];wt=ordered([t for t in tables['work_titles'] if t['work_id']==w['id']]);terms=ordered([t for t in tables['work_classification_terms'] if t['work_id']==w['id']]);titles=[attrs(t,['text','raw_text','source_type','language','xml_id','source_order','locator'])|{'selected_for_display':t['source_order']==w['display_title_order']} for t in wt]
  selected=next((t for t in wt if t['source_order']==w['display_title_order']),None)
  pub={k:w.get(k) for k in ['id','title','catalogue_number','composition_date','composition_year','genre','source_file','source_identifier']};pub['composer']={'id':w['composer_id'],'name':composers[w['composer_id']]['name']};pub['titles']=titles;pub['classification_terms']=[attrs(t,['text','raw_text','xml_id','source_order','locator','classification_metadata','term_list_metadata']) for t in terms];pub['display_title_policy']={'name':'main_untyped_uniform_alternative_subordinate_v1','selection_reason':w['display_title_reason'],'source_order':w['display_title_order'],'xml_id':selected['xml_id'] if selected else None,'subordinate_fallback':selected is not None and selected['source_type']=='subordinate'}
  pub['catalogue_identifiers']=[{'type':i['identifier_type'],'value':i['value']} for i in sorted(tables['catalogue_identifiers'],key=lambda r:r['id']) if i['work_id']==w['id']]
  pub['instrumentation']=[i['name'] for i in tables['instrumentations'] if i['work_id']==w['id']]
  # Preserve exact rows separately; historical comparison decides semantic scope.
  for table in ['movements','source_references','performances','external_references']:pub['sql_'+table]=[r for r in tables.get(table,[]) if r['work_id']==w['id']]
  cs={'document':{k:d[k] for k in ['input_profile','catalogue','record_key','root_xml_id','committed_sha256']},'projection':{'version':d['source_projection_version'],'summary':d['source_projection_summary']},'descriptions':[]}
  for s in ordered([s for s in sources.values() if s['catalogue_document_id']==d['id']]):
   sp=attrs(s,['xml_id','locator','source_order','label','parent_metadata','state','identifiers','titles','classification_terms','publication','physical_description','notes','links','availability']);sp['held_items']=[];sp['relations']=[]
   for item in ordered([i for i in tables['held_items'] if i['source_description_id']==s['id']]):sp['held_items'].append(attrs(item,['xml_id','locator','source_order','label','parent_metadata','state','identifiers','physical_locations','physical_description','links','availability'])|{'source_xml_id':s['xml_id']})
   for rel in sorted([r for r in tables['source_relations'] if r['source_description_id']==s['id']],key=lambda r:(r['relation_order'],r['token_order'],r['id'])):
    sp['relations'].append(attrs(rel,['xml_id','locator','relation_order','token_order','rel','raw_target','target_token','parent_metadata','resolution_state','resolution_reason','expression_context'])|{'source_xml_id':s['xml_id'],'target_source_xml_id':sources[rel['target_source_description_id']]['xml_id'] if rel['target_source_description_id'] is not None else None})
   cs['descriptions'].append(sp)
  pub['catalogue_sources']=cs;out[d['record_key']]=pub
 return out

def run(units,sql,api):
 results=[]
 for unit in units:
  r={k:unit[k] for k in ['assertion_id','record_key','stratum','domain','target_pointer','operation','source_filename','source_sha256','source_locator']}
  for kind,obs in [('sql',sql),('api',api)]:
   mismatch=compare(unit,obs.get(unit['record_key'],MISSING));r[kind+'_status']='PASS' if not mismatch else 'FAIL';r[kind+'_mismatches']=mismatch
  results.append(r)
 return results

def save(p,v):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('x') as f:json.dump(v,f,ensure_ascii=False,indent=2);f.write('\n')

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--units',required=True,type=Path);ap.add_argument('--snapshot',required=True,type=Path);ap.add_argument('--api-observations',required=True,type=Path,help='JSON object keyed by CNW record_key; values are exact full captured detail body');ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();units=json.loads(a.units.read_text())['units'];snap=json.loads(a.snapshot.read_text());sql=sql_details(snap);api=json.loads(a.api_observations.read_text());result=run(units,sql,api);save(a.out/'sql_observed_details_local_only.json',sql);save(a.out/'semantic_extension_sql_selected.json',{k:sql[k] for k in sorted({u['record_key'] for u in units})});save(a.out/'semantic_unit_results.json',result)
 groups=collections.defaultdict(collections.Counter)
 for r in result:
  for kind in ['sql','api']:groups[(r['stratum'],r['domain'],kind)][r[kind+'_status']]+=1
 summary=[{'stratum':s,'domain':d,'observation':k,'eligible':sum(c.values()),**dict(c)} for (s,d,k),c in sorted(groups.items())]
 # Same genuine comparator, changed expectation only; no observation mutation.
 negative=copy.deepcopy(next(u for u in units if u['domain']=='source_titles' and u['operation']=='deep_equal'));negative['expected']['text']='F4 DELIBERATELY WRONG EXPECTED SOURCE TITLE';control={k:compare(negative,o[negative['record_key']]) for k,o in [('sql',sql),('api',api)]}
 save(a.out/'semantic_negative_control.json',{'expected_case_id':negative['assertion_id'],'expected_only_mutation':negative,'observed_bytes_unchanged':True,'sql_rejected':bool(control['sql']),'api_rejected':bool(control['api']),'mismatches':control})
 with (a.out/'semantic_extension_results.csv').open('x',newline='') as f:
  keys=['assertion_id','record_key','stratum','domain','target_pointer','source_filename','source_sha256','source_locator','sql_status','api_status'];w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows({k:r[k] for k in keys} for r in result)
 verdict={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PASS' if all(r[k+'_status']=='PASS' for r in result for k in ['sql','api']) and all(control.values()) else 'FAIL','units':len(result),'source_to_sql_passed':sum(r['sql_status']=='PASS' for r in result),'source_to_api_passed':sum(r['api_status']=='PASS' for r in result),'domains':summary,'inputs':[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [a.units,a.snapshot,a.api_observations]]};save(a.out/'semantic_summary.json',verdict);print(json.dumps({k:v for k,v in verdict.items() if k!='domains'},indent=2))
 raise SystemExit(0 if verdict['status']=='PASS' else 1)
if __name__=='__main__':main()
