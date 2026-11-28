"""Build the V1 book catalogue from cached Open Library work metadata.

The fetch step is intentionally separate from build/validate so normal app
builds and tests never depend on the network.
"""
from __future__ import annotations
import argparse, csv, json, re, time, unicodedata, urllib.parse, urllib.request
from collections import Counter, defaultdict
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'assets/data/books.json'; CACHE=ROOT/'docs/data_sources/books_openlibrary_candidates.json'
INDEX=ROOT/'assets/data/book_index.json'
REPORT=ROOT/'docs/data_sources/book_catalogue_distribution.json'
DUPES=ROOT/'docs/data_sources/book_duplicate_resolution.csv'
AUTHORS=ROOT/'docs/data_sources/complete_book_authors_report.md'
TOP_AUTHORS=ROOT/'docs/data_sources/book_top_authors.csv'
FIELDS='key,title,alternative_title,author_name,author_key,first_publish_year,language,subject,place,ratings_count,readinglog_count,edition_count'
QUERIES=[
 ('india','subject:India'),('india','place:India'),('india','subject:"Indian literature"'),
 ('india','subject:"Hindi literature"'),('india','language:hin'),('india','subject:"Bengali literature"'),
 ('global','readinglog_count:[100 TO *] language:eng'),('global','ratings_count:[50 TO *] language:eng'),
 ('global','subject:classics language:eng'),('global','subject:fantasy language:eng'),
 ('global','subject:"science fiction" language:eng'),('global','subject:mystery language:eng'),
 ('global','subject:history language:eng'),('global','subject:biography language:eng'),
]
GENRES=['Fiction','Classics','Literary Fiction','Contemporary Fiction','Historical Fiction','Romance','Mystery & Thriller','Crime','Fantasy','Science Fiction','Horror','Adventure','Satire','Short Stories','Drama','Poetry','Young Adult',"Children's Literature",'Children & Young Adult','Biography & Memoir','History','Business & Economics','Self-Help','Psychology','Philosophy','Science','Technology','Politics & Society','Travel','Religion & Spirituality','True Crime','Essays','Nature & Environment','Health & Wellness','Personal Finance']
MAP=[('science fiction','Science Fiction'),('fantasy','Fantasy'),('mystery','Mystery & Thriller'),('thriller','Mystery & Thriller'),('crime','Crime'),('romance','Romance'),('historical fiction','Historical Fiction'),('horror','Horror'),('poetry','Poetry'),('drama','Drama'),('plays','Drama'),('short stor','Short Stories'),('young adult','Young Adult'),('juvenile',"Children's Literature"),('children',"Children's Literature"),('biograph','Biography & Memoir'),('memoir','Biography & Memoir'),('history','History'),('business','Business & Economics'),('economics','Business & Economics'),('self-help','Self-Help'),('psychology','Psychology'),('philosophy','Philosophy'),('science','Science'),('technology','Technology'),('politic','Politics & Society'),('travel','Travel'),('religion','Religion & Spirituality'),('spiritual','Religion & Spirituality'),('true crime','True Crime'),('essay','Essays'),('nature','Nature & Environment'),('health','Health & Wellness'),('finance','Personal Finance'),('classic','Classics'),('satire','Satire'),('adventure','Adventure')]

def norm(v): return re.sub(r'[^a-z0-9]+','',unicodedata.normalize('NFKD',v).encode('ascii','ignore').decode().lower())
AUTHOR_ALIASES={'munshipremchand':'premchand','rasipuramkrishnaswamynarayan':'rknarayan'}
def author_norm(v):
 value=norm(v)
 return AUTHOR_ALIASES.get(value,value)
def genre_id(name): return 'GEN_'+re.sub(r'[^A-Z0-9]+','_',name.upper()).strip('_')
def get(url):
 req=urllib.request.Request(url,headers={'User-Agent':'LifeExperiencesCatalogue/1.0 (local catalogue build)'})
 last=None
 for attempt in range(4):
  try:
   with urllib.request.urlopen(req,timeout=90) as r:return json.load(r)
  except Exception as error:
   last=error;time.sleep(2**attempt)
 raise last
