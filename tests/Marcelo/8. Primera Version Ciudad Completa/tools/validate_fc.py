from pathlib import Path
import json,hashlib,math
import numpy as np
from scipy.ndimage import binary_dilation,label
R=Path(__file__).resolve().parents[1];M=json.loads((R/'mapa/ciudad.json').read_text());C=json.loads((R/'catalogo.json').read_text());A={a['id']:a for a in C['assets']};w,h=M['collision_width'],M['collision_height'];col=np.frombuffer((R/'mapa/colision8.bin').read_bytes(),np.uint8).reshape(h,w).astype(bool);lab,_=label(~binary_dilation(col,structure=np.ones((3,3),bool)));main=lab[M['spawn'][1]//8,M['spawn'][0]//8];doors=[];errors=[]
for o in M['objects']:
 if o['kind'] not in ['building','landmark']:continue
 x,y=int(o['x']//8),int(o['y']//8);region=lab[y+2:y+14,max(0,x-6):min(w,x+7)];ok=bool((region==main).any());doors.append({'asset':o['id'],'x':o['x'],'y':o['y'],'reachable':ok})
 if not ok:errors.append('Door: '+str(o))
for p in M['pois']:
 if lab[p['y']//8,p['x']//8]!=main:errors.append('POI: '+p['id'])
for a in M['residents']:
 for p,q in zip(a['route'],a['route'][1:]):
  for t in np.linspace(0,1,max(2,math.ceil(math.dist(p,q)/4)+1)):
   x,y=(round(p[j]+t*(q[j]-p[j])) for j in (0,1))
   if not lab[y//8,x//8]:errors.append('Unsafe route: '+str(a['id']));break
art=[]
for a in C['assets']:
 if a['file'].startswith('assets/aprobados/'):art.append({'id':a['id'],'sha256':hashlib.sha256((R/a['file']).read_bytes()).hexdigest()})
char=hashlib.sha256((R/'assets/elias_64.png').read_bytes()).hexdigest();expected=json.loads((R/'docs/asset_versions.json').read_text())['character_sha256']
if char!=expected:errors.append('Character art changed')
report={'dimensions':[M['pixel_width'],M['pixel_height']],'doors_checked':len(doors),'doors_reachable':sum(d['reachable'] for d in doors),'pois_connected':len(M['pois']),'residents_checked':len(M['residents']),'character_unchanged':char==expected,'errors':errors,'passed':not errors};(R/'docs/fc_validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));(R/'docs/fc_door_access.json').write_text(json.dumps(doors));(R/'docs/fc_assets_sha256.json').write_text(json.dumps(art));print(json.dumps(report));assert not errors
