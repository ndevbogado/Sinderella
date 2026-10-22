"""Briar F.C: deterministic native-scale layout, collision, routes and terrain controls."""
from pathlib import Path
import ast,json,math,random,heapq,copy,collections
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import binary_dilation,distance_transform_edt,label
from scipy.spatial import cKDTree
R=Path(__file__).resolve().parents[1]
def read(p):return json.loads((R/p).read_text())
def save(p,v):(R/p).write_text(json.dumps(v,ensure_ascii=False,separators=(',',':'),default=lambda x:int(x)))
C=read('catalogo.json');ARC=read('sources/arquitectura_aprobada.json');assets={a['id']:a for a in C['assets']}
for a in read('sources/integration_baseline/catalogo.json')['assets']:
 if a['id'] not in assets:assets[a['id']]=a
PW,PH,S=9600,9720,8;W,H=1200,1215;rng=random.Random(7102026)
# Reuse the original terrain and footprint algorithms, without executing its old layout.
tree=ast.parse((R/'tools/integrate_approved.py').read_text())
for n in tree.body:
 if isinstance(n,ast.FunctionDef) and n.name in ['stroke_distance','footprint','rdp','octile']:
  exec(compile(ast.Module(body=[n],type_ignores=[]),'<terrain helpers>','exec'))
poly=[[2424,616],[7176,616],[8984,2424],[8984,7296],[7176,9104],[2424,9104],[616,7296],[616,2424]]
gates=[{'id':i,'x':x,'y':y} for i,x,y in [('norte',4800,616),('este',8984,4864),('sur',4800,9104),('oeste',616,4864)]]
M={'version':'5.0.0','title':'Briar — F.C · Meandros y mercados','pixel_width':PW,'pixel_height':PH,'screen_width':960,'screen_height':540,'screens':[10,18],'tile_size':32,'width':300,'height':304,'seed':7102026,'river':'noroeste a sudeste, meandros F.C','river_width':240,'wall_polygon':poly,'gates':gates,'objects':[],'bridges':[],'docks':[],'pois':[],'regions':[],'roads':[],'residents':[],'boats':[],'effects':[],'atlas_mode':'marching_squares_16','diagonal_atlases':C['diagonal_atlases'],'layers':{'base':'mapa/base.bin','overlay':'mapa/overlay.bin','collision':'mapa/colision8.bin'},'collision_cell_size':8,'collision_width':W,'collision_height':H,'terrain_mode':'approved_continuous_fields','street_angles':[0,45,90,135],'design_variant':'F.C'}
objects=M['objects'];roads=M['roads'];pois=M['pois'];zones=[]
def snap(x,s=8):return round(x/s)*s
def world(p):return [snap(400+p[0]*17.6),snap(407.2+p[1]*17.6)]
def mask_poly(points):
 im=Image.new('L',(W,H));ImageDraw.Draw(im).polygon([(x/8,y/8) for x,y in points],fill=1);return np.array(im,bool)
def mask_line(points,width):
 im=Image.new('L',(W,H));ImageDraw.Draw(im).line([(x/8,y/8) for x,y in points],fill=1,width=max(1,round(width/8)),joint='curve');return np.array(im,bool)