def fetch():
 CACHE.parent.mkdir(parents=True,exist_ok=True); rows=[];done=set()
 if CACHE.exists():
  previous=json.loads(CACHE.read_text(encoding='utf-8'));rows=previous.get('records',[]);done={tuple(x) for x in previous.get('completed_requests',[])}
 for group,q in QUERIES:
  for page in range(1,3):
   if (q,page) in done:continue
   params=urllib.parse.urlencode({'q':q,'fields':FIELDS,'limit':200,'page':page,'sort':'readinglog'})
   data=get('https://openlibrary.org/search.json?'+params)
   for doc in data.get('docs',[]): doc['_candidate_group']=group;doc['_candidate_query']=q;rows.append(doc)
   done.add((q,page));CACHE.write_text(json.dumps({'accessed':'2026-09-28','source':'https://openlibrary.org/search.json','queries':QUERIES,'completed_requests':sorted(done),'records':rows},ensure_ascii=False),encoding='utf-8')
   if len(data.get('docs',[]))<200:break
   time.sleep(.75)
 print(f'cached {len(rows)} candidates')

def genre(doc):
 text=' '.join(doc.get('subject',[])).lower()
 for needle,value in MAP:
  if needle in text:return value
 return 'Literary Fiction' if doc.get('_candidate_group')=='global' else 'Contemporary Fiction'
def score(d):return int(d.get('readinglog_count') or 0)*10+int(d.get('ratings_count') or 0)*20+int(d.get('edition_count') or 0)
def eligible(d):
 langs=set(d.get('language') or []);year=d.get('first_publish_year');title=str(d.get('title') or '').strip()
 return bool(title and d.get('author_name') and ({'eng','hin'}&langs) and (not year or 500<=int(year)<=2026) and len(title)<=180)

