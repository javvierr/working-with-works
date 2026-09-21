"""Reevaluate immutable historical assertions using fresh captured SQL/API.
Compound meaning follows original mapped-meaning text. Classifications remain
preserved/transformed as intended/omitted/incorrect/not applicable, separate from
current supported-scope eligibility and SQL/API equality. No old result is copied.
"""
import argparse,collections,datetime,hashlib,json,csv,re
from pathlib import Path
from f4_semantic_compare import sql_details,diff,save

def title_rows(p):return [{'text':t['text'],'language':t['language'] or '','type':t['source_type'] or ''} for t in p['titles']]
def pub(p,kind):
 out={k:p[k] for k in ['title','composer','catalogue_number','catalogue_identifiers','composition_date','composition_year','titles','classification_terms','catalogue_sources','instrumentation']}
 if kind=='sql':
  out['performances']=[{k:r[k] for k in ['performed_on','location','performers','note']} for r in p['sql_performances']]
  out['external_references']=[{k:r[k] for k in ['label','url']} for r in p['sql_external_references']]
  out['movements']=p['sql_movements']
 else:
  for k in ['performances','external_references','movements']:out[k]=p[k]
 return out

def selected(c,actual):
 d=c['domain'];e=c['original_expectation'];cs=actual['catalogue_sources'];sources=cs['descriptions'];items=[i for s in sources for i in s['held_items']]
 if d=='work_identity':return {'catalogue_number':actual['catalogue_number'],'catalogue_identifiers':actual['catalogue_identifiers'],'document':cs['document']}
 if d=='responsibility':return {'composer_name':actual['composer']['name'],'other_contributor_rows':[]}
 if d=='catalogue_identifier':return {'catalogue_number':actual['catalogue_number'],'rows':actual['catalogue_identifiers']}
 if d=='title':return {'display_title':actual['title'],'rows':title_rows(actual)}
 if d=='composition_date':return {'composition_date':actual['composition_date'],'composition_year':actual['composition_year']}
 if d=='component_structure':return {'expression_or_component_entities':[],'movement_count':len(actual['movements']),'source_relation_contexts':[r['expression_context'] for s in sources for r in s['relations'] if r['expression_context']]}
 if d=='instrumentation':return {'count':len(actual['instrumentation']),'names':sorted(actual['instrumentation']),'retained_resource_attributes':[]}
 if d=='source_description':
  hands=[v for i in items for v in i['physical_description'] if v['element']=='hand'];v={'manifestations':len(sources),'held_items':len(items),'hand_lists':len({h['parent_metadata']['locator'] for h in hands}),'summary':cs['projection']['summary']}
  if sources:
   s=sources[0];item=s['held_items'][0] if s['held_items'] else None;v['representative']={'manifestation_title':s['titles'][0]['text'] if s['titles'] else None,'item_identifier':item['identifiers'][0]['text'] if item and item['identifiers'] else None,'repository':None,'location':None}
   if item and item['physical_locations']:
    loc=item['physical_locations'][0];v['representative']['location']=loc['identifiers'][0]['text'] if loc['identifiers'] else None
    if loc['repositories']:
     repo=loc['repositories'][0];v['representative']['repository']=repo['identifiers'][0]['text'] if repo['identifiers'] else None
  return v
 if d=='performance_and_relation_absence':return {'events':len(actual['performances']),'external_references':len(actual['external_references'])}
 if d=='performance_event':return {'event_count':len(actual['performances'])}|({'first_event':actual['performances'][0] if actual['performances'] else None} if 'first_event' in e else {})
 if d=='relation_target':return {'external_references':actual['external_references'],'count':len(actual['external_references']),'work_graph_entities':[],'source_relation_scope':'Explicit source-owned relations do not represent work-level component/graph/graphic targets.'}
 if d=='technical_import':return {'committed_document':cs['document'],'current_work_available':True}
 raise ValueError(d)

