"""Integrate approved Briar art while preserving the authored octagonal city."""
from pathlib import Path
import json,math,random,heapq,collections,copy
import numpy as np
from PIL import Image,ImageDraw
from scipy.spatial import cKDTree
from scipy.ndimage import binary_dilation,label
R=Path(__file__).resolve().parents[1];B=R/'sources/integration_baseline'
C=json.loads((B/'catalogo.json').read_text());M=json.loads((B/'ciudad.json').read_text())
ARC=json.loads((R/'sources/arquitectura_aprobada.json').read_text());TER=json.loads((R/'sources/suelos_aprobados.json').read_text())
PW,PH=14400,14580;S=8;W,H=1800,1823;rng=random.Random(6102026)
oldassets={a['id']:a for a in C['assets']};assets=dict(oldassets)
def save(p,j):p.write_text(json.dumps(j,ensure_ascii=False,separators=(',',':')))
def inside(x,y,m=0):
 return 768+m<x<13632-m and 768+m<y<13824-m and x+y>4864+m and x-y<9536-m and x+y<24096-m and y-x<9728-m
for a in ARC['assets']:
 if a.get('new_asset') is False:continue
 a=copy.deepcopy(a);a['id']='r02_'+a['id'];a['file']='assets/aprobados/'+Path(a['file']).name;a['ground']=a['group'] in ['sotobosque','raices'];a['solid']=a['group'] in ['edificaciones','monumentos','arboles']
 w,h=a['width'],a['height'];ax,ay=a['anchor']
 if a['group']=='edificaciones':
  a['collision_polygons']=[a.get('ground_footprint',[[w*.12,h-120],[w*.88,h-120],[w*.88,h-16],[w*.12,h-16]])]
 elif a['group']=='monumentos':
  a['collision_polygons']=[[[w*.09,h-300],[w*.91,h-300],[w*.91,h-24],[w*.09,h-24]]]
 elif a['group']=='arboles':
  rad=max(10,int(w*.045));a['collision_polygons']=[[[ax-rad,ay-18],[ax+rad,ay-18],[ax+rad,ay+4],[ax-rad,ay+4]]]
 else:a['collision_polygons']=[]
 assets[a['id']]=a
for f in ARC['bridges']:
 for p in f['parts']:
  id=f['id']+'_'+p['part'];a={'id':id,'label':f['label']+' · '+p['part'],'file':'assets/aprobados/'+Path(p['file']).name,'foreground':'assets/aprobados/'+Path(p['foreground']).name,'width':p['width'],'height':p['height'],'anchor':p['anchor'],'ground':True,'solid':False,'collision_polygons':[],'step':p['step'],'walkable_polygon':p['walkable_polygon'],'group':'puentes_modulares'}
  assets[id]=a
def rdp(points,tol=120):
 if len(points)<3:return points
 a,b=np.array(points[0]),np.array(points[-1]);p=np.array(points);ab=b-a;t=np.clip(((p-a)*ab).sum(axis=1)/max(1,(ab*ab).sum()),0,1)
 d=np.linalg.norm(p-(a+t[:,None]*ab),axis=1);i=int(np.argmax(d))
 return rdp(points[:i+1],tol)[:-1]+rdp(points[i:],tol) if d[i]>tol else [points[0],points[-1]]
def octile(points):
 ps=[[round(x/16)*16,round(y/16)*16] for x,y in rdp(points)];out=[ps[0]]
 for q in ps[1:]:
  x,y=out[-1];dx,dy=q[0]-x,q[1]-y;sx=1 if dx>=0 else -1;sy=1 if dy>=0 else -1
  if abs(dx)>abs(dy):
   half=round((abs(dx)-abs(dy))/32)*16;a=[x+sx*half,y];b=[a[0]+sx*abs(dy),q[1]]
  else:
   half=round((abs(dy)-abs(dx))/32)*16;a=[x,y+sy*half];b=[q[0],a[1]+sy*abs(dx)]
  for p in [a,b,q]:
   if p!=out[-1]:out.append(p)
 slim=[]
 for p in out:
  while len(slim)>1:
   a,b=slim[-2:];u=(b[0]-a[0],b[1]-a[1]);v=(p[0]-b[0],p[1]-b[1])
   if u[0]*v[1]!=u[1]*v[0] or u[0]*v[0]+u[1]*v[1]<=0:break
   slim.pop()
  slim.append(p)
 return slim
