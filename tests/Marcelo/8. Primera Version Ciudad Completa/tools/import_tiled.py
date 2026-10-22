"""Import R02 modules, 8 px collision, destinations and actor routes from Tiled.
Usage: python3 tools/import_tiled.py [map.tmx] [--check]
Ground layers are a locked reference; use the terrain pipeline to edit them.
"""
from pathlib import Path
import argparse,array,base64,gzip,json,math,sys,zlib
import xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('map',nargs='?',type=Path,default=R/'tiled/Briar_Gran_Ciudad.tmx');parser.add_argument('--check',action='store_true');args=parser.parse_args()
tm=E.parse(args.map).getroot();M=json.loads((R/'mapa/ciudad.json').read_text());A={a['id']:a for a in json.loads((R/'catalogo.json').read_text())['assets']};T=json.loads((R/'mapa/terrain_chunks.json').read_text());cw,ch=M['collision_width'],M['collision_height']
def require(test,message):
 if not test:raise ValueError(message)
def prop(o):return {p.get('name'):p.get('value',p.text or '') for p in o.findall('properties/property')}
require(prop(tm).get('briar_format')=='R02','Use the R02 export; earlier TMX versions have different terrain and anchors.')
require(tuple(tm.get(k) for k in ['width','height','tilewidth','tileheight','infinite'])==(str(cw),str(ch),'8','8','0'),'Keep the map dimensions and 8 px collision grid.')
require({int(t.get('firstgid')):Path(t.get('source')).name for t in tm.findall('tileset')}=={1:'colision.tsx',2:'modulos.tsx'},'Keep the exported tileset order.')
ground=tm.find("group[@id='1']");require(ground is not None,'Keep the ground reference group.');images=ground.findall('imagelayer')
require(len(images)==T['columns']*T['rows'],'Ground layers must be rebuilt through the R02 terrain pipeline.')
for image in images:
 x,y=map(int,image.get('name').split('_'))
 require(float(image.get('offsetx','0'))==x*512 and float(image.get('offsety','0'))==y*512 and image.find('image').get('source')=='../'+T['file_pattern'].format(x=x,y=y),'Ground layers cannot be moved or replaced in this import.')
layer=tm.find("layer[@id='5']");require(layer is not None,'Missing collision layer.');d=layer.find('data')
if d.get('encoding')=='csv':values=[int(s.strip()) for s in d.text.split(',') if s.strip()]
elif d.get('encoding')=='base64':
 raw=base64.b64decode(d.text);compression=d.get('compression')
 if compression=='zlib':raw=zlib.decompress(raw)
 elif compression=='gzip':raw=gzip.decompress(raw)
 elif compression:raise ValueError('Use CSV, zlib, gzip or uncompressed base64.')
 values=array.array('I');values.frombytes(raw)
 if sys.byteorder!='little':values.byteswap()
else:values=[int(t.get('gid')) for t in d.findall('tile')]
require(len(values)==cw*ch and all(v in (0,1) for v in values),'Collision accepts only tile 1 or empty 0; no flips.');collision=bytes(v for v in values)
def clear(x,y):
 if not 12<=x<M['pixel_width']-12 or not 64<=y<M['pixel_height']-12:return False
 return all(not collision[int((y+dy)//8)*cw+int((x+dx)//8)] for dx,dy in [(0,0),(-7,-3),(7,-3),(-7,3),(7,3)])
objects=[];destinations=[];actors={7:[],8:[]}
for group in tm.findall('objectgroup'):
 lid=int(group.get('id'))
 for o in group.findall('object'):
  p=prop(o)
  if lid==6:
   point=json.loads(p['source_data']);point.update(id=o.get('name'),x=round(float(o.get('x'))),y=round(float(o.get('y'))));destinations.append(point)
  elif lid in actors:
   actor=json.loads(p['actor_data']);origin=[float(o.get('x')),float(o.get('y'))]
   actor['route']=[[round(origin[0]+float(v.split(',')[0])),round(origin[1]+float(v.split(',')[1]))] for v in o.find('polyline').get('points').split()]
   require(len(actor['route'])>=2,'Every route needs at least two points.');actor['start_index']=min(actor.get('start_index',0),len(actor['route'])-1);actors[lid].append(actor)
  elif lid in (3,4):
   a=A[p['asset_id']];expected_gid=2+list(A).index(a['id'])
   require(int(o.get('gid'))==expected_gid and float(o.get('rotation','0'))==0 and float(o.get('width'))==a['width'] and float(o.get('height'))==a['height'],'Keep native size, orientation and module identity; use the pre-drawn diagonal modules.')
   source=json.loads(p['source_data']);ob=dict(source,id=a['id'],x=round(float(o.get('x'))+a['anchor'][0],3),y=round(float(o.get('y'))+a['anchor'][1]-a['height'],3))
   require(source.get('kind')!='bridge' or ob==source,'Move bridges through the layout pipeline so all modules, approaches and collision stay connected.')
   objects.append((int(p['source_index']),ob))
objects=[ob for _,ob in sorted(objects,key=lambda pair:pair[0])]
require(len({p['id'] for p in destinations})==len(destinations),'Destination IDs must be unique.')
for p in destinations:require(clear(p['x'],p['y']),'Destination on collision: '+p['id'])
for actor in actors[7]:
 route=actor['route']
 for a,b in zip(route,route[1:]):
  steps=max(1,math.ceil(math.dist(a,b)/4))
  for i in range(steps+1):
   t=i/steps;require(clear(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t),'Resident route crosses collision: '+str(actor['id']))
same={'objects':objects==M['objects'],'destinations':destinations==M['pois'],'collision':collision==(R/M['layers']['collision']).read_bytes(),'residents':actors[7]==M['residents'],'boats':actors[8]==M['boats']}
report={'valid':True,'unchanged_roundtrip':all(same.values()),'comparison':same,'objects':len(objects),'destinations':len(destinations),'collision_bytes':len(collision),'check_only':args.check}
if args.check:(R/'docs/tiled_roundtrip.json').write_text(json.dumps(report,indent=2))
else:
 M.update(objects=objects,pois=destinations,residents=actors[7],boats=actors[8]);spawn=next(p for p in destinations if p['id']=='mercado');M['spawn']=[spawn['x'],spawn['y']]
 (R/M['layers']['collision']).write_bytes(collision);(R/'mapa/ciudad.json').write_text(json.dumps(M,ensure_ascii=False,separators=(',',':')))
print(json.dumps(report))
if not args.check:print('Rebuild previews and HTML with render_city.cjs and build_web.cjs. Godot reads the updated map directly.')