def evaluate(c,obs,fact,corpus):
 e=c['original_expectation'];domain=c['domain'];cid=c['assertion_id'];in_scope=True;reason='';classification='incorrect';source_check=True
 if domain=='technical_import':
  source_check=e['file_size']==corpus['bytes'];classification='not applicable';in_scope=False;reason='Technical-only original assertion: pinned byte size/source namespace and current committed work availability are recorded separately from semantic fidelity.'
 elif domain=='work_identity':
  want=e.get('identifiers') or e.get('cnw') or [e['identifier']];got=obs['catalogue_identifiers'];ok=fact['work_count']==e['work_count']==1 and all(i in got for i in want) and obs['document']['record_key']==fact['record_key'];classification='preserved' if ok else 'incorrect';reason='One document-owned work with the exact original direct catalogue identity; collection keys retain their literal text.'
 elif domain=='responsibility':
  composers=[i['name'] for i in e if i['role']=='composer'];ok=obs['composer_name'] in composers;others=[i for i in e if i['role']!='composer'];classification='incorrect' if not ok else 'omitted' if others else 'preserved';in_scope=not others;reason='The observed composer is compared to the direct source composer. Additional original contributor roles remain absent and keep the compound assertion omitted.' if others else 'The direct composer is the entire responsibility asserted by this original row.'
 elif domain=='catalogue_identifier':
  classification='preserved' if obs['rows']==e else 'incorrect';reason='Exact ordered original identifier type/value inventory is compared, with explicit database-ID source insertion order rather than a newly claimed ordinal column.'
 elif domain=='title':
  want=e if isinstance(e,list) else e.get('titles');ok=True
  if want is not None:ok=obs['rows']==want
  if isinstance(e,dict):
   if 'count' in e:ok=ok and len(obs['rows'])==e['count']
   if 'languages' in e:ok=ok and [x['language'] for x in obs['rows']]==e['languages']
   if 'types' in e:ok=ok and [x['type'] for x in obs['rows']]==e['types']
   if 'subordinate_count' in e:ok=ok and sum(x['type']=='subordinate' for x in obs['rows'])==e['subordinate_count']
  original_heading=next((t['text'] for t in fact['titles'] if t['type']=='' and t['text']),None)
  if want is not None:ok=ok and obs['display_title']==original_heading
  classification='preserved' if ok else 'incorrect';reason='All asserted ordered title texts/types/languages and the historical first-untyped heading are compared directly.'
  if cid=='277-04':reason+=' The original first-untyped expectation remains Serenade; PASS here is not substituted from F1 ranking. The separate S4-277 work_display unit independently checks the approved F1 policy.'
 elif domain=='composition_date':
  if e.get('direct_creation_count')==0:ok=obs['composition_date'] is None and obs['composition_year'] is None;classification='preserved' if ok else 'incorrect';reason='No direct source creation is compared with absent date and year; no nested date is substituted.'
  else:
   want=e['creation_text'];year=int(re.search(r'\d{4}',want).group());ok=obs['composition_date']==want and obs['composition_year']==year;classification='transformed as intended' if ok else 'incorrect';reason='Original complete date wording preserves exact/ranged/uncertain meaning; the first/lower year is the declared scalar normalization. No structured-bound field is falsely claimed.'
 elif domain=='component_structure':
  classification='omitted';in_scope=False;reason='The current schema has no full expression/component entity hierarchy. Explicit source-to-expression context is retained separately and cannot satisfy this broader original hierarchy assertion.'
 elif domain=='instrumentation':
  pure_count=isinstance(e,dict) and set(e).issubset({'populated_resources'})
  if pure_count:
   wanted=e['populated_resources'];classification='preserved' if obs['count']==wanted else 'omitted';reason='The original bounded populated-resource count is compared with stored/API rows; retained occurrences are not inferred from distinct names.'
  else:
   names=[v['text'] for v in fact['performance_resources']];supportednames={str(v['attributes'].get('count') or '').strip()+' '+str(v['text']) for v in fact['performance_resources']}|set(names);unexpected=[x for x in obs['names'] if x not in {v.strip() for v in supportednames}];classification='incorrect' if unexpected else 'omitted';in_scope=False;reason='Names/count strings survive where represented, but resource occurrences/codedval/solo/grouping in the original compound assertion are not fully represented. Missing attributes remain an omission, not a successful rich-resource mapping.'
 elif domain=='source_description':
  checks=[]
  for k in ['manifestations','held_items','hand_lists']:
   if k in e:checks.append(obs[k]==e[k])
  representative=e.get('representative') or (e if 'manifestation_title' in e else None)
  if representative:checks.extend(obs.get('representative',{}).get(k)==v for k,v in representative.items())
  classification='preserved' if all(checks) else 'omitted';reason='Original source/item counts and any representative title/repository/location/hand ownership are compared with explicit F2 document/source/item projections, separately from legacy SourceReference.'
  if cid=='2-B04':in_scope=False;reason+=' The original structural count includes nested item_e5f8b4a6 below item/componentList, outside approved direct itemList/item selection: structural38 versus eligible37. The omission remains visible rather than widening the mapping.'
 elif domain=='performance_and_relation_absence':
  classification='preserved' if obs['events']==e['events']==0 and obs['external_references']==e['relation_ref_ptr_targets']==0 else 'incorrect';reason='Original zero-event/zero-target assertion is checked against actual empty domain rows and API arrays.'
 elif domain=='performance_event':
  count=e.get('event_count',e.get('events'));ok=obs['event_count']==count
  if 'first_event' not in e:classification='preserved' if ok else 'omitted';reason='The original bounded event-node count is compared; no richer event model is implied.'
  else:
   first=e['first_event'];got=obs['first_event'];parts=[]
   if first.get('venue'):parts.append('Venue: '+first['venue'])
   if first.get('place'):parts.append('Place: '+first['place'])
   people=[x['name']+(' ('+x['role']+')' if x.get('role') else '') for x in first.get('people',[])];corporations=[x['name']+(' ('+x['role']+')' if x.get('role') else '') for x in first.get('corporations',[])];expected={'performed_on':first.get('date') or None,'location':'; '.join(parts) or None,'performers':', '.join(people+corporations) or None,'note':first.get('description') or None}
   ok=ok and got==expected;classification='transformed as intended' if ok else 'omitted';reason='Compare original mapped meaning: event count and representative direct date/place/venue/participants/roles/description through declared flat strings. Source element_text is retained as context, including bibliography outside this selected event mapping; full event XML is not claimed.'
   if cid=='277-11':in_scope=False;reason='The original one event node is empty of supported direct values. A truthful skipped-event warning and no invented Performance record do not preserve an event entity; original assertion remains omitted.'
 elif domain=='relation_target':
  refs=obs['external_references'];absolute=[v for v in fact['targets'] if v['element'] in ['relation','ptr','ref'] and re.match(r'^https?://[^/\s]+',v['target'])];actual=[r['url'] for r in refs];expectedurls=list(dict.fromkeys(v['target'] for v in absolute));unexpected=[url for url in actual if url not in expectedurls]
  count_only=set(e).issubset({'absolute_work_urls','absolute_urls'})
  if count_only:expectedcount=next(iter(e.values()));classification='preserved' if len(actual)==expectedcount and sorted(actual)==sorted(expectedurls) else 'incorrect';reason='Bounded original absolute HTTP(S) URL assertion is compared separately from unresolved/unsupported work-graph targets.'
  else:classification='incorrect' if unexpected else 'omitted';in_scope=False;reason='The original broader work/component/graphic target inventory is not represented by the bounded source-owned relation graph. Retained syntactically absolute HTTP(S) references are checked for contradiction; internal, relative, graphic and other graph meanings remain omitted.'
 return classification,in_scope,reason,source_check

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--cases',required=True,type=Path);ap.add_argument('--source-facts',required=True,type=Path);ap.add_argument('--census',required=True,type=Path);ap.add_argument('--snapshot',required=True,type=Path);ap.add_argument('--api-observations',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();cases=json.loads(a.cases.read_text())['cases'];facts=json.loads(a.source_facts.read_text())['files'];census={r['filename']:r for r in json.loads(a.census.read_text())['files']};sql=sql_details(json.loads(a.snapshot.read_text()));api=json.loads(a.api_observations.read_text());result=[]
 for c in cases:
  fact=facts[c['source_filename']];key=fact['record_key'];r=dict(c);r['record_key']=key;r['source_sha256']=census[c['source_filename']]['sha256'];r['source_facts_reference']='acceptance/semantic_frozen/semantic_legacy_source_facts_v1.json#/files/'+c['source_filename'];r['current_sql_observation']=selected(c,pub(sql[key],'sql'));r['current_api_observation']=selected(c,pub(api[key],'api'));classification,in_scope,reason,source_check=evaluate(c,r['current_sql_observation'],fact,census[c['source_filename']]);api_class,_,_,_=evaluate(c,r['current_api_observation'],fact,census[c['source_filename']]);r['current_classification']=classification;r['api_classification']=api_class;r['approved_supported_scope_eligible']=in_scope;r['rationale']=reason;r['SQL_API_agreement']=r['current_sql_observation']==r['current_api_observation'];r['source_identity_checked']=source_check;r['evaluation_status']='EVALUATED' if r['SQL_API_agreement'] and classification==api_class else 'FAIL';r.pop('status');result.append(r)
 summary={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'gate_status':'PASS' if len(result)==83 and all(r['evaluation_status']=='EVALUATED' and r['source_identity_checked'] and (not r['approved_supported_scope_eligible'] or r['current_classification'] in ['preserved','transformed as intended']) for r in result) else 'FAIL','rows':len(result),'original_semantic_eligible':sum(r['original_eligible'] for r in result),'current_supported_scope_eligible':sum(r['approved_supported_scope_eligible'] for r in result),'classifications':dict(collections.Counter(r['current_classification'] for r in result)),'SQL_API_agreement':sum(r['SQL_API_agreement'] for r in result),'by_domain':[{ 'domain':d,'rows':len(rs),'classifications':dict(collections.Counter(r['current_classification'] for r in rs)),'original_semantic_eligible':sum(r['original_eligible'] for r in rs),'current_supported_scope_eligible':sum(r['approved_supported_scope_eligible'] for r in rs)} for d,rs in [(d,[r for r in result if r['domain']==d]) for d in sorted({r['domain'] for r in result})]],'technical_gate_note':'PASS means complete honest fresh evaluation with immutable expectations. It does not turn omitted/unsupported historical assertions into semantic passes. Any current supported contradiction is separately consequential.','inputs':[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [a.cases,a.source_facts,a.census,a.snapshot,a.api_observations]]};save(a.out/'historical_assertion_observations.json',result);save(a.out/'historical_summary.json',summary)
 keys=['assertion_id','record_identifier','record_key','source_filename','source_sha256','domain','original_source_locator','original_expectation','original_mapped_meaning','original_eligible','old_baseline_classification','old_post_correction_classification','policy','approved_supported_scope_eligible','current_classification','api_classification','SQL_API_agreement','evaluation_status','rationale','source_facts_reference']
 with (a.out/'historical_assertion_results.csv').open('x',newline='') as f:
  w=csv.DictWriter(f,fieldnames=keys);w.writeheader()
  for r in result:w.writerow({k:json.dumps(r[k],ensure_ascii=False) if isinstance(r[k],(dict,list)) else r[k] for k in keys})
 print(json.dumps({k:v for k,v in summary.items() if k!='by_domain'},indent=2))
 raise SystemExit(0 if summary['gate_status']=='PASS' else 1)
if __name__=='__main__':main()