def build():
 old=json.loads(DATA.read_text(encoding='utf-8')); raw=json.loads(CACHE.read_text(encoding='utf-8'))['records']
 bykey={}
 for d in raw:
  key=d.get('key');
  if not key or not eligible(d):continue
  previous=bykey.get(key)
  if previous:
   previous['_candidate_group']='india' if 'india' in {previous['_candidate_group'],d['_candidate_group']} else 'global'
  elif key:bykey[key]=d
 candidates=sorted(bykey.values(),key=score,reverse=True)
 books=list(old['books'][:36]); used_keys=set()
 indian_seed_ids={f'BK{x:06d}' for x in [*range(1,12),20,*range(21,37)]}
 for b in books:
  is_indian=b['id'] in indian_seed_ids
  b['is_indian_author_or_work']=is_indian
  b['country_or_literary_tradition']='India' if is_indian else 'International'
 seen=set()
 for b in books:
  author=author_norm(b['primary_author_display'])
  for title in [b['canonical_title'],b.get('original_title'),*(b.get('alternate_titles') or []),b.get('transliterated_title')]:
   if title and norm(title):seen.add((norm(title),author))
 dupes=[]
 def take(group,count):
  for d in candidates:
   if len([b for b in books if b.get('_selection_group')==group])>=count:return
   if d['_candidate_group']!=group or d['key'] in used_keys:continue
   author=author_norm(d['author_name'][0]); signatures={(norm(title),author) for title in [d['title'],*(d.get('alternative_title') or [])] if norm(title)}
   if signatures & seen:dupes.append((d['key'],d['title'],d['author_name'][0],'merged_or_skipped_normalized_identity'));continue
   used_keys.add(d['key']);seen.update(signatures); books.append(make_book(d,len(books)+1,group))
 existing_indian=sum(1 for b in books if b.get('is_indian_author_or_work'))
 take('india',400-existing_indian); take('global',1000-len(books))
 if len(books)<1000:
  for d in candidates:
   if len(books)==1000:break
   if d['key'] in used_keys:continue
   author=author_norm(d['author_name'][0]);signatures={(norm(title),author) for title in [d['title'],*(d.get('alternative_title') or [])] if norm(title)}
   if signatures & seen:continue
   used_keys.add(d['key']);seen.update(signatures);books.append(make_book(d,len(books)+1,d['_candidate_group']))
 if len(books)!=1000:raise RuntimeError(f'only {len(books)} eligible unique works; expand candidate cache')
 for b in books:
  b.pop('_selection_group',None)
  b.setdefault('alternate_titles',[]); b.setdefault('transliterated_title',None)
  b.setdefault('primary_genre_id',genre_id(b['primary_genre']))
  b.setdefault('country_or_literary_tradition',None)
  b.setdefault('is_indian_author_or_work',None)
  b.setdefault('source_urls',[]); b.setdefault('metadata_verified',False)
  b.setdefault('verification_notes','Preserved architecture-validation seed; detailed provenance remains to be reviewed.')
  b.setdefault('source_work_id',None); b.setdefault('notability',None)
 seed_author_ids={x for b in books[:36] for x in b['author_ids']}; authors=[a for a in old['authors'] if a['id'] in seed_author_ids]
 author_seed={author_norm(a['name']):a for a in authors}; author_by_source={}
 for b in books:
  if b['id']<= 'BK000036':continue
  ids=[]
  for source,name in zip(b.pop('_author_source_ids'),b.pop('_author_names')):
   if source not in author_by_source:
    existing=author_seed.get(author_norm(name))
    if existing:author_by_source[source]=existing['id']
    else:
     aid=f'AUTH{len(authors)+1:04d}';author_by_source[source]=aid
     authors.append({'id':aid,'name':name,'native_name':None,'alternate_names':[],'primary_language':None,'country_or_tradition':None,'book_ids':[],'bibliography_status':'partial','bibliography_scope':None,'verified_book_count':None,'verification_notes':'Open Library candidate import; complete bibliography not verified.','last_verified':None,'source_urls':[f'https://openlibrary.org/authors/{source}']})
   ids.append(author_by_source[source])
  b['author_ids']=ids
 for a in authors:a['book_ids']=[b['id'] for b in books if a['id'] in b['author_ids']]
 collections=make_collections(books); series=make_series(books)
 genre_entities=[{'id':genre_id(name),'name':name,'description':None,'parent_genre_id':None} for name in GENRES]
 out={'schema_version':3,'genres':GENRES,'genre_entities':genre_entities,'series':series,'authors':authors,'books':books,'collections':collections}
 # This generated asset is intentionally compact: it is parsed on app start
 # and remains reviewable through the source cache and CSV/JSON reports.
 DATA.write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
 INDEX.write_text(json.dumps({'schema_version':1,'book_ids':[b['id'] for b in books]},separators=(',',':'))+'\n',encoding='utf-8')
 DUPES.parent.mkdir(parents=True,exist_ok=True)
 with DUPES.open('w',newline='',encoding='utf-8') as f:
  w=csv.writer(f);w.writerow(['source_work_id','title','author','resolution']);w.writerows(dupes)
 report(out,dupes);validate(out);print('built 1000 canonical works')

