"""Independent F4 XML reader. Derived from approved public contracts, never app code.
Uses stdlib ElementTree, explicit MEI namespace, local bytes only; no network methods.
Produces prospective selected-field oracles plus corpus structural/ownership census.
"""
import argparse,collections,csv,datetime,hashlib,json,re,xml.etree.ElementTree as ET
from pathlib import Path
NS='http://www.music-encoding.org/ns/mei'; XNS='http://www.w3.org/XML/1998/namespace'
M='{'+NS+'}'; X='{'+XNS+'}'; NOW=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
DEVELOPMENT=['417','277','63','17','45','Coll. 27']; RESERVED=['48','1','Coll. 21','202']
FIELDS=['identifiers','titles','classification_terms','publication','physical_description','notes','links']
def norm(s):
 s=re.sub(r'[ \t\r\n]+',' ',s or '').strip(' ');return s or None
def raw(n): return ''.join(n.itertext())
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,d):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('x') as f: json.dump(d,f,ensure_ascii=False,indent=2);f.write('\n')
class Reader:
 def __init__(self,p):
  self.path=p; self.data=p.read_bytes();self.root=ET.fromstring(self.data);self.parents={c:n for n in self.root.iter() for c in n};self.order={n:i for i,n in enumerate(self.root.iter())};self.ids={n.get(X+'id'):n for n in self.root.iter() if n.get(X+'id')};self.locators={}
  self.work=self.root.find(M+'meiHead/'+M+'workList/'+M+'work')
  self.sources=self.root.findall(M+'meiHead/'+M+'manifestationList/'+M+'manifestation')
  self.key=next(norm(raw(n)) for n in self.work.findall(M+'identifier') if any((n.get(k) or '').strip().lower()=='cnw' for k in ['type','label']))
 def loc(self,n):
  if n not in self.locators:
   p=self.parents.get(n);pos=1 if p is None else [c for c in p if c.tag==n.tag].index(n)+1
   tag='m:'+n.tag[len(M):] if n.tag.startswith(M) else n.tag
   self.locators[n]=('' if p is None else self.loc(p))+'/'+tag+'['+str(pos)+']'
  return self.locators[n]
 def meta(self,n): return {'xml_id':n.get(X+'id'),'locator':self.loc(n),'attributes':dict(n.attrib)}
 def ancestors(self,n):
  a=[]
  while n in self.parents:n=self.parents[n];a.append(n)
  return a
 def values(self,nodes,title=False,classification=None):
  out=[]
  for i,n in enumerate(sorted(set(nodes),key=self.order.get),1):
   v={'element':n.tag[len(M):],'text':norm(raw(n)),'raw_text':raw(n),'source_type':n.get('type'),'language':n.get(X+'lang'),'xml_id':n.get(X+'id'),'source_order':i,'locator':self.loc(n),'attributes':dict(n.attrib),'parent_metadata':self.meta(self.parents[n])}
   if title:v['title_stmt_metadata']=self.meta(self.parents[n])
   if classification is not None:
    cl,ls=classification[n];v['classification_metadata']=self.meta(cl);v['term_list_metadata']=[self.meta(x) for x in ls]
   out.append(v)
  return out
 def union(self,n,paths): return sorted([c for p in paths for c in n.findall(p)],key=self.order.get)
 def classes(self,owner):
  out={}
  for cl in owner.findall(M+'classification'):
   for term in cl.iter(M+'term'):
    chain=[];p=self.parents[term]
    while p is not cl:chain.append(p);p=self.parents[p]
    if all(x.tag==M+'termList' for x in chain):out[term]=(cl,list(reversed(chain)))
  return out
 def base(self,n,order):
  return {**self.meta(n),'source_order':order,'label':norm(n.get('label')),'parent_metadata':self.meta(self.parents[n])}
 def locations(self,item):
  out=[]
  for i,loc in enumerate(item.findall(M+'physLoc'),1):
   d={**self.meta(loc),'source_order':i,'repositories':[],'identifiers':self.values(loc.findall(M+'identifier'))}
   for j,repo in enumerate(loc.findall(M+'repository'),1):
    d['repositories'].append({**self.meta(repo),'source_order':j,'identifiers':self.values(repo.findall(M+'identifier')),'names':self.values(repo.findall(M+'corpName')),'links':self.values(self.union(repo,[M+'ptr',M+'ref']))})
   out.append(d)
  return out
 def present(self,vals):return any(v.get('text') for v in vals)
 def state(self,nonlinks,links,label):
  if self.present(nonlinks):return 'descriptive'
  if label or any(norm(v['attributes'].get(k)) for v in links for k in ['target','href']):return 'label_or_link_stub'
  return 'empty_placeholder'
 def item(self,n,i,source):
  d=self.base(n,i);d['source_xml_id']=source.get(X+'id');d['identifiers']=self.values(n.findall(M+'identifier'));d['physical_locations']=self.locations(n);d['physical_description']=self.values(self.union(n,[M+'physDesc/'+M+'physMedium',M+'physDesc/'+M+'handList/'+M+'hand']));d['links']=self.values(self.union(n,[M+'ptr',M+'ref']))
  repos=[v for l in d['physical_locations'] for r in l['repositories'] for k in ['identifiers','names'] for v in r[k]];locations=[v for l in d['physical_locations'] for v in l['identifiers']];links=d['links']+[v for l in d['physical_locations'] for r in l['repositories'] for v in r['links']]
  d['state']=self.state(d['identifiers']+d['physical_description']+repos+locations,links,d['label'])
  d['availability']={k:'present' if self.present(v) else 'missing' for k,v in {'identifiers':d['identifiers'],'repositories':repos,'location_identifiers':locations,'physical_description':d['physical_description']}.items()};return d
 def expression(self,n):
  snap=lambda x:{**self.meta(x),'label':norm(x.get('label')),'titles':self.values(x.findall(M+'title'))}
  d=snap(n);d['ancestor_expressions']=[snap(a) for a in reversed(self.ancestors(n)) if a.tag==M+'expression'];d['containing_work']={'xml_id':self.work.get(X+'id'),'locator':self.loc(self.work)};return d
 def relation(self,n,ri,source,represented_ids):
  rawtarget=n.get('target');tokens=re.findall(r'[^ \t\r\n]+',rawtarget or '') or [None];out=[]
  for ti,token in enumerate(tokens,1):
   d={**self.meta(n),'source_xml_id':source.get(X+'id'),'relation_order':ri,'token_order':ti,'rel':n.get('rel'),'raw_target':rawtarget,'target_token':token,'parent_metadata':self.meta(self.parents[n]),'resolution_state':'unresolved','resolution_reason':None,'target_source_xml_id':None,'expression_context':None}
   why=None;target=None
   if token is None:why='missing_target'
   elif n.get('rel') not in ['isEmbodimentOf','isReproductionOf','hasReproduction']:why='unsupported_relation_type'
   elif not re.fullmatch(r'#[^#/\? \t\r\n]+',token):why='unsupported_target_form'
   elif token[1:] not in self.ids:why='missing_fragment'
   else:
    target=self.ids[token[1:]]
    if n.get('rel')=='isEmbodimentOf':
     if target.tag!=M+'expression':why='wrong_target_type'
     elif self.work not in self.ancestors(target):why='expression_outside_supported_work'
     else:d['resolution_state']='resolved_expression';d['expression_context']=self.expression(target)
    else:
     if target.tag!=M+'manifestation':why='wrong_target_type'
     elif target.get(X+'id') not in represented_ids:why='unsupported_source_target'
     else:d['resolution_state']='resolved_source';d['target_source_xml_id']=target.get(X+'id')
   d['resolution_reason']=why;out.append(d)
  return out
 def projection(self):
  descriptions=[];issues=[];counts=collections.Counter();represented_ids={s.get(X+'id') for s in self.sources if norm(s.get(X+'id'))}
  def issue(kind,n,reason):
   q={'kind':kind,'locator':self.loc(n),'reason':reason}
   if n.get(X+'id') is not None:q['xml_id']=n.get(X+'id')
   issues.append(q)
  for si,s in enumerate(self.sources,1):
   items=s.findall(M+'itemList/'+M+'item');rels=s.findall(M+'relationList/'+M+'relation');counts['source_nodes']+=1;counts['item_nodes']+=len(items);counts['relation_nodes']+=len(rels);counts['relation_tokens']+=sum(len(re.findall(r'[^ \t\r\n]+',r.get('target') or '')) or 1 for r in rels)
   if not norm(s.get(X+'id')):
    counts['unsupported_sources']+=1;counts['unsupported_items']+=len(items);counts['unsupported_relation_nodes']+=len(rels);issue('source',s,'missing_xml_id');continue
   d=self.base(s,si)
   for k,paths in {'identifiers':[M+'identifier'],'titles':[M+'titleStmt/'+M+'title'],'publication':[M+'pubStmt/'+M+'publisher',M+'pubStmt/'+M+'pubPlace',M+'pubStmt/'+M+'date'],'physical_description':[M+'physDesc/'+M+'titlePage',M+'physDesc/'+M+'plateNum'],'notes':[M+'notesStmt/'+M+'annot'],'links':[M+'ptr',M+'ref']}.items():d[k]=self.values(self.union(s,paths),title=k=='titles')
   classes=self.classes(s);d['classification_terms']=self.values(classes.keys(),classification=classes);d['state']=self.state([v for k in FIELDS if k!='links' for v in d[k]],d['links'],d['label']);d['availability']={k:'present' if self.present(d[k]) else 'missing' for k in FIELDS if k!='links'}
   d['held_items']=[]
   for ii,item in enumerate(items,1):
    if not norm(item.get(X+'id')):counts['unsupported_items']+=1;issue('item',item,'missing_xml_id')
    else:d['held_items'].append(self.item(item,ii,s))
   d['relations']=[]
   for ri,rel in enumerate(rels,1):
    for r in self.relation(rel,ri,s,represented_ids):
     d['relations'].append(r)
     if r['resolution_state']=='unresolved':issue('relation',rel,r['resolution_reason'])
   descriptions.append(d)
  relations=[r for s in descriptions for r in s['relations']];items=[i for s in descriptions for i in s['held_items']]
  for k,v in {'represented_sources':len(descriptions),'represented_items':len(items),'represented_relations':len(relations),'resolved_relations':sum(r['resolution_state']!='unresolved' for r in relations),'unresolved_relations':sum(r['resolution_state']=='unresolved' for r in relations)}.items():counts[k]=v
  keys=['source_nodes','represented_sources','unsupported_sources','item_nodes','represented_items','unsupported_items','relation_nodes','relation_tokens','represented_relations','unsupported_relation_nodes','resolved_relations','unresolved_relations']
  summary={'state':'absent_in_source' if not self.sources else 'partial' if issues else 'complete',**{k:counts[k] for k in keys},'source_state_counts':dict(collections.Counter(s['state'] for s in descriptions)),'item_state_counts':dict(collections.Counter(i['state'] for i in items)),'issue_count':len(issues),'issues':issues[:50],'issues_truncated':len(issues)>50}
  return {'document':{'input_profile':'official_cnw_v401','catalogue':'CNW','record_key':self.key,'root_xml_id':self.root.get(X+'id'),'committed_sha256':hashlib.sha256(self.data).hexdigest()},'projection':{'version':'cnw_sources_v1','summary':summary},'descriptions':descriptions}
 def workfacts(self):
  titles=[]
  for i,n in enumerate(self.work.findall(M+'title'),1):
   if not norm(raw(n)):continue
   titles.append({'text':norm(raw(n)),'raw_text':raw(n),'source_type':n.get('type'),'language':n.get(X+'lang'),'xml_id':n.get(X+'id'),'source_order':i,'locator':self.loc(n),'attributes':dict(n.attrib)})
  cl=self.classes(self.work);terms=[]
  for n,(owner,lists) in cl.items():
   if not norm(raw(n)):continue
   terms.append({'text':norm(raw(n)),'raw_text':raw(n),'xml_id':n.get(X+'id'),'source_order':len(terms)+1,'locator':self.loc(n),'attributes':dict(n.attrib),'classification_metadata':{'locator':self.loc(owner),'attributes':dict(owner.attrib)},'term_list_metadata':[{'locator':self.loc(x),'attributes':dict(x.attrib)} for x in lists]})
  ranks={'main':0,None:1,'uniform':2,'alternative':3,'subordinate':4};eligible=[t for t in titles if (None if norm(t['source_type']) is None else t['source_type']) in ranks]
  heading=min(eligible,key=lambda t:(ranks[None if norm(t['source_type']) is None else t['source_type']],t['source_order'])) if eligible else None
  return {'titles':titles,'classification_terms':terms,'title':heading['text'] if heading else None,'heading_source_order':heading['source_order'] if heading else None,'heading_source_type':heading['source_type'] if heading else None,'genre':terms[0]['text'] if terms else None,'policy':'main_untyped_uniform_alternative_subordinate_v1'}
 def legacyfacts(self):
  w=self.work;nodes=lambda name:list(w.iter(M+name));v=lambda n:{'text':norm(raw(n)),'attributes':dict(n.attrib),'locator':self.loc(n)}
  ids=[{'type':n.get('type') or n.get('label'),'value':norm(raw(n)),'locator':self.loc(n)} for n in w.findall(M+'identifier')]
  contributors=[{'name':norm(raw(n)),'role':n.get('role'),'locator':self.loc(n),'attributes':dict(n.attrib)} for c in w.findall(M+'contributor') for n in c.iter(M+'persName')]
  targets=[{'element':n.tag[len(M):],'target':n.get('target'),'relation':n.get('rel') or '','label':n.get('label') or norm(raw(n)) or '','locator':self.loc(n)} for n in w.iter() if n.get('target') is not None]
  events=[]
  for n in nodes('event'):
   events.append({'locator':self.loc(n),'attributes':dict(n.attrib),'direct_values':[v(c) for c in n if c.tag in [M+x for x in ['date','geogName','persName','corpName','desc']]],'text':norm(raw(n))})
  return {'record_key':self.key,'work_count':len(list(self.root.iter(M+'work'))),'identifiers':ids,'contributors':contributors,'titles':[{'text':norm(raw(n)) or '','language':n.get(X+'lang') or '','type':n.get('type') or '','locator':self.loc(n)} for n in w.findall(M+'title')],'creation':[v(n) for c in w.findall(M+'creation') for n in c.findall(M+'date')],'direct_creation_count':len(w.findall(M+'creation')),'expressions':[{'xml_id':n.get(X+'id'),'locator':self.loc(n),'n':n.get('n'),'titles':[v(t) for t in n.findall(M+'title')],'tempos':[v(t) for t in n.findall(M+'tempo')]} for n in nodes('expression')],'component_lists':len(nodes('componentList')),'performance_resources':[v(n) for n in nodes('perfRes') if norm(raw(n))],'events':events,'targets':targets,'hand_list_count':len(list(self.root.iter(M+'handList'))),'manifestation_count':len(list(self.root.iter(M+'manifestation'))),'item_count':len(list(self.root.iter(M+'item')))}
 def census(self,projection):
  srcs=projection['descriptions'];out={'filename':self.path.name,'sha256':hashlib.sha256(self.data).hexdigest(),'bytes':len(self.data),'record_key':self.key,'root_xml_id':self.root.get(X+'id'),'work_xml_id':self.work.get(X+'id'),'work_locator':self.loc(self.work),'namespace':NS,'mei_version':self.root.get('meiversion'),'work_count':len(list(self.root.iter(M+'work'))),'expression_nodes':len(list(self.root.iter(M+'expression'))),'manifestation_nodes':len(list(self.root.iter(M+'manifestation'))),'item_nodes':len(list(self.root.iter(M+'item'))),'direct_source_relation_types':dict(collections.Counter(r.get('rel') for s in self.sources for r in s.findall(M+'relationList/'+M+'relation'))),'projection_summary':projection['projection']['summary'],'sources':[]}
  for s in srcs:out['sources'].append({k:s[k] for k in ['xml_id','locator','source_order','state']}|{'selected_value_counts':{k:len(s[k]) for k in FIELDS},'selected_blank_value_counts':{k:sum(v['text'] is None for v in s[k]) for k in FIELDS}}|{'held_items':[{k:i[k] for k in ['xml_id','source_xml_id','locator','source_order','state']} for i in s['held_items']],'relations':[{k:r[k] for k in ['xml_id','locator','source_xml_id','relation_order','token_order','rel','raw_target','target_token','resolution_state','resolution_reason','target_source_xml_id']}|{'expression_xml_id':None if not r['expression_context'] else r['expression_context']['xml_id'],'expression_locator':None if not r['expression_context'] else r['expression_context']['locator'],'expression_work_xml_id':None if not r['expression_context'] else r['expression_context']['containing_work']['xml_id']} for r in s['relations']]})
  return out

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--package',required=True,type=Path);ap.add_argument('--source',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);ap.add_argument('--prior',required=True,type=Path);a=ap.parse_args();profile=json.loads((a.package/'context/source_profile.json').read_text());baseline=list(csv.DictReader((a.package/'context/phase2_fidelity_matrix.csv').open()));post=list(csv.DictReader((a.package/'context/phase2_post_correction_fidelity_matrix.csv').open()));legacy_names={Path(r['source_file']).name for r in baseline};census=[];extension=[];legacy={};reused=[]
 oldf2=json.loads((a.prior/'prior/F2R1/prior/F2/acceptance/f2_source_expectations_v1.json').read_text());oldf2={r['logical_identity']['record_key']:r for r in oldf2['development_records']}
 oldf1=json.loads((a.prior/'prior/F2R1/acceptance/f1_expectations_v1.json').read_text());oldf1={r['logical_identity']['record_key']:r for r in oldf1['development_records']}
 for pin in profile['per_file']:
  p=a.source/pin['filename'];assert p.is_file() and not p.is_symlink();assert p.stat().st_size==pin['bytes'] and sha(p)==pin['sha256'];r=Reader(p);pr=r.projection();census.append(r.census(pr))
  if r.key in DEVELOPMENT+RESERVED:
   wf=r.workfacts();extension.append({'record_key':r.key,'stratum':'development_regression' if r.key in DEVELOPMENT else 'reserved_purposive','source_filename':p.name,'source_sha256':pin['sha256'],'source_bytes':pin['bytes'],'expected_work':wf,'expected_catalogue_sources':pr})
   if r.key in DEVELOPMENT:
    # Independent current XML projection is checked against pre-existing source-only oracle,
    # never against actual application outcomes. Detailed diffs are retained before any revision.
    reused.append({'record_key':r.key,'F2_projection_exact_equal':pr==oldf2[r.key]['expected_catalogue_sources'],'F1_titles_exact_equal':wf['titles']==oldf1[r.key]['titles'],'F1_heading_exact_equal':wf['title']==oldf1[r.key]['required_heading'],'F1_genre_exact_equal':wf['genre']==oldf1[r.key]['required_derived_genre']})
  if p.name in legacy_names:legacy[p.name]=r.legacyfacts()
 write(a.out/'semantic_extension_v1.json',{'version':'f4_semantic_extension_v1','frozen_utc':NOW(),'independent_method':'f4_source_oracle.py; source-only stdlib namespace-aware parser; approved F1/F2 policies; no application imports or database/API reads','records':extension})
 write(a.out/'semantic_corpus_census_v1.json',{'version':'f4_semantic_corpus_census_v1','frozen_utc':NOW(),'files':census,'aggregate':{'file_count':len(census),'bytes':sum(r['bytes'] for r in census),'manifestations':sum(r['manifestation_nodes'] for r in census),'items':sum(r['item_nodes'] for r in census),'expressions':sum(r['expression_nodes'] for r in census)}})
 write(a.out/'semantic_legacy_source_facts_v1.json',{'version':'f4_semantic_legacy_source_facts_v1','frozen_utc':NOW(),'files':legacy})
 write(a.out/'semantic_prior_oracle_reconciliation_v1.json',{'checks':reused,'overall':all(all(v for k,v in x.items() if k!='record_key') for x in reused)})
 hist=[]
 for old,new in zip(baseline,post):
  assert old['assertion_id']==new['assertion_id'];hist.append({'assertion_id':old['assertion_id'],'record_identifier':old['record_identifier'],'source_filename':Path(old['source_file']).name,'domain':old['domain'],'original_expectation':json.loads(old['official_expected_value']),'original_source_locator':old['official_source_locator'],'original_mapped_meaning':old['expected_mapped_meaning'],'original_eligible':old['eligible_for_semantic_denominator']=='true','old_baseline_classification':old['classification'],'old_post_correction_classification':new['post_correction_classification'],'policy':'legacy first-untyped display plus original five title records' if old['assertion_id']=='277-04' else 'immutable original assertion; approved representation limits recorded separately','status':'NOT_RUN'})
 write(a.out/'semantic_historical_cases_v1.json',{'version':'f4_historical_cases_v1','frozen_utc':NOW(),'cases':hist})
 print(json.dumps({'extension_records':len(extension),'census_files':len(census),'historical_cases':len(hist),'prior_reconciliation':reused},indent=2))
if __name__=='__main__':main()
