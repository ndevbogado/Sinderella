"""Export the integrated R02 city, native images and 8 px collision to Tiled."""
from pathlib import Path
import array, base64, json, struct, sys, zlib
import xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]; D=R/'tiled'; D.mkdir(exist_ok=True)
C=json.loads((R/'catalogo.json').read_text()); M=json.loads((R/'mapa/ciudad.json').read_text())
A={a['id']:a for a in C['assets']}; T=json.loads((R/'mapa/terrain_chunks.json').read_text())
def write(element,name):
 E.indent(element); E.ElementTree(element).write(D/name,encoding='utf-8',xml_declaration=True)
def props(element,values):
 p=E.SubElement(element,'properties')
 for k,v in values.items():
  attrs={'name':k,'value':str(v).lower() if isinstance(v,bool) else str(v)}
  if isinstance(v,bool):attrs['type']='bool'
  elif isinstance(v,int):attrs['type']='int'
  E.SubElement(p,'property',attrs)
# Technical collision marker, independent of the artwork.
def png_chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
(D/'colision_8.png').write_bytes(b'\x89PNG\r\n\x1a\n'+png_chunk(b'IHDR',struct.pack('>IIBBBBB',8,8,8,6,0,0,0))+png_chunk(b'IDAT',zlib.compress((b'\0'+bytes([232,75,90,180])*8)*8))+png_chunk(b'IEND',b''))
solid=E.Element('tileset',{'version':'1.10','name':'colision','tilewidth':'8','tileheight':'8','tilecount':'1','columns':'1'})
E.SubElement(solid,'image',{'source':'colision_8.png','width':'8','height':'8'});write(solid,'colision.tsx')
ts=E.Element('tileset',{'version':'1.10','name':'modulos','tilewidth':str(max(a['width'] for a in A.values())),'tileheight':str(max(a['height'] for a in A.values())),'tilecount':str(len(A)),'columns':'0','objectalignment':'bottomleft'})
gids={}
for i,a in enumerate(C['assets']):
 gids[a['id']]=2+i;t=E.SubElement(ts,'tile',{'id':str(i)})
 props(t,{'asset_id':a['id'],'name':a['label'],'solid':a['solid'],'ground':a['ground'],'anchor_x':a['anchor'][0],'anchor_y':a['anchor'][1]})
 E.SubElement(t,'image',{'source':'../'+a['file'],'width':str(a['width']),'height':str(a['height'])})
 if a['collision_polygons']:
  g=E.SubElement(t,'objectgroup',{'draworder':'index'})
  for j,poly in enumerate(a['collision_polygons']):E.SubElement(E.SubElement(g,'object',{'id':str(j+1),'x':'0','y':'0'}),'polygon',{'points':' '.join(','.join(map(str,p)) for p in poly)})
write(ts,'modulos.tsx')
tm=E.Element('map',{'version':'1.10','orientation':'orthogonal','renderorder':'right-down','width':str(M['collision_width']),'height':str(M['collision_height']),'tilewidth':'8','tileheight':'8','infinite':'0','nextlayerid':str(100+T['columns']*T['rows']),'backgroundcolor':'#183127'})
props(tm,{'title':M['title'],'briar_format':'R02','world_width':M['pixel_width'],'world_height':M['pixel_height'],'screen_width':960,'screen_height':540,'authoring_grid':32,'collision_grid':8,'note':'Ground images show the exact native terrain. Edit roads/material fields through the R02 pipeline. Last collision row extends 4 px beyond the world.'})
for gid,file in [(1,'colision.tsx'),(2,'modulos.tsx')]:E.SubElement(tm,'tileset',{'firstgid':str(gid),'source':file})
ground=E.SubElement(tm,'group',{'id':'1','name':'Terreno continuo R02','locked':'1'})
for y in range(T['rows']):
 for x in range(T['columns']):
  l=E.SubElement(ground,'imagelayer',{'id':str(100+y*T['columns']+x),'name':f'{x}_{y}','offsetx':str(x*512),'offsety':str(y*512),'locked':'1'})
  E.SubElement(l,'image',{'source':'../'+T['file_pattern'].format(x=x,y=y),'width':'512','height':'512'})
n=1
for lid,name,ground in [(3,'Puentes y suelo',True),(4,'Edificios y decoracion',False)]:
 g=E.SubElement(tm,'objectgroup',{'id':str(lid),'name':name,'draworder':'topdown'})
 for index,ob in enumerate(M['objects']):
  a=A[ob['id']]
  if a['ground']!=ground:continue
  o=E.SubElement(g,'object',{'id':str(n),'name':ob['id'],'gid':str(gids[ob['id']]),'x':str(ob['x']-a['anchor'][0]),'y':str(ob['y']-a['anchor'][1]+a['height']),'width':str(a['width']),'height':str(a['height'])});n+=1
  props(o,{'asset_id':ob['id'],'source_index':index,'source_data':json.dumps(ob,ensure_ascii=False,separators=(',',':'))})
collision=(R/M['layers']['collision']).read_bytes();assert len(collision)==M['collision_width']*M['collision_height']
l=E.SubElement(tm,'layer',{'id':'5','name':'Colision — 8 px — 1 bloquea, 0 libre','width':str(M['collision_width']),'height':str(M['collision_height']),'visible':'0','opacity':'0.5'})
values=array.array('I',list(collision))
if sys.byteorder!='little':values.byteswap()
E.SubElement(l,'data',{'encoding':'base64','compression':'zlib'}).text=base64.b64encode(zlib.compress(values.tobytes())).decode()
g=E.SubElement(tm,'objectgroup',{'id':'6','name':'Destinos','visible':'0'})
for p in M['pois']:
 o=E.SubElement(g,'object',{'id':str(n),'name':p['id'],'x':str(p['x']),'y':str(p['y'])});n+=1;E.SubElement(o,'point');props(o,{'source_data':json.dumps(p,ensure_ascii=False,separators=(',',':'))})
for lid,kind in [(7,'residents'),(8,'boats')]:
 g=E.SubElement(tm,'objectgroup',{'id':str(lid),'name':'Rutas — '+kind,'visible':'0'})
 for actor in M[kind]:
  a=actor['route'][0];o=E.SubElement(g,'object',{'id':str(n),'name':kind+'_'+str(actor['id']),'x':str(a[0]),'y':str(a[1])});n+=1
  E.SubElement(o,'polyline',{'points':' '.join(str(p[0]-a[0])+','+str(p[1]-a[1]) for p in actor['route'])})
  props(o,{'actor_data':json.dumps({k:v for k,v in actor.items() if k!='route'},ensure_ascii=False,separators=(',',':'))})
tm.set('nextobjectid',str(n));write(tm,'Briar_Gran_Ciudad.tmx');E.parse(D/'Briar_Gran_Ciudad.tmx')
report={'tmx':'tiled/Briar_Gran_Ciudad.tmx','version':'R02','collision_grid':[M['collision_width'],M['collision_height']],'tile_size':8,'tilesets':2,'native_ground_images':T['columns']*T['rows'],'object_instances':len(M['objects']),'destinations':len(M['pois']),'xml_parsed':True,'opened_in_tiled':False}
(R/'docs/tiled_validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