def make_book(d,n,group):
 langs=[]
 if 'eng' in (d.get('language') or []):langs.append('english')
 if 'hin' in (d.get('language') or []):langs.append('hindi')
 g=genre(d);authors=d['author_name']; keys=d.get('author_key') or [f'unknown-{norm(x)}' for x in authors]
 year=d.get('first_publish_year'); title=d['title'].strip(); nonfiction={'Biography & Memoir','History','Business & Economics','Self-Help','Psychology','Philosophy','Science','Technology','Politics & Society','Travel','Religion & Spirituality','True Crime','Essays','Nature & Environment','Health & Wellness','Personal Finance'}; classification='poetry' if g=='Poetry' else 'drama' if g=='Drama' else 'non_fiction' if g in nonfiction else 'fiction'
 author_display=authors[0] if len(authors)==1 else f'{authors[0]} et al.'
 description=(f'{title} is a notable {g.lower()} work by {author_display}'
              +(f', first published in {year}.' if year else '.')
              +' It is included for its documented readership and literary, cultural, or subject significance.')
 return {'id':f'BK{n:06d}','canonical_title':title,'original_title':None,'alternate_titles':d.get('alternative_title',[])[:5],'transliterated_title':None,'author_ids':[],'_author_source_ids':keys,'_author_names':authors,'primary_author_display':author_display,'original_language':None,'available_languages':langs,'publication_year':year,'primary_genre':g,'primary_genre_id':genre_id(g),'secondary_genres':[],'classification':classification,'description':description,'cover_asset':None,'tags':[],'series_id':None,'series_position':None,'country_or_literary_tradition':'India' if group=='india' else 'International','is_indian_author_or_work':group=='india','content_status':'source_imported_needs_review','source_urls':[f'https://openlibrary.org{d["key"]}'],'metadata_verified':False,'verification_notes':'Work identity and popularity signals imported from Open Library; taxonomy and language availability require editorial review.','source_work_id':d['key'],'notability':{'readinglog_count':d.get('readinglog_count',0),'ratings_count':d.get('ratings_count',0),'edition_count':d.get('edition_count',0)},'_selection_group':group}

def make_series(books):
 names={'rusty':'Rusty','poirot':'Hercule Poirot','jhutha_sach':'Jhutha Sach','shekhar':'Shekhar: Ek Jivani'}
 result=[]
 for raw_sid in sorted({b.get('series_id') for b in books if b.get('series_id')}):
  sid=raw_sid[4:].lower() if raw_sid.startswith('SER_') else raw_sid
  canonical_id='SER_'+sid.upper()
  book_ids=[b['id'] for b in books if b.get('series_id')==raw_sid]
  result.append({'id':canonical_id,'legacy_id':sid,'name':names.get(sid,sid.replace('_',' ').title()),'book_ids':book_ids,'is_complete':False,'verification_notes':'Series relationship preserved from the architecture-validation seed; full series scope is not verified.'})
  for b in books:
   if b.get('series_id')==raw_sid:b['series_id']=canonical_id
 return result

def make_collections(books):
 specs=[('ESSENTIAL_CLASSICS','Essential Classics','Classics',50),('HINDI_CLASSICS','Hindi Classics','Classics',25),('INDIAN_FICTION','Indian Fiction Essentials','Literary Fiction',40),('SCIENCE_FICTION','Essential Science Fiction','Science Fiction',30),('MYSTERY','Essential Mystery & Thriller','Mystery & Thriller',30),('FANTASY','Essential Fantasy','Fantasy',30),('BIOGRAPHIES','Great Biographies & Memoirs','Biography & Memoir',30),('HISTORY','History Essentials','History',30),('SCIENCE','Science Essentials','Science',25),('PERSONAL_GROWTH','Personal Growth Essentials','Self-Help',25),('BUSINESS','Business Essentials','Business & Economics',25),('POETRY','Poetry Essentials','Poetry',25),('ROMANCE','Romance Essentials','Romance',25),('HISTORICAL_FICTION','Historical Fiction Essentials','Historical Fiction',30),('GLOBAL_MODERN','Modern Global Literature','Contemporary Fiction',40)]
 result=[{'id':'BOOKCOLL_ENGLISH','title':'English Books','description':'Dynamic English-language view.','book_ids':[],'language':'english'}, {'id':'BOOKCOLL_HINDI','title':'Hindi Books','description':'Dynamic Hindi-language view.','book_ids':[],'language':'hindi'}]
 for cid,title,g,count in specs:
  if cid=='GLOBAL_MODERN':
   pool=[b for b in books if b.get('is_indian_author_or_work') is False and b['classification']=='fiction' and (b.get('publication_year') or 0)>=1945]
  else:
   pool=[b for b in books if b['primary_genre']==g and (cid!='HINDI_CLASSICS' or 'hindi' in b['available_languages']) and (cid!='INDIAN_FICTION' or b.get('is_indian_author_or_work') is True)]
  ids=[b['id'] for b in pool[:count]]
  if ids:result.append({'id':'BOOKCOLL_'+cid,'title':title,'description':f'A finite curated selection of {len(ids)} notable {g.lower()} works.','book_ids':ids})
 return result