bridge_objects=[];bridge_old=copy.deepcopy(M['bridges']);families={f['id']:f for f in ARC['bridges']}
for b in M['bridges']:
 if b['id']=='puente_2':
  target=[b['x']+320,b['y']+352];b['x'],b['y']=min(M['river_path'],key=lambda p:math.dist(p,target))
 f=families['puente_'+b['material']+'_ne'];n=3;length=256+128*n;cx,cy=b['x'],b['y'];a=[round(cx-144-n*64),round(cy+144+n*64)];end=[a[0]+length,a[1]-length]
 b.update({'a':a,'b':end,'width':48,'direction':'ne','spans':n,'kit':f['id'],'axis_degrees':-45,'x':a[0]+length/2,'y':a[1]-length/2})
 t=0
 for p in [f['parts'][0]]+[f['parts'][1]]*n+[f['parts'][2]]:
  bridge_objects.append({'id':f['id']+'_'+p['part'],'x':a[0]+t,'y':a[1]-t,'kind':'bridge','solid':False,'bridge_id':b['id']});t+=p['step'][0]
roads=[]
for rr in M['roads']:
 rr=copy.deepcopy(rr);points=rr['points']
 for old,new in zip(bridge_old,M['bridges']):
  for k in ['a','b']:
   points=[new[k] if math.dist(p,old[k])<24 else p for p in points]
 rr['points']=octile(points);roads.append(rr)
# Connect each new abutment to its former approach with permitted angles.
for old,new in zip(bridge_old,M['bridges']):
 for key in ['a','b']:roads.append({'points':octile([new[key],old[key]]),'width':80,'kind':1,'name':'Acceso '+new['name']})