interior=mask_poly(poly);wall=mask_line(poly+[poly[0]],72)
for g in gates:wall[g['y']//8-13:g['y']//8+14,g['x']//8-13:g['x']//8+14]=False
knots=[world(p) for p in [[-16,-16],[65,65],[155,90],[190,145],[125,210],[150,290],[195,350],[280,365],[350,340],[390,400],[440,440],[520,520]]];ext=[knots[0]]+knots+[knots[-1]];river=[]
for i in range(1,len(ext)-2):
 a,b,c,d=ext[i-1:i+3]
 for t in np.linspace(0,1,24,endpoint=False):river.append([round(.5*(2*b[j]+(-a[j]+c[j])*t+(2*a[j]-5*b[j]+4*c[j]-d[j])*t*t+(-a[j]+3*b[j]-3*c[j]+d[j])*t*t*t)) for j in (0,1)])
river.append(knots[-1]);M['river_path']=river
water_d=np.full((H,W),-128,np.float32);road_d=np.full((H,W),-128,np.float32);road_mat=np.zeros((H,W),np.uint8)
stroke_distance(water_d,river,240)
occ=np.zeros((H,W),bool);visual=np.zeros_like(occ);reserved=np.zeros_like(occ);background=np.full((H,W),3,np.uint8);background[interior]=5
for x,y,r,mat in [(4800,4300,2400,0),(6600,2400,1800,4),(7500,5600,1900,5),(2250,6200,1500,8),(5300,8050,1900,1)]:
 yy,xx=np.ogrid[:H,:W];background[((xx*8-x)**2+(yy*8-y)**2<r*r)&interior]=mat
def bounds(rect):
 x,y,w,h=rect;return max(0,int(x//8)),max(0,int(y//8)),min(W,int(math.ceil((x+w)/8))),min(H,int(math.ceil((y+h)/8)))
def mark(arr,rect,v=True):
 x0,y0,x1,y1=bounds(rect);arr[y0:y1,x0:x1]=v

def artrect(o,pad=0):
 a=assets[o['id']];return [o['x']-a['anchor'][0]+8-pad,o['y']-a['anchor'][1]+8-pad,a['width']-16+pad*2,a['height']-16+pad*2]
def stamp(o):
 x,y,mask=footprint(o);h,w=mask.shape
 x0,y0=max(0,x),max(0,y);x1,y1=min(W,x+w),min(H,y+h)
 if x1>x0 and y1>y0:occ[y0:y1,x0:x1]|=mask[y0-y:y1-y,x0-x:x1-x]
def add(id,x,y,kind='decor',solid=None):
 o={'id':id,'x':snap(x),'y':snap(y),'kind':kind}
 if solid is not None:o['solid']=solid
 objects.append(o)
 if assets[id].get('solid') and solid is not False:stamp(o)
 return o

def area(id,name,rect,mat,purpose):
 mark(background,rect,mat);mark(reserved,rect);zones.append({'id':id,'name':name,'rect':rect,'purpose':purpose})
for id,x,y,poi,name in [('r02_castillo',4800,5376,'castillo','Castillo de Briar'),('r02_catedral',6496,2800,'catedral','Catedral'),('r02_mando',1984,6496,'mando','Mando del ejército'),('r02_universidad',7648,5936,'universidad','Universidad'),('biblioteca',7984,7456,'biblioteca','Biblioteca')]:
 o=add(id,x,y,'landmark');mark(visual,artrect(o,24));mark(reserved,artrect(o,40));pois.append({'id':poi,'name':name,'x':x,'y':y+128,'description':'Acceso a '+name+'.'})
 a=assets[id];area(poi+'_acceso',name+' · acceso',[x-a['width']/2-24,y-40,a['width']+48,264],4,'Acceso y circulación pública');M['regions'].append({'id':poi,'name':name,'rect':[x-a['width']/2-200,y-a['height']-100,a['width']+400,a['height']+500]})
area('pregones','Plaza de los pregones',[4400,5456,800,448],4,'Anuncios reales y reunión de los vecinos')
area('tarima','Tarima de los pregones',[4664,5440,272,96],9,'Estrado del pregonero')
add('estandarte',4656,5528);add('estandarte',4952,5528);pois.append({'id':'pregones','name':'Plaza de los pregones','x':4800,'y':5704,'description':'Los decretos del rey se anuncian desde la tarima junto al castillo.'})
area('mercado','Plaza del mercado',[5032,7608,784,512],1,'Puestos, carga y comercio diario')
for x in [5144,5376,5608]:
 for y in [7712,8064]:add('puesto_frutas' if x%3 else 'puesto_libros',x,y)
pois.append({'id':'mercado','name':'Plaza del mercado','x':5440,'y':7904,'description':'Puestos y comercios en el barrio meridional.'})
area('fuente','Plazoleta de la fuente',[5344,3680,512,424],12,'Agua y descanso del barrio central');add('fuente',5600,3912)
for x,y in [(5432,3800),(5760,3800),(5432,4040),(5760,4040)]:add('banco',x,y)
pois.append({'id':'fuente','name':'Plazoleta de la fuente','x':5584,'y':4048,'description':'Fuente y bancos en un pequeño lugar de encuentro.'});area('atrio','Atrio de la catedral',[6136,2856,720,336],4,'Reunión y ceremonias frente al templo')
# Native modular bridges: both diagonals; bridge length changes by repeating the middle.
families={f['id']:f for f in ARC['bridges']};decks=np.zeros_like(occ)
for i,(target,name) in enumerate([((135,88),'Puente del Norte'),((184,153),'Puente del Recodo'),((137,234),'Puente de los Vecinos'),((168,322),'Puente de la Guardia'),((255,360),'Puente del Mercado'),((346,342),'Puente de los Estudios'),((405,410),'Puente de los Muelles')]):
 dest=world(target);j=min(range(2,len(river)-2),key=lambda k:math.dist(river[k],dest));cx,cy=river[j];vx=river[j+2][0]-river[j-2][0];vy=river[j+2][1]-river[j-2][1];direction='ne' if vx*vy>=0 else 'se';sign=-1 if direction=='ne' else 1;mat='madera' if i in [1,2,6] else 'piedra';f=families[f'puente_{mat}_{direction}'];cx=snap(cx,32);cy=snap(cy,32);n=2
 while True:
  length=256+128*n;a=[cx-length//2,cy-sign*length//2];b=[cx+length//2,cy+sign*length//2]
  if water_d[a[1]//8,a[0]//8]<-56 and water_d[b[1]//8,b[0]//8]<-56:break
  n+=1
  if n>6:raise RuntimeError('Bridge banks too short')
 br={'id':'puente_'+str(i+1),'name':name,'material':mat,'a':a,'b':b,'x':cx,'y':cy,'width':48,'direction':direction,'spans':n,'kit':f['id'],'axis_degrees':sign*45};M['bridges'].append(br)
 pos=a[:]
 for part in [f['parts'][0]]+[f['parts'][1]]*n+[f['parts'][2]]:
  objects.append({'id':f['id']+'_'+part['part'],'x':pos[0],'y':pos[1],'kind':'bridge','solid':False,'bridge_id':br['id']});pos=[pos[k]+part['step'][k] for k in (0,1)]
 decks|=mask_line([a,b],56);reserved|=mask_line([a,b],160);pois.append({'id':br['id'],'name':name,'x':a[0]-32,'y':a[1]-sign*32,'description':'Paso modular de '+mat+' sobre los meandros.'})
# Streets use eight-direction navigation. Crossings are confined to real bridge decks.
allowed=~((water_d>-68)|visual|wall);allowed[decks]=True;nav=allowed[::4,::4];nh,nw=nav.shape;yy,xx=np.nonzero(nav);plan_tree=cKDTree(np.c_[xx*32,yy*32]);ideal=np.zeros_like(occ)
paths=[[(250,12),(250,110),(200,160),(200,300),(250,350),(250,494)],[(12,253),(100,253),(150,303),(310,303),(360,253),(488,253)],[(90,130),(140,180),(330,180),(390,120)],[(90,390),(180,390),(330,240),(430,240)],[(330,110),(330,370),(390,430)]]
for path in paths:ideal|=mask_line([world(p) for p in path],48)
pref=distance_transform_edt(~ideal)[::4,::4]*8;existing=np.zeros_like(nav)
def near_plan(p):
 _,i=plan_tree.query(p);return int(xx[i]),int(yy[i])
def astar(p,q):
 sx,sy=near_plan(p);ex,ey=near_plan(q);start=sy*nw+sx;goal=ey*nw+ex;todo=[(0,start)];cost={start:0};prev={}
 while todo:
  _,i=heapq.heappop(todo)
  if i==goal:
   ids=[i]
   while i in prev:i=prev[i];ids.append(i)
   raw=[[j%nw*32,j//nw*32] for j in reversed(ids)];slim=[]
   for point in raw:
    while len(slim)>1:
     a,b=slim[-2:];u=[b[0]-a[0],b[1]-a[1]];v=[point[0]-b[0],point[1]-b[1]]
     if u[0]*v[1]!=u[1]*v[0] or u[0]*v[0]+u[1]*v[1]<=0:break
     slim.pop()
    slim.append(point)
   for j in ids:existing[j//nw,j%nw]=True
   return slim
  x,y=i%nw,i//nw
  for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
   nx,ny=x+dx,y+dy
   if not(1<=nx<nw-1 and 2<=ny<nh-1) or not nav[ny,nx]:continue
   if dx and dy and not decks[ny*4,nx*4] and (not nav[y,nx] or not nav[ny,x]):continue
   j=ny*nw+nx;v=cost[i]+(14 if dx and dy else 10)+min(12,pref[ny,nx]/100)+(0 if existing[ny,nx] else 2)
   if v<cost.get(j,1e20):cost[j]=v;prev[j]=i;heapq.heappush(todo,(v+10*max(abs(nx-ex),abs(ny-ey)),j))
 raise RuntimeError('No street route '+str([p,q]))
def road(p,q,name,width=112,kind=1):
 points=astar(p,q)
 if len(points)>1:roads.append({'points':points,'width':width,'kind':kind,'name':name});stroke_distance(road_d,points,width,0 if kind==1 else 2)
def closest_road(p):return min([z for rr in roads for z in rr['points']],key=lambda z:math.dist(z,p))
for i,path in enumerate(paths):
 for a,b in zip(path,path[1:]):road(world(a),world(b),'Calle principal '+str(i+1),144 if i<2 else 112)
for g in gates:
 dx,dy={'norte':(0,-1),'sur':(0,1),'oeste':(-1,0),'este':(1,0)}[g['id']];x,y=g['x'],g['y'];points=[[x-dx*256,y-dy*256],[x+dx*640,y+dy*640]];roads.append({'points':points,'width':144,'kind':1,'name':'Camino de la puerta '+g['id']});stroke_distance(road_d,points,144,0);pois.append({'id':'puerta_'+g['id'],'name':'Puerta '+g['id'],'x':x-dx*160,'y':y-dy*160,'description':'Acceso a la ciudad y al bosque exterior.'})
for p in pois:road([p['x'],p['y']],closest_road([p['x'],p['y']]),'Acceso a '+p['name'],96)
for b in M['bridges']:
 for p in [b['a'],b['b']]:road(p,closest_road(p),'Acceso a '+b['name'],80)
for y in range(1450,8660,680):
 for x in range(1350,8680,820):
  x+=rng.randrange(-128,129,32);y0=y+rng.randrange(-96,97,32)
  if not interior[y0//8,x//8] or water_d[y0//8,x//8]>-120 or reserved[y0//8,x//8]:continue
  goal=closest_road([x,y0])
  if 200<math.dist(goal,[x,y0])<1100:road([x,y0],goal,'Pasaje de barrio',64,2)
print('Street network',len(roads),flush=True)
# Compact lots follow street fronts. Roofs may project over a rear alley; footprints never do.
road_buffer=road_d>-24;occupied=visual.copy();buildings=[]
def site(o,pad=0):
 a=assets[o['id']];return [o['x']-a['width']*.46-pad,o['y']-a['height']*.65-pad,a['width']*.92+2*pad,a['height']*.65+2*pad]
def place_house(id,x,y):
 o={'id':id,'x':snap(x),'y':snap(y),'kind':'building'};x0,y0,x1,y1=bounds(site(o,8))
 if x1<=x0 or y1<=y0 or not interior[y0:y1,x0:x1].all():return False
 if np.any(occupied[y0:y1,x0:x1]|reserved[y0:y1,x0:x1]|(water_d[y0:y1,x0:x1]>-32)):return False
 # Use the full native ground polygon, avoiding road intersections between vertices too.
 fx,fy,fm=footprint(o);fh,fw=fm.shape
 if fx<0 or fy<0 or fx+fw>W or fy+fh>H:return False
 if np.any(fm&road_buffer[fy:fy+fh,fx:fx+fw]):return False
 a=assets[id];bx0,by0,bx1,by1=bounds([o['x']-a['width']*.42,o['y']-a['height']*.28,a['width']*.84,a['height']*.28+8])
 if np.any(road_buffer[by0:by1,bx0:bx1]):return False
 objects.append(o);stamp(o);mark(occupied,site(o,8));buildings.append(o);mark(background,[o['x']-a['width']*.4,o['y']-12,a['width']*.8,80],8 if 'herreria' in id or 'almacen' in id else 1);return True
card=['r02_casa','r02_casa','r02_panaderia','r02_herbolario','r02_almacen','r02_posada'];diag=['r02_casa_45','r02_panaderia_45','r02_libreria_45','r02_herreria_45']
for rr in roads:
 for a,b in zip(rr['points'],rr['points'][1:]):
  length=math.dist(a,b)
  if length<96:continue
  tx,ty=(b[0]-a[0])/length,(b[1]-a[1])/length;nx,ny=-ty,tx
  for t in np.arange(120,length,256):
   for sign in [-1,1]:
    id=rng.choice(diag if abs(tx)>.1 and abs(ty)>.1 else card);asset=assets[id];offset=abs(nx)*(asset['width']/2+20)+abs(ny)*(asset['height']/2+12)+rr['width']/2+24
    place_house(id,a[0]+tx*t+nx*sign*offset,a[1]+ty*t+ny*sign*offset+asset['height']/2-4)
for batch in [0,1]:
 candidates=[(x+rng.randrange(-24,25,8),y+rng.randrange(-24,25,8)) for y in range(1152,8864,80) for x in range(1008,8720,80)];candidates.sort(key=lambda p:(p[1]//240,p[0]))
 for x,y in candidates:
  if occupied[y//8,x//8] or reserved[y//8,x//8] or road_d[y//8,x//8]>-20:continue
  place_house(rng.choice(['r02_casa','r02_casa','r02_herbolario','r02_panaderia'] if batch==0 else ['r02_casa','r02_herbolario','r02_casa_45']),x,y)
for o in buildings:stroke_distance(road_d,[[o['x'],o['y']+24],[o['x'],o['y']+72]],48,2)
print('Buildings',len(buildings),flush=True)
# Every larger residual pocket gets a working use, instead of unassigned empty grass.
activity=[];free=interior&~(occupied|reserved|road_buffer|wall|(water_d>-80));clearance=distance_transform_edt(free)*8
for _ in range(28):
 iy,ix=np.unravel_index(np.argmax(clearance),clearance.shape)
 if clearance[iy,ix]<88:break
 x,y=ix*8,iy*8;typ=len(activity)%4
 options=[([('pozo',0,0),('banco',120,32),('jardinera',-120,16)],'Patio vecinal con pozo',1),([('carro',0,0),('cajon',104,32),('barriles',-100,40),('sacos',64,-64)],'Patio de carga y almacén',8),([('puesto_frutas',0,0),('puesto_libros',152,0),('banco',-104,40)],'Pequeña feria de barrio',1),([('jardinera',-96,0),('banco',16,0),('jardinera',120,0),('pozo',24,100)],'Patio de descanso y agua',5)]
 ids,purpose,mat=options[typ];area('patio_'+str(len(activity)),purpose,[x-144,y-112,288,240],mat,purpose)
 for id,dx,dy in ids:
  if free[(y+dy)//8,(x+dx)//8]:add(id,x+dx,y+dy,'courtyard')
 activity.append({'x':x,'y':y,'purpose':purpose});mark(clearance,[x-320,y-280,640,560],0)
for j,o in enumerate(buildings):
 a=assets[o['id']];x=o['x']-a['width']*.35;y=o['y']+20
 if water_d[int(y/8),int(x/8)]<-12 and not occ[int(y/8),int(x/8)]:add(['jardinera','barriles','farola','cajon'][j%4],x,y,'frontage')
 if 'herreria' in o['id']:M['effects'].append({'type':'smoke','x':o['x']-24,'y':o['y']-a['height']+56})
# Two native piers, on a south bank, with reachable landings and cargo yards.
pier_exclusion=binary_dilation(decks,iterations=10)
for x in range(4304,6400,64):
 wet=np.flatnonzero(water_d[760:925,x//8]>0)
 if not len(wet):continue
 y=(760+int(wet[-1]))*8+40
 if any(abs(x-d[0])<448 for d in M['docks']):continue
 bx0,by0,bx1,by1=bounds([x-140,y,280,160])
 if np.any(occ[by0:by1,bx0:bx1]):continue
 px0,py0,px1,py1=bounds([x-144,y-296,288,304])
 if np.any(pier_exclusion[py0:py1,px0:px1]):continue
 add('muelle',x,y,'dock',False);M['docks'].append([x,y]);decks|=mask_poly([[x-24,y+8],[x-24,y-208],[x+24,y-208],[x+24,y+8]])|mask_poly([[x-108,y-208],[x+108,y-208],[x+108,y-152],[x-108,y-152]])
 area('embarcadero_'+str(len(M['docks'])),'Embarcadero',[x-144,y+8,288,112],16,'Carga y descarga fluvial');add('barriles',x-104,y+64);add('sacos',x+112,y+64)
 if len(M['docks'])==2:break
assert len(M['docks'])==2,'Two usable docks required'
x,y=M['docks'][0];pois.append({'id':'muelles','name':'Muelles del meandro','x':x,'y':y+96,'description':'Embarcaderos y transferencia de carga junto al barrio del mercado.'})
forest=0
for _ in range(12000):
 if forest>=700:break
 x=rng.randrange(32,PW-32,8);y=rng.randrange(280,PH-32,8)
 if interior[y//8,x//8] or road_d[y//8,x//8]>-120 or water_d[y//8,x//8]>-72 or any(math.dist([x,y],[g['x'],g['y']])<280 for g in gates) or occ[y//8,x//8]:continue
 add('r02_arbol_'+str(rng.randrange(1,13)).zfill(2),x,y,'outside');forest+=1
for _ in range(600):
 x=rng.randrange(24,PW-24,8);y=rng.randrange(64,PH-24,8)
 if not interior[y//8,x//8] and water_d[y//8,x//8]<-30 and road_d[y//8,x//8]<-32:add('r02_sotobosque_'+str(rng.choice([1,2,3,5,7,8,11,12])).zfill(2),x,y,'outside',False)
pois.append({'id':'bosque','name':'Bosque exterior','x':352,'y':4864,'description':'Bosque frondoso junto a la puerta oeste.'})
collision=occ|wall|(water_d>-3);collision[decks]=False;collision[:8]=True;collision[-2:]=True;collision[:,:2]=True;collision[:,-2:]=True
safe=~binary_dilation(collision,structure=np.ones((3,3),bool));navsafe=safe[1::2,1::2];labels,_=label(navsafe);main=np.bincount(labels.ravel())[1:].argmax()+1;reachable=labels==main;valid=np.argwhere(reachable);ntree=cKDTree(np.c_[valid[:,1]*16+8,valid[:,0]*16+8])
def near(p):
 _,j=ntree.query(p);return [int(valid[j,1])*16+8,int(valid[j,0])*16+8]
for p in pois:p['x'],p['y']=near([p['x'],p['y']])
for o in buildings:
 if 'herreria' in o['id']:
  x,y=near([o['x'],o['y']+64]);pois.append({'id':'herreria','name':'Calle de los Oficios','x':x,'y':y,'description':'Fraguas, talleres y patios de trabajo.'});break
M['spawn']=near([5440,7920]);roadcells=np.argwhere(reachable&(road_d[1::2,1::2]>0));rtree=cKDTree(np.c_[roadcells[:,1]*16+8,roadcells[:,0]*16+8]);NH,NW=reachable.shape
# Native 16px pathfinding includes collision clearance and prevents diagonal corner cutting.
def route(p,q):
 _,i=rtree.query(p);_,j=rtree.query(q);sy,sx=roadcells[i];ey,ex=roadcells[j];start=int(sy*NW+sx);goal=int(ey*NW+ex);cost={start:0};prev={};todo=[(0,start)]
 while todo:
  _,i=heapq.heappop(todo)
  if i==goal:
   path=[i]
   while i in prev:i=prev[i];path.append(i)
   return [[j%NW*16+8,j//NW*16+8] for j in reversed(path)]
  if len(cost)>12000:return None
  x,y=i%NW,i//NW
  for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1),(1,-1),(-1,-1)]:
   nx,ny=x+dx,y+dy
   if not(0<=nx<NW and 0<=ny<NH) or not reachable[ny,nx]:continue
   if dx and dy and (not reachable[y,nx] or not reachable[ny,x]):continue
   j=ny*NW+nx;v=cost[i]+(14 if dx and dy else 10)+(0 if road_d[ny*2+1,nx*2+1]>0 else 8)
   if v<cost.get(j,1e20):cost[j]=v;prev[j]=i;heapq.heappush(todo,(v+10*max(abs(nx-ex),abs(ny-ey)),j))
 return None
roles=[('Vecina','La fuente está al nordeste del castillo.'),('Comerciante','El mercado queda al sur, cruzando el río.'),('Guardia','Los pregones se anuncian delante del castillo.'),('Artesana','Los patios de los talleres siempre tienen trabajo.'),('Estudiante','La universidad está al este, la biblioteca más al sur.'),('Barquero','El río trae carga desde el noroeste.')]
for i in range(400):
 if i==0:p=[4800,5672];q=[4950,5800];name='Pregonero';line='¡Por orden de la Corona de Briar! Los anuncios se leen en esta plaza.';role=2
 else:
  rc=roadcells[rng.randrange(len(roadcells))];p=[int(rc[1])*16+8,int(rc[0])*16+8];q=[p[0]+rng.randrange(-480,481,16),p[1]+rng.randrange(-480,481,16)];role=i%6;name,line=roles[role]
 path=route(p,q)
 if path and len(path)>3:M['residents'].append({'id':i,'role':role,'name':name,'line':line,'route':path,'speed':rng.randrange(32,57),'start_index':rng.randrange(len(path)),'pause':1.5 if i else 4})
for i in range(7):
 section=river[12+i*30:50+i*30];M['boats'].append({'id':i,'asset':'b1_barca_carga' if i%2 else 'b1_barca_pesca','route':section,'speed':24+i*2,'start_index':i%len(section)})
for o in objects:
 if o['id']=='farola':M['effects'].append({'type':'lamp','x':o['x'],'y':o['y']-88})
 if o['id']=='fuente':M['effects'].append({'type':'fountain','x':o['x'],'y':o['y']-53})
M['public_spaces']=zones;M['courtyards']=activity;C['version']='5.0.0';C['terrain_revision']['control_size']=[W,H]
used={o['id'] for o in objects}|{b['asset'] for b in M['boats']};C['assets']=[a for id,a in assets.items() if id in used or id.startswith(('r02_','puente_','b1_muralla','b12_','muralla_')) or id in ['torre_muralla','porton_abierto']]
for z in zones:x0,y0,x1,y1=bounds(z['rect']);road_d[y0:y1,x0:x1]=-128
control=np.stack([background,road_mat,np.rint(np.clip(road_d,-128,127)+128).astype(np.uint8),np.full((H,W),255,np.uint8)],axis=2);gy,gx=np.gradient(water_d);length=np.maximum(.001,np.hypot(gx,gy));ri=np.stack([np.rint(np.clip(water_d,-128,127)+128).astype(np.uint8),np.rint(127+gx/length*127).astype(np.uint8),np.rint(127+gy/length*127).astype(np.uint8),np.full((H,W),255,np.uint8)],axis=2)
Image.fromarray(control).save(R/'mapa/superficie.png');Image.fromarray(ri).save(R/'mapa/rio_distancia.png');(R/'mapa/colision8.bin').write_bytes(collision.astype(np.uint8).tobytes())
yy=np.minimum(H-1,np.arange(304)*4+2);xx=np.arange(300)*4+2;coarse=background[yy[:,None],xx[None,:]].astype('<u2')*4;overlay=np.where(water_d[yy[:,None],xx[None,:]]>0,208,0).astype('<u2');(R/'mapa/base.bin').write_bytes(coarse.tobytes());(R/'mapa/overlay.bin').write_bytes(overlay.tobytes());(R/'mapa/colision.bin').write_bytes(collision[yy[:,None],xx[None,:]].astype(np.uint8).tobytes())
save('catalogo.json',C);save('mapa/ciudad.json',M)
angles=all(a[0]==b[0] or a[1]==b[1] or abs(a[0]-b[0])==abs(a[1]-b[1]) for rr in roads for a,b in zip(rr['points'],rr['points'][1:]))
report={'variant':'F.C','dimensions':[PW,PH],'screens':[10,18],'street_angles_valid':angles,'buildings':len(buildings),'forest_trees':forest,'residents':len(M['residents']),'bridges':len(M['bridges']),'docks':len(M['docks']),'unique_landmarks':{id:sum(o['id']=='r02_'+id for o in objects) for id in ['castillo','catedral','mando','universidad']},'working_courtyards':len(activity),'pois':len(pois),'collision_cell':8,'asset_art_unchanged':True}
save('docs/integration_layout.json',report);print(json.dumps(report),flush=True)