def validate(d):
 books=d['books'];authors=d['authors'];ids=[b['id'] for b in books];aids={a['id'] for a in authors};genres=set(d['genres']);gids={g['id'] for g in d['genre_entities']};sids={s['id'] for s in d['series']}
 assert len(books)==1000 and len(ids)==len(set(ids));assert len(aids)==len(authors)
 assert all(b['canonical_title'].strip() and set(b['available_languages'])<= {'english','hindi'} and b['available_languages'] for b in books)
 assert all(set(b['author_ids'])<=aids and b['primary_genre'] in genres and b['primary_genre_id'] in gids for b in books)
 assert all(not b.get('series_id') or b['series_id'] in sids for b in books)
 assert all(not b.get('series_position') or b['series_position']>0 for b in books)
 assert all(b.get('cover_asset') is None for b in books)
 assert all(20<=len(b['description'].split())<=60 or b['id']<='BK000036' for b in books)
 assert all(len(c.get('book_ids',[]))==len(set(c.get('book_ids',[]))) and set(c.get('book_ids',[]))<=set(ids) for c in d['collections'])
 assert json.loads(INDEX.read_text(encoding='utf-8'))['book_ids']==ids
 for a in authors:
  if a['bibliography_status']=='complete':assert a.get('verified_book_count')==len(a['book_ids']) and a.get('source_urls')

def report(d,dupes):
 books=d['books']; ac=Counter(len(a['book_ids']) for a in d['authors']); original=Counter(b.get('original_language') or 'unknown' for b in books); classes=Counter(b['classification'] for b in books); genres=Counter(b['primary_genre'] for b in books)
 r={'total':len(books),'english_available':sum('english'in b['available_languages'] for b in books),'hindi_available':sum('hindi'in b['available_languages'] for b in books),'both':sum(len(b['available_languages'])==2 for b in books),'original_language':original,'indian':sum(bool(b.get('is_indian_author_or_work')) for b in books),'international':sum(b.get('is_indian_author_or_work') is False for b in books),'unclassified_region':sum(b.get('is_indian_author_or_work') is None for b in books),'classification':classes,'primary_genres':genres,'authors':len(d['authors']),'author_distribution':{'1':ac[1],'2-4':sum(ac[x] for x in range(2,5)),'5-9':sum(ac[x] for x in range(5,10)),'10+':sum(v for k,v in ac.items() if k>=10)},'series':len(d['series']),'series_books':sum(bool(b.get('series_id')) for b in books),'collections':len(d['collections']),'curated_collections':sum(bool(c.get('book_ids')) for c in d['collections']),'dynamic_language_views':sum(bool(c.get('language')) for c in d['collections']),'duplicate_candidates':len(dupes),'duplicate_records_merged':len(dupes),'needs_review':sum(b['content_status'].endswith('needs_review') for b in books),'authors_needing_bibliography_review':sum(a['bibliography_status']!='complete' for a in d['authors'])}
 REPORT.write_text(json.dumps(r,ensure_ascii=False,indent=2,default=dict)+'\n',encoding='utf-8')
 complete=[a for a in d['authors'] if a['bibliography_status']=='complete']; AUTHORS.write_text('# Complete book authors report\n\n'+('No authors are marked complete. Bibliography scope verification is required before enabling completion claims.\n' if not complete else ''),encoding='utf-8')
 counts=sorted(((a['name'],a['id'],len(a['book_ids'])) for a in d['authors']),key=lambda x:(-x[2],x[0].casefold()))[:50]
 with TOP_AUTHORS.open('w',newline='',encoding='utf-8') as f:
  w=csv.writer(f);w.writerow(['rank','author_id','author_name','catalogue_book_count']);w.writerows((i,aid,name,count) for i,(name,aid,count) in enumerate(counts,1))

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['fetch','build','validate']);a=p.parse_args()
 if a.command=='fetch':fetch()
 elif a.command=='build':build()
 else:validate(json.loads(DATA.read_text(encoding='utf-8')));print('validation passed')