roads.append({'points':octile([[9296,9856],[9648,11056]]),'width':128,'kind':1,'name':'Paseo de la Universidad'})
M['roads']=roads
road_d=np.full((H,W),-128,np.float32);road_mat=np.zeros((H,W),np.uint8)
water_d=np.full((H,W),-128,np.float32)
def stroke_distance(dest,points,width,material=None):
 half=width/2
 for a,b in zip(points,points[1:]):
  x0=max(0,int((min(a[0],b[0])-half-132)//S));x1=min(W,int((max(a[0],b[0])+half+132)//S)+1);y0=max(0,int((min(a[1],b[1])-half-132)//S));y1=min(H,int((max(a[1],b[1])+half+132)//S)+1)
  if x1<=x0 or y1<=y0:continue
  yy,xx=np.mgrid[y0:y1,x0:x1];xx=xx*S;yy=yy*S;dx=b[0]-a[0];dy=b[1]-a[1];t=np.clip(((xx-a[0])*dx+(yy-a[1])*dy)/max(1,dx*dx+dy*dy),0,1)
  d=half-np.hypot(xx-a[0]-t*dx,yy-a[1]-t*dy);v=dest[y0:y1,x0:x1];hit=d>v
  if material is not None:road_mat[y0:y1,x0:x1][hit]=material
  np.maximum(v,d,out=v)
stroke_distance(water_d,M['river_path'],M['river_width'])
for rr in roads:stroke_distance(road_d,rr['points'],rr['width'],0 if rr['kind']==1 else 2)
base32=np.frombuffer((B/'base.bin').read_bytes(),dtype='<u2').reshape(456,450)//4
background=np.repeat(np.repeat(base32,4,axis=0),4,axis=1)[:H,:W].astype(np.uint8)
# Remove checkerboard placement and retain continuous court paving.
background[np.isin(background,[7,9,10])]=3
def area(x,y,w,h,mat):
 background[max(0,y//8):min(H,(y+h)//8),max(0,x//8):min(W,(x+w)//8)]=mat
area(8464,9392,1712,720,4);area(10000,8776,1216,1200,16)
for b in M['bridges']:
 if b['material']=='piedra':
  for x,y in [b['a'],b['b']]:area(x-96,y-96,192,192,4)
wall=Image.new('L',(W,H));dw=ImageDraw.Draw(wall);poly=[(x/8,y/8) for x,y in M['wall_polygon']];dw.line(poly+[poly[0]],fill=1,width=7,joint='curve')
for g in M['gates']:x,y=g['x']/8,g['y']/8;dw.rectangle((x-12,y-12,x+12,y+12),fill=0)
wall=np.array(wall,dtype=bool);occ=np.zeros((H,W),bool);built=np.zeros_like(occ)
def footprint(o):
 a=assets[o['id']];w,h=a['width'],a['height'];ax,ay=a.get('anchor',[w/2,h]);x0=math.floor((o['x']-ax)/8);y0=math.floor((o['y']-ay)/8)
 fw,fh=math.ceil(w/8)+2,math.ceil(h/8)+2;im=Image.new('L',(fw,fh));d=ImageDraw.Draw(im)
 for p in a.get('collision_polygons',[]):d.polygon([(v[0]/8,v[1]/8) for v in p],fill=1)
 return x0,y0,np.array(im,dtype=bool)
def place(o,check_roads=False,separate=True):
 x,y,mask=footprint(o);h,w=mask.shape
 if x<0 or y<0 or x+w>W or y+h>H:return False
 padded=binary_dilation(mask,iterations=2) if separate else mask
 obstacles=occ[y:y+h,x:x+w]|wall[y:y+h,x:x+w]|(water_d[y:y+h,x:x+w]>-8)
 if check_roads:obstacles=obstacles|(road_d[y:y+h,x:x+w]>-12)
 if np.any(padded&obstacles):return False
 occ[y:y+h,x:x+w]|=mask
 if o.get('kind') in ['building','landmark']:built[y:y+h,x:x+w]|=mask
 objects.append(o);return True
objects=[]
landmap={'castillo_integrado':'r02_castillo','catedral':'r02_catedral','mando_ejercito':'r02_mando','biblioteca':'biblioteca'}
for o in M['objects']:
 if o.get('kind')=='landmark':
  o=copy.deepcopy(o);o['id']=landmap[o['id']]
  if not place(o):raise RuntimeError('Landmark obstructed '+o['id'])
university={'id':'r02_universidad','x':9296,'y':9616,'kind':'landmark'}
if not place(university):raise RuntimeError('University obstructed')
M['pois'].append({'id':'universidad','name':'Universidad de Briar','x':9296,'y':9808,'description':'Claustro académico y observatorio; edificio único, distinto de la biblioteca.'})
M['pois'].append({'id':'bosque','name':'Bosque exterior','x':448,'y':7824,'description':'Bosque frondoso junto a la muralla oeste, con doce siluetas de árbol y sotobosque.'})
M['regions'].insert(0,{'id':'universidad','name':'Recinto Universitario','rect':[8400,8376,1900,1720]})
# Find nearby road orientation without distorting any building sprite.
samples=[];angles=[]
for rr in roads:
 for a,b in zip(rr['points'],rr['points'][1:]):
  steps=max(1,int(math.dist(a,b)/80));diag=bool(a[0]!=b[0] and a[1]!=b[1])
  for t in np.linspace(0,1,steps+1):samples.append([a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])]);angles.append(diag)
tree=cKDTree(samples);moved=0;dropped=0
offsets=[(0,0)]
for radius in [48,96,160,240,336,448,592,752]:
 for t in range(16):offsets.append((round(math.cos(t*math.pi/8)*radius/8)*8,round(math.sin(t*math.pi/8)*radius/8)*8))
card=['casa','casa','casa','panaderia','herbolario','posada','almacen'];diag=['casa_45','casa_45','panaderia_45','libreria_45','herreria_45']
for index,old in enumerate(o for o in M['objects'] if o.get('kind')=='building'):
 _,j=tree.query([old['x'],old['y']]);id='herreria' if old['id']=='herreria' else (diag if angles[j] else card)[index%len(diag if angles[j] else card)]
 success=False
 for dx,dy in offsets:
  x=round((old['x']+dx)/8)*8;y=round((old['y']+dy)/8)*8
  if not inside(x,y,224) or any(abs(x-b['x'])<440 and abs(y-b['y'])<440 for b in M['bridges']):continue
  o={'id':'r02_'+id,'x':x,'y':y,'kind':'building'}
  if place(o,True):success=True;moved+=bool(dx or dy);break
 if not success:dropped+=1
# Existing civic props and defenses remain in their city; discard only obstructed bases.
for old in M['objects']:
 if old.get('kind') in ['landmark','building','bridge']:continue
 o=copy.deepcopy(old)
 if o.get('kind') in ['wall','gate','watergate','dock']:
  objects.append(o);continue
 if o['id'] in ['arbol','cipres']:
  o['id']='r02_arbol_'+str((int(o['x']+o['y'])%12)+1).zfill(2)
 if o['id']=='arbusto':o['id']='r02_sotobosque_'+str([1,2,3,11][int(o['x'])%4]).zfill(2)
 if assets[o['id']].get('solid') and o.get('solid',True):place(o,True,False)
 else:
  xi,yi=int(o['x']/8),int(o['y']/8)
  if 0<=xi<W and 0<=yi<H and not built[yi,xi] and water_d[yi,xi]<-8:objects.append(o)
# Forest is irregular, diverse and keeps gate routes and the river clear.
forest_count=sum(1 for o in objects if o.get('kind')=='outside' and o['id'].startswith('r02_arbol'))
for _ in range(12000):
 if forest_count>=1100:break
 x=rng.randrange(40,PW-40,8);y=rng.randrange(280,PH-40,8)
 if inside(x,y,-160) or road_d[y//8,x//8]>-96 or water_d[y//8,x//8]>-72 or any(math.dist([x,y],[g['x'],g['y']])<288 for g in M['gates']):continue
 o={'id':'r02_arbol_'+str(rng.randrange(1,13)).zfill(2),'x':x,'y':y,'kind':'outside'}
 if place(o,True):forest_count+=1
for _ in range(1700):
 x=rng.randrange(32,PW-32,8);y=rng.randrange(64,PH-32,8)
 if inside(x,y,-80) or road_d[y//8,x//8]>-40 or water_d[y//8,x//8]>-16:continue
 objects.append({'id':'r02_sotobosque_'+str(rng.choice([1,2,3,5,7,8,11,12])).zfill(2),'x':x,'y':y,'kind':'outside'})
objects+=bridge_objects
collision=occ|wall|(water_d>-3)
def clear_polygon(points):
 im=Image.new('L',(W,H));ImageDraw.Draw(im).polygon([(x/8,y/8) for x,y in points],fill=1);collision[np.array(im,dtype=bool)]=False
for b in M['bridges']:
 a,z=[b['a'][0]-12,b['a'][1]+12],[b['b'][0]+12,b['b'][1]-12];v=17
 clear_polygon([[a[0]-v,a[1]-v],[z[0]-v,z[1]-v],[z[0]+v,z[1]+v],[a[0]+v,a[1]+v]])
for x,y in M['docks']:
 clear_polygon([[x-24,y],[x-24,y-208],[x+24,y-208],[x+24,y]])
 clear_polygon([[x-108,y-208],[x+108,y-208],[x+108,y-152],[x-108,y-152]])
collision[:8]=True;collision[-2:]=True;collision[:,:2]=True;collision[:,-2:]=True
# Navigation accounts for the player's foot radius on a 16px planning lattice.
safe=~binary_dilation(collision,structure=np.ones((3,3),dtype=bool));nav=safe[1::2,1::2];NH,NW=nav.shape
labels,num=label(nav);spawn=M['spawn'];main_label=int(labels[spawn[1]//16,spawn[0]//16])
if not main_label:main_label=int(np.bincount(labels.ravel())[1:].argmax()+1)
reachable=labels==main_label;valid=np.argwhere(reachable);navtree=cKDTree(np.column_stack([valid[:,1]*16+8,valid[:,0]*16+8]))
def nearest(x,y):
 _,i=navtree.query([x,y]);return [int(valid[i,1])*16+8,int(valid[i,0])*16+8]
for p in M['pois']:
 if p['id'].startswith('puente_'):
  b=next(b for b in M['bridges'] if b['id']==p['id']);p['x'],p['y']=b['a'][0]-32,b['a'][1]+32
 p['x'],p['y']=nearest(p['x'],p['y'])
M['spawn']=[next(p for p in M['pois'] if p['id']=='mercado')[k] for k in ['x','y']]
roadnav=(road_d[1::2,1::2]>0)&reachable
roadcells=np.argwhere(roadnav);rtree=cKDTree(np.column_stack([roadcells[:,1]*16+8,roadcells[:,0]*16+8]))
def near_road(p):
 _,i=rtree.query(p);return [int(roadcells[i,1]),int(roadcells[i,0])]
def route(a,b):
 start=a[1]*NW+a[0];goal=b[1]*NW+b[0];todo=[(0,start)];cost={start:0};prev={}
 while todo:
  _,i=heapq.heappop(todo)
  if i==goal:
   path=[i]
   while i in prev:i=prev[i];path.append(i)
   return [[int(j%NW)*16+8,int(j//NW)*16+8] for j in reversed(path)]
  if len(cost)>24000:return None
  x=i%NW;y=i//NW
  for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1),(1,-1),(-1,-1)]:
   nx=x+dx;ny=y+dy
   if not (0<=nx<NW and 0<=ny<NH) or not reachable[ny,nx]:continue
   if dx and dy and (not reachable[y,nx] or not reachable[ny,x]):continue
   j=ny*NW+nx;v=cost[i]+(14 if dx and dy else 10)+(0 if roadnav[ny,nx] else 5)
   if v<cost.get(j,10**10):cost[j]=v;prev[j]=i;heapq.heappush(todo,(v+10*max(abs(nx-b[0]),abs(ny-b[1])),j))
 return None
residents=[]
for n in M['residents']:
 a=near_road(n['route'][0]);b=near_road(n['route'][-1]);p=route(a,b)
 if p and len(p)>2:
  n=copy.deepcopy(n);n['route']=p;n['start_index']=min(n['start_index'],len(p)-1);residents.append(n)
M['residents']=residents;M['objects']=objects
M['effects']=[]
for o in objects:
 if o['id']=='farola':M['effects'].append({'type':'lamp','x':o['x'],'y':o['y']-88})
 if o['id']=='fuente':M['effects'].append({'type':'fountain','x':o['x'],'y':o['y']-53})
 if 'herreria' in o['id']:M['effects'].append({'type':'smoke','x':o['x']-24,'y':o['y']-assets[o['id']]['height']+56})
used={o['id'] for o in objects}|{b['asset'] for b in M['boats']}|{a for a in assets if a.startswith('puente_') and '_se_' in a}
C['assets']=[a for id,a in assets.items() if id in used]
C['materials']=[{'id':m['id'],'name':m['name'],'file':'terrenos/materiales/'+Path(m['source']).name,'field':'terrenos/campos/'+Path(m['field']).name,'source_size':m['source_size'],'atlas_id':m['id']*4} for m in TER['materials']]
C['terrain_revision']={'revision':2,'water':['terrenos/campos/'+Path(w['field']).name for w in TER['water_layers']],'coping':'terrenos/campos/'+Path(TER['bank_coping_field']).name,'control':'mapa/superficie.png','river':'mapa/rio_distancia.png','grid_step':8,'control_size':[W,H],'chunk_size':512}
for t in C['transitions']:
 match=next((n for n in TER['transitions'] if n['family']==t['family'] and n['mask']==t['mask']),None)
 if match:t['file']='terrenos/transiciones/'+Path(match['file']).name
for t in C['diagonal_transitions']:
 match=next((n for n in TER['diagonals'] if n['family']==t['family'] and n['mask']==t['mask']),None)
 if match:t['file']='terrenos/diagonales/'+Path(match['file']).name
C['version']='4.0.0';M.update({'version':'4.0.0','title':'Briar — Ciudad integrada R02','collision_cell_size':8,'collision_width':W,'collision_height':H,'terrain_mode':'approved_continuous_fields','street_angles':[0,45,90,135]})
M['layers']['collision']='mapa/colision8.bin'
control=np.stack([background,road_mat,np.rint(np.clip(road_d,-128,127)+128).astype(np.uint8),np.full((H,W),255,np.uint8)],axis=2)
gy,gx=np.gradient(water_d);length=np.maximum(.001,np.hypot(gx,gy));river=np.stack([np.rint(np.clip(water_d,-128,127)+128).astype(np.uint8),np.rint(127+gx/length*127).astype(np.uint8),np.rint(127+gy/length*127).astype(np.uint8),np.full((H,W),255,np.uint8)],axis=2)
Image.fromarray(control).save(R/'mapa/superficie.png');Image.fromarray(river).save(R/'mapa/rio_distancia.png')
(R/'mapa/colision8.bin').write_bytes(collision.astype(np.uint8).tobytes())
# Keep coarse navigation data for editor exchange and diagnostic overlays.
(R/'mapa/colision.bin').write_bytes(collision[np.minimum(H-1,np.arange(456)*4+2)[:,None],np.minimum(W-1,np.arange(450)*4+2)[None,:]].astype(np.uint8).tobytes())
save(R/'catalogo.json',C);save(R/'mapa/ciudad.json',M)
angles_ok=all((a[0]==b[0] or a[1]==b[1] or abs(a[0]-b[0])==abs(a[1]-b[1])) for rr in roads for a,b in zip(rr['points'],rr['points'][1:]))
report={'street_angles_valid':angles_ok,'buildings':sum(o['kind']=='building' for o in objects),'relocated_buildings':moved,'unplaced_old_buildings':dropped,'forest_trees':forest_count,'residents':len(residents),'bridges':len(M['bridges']),'unique_landmarks':{id:sum(o['id']=='r02_'+id for o in objects) for id in ['castillo','catedral','mando','universidad']},'pois_reachable':len(M['pois']),'collision_cell':8,'objects':len(objects)}
save(R/'docs/integration_layout.json',report);print(json.dumps(report),flush=True)

