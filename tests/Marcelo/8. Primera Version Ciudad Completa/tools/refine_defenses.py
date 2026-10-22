"""Place native diagonal modules, side gates and river arches on the approved map.
Run after build_b1.py. Terrain, navigation, population and roads stay authoritative.
"""
from pathlib import Path
import json, math, collections
R=Path(__file__).resolve().parents[1]
M=json.loads((R/'mapa/ciudad.json').read_text()); C=json.loads((R/'catalogo.json').read_text())
A={a['id']:a for a in C['assets']}
M['objects']=[o for o in M['objects'] if o.get('kind') not in ('wall','gate','watergate')]
shape=M['wall_polygon']; gates=M['gates']; pieces=[]; crossings=[]
def cross(a,b,c,d):
 u=[b[i]-a[i] for i in range(2)];v=[d[i]-c[i] for i in range(2)]
 den=u[0]*v[1]-u[1]*v[0]
 if abs(den)<1e-9:return
 q=[c[i]-a[i] for i in range(2)]
 t=(q[0]*v[1]-q[1]*v[0])/den;s=(q[0]*u[1]-q[1]*u[0])/den
 if 0<=t<=1 and 0<=s<=1:return [a[i]+u[i]*t for i in range(2)]
for side,(a,b) in enumerate(zip(shape,shape[1:]+shape[:1])):
 for c,d in zip(M['river_path'],M['river_path'][1:]):
  p=cross(a,b,c,d)
  if p is not None:crossings.append({'side':side,'point':p})
def add(id,x,y,kind='wall',registered=False,**extra):
 a=A[id]
 if registered:
  ax,ay=a['world_anchor'];x=x-ax+a['width']/2;y=y-ay+a['height']
 M['objects'].append({'id':id,'x':round(x,3),'y':round(y,3),'kind':kind,'solid':False,**extra})
for side,(a,b) in enumerate(zip(shape,shape[1:]+shape[:1])):
 dx=b[0]-a[0];dy=b[1]-a[1];length=math.hypot(dx,dy)
 relevant=[g for g in gates if min(a[0],b[0])<=g['x']<=max(a[0],b[0]) and min(a[1],b[1])<=g['y']<=max(a[1],b[1])]
 if dx and dy:
  left,right=sorted([a,b]);lo,hi=left[0],right[0];slope=(right[1]-left[1])/(hi-lo)
  line=lambda x:left[1]+slope*(x-lo)
  cuts=[]
  for r in [c for c in crossings if c['side']==side]:
   x,y=r['point'];ar=A['b12_arco_rio_ne'];ax,ay=ar['world_anchor']
   add(ar['id'],x,y,'watergate',True,wall_side=side)
   cuts.append((x-ax+16,x+ar['width']-ax-16));r['span']=[x-ax,x+ar['width']-ax]
  intervals=[];start=lo
  for u,v in sorted(cuts):intervals.append((start,u));start=v
  intervals.append((start,hi))
  id='b1_muralla_se' if slope>0 else 'b1_muralla_ne'
  for start,end in intervals:
   if end<=start:continue
   positions=[];x=start
   while x+256<end:positions.append(x);x+=240
   positions.append(max(start,end-256))
   for x in sorted(set(round(x,3) for x in positions)):
    add(id,x+128,line(x+128),registered=True,wall_side=side)
    pieces.append({'side':side,'id':id,'left':x,'right':x+256,'point':[x+128,line(x+128)]})
 else:
  steps=math.ceil(length/64)
  for i in range(steps+1):
   t=min(length,i*64);x=a[0]+dx*t/length;y=a[1]+dy*t/length
   if dx and any(abs(x-g['x'])<160 for g in relevant):continue
   if dy and any(g['y']-96<y<g['y']+288 for g in relevant):continue
   add('muralla_repetible_h' if dx else 'muralla_repetible_v',x,y,wall_side=side)
  if dy:
   for g in relevant:
    add('muralla_repetible_v',g['x'],g['y']-96,wall_side=side)
    add('muralla_repetible_v',g['x'],g['y']+288,wall_side=side)
 # Towers retain the original green roof, stone and heraldry.
 for t in range(0,int(length),768):
  x=a[0]+dx*t/length;y=a[1]+dy*t/length
  if any(math.hypot(x-g['x'],y-g['y'])<400 for g in gates):continue
  if any(r['side']==side and r['span'][0]-96<x<r['span'][1]+96 for r in crossings):continue
  add('torre_muralla',x,y,wall_side=side)
for x,y in shape:
 if not any(o['id']=='torre_muralla' and math.hypot(x-o['x'],y-o['y'])<16 for o in M['objects']):add('torre_muralla',x,y)
for g in gates:
 if g['id'] in ('este','oeste'):add('b12_puerta_'+g['id'],g['x'],g['y'],'gate',True)
 else:add('porton_abierto',g['x'],g['y']+48,'gate')
M['version']=C['version']
M['defenses']={'revision':'B.1.2','style_reference':'Murallas y portón originales de Briar','diagonal_segments':pieces,'river_crossings':crossings,'side_gate_axis':'east-west','depth_slices':32}
(R/'mapa/ciudad.json').write_text(json.dumps(M,ensure_ascii=False,separators=(',',':')))
p=R/'docs/defenses_validation.json';report={};report['placed_objects']=len(M['objects']);report['counts']=dict(collections.Counter(o['id'] for o in M['objects']));report['defenses_revision']='B.1.2';p.write_text(json.dumps(report,ensure_ascii=False,indent=2))
print('Placed',len(pieces),'diagonal modules,',len(crossings),'river arches and 2 side gates;',len(M['objects']),'total objects.')
