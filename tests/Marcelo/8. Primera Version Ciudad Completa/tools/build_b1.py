"""Briar B.1: authored civic layout, organic street graph, native 32px terrain,
octagonal wall, navigation and residents. Deterministic seed 1012026."""
from pathlib import Path
import json, math, random, array, heapq, collections
import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial import Delaunay, cKDTree
R=Path(__file__).resolve().parents[1];C=json.loads((R/'catalogo.json').read_text());A={a['id']:a for a in C['assets']}
PW,PH,T=14400,14580,32;W,H=450,456;N=W*H;S=8;rng=random.Random(1012026)
objects=[];roads=[];pois=[];bridges=[];effects=[];regions=[];occupied={};reservations=[]
shape=[(4096,768),(10304,768),(13632,4096),(13632,10464),(10304,13824),(4096,13824),(768,10464),(768,4096)]
gates=[('norte',7200,768),('este',13632,7296),('sur',7200,13824),('oeste',768,7296)]
surface=Image.new('L',(1801,1825));sd=ImageDraw.Draw(surface);waterim=Image.new('L',surface.size);wd=ImageDraw.Draw(waterim)
road_im=Image.new('L',surface.size);rd=ImageDraw.Draw(road_im)
terrain=np.full((H,W),12,dtype=np.uint16);road_grid=np.zeros((H,W),np.uint8)
def inside(x,y,margin=0):
 return 768+margin<x<13632-margin and 768+margin<y<13824-margin and x+y>4864+margin and x-y<9536-margin and x+y<24096-margin and y-x<9728-margin
def scalepts(points):return [(round(x/S),round(y/S)) for x,y in points]
def stroke(draw,points,width,fill):
 pts=scalepts(points);w=max(1,round(width/S));draw.line(pts,fill=fill,width=w,joint='curve');r=w//2
 for x,y in pts:draw.ellipse((x-r,y-r,x+r,y+r),fill=fill)
def curve(points,step=32):
 p=[points[0]]+points+[points[-1]];out=[]
 for i in range(1,len(p)-2):
  a,b,c,d=[np.array(p[j],float) for j in [i-1,i,i+1,i+2]];n=max(2,int(np.linalg.norm(c-b)/step))
  for k in range(n):
   t=k/n;v=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t);out.append([round(v[0]),round(v[1])])
 out.append(list(points[-1]));return out
river=curve([[-640,-128],[1536,1184],[2912,2176],[3680,4096],[5056,5504],[7200,6688],[9504,7904],[11136,9568],[12320,11680],[14848,14240]],24)
stroke(wd,river,352,1);water_pixels=np.asarray(waterim)
def watery(x,y):return 0<=x<PW and 0<=y<PH and bool(water_pixels[min(1824,int(y/S)),min(1800,int(x/S))])
def road(points,width=96,kind=1,smooth=True,name=''):
 pts=curve(points,32) if smooth and len(points)>2 else points
 stroke(rd,pts,width,kind);roads.append({'points':pts,'width':width,'kind':kind,'name':name});return pts
def rect_cells(rect):
 x,y,w,h=rect
 for yy in range(max(0,math.floor(y/T)),min(H,math.ceil((y+h)/T))):
  for xx in range(max(0,math.floor(x/T)),min(W,math.ceil((x+w)/T))):yield xx,yy
def paint(rect,mat=4):
 for x,y in rect_cells(rect):terrain[y,x]=mat*4+(x*3+y*7)%4
def reserve(rect):reservations.append(rect)
def overlaps(a,b):return a[0]<b[0]+b[2] and a[0]+a[2]>b[0] and a[1]<b[1]+b[3] and a[1]+a[3]>b[1]
def region(id,name,rect):regions.append({'id':id,'name':name,'rect':rect});reserve(rect)
def poi(id,name,x,y,desc):pois.append({'id':id,'name':name,'x':int(x),'y':int(y),'description':desc})
def add(id,x,y,kind='',pack=False,solid=None):
 a=A[id];x=int(x);y=int(y);rect=[x-a['width']*.43,y-a['height']*.66,a['width']*.86,a['height']*.65]
 if pack:
  if not inside(x,y,176) or any(overlaps(rect,r) for r in reservations):return False
  for px,py in [(x,y-32),(x-a['width']*.35,y-64),(x+a['width']*.35,y-64),(x,y-160)]:
   if watery(px,py):return False
  # Foundation cannot occupy any existing road, including a diagonal verge.
  for xx,yy in rect_cells([x-a['width']*.38,y-96,a['width']*.76,104]):
   if road_grid[yy,xx]:return False
  for by in range(int(rect[1]//256),int((rect[1]+rect[3])//256)+1):
   for bx in range(int(rect[0]//256),int((rect[0]+rect[2])//256)+1):
    if any(overlaps(rect,o) for o in occupied.get((bx,by),[])):return False
 o={'id':id,'x':x,'y':y,'kind':kind}
 if solid is not None:o['solid']=solid
 objects.append(o)
 if pack or kind=='building':
  for by in range(int(rect[1]//256),int((rect[1]+rect[3])//256)+1):
   for bx in range(int(rect[0]//256),int((rect[0]+rect[2])//256)+1):occupied.setdefault((bx,by),[]).append(rect)
 return True
# Authored connections preserving B.1's recognizable positions and districts.
road([[7200,0],[7200,768],[6688,2272],[6496,4128],[6864,5264],[7360,5504]],176,name='Camino del Palacio')
road([[7200,768],[8096,2240],[9216,3456],[9728,5152],[11904,6496],[12832,7008],[13632,7296],[14400,7296]],144,name='Avenida de la Guardia')
road([[0,7296],[768,7296],[2304,6944],[3456,7488],[4832,7488],[5856,8736],[6464,10272],[6944,12512],[7200,13824],[7200,14580]],160,name='Camino de los Mercaderes')
road([[3296,5072],[2528,5984],[2944,7104],[4832,7488]],112,name='Calle de la Catedral')
road([[4832,7488],[4544,8800],[3712,10048],[4864,11328],[6208,11904],[6944,12512]],112,name='Calle de los Oficios')
road([[6464,10272],[8032,10880],[9632,11200],[11168,12256],[12224,12032]],128,name='Paseo de los Libros')
road([[11904,6496],[11488,7520],[11616,8752],[12544,9536]],144,name='Paseo de los Muelles')
road([[13632,7296],[12576,7776],[11616,8752]],144)
road([[7360,5504],[8448,5216],[9728,5152]],112)
# River bridge centers are selected along the approved northwest-southeast flow.
for i,ratio in enumerate([.205,.305,.400,.490,.580,.685,.80]):
 n=int(ratio*(len(river)-1));cx,cy=river[n];mat='madera' if i in [0,3,5] else 'piedra'
 p=[cx-352,cy+192];q=[cx+352,cy-192]
 bridges.append({'id':'puente_'+str(i+1),'name':['Puente del Jardín','Puente de la Catedral','Puente del Mercado','Puente de los Tejedores','Puente de la Guardia','Puente de los Muelles','Puente de los Libros'][i],'material':mat,'a':p,'b':q,'x':cx,'y':cy,'width':80})
 add('b1_puente_'+mat,cx,cy+256,'bridge',solid=False);reserve([cx-440,cy-304,880,640])
 road([p,[p[0]-256,p[1]+128]],112);road([q,[q[0]+256,q[1]-128]],112)
 poi('puente_'+str(i+1),bridges[-1]['name'],p[0]-48,p[1]+16,'Cruce de '+mat+' entre los barrios de Briar.')
left_targets=[[2624,3520],[3296,5072],[4832,7488],[5856,8736],[8032,10880],[9632,11200],[11168,12256]]
right_targets=[[6496,4128],[6864,5264],[7360,5504],[9728,5152],[11904,6496],[11616,8752],[12544,9536]]
for b,left,right in zip(bridges,left_targets,right_targets):road([left,b['a']],112);road([right,b['b']],112)
# Riverbank walks echo the local tangent rather than parallel rectangular roads.
for side in [-1,1]:
 pts=[]
 for i in range(8,len(river)-8,4):
  x,y=river[i];dx=river[i+3][0]-river[i-3][0];dy=river[i+3][1]-river[i-3][1];ln=math.hypot(dx,dy)
  px=x-side*dy/ln*272;py=y+side*dx/ln*272
  if inside(px,py,200):pts.append([round(px),round(py)])
 if pts:road(pts,80,1,False,'Paseo de ribera')
# Major precincts are compact enough to show activity in a 960x540 viewport.
region('real','Recinto Real',[6400,3744,2144,2112]);add('castillo_integrado',7360,5280,'landmark');paint([6592,5280,1568,512],4);paint([7264,5280,192,544],12)
poi('castillo','Castillo y Torre Central',7360,5440,'El castillo y su torre forman una sola construcción.')
for x in [6872,7832]:add('estandarte',x,5376);add('jardinera',x,5472);add('farola',x,5600)
for x in [6640,8080]:add('fuente',x,5536);add('cipres',x,4992);add('cipres',x,4576)
region('catedral','Barrio de la Catedral',[2608,3856,1376,1488]);add('catedral',3296,4880,'landmark');paint([2816,4880,960,448],4);paint([3200,4848,192,512],12)
poi('catedral','Catedral de la Rosa',3296,5088,'Atrio, fuente y pequeños patios alrededor del templo.')
for x in [2880,3696]:add('cipres',x,4848);add('banco',x,5168);add('jardinera',x,5056)
add('fuente',3296,5296)
region('academico','Barrio de la Biblioteca',[8816,9872,1632,1664]);add('biblioteca',9632,10848,'landmark');paint([9040,10848,1216,640],4);paint([9536,10816,192,512],12)
poi('biblioteca','Gran Biblioteca',9632,11040,'Libros, estudio y un claustro con jardín.')
for x in [9120,10080]:add('puesto_libros',x,11024);add('banco',x,11312);add('jardinera',x+128,11312);add('cipres',x,10592)
region('militar','Distrito de la Guardia',[10944,5344,1824,1600]);add('mando_ejercito',11904,6256,'landmark');paint([11328,6256,1152,608],11)
poi('mando','Centro de Mando',11904,6496,'Patio de instrucción, guardias y almacenes del ejército.')
for x in [11424,12320]:add('estandarte',x,6352);add('cajon',x,6720);add('barriles',x+96,6720)
region('mercado','Gran Mercado',[3840,6624,1952,1664]);paint([4000,7008,1600,1152],4)
add('fuente',4704,7360);poi('mercado','Gran Mercado',4832,7552,'Mercaderes, panadería, posada y vecinos alrededor de la fuente.')
for id,x,y in [('b1_casa_03',4256,7112),('b1_casa_02',4624,7008),('b1_casa_05',5312,7168),('b1_casa_01',4056,7872),('b1_casa_11',5504,7776),('b1_casa_08',4392,8176)]:add(id,x,y,'building')
for i,(x,y) in enumerate([(4224,7520),(4416,7440),(4536,7672),(5184,7512),(5392,7424),(5136,7896),(4744,8056),(4056,7600)]):add('puesto_frutas' if i%2==0 else 'puesto_libros',x,y)
for x,y in [(4504,7200),(4864,7248),(4896,7872),(4144,7776),(5520,8064)]:add('jardinera',x,y)
for x,y in [(4984,7304),(4456,7912),(5280,7728)]:add('farola',x,y);add('banco',x+88,y+24)
add('carro',4184,7272);add('cartel',4984,7632)
region('artesanos','Barrio de los Oficios',[4064,10144,1632,1792]);paint([4264,10992,1232,688],13)
for id,x,y in [('herreria',4640,11168),('b1_casa_12',5184,10912),('b1_casa_05',4256,11296),('b1_casa_10',5376,11648)]:add(id,x,y,'building');effects.append({'type':'smoke','x':x-38,'y':y-220})
poi('herreria','Herrerías y Talleres',4816,11328,'Forjas encendidas, aprendices y carros de reparto.')
for x,y in [(4960,11584),(4448,11648),(5464,11296)]:add('carro',x,y);add('barriles',x+88,y);add('sacos',x+160,y)
region('muelles','Barrio de los Muelles',[10016,8704,1728,1280]);poi('muelles','Muelles del Río',10784,9552,'Almacenes, estibadores y barcas en movimiento.')
for id,x,y in [('b1_casa_10',10656,9472),('b1_casa_05',11072,9936),('b1_casa_03',10256,9104)]:add(id,x,y,'building')
for x,y in [(10688,9728),(10912,9920),(10400,9296)]:add('cajon',x,y);add('barriles',x+72,y);add('carro',x+192,y+40)
docks=[]
for x,y in [(10528,9232),(10816,9552),(11024,9808)]:
 add('muelle',x,y,'dock',solid=False);docks.append([x,y])
 road([[x,y+32],[x-224,y+176],[10784,9552]],80,1,False)
 reserve([x-160,y-280,320,380])
road([[10784,9552],[10080,9952],[9632,11200]],112)
# Secondary streets are a selectively connected triangulation of jittered ward nodes.
nodes=[]
for by in range(1632,13248,864):
 for bx in range(1472,13200,864):
  x=bx+rng.randint(-240,240);y=by+rng.randint(-232,232)
  if inside(x,y,224) and not watery(x,y) and not any(overlaps([x-96,y-96,192,192],r) for r in reservations):nodes.append([x,y])
tri=Delaunay(np.array(nodes));edges=set()
for t in tri.simplices:
 for a,b in [(t[0],t[1]),(t[1],t[2]),(t[2],t[0])]:edges.add(tuple(sorted((int(a),int(b)))))
for ai,bi in sorted(edges):
 a,b=nodes[ai],nodes[bi];dist=math.dist(a,b)
 if dist>1500 or rng.random()>.72:continue
 checks=[[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t] for t in [.15,.3,.5,.7,.85]]
 if any(watery(*p) or any(overlaps([p[0]-64,p[1]-64,128,128],r) for r in reservations) for p in checks):continue
 road([a,b],rng.choice([72,80,96]),2 if rng.random()<.16 else 1,False)
# Raster snapshots used for siting foundations and choosing accessible front doors.
roadpix=np.asarray(road_im);yy,xx=np.mgrid[0:H,0:W];road_grid[:]=roadpix[np.minimum(1824,yy*4+2),np.minimum(1800,xx*4+2)]
samples=[]
for rr in roads:
 for a,b in zip(rr['points'],rr['points'][1:]):
  length=math.dist(a,b)
  for i in range(max(1,int(length/64))):
   t=i/max(1,int(length/64));samples.append([a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t])
street_tree=cKDTree(samples)
# Dense but varied frontage: houses face narrow lanes and share rear courtyards.
candidates=[]
for rr in roads:
 pts=rr['points'];carry=0.0
 for p,q in zip(pts,pts[1:]):
  dist=math.dist(p,q)
  if not dist:continue
  for step in np.arange(0,dist,80):
   carry+=80
   if carry<260:continue
   carry=0;u=step/dist;x=p[0]+(q[0]-p[0])*u;y=p[1]+(q[1]-p[1])*u;nx=-(q[1]-p[1])/dist;ny=(q[0]-p[0])/dist
   for side in [-1,1]:candidates.append((x+nx*side*(rr['width']/2+168),y+ny*side*(rr['width']/2+168)))
rng.shuffle(candidates)
for _ in range(20000):candidates.append((rng.randrange(1152,13248),rng.randrange(1200,13440)))
for x,y in candidates:
 distance,j=street_tree.query([x,y]);
 if distance<100 or distance>480:continue
 id='b1_casa_'+str(rng.randrange(1,13)).zfill(2) if rng.random()<.76 else rng.choice(['casa_01','casa_02','herbolario','posada','gremio'])
 if add(id,x,y,'building',True):
  # A front-door link belongs to the same street graph, without a rectangular city grid.
  if distance<280:stroke(rd,[[x,y+24],samples[j]],40,2)
  if rng.random()<.37:add('jardinera',x+A[id]['width']*.39,y+20)
  if rng.random()<.2:add('barriles',x-A[id]['width']*.38,y+24)
  if rng.random()<.08:effects.append({'type':'smoke','x':int(x-40),'y':int(y-A[id]['height']+40)})
# Small shared courtyards use cobbles; greenery is gathered into planted pockets.
for y in range(H):
 for x in range(W):
  px=x*32+16;py=y*32+16
  if terrain[y,x]==12 and inside(px,py,96) and not watery(px,py):
   dist,_=street_tree.query([px,py])
   if dist<448:terrain[y,x]=4+(x*3+y*7)%4
# A royal garden fills the precinct behind the single integrated castle.
road([[6592,4000],[6592,5120],[6592,5552]],80,1,False)
road([[8128,4000],[8128,5120],[8128,5552]],80,1,False)
road([[6592,4000],[8128,4000]],80,1,False)
for x in [6848,7104,7360,7616,7872]:
 add('seto',x,3992);add('rosas',x,4024)
for y in [4320,4640,4960]:
 for x in [6480,8272]:add('cipres',x,y);add('jardinera',x,y+100)
# Planted pockets between housing blocks make the city green rather than empty.
for _ in range(2600):
 x=rng.randrange(1152,13248);y=rng.randrange(1280,13344)
 if add(rng.choice(['arbol','arbol','cipres','arbusto','rosas']),x,y,'garden',True):
  paint([x-64,y-64,128,128],3)
# Lamps and small street props at irregular intervals on the main routes.
for rr in roads[:16]:
 for i in range(5,len(rr['points']),13):
  x,y=rr['points'][i];p=rr['points'][i-2];q=rr['points'][min(i+2,len(rr['points'])-1)]
  dx=q[0]-p[0];dy=q[1]-p[1];ln=math.hypot(dx,dy) or 1
  add('farola',x-dy/ln*126,y+dx/ln*126,'street',True)
# Street trees, little wells and benches live in pockets between buildings.
for x,y in nodes:
 if any(overlaps([x-80,y-64,160,128],r) for r in reservations):continue
 for id,dx,dy in [('arbol',132,32),('banco',48,120),('farola',-80,-16)]:add(id,x+dx,y+dy,'pocket',True)
 if rng.random()<.23:add('pozo',x-160,y+112,'pocket',True)
# Octagon walls. Every diagonal has physical collision independent of the artwork.
for side,(a,b) in enumerate(zip(shape,shape[1:]+shape[:1])):
 length=math.dist(a,b);dx=(b[0]-a[0])/length;dy=(b[1]-a[1])/length;spacing=64 if a[1]==b[1] or a[0]==b[0] else 56
 for s in np.arange(0,length,spacing):
  x=a[0]+dx*s;y=a[1]+dy*s
  if any(math.hypot(x-gx,y-gy)<192 for _,gx,gy in gates):continue
  if watery(x,y):continue
  if a[1]==b[1]:id='muralla_repetible_h'
  elif a[0]==b[0]:id='muralla_repetible_v'
  else:id='b1_muralla_se' if dx*dy>0 else 'b1_muralla_ne'
  add(id,x,y,'wall',solid=False)
 for s in np.arange(0,length,768):
  x=a[0]+dx*s;y=a[1]+dy*s
  if not watery(x,y) and all(math.hypot(x-gx,y-gy)>256 for _,gx,gy in gates):add('torre_muralla',x,y,'wall',solid=False)
for x,y in shape:add('torre_muralla',x,y,'wall',solid=False)
for id,x,y in gates:
 add('porton_abierto',x,y+48,'gate',solid=False);poi('puerta_'+id,'Puerta '+id.title(),x+(160 if id=='oeste' else -160 if id=='este' else 0),y+(160 if id=='norte' else -160 if id=='sur' else 0),'Acceso '+id+' de la muralla octagonal.')
# Nature outside the walls gives scale without occupying inhabited street blocks.
for _ in range(1700):
 x=rng.randint(64,PW-64);y=rng.randint(240,PH-32)
 if not inside(x,y,-144) and not watery(x,y) and all(math.dist([x,y],[gx,gy])>260 for _,gx,gy in gates):
  if not roadpix[min(1824,int(y/8)),min(1800,int(x/8))]:add(rng.choice(['arbol','cipres','arbusto']),x,y,'outside')
# Terrain corners form marching-square diagonal tiles: TL=1 TR=2 BR=4 BL=8.
roadpix=np.asarray(road_im);cx=np.minimum(1800,np.arange(W+1)*4);cy=np.minimum(1824,np.arange(H+1)*4)
wc=water_pixels[np.ix_(cy,cx)];rc=roadpix[np.ix_(cy,cx)]
kind=np.where(wc,3,rc);overlay=np.zeros((H,W),dtype=np.uint16)
for typ in [1,2,3]:
 m=(kind==typ).astype(np.uint16);mask=m[:-1,:-1]+2*m[:-1,1:]+4*m[1:,1:]+8*m[1:,:-1]
 overlay=np.where(mask>0,1+typ*64+mask,overlay)
water_grid=water_pixels[np.minimum(1824,yy*4+2),np.minimum(1800,xx*4+2)]
road_grid=roadpix[np.minimum(1824,yy*4+2),np.minimum(1800,xx*4+2)]
collision=water_grid.copy().astype(np.uint8)
for o in objects:
 a=A[o['id']]
 if not o.get('solid',a['solid']):continue
 for poly in a['collision_polygons']:
  xs=[o['x']-a['width']/2+p[0] for p in poly];ys=[o['y']-a['height']+p[1] for p in poly]
  for x,y in rect_cells([min(xs),min(ys),max(xs)-min(xs),max(ys)-min(ys)]):collision[y,x]=1
wallim=Image.new('L',surface.size);draw=ImageDraw.Draw(wallim);stroke(draw,shape+[shape[0]],56,1)
for id,x,y in gates:draw.rectangle((int((x-96)/8),int((y-96)/8),int((x+96)/8),int((y+96)/8)),fill=0)
walls=np.asarray(wallim)[np.minimum(1824,yy*4+2),np.minimum(1800,xx*4+2)];collision|=walls
for b in bridges:
 im=Image.new('L',surface.size);stroke(ImageDraw.Draw(im),[b['a'],b['b']],b['width'],1)
 mask=np.asarray(im)[np.minimum(1824,yy*4+2),np.minimum(1800,xx*4+2)]>0;collision[mask]=0;road_grid[mask]=1
for x,y in docks:
 # T-shaped jetty: a 64px stem and a 224px crosspiece, aligned to the sprite.
 for rect in [[x-32,y-208,64,208],[x-112,y-208,224,64]]:
  for xx,yy in rect_cells(rect):collision[yy,xx]=0;road_grid[yy,xx]=1
# Install the same four gate openings in both visual and physical layers.
def free(x,y):return 16<=x<PW-16 and 64<=y<PH-16 and not collision[int(y//32),int(x//32)]
def nearest_free(x,y,only_road=False):
 x=int(x//32);y=int(y//32)
 for r in range(30):
  for dy in range(-r,r+1):
   for dx in range(-r,r+1):
    if r and abs(dx)!=r and abs(dy)!=r:continue
    xx=x+dx;yy=y+dy
    if 1<=xx<W-1 and 2<=yy<H-1 and not collision[yy,xx] and (not only_road or road_grid[yy,xx]):return [xx*32+16,yy*32+16]
 raise RuntimeError('No accessible spawn')
for p in pois:p['x'],p['y']=nearest_free(p['x'],p['y'])
spawn=next(p for p in pois if p['id']=='mercado');start=(spawn['y']//32)*W+spawn['x']//32;flat=collision.ravel();seen=np.zeros(N,np.uint8);seen[start]=1;queue=collections.deque([start])
while queue:
 i=queue.popleft();x=i%W;y=i//W
 for dx,dy in [(0,1),(1,0),(-1,0),(0,-1)]:
  nx=x+dx;ny=y+dy
  if 0<=nx<W and 0<=ny<H:
   ni=ny*W+nx
   if not flat[ni] and not seen[ni]:seen[ni]=1;queue.append(ni)
bad=[p['id'] for p in pois if not seen[(p['y']//32)*W+p['x']//32]]
if bad:raise RuntimeError('Disconnected places: '+str(bad))
print('Geometry and placement ready:',len(objects),'objects; connected POIs:',len(pois),flush=True)
# Deterministic walking routes. A* never cuts a blocked diagonal corner.
def route(a,b):
 ax,ay=a[0]//32,a[1]//32;bx,by=b[0]//32,b[1]//32;start=ay*W+ax;goal=by*W+bx;todo=[(0,start)];cost={start:0};prev={}
 while todo:
  _,i=heapq.heappop(todo)
  if i==goal:
   result=[i]
   while i in prev:i=prev[i];result.append(i)
   return [[(j%W)*32+16,(j//W)*32+16] for j in reversed(result)]
  if len(cost)>10000:return None
  x=i%W;y=i//W
  for dx,dy in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1),(1,-1),(-1,-1)]:
   nx=x+dx;ny=y+dy
   if not(1<=nx<W-1 and 2<=ny<H-1):continue
   j=ny*W+nx
   if flat[j] or (dx and dy and (flat[y*W+nx] or flat[ny*W+x])):continue
   v=cost[i]+(14 if dx and dy else 10)+(0 if road_grid[ny,nx] else 4)
   if v<cost.get(j,10**12):cost[j]=v;prev[j]=i;heapq.heappush(todo,(v+10*max(abs(nx-bx),abs(ny-by)),j))
 return None
valid=np.argwhere((road_grid>0)&(collision==0));valid=[(int(x)*32+16,int(y)*32+16) for y,x in valid if inside(int(x)*32,int(y)*32,160) and seen[int(y)*W+int(x)]]
residents=[]
roles=C['npcs']['rows'];lines=[['Las frutas llegaron esta mañana por el río.','Los puestos rodean la fuente; el paso central queda libre.'],['Las cuatro puertas tienen guardia.','El camino del norte lleva al recinto real.'],['Las barcas descargan en los muelles junto al puente.','Las cajas pesadas van junto al almacén.'],['En estos patios siempre hay alguien a quien saludar.','Las callecitas se encuentran otra vez en la plaza.'],['La biblioteca está al sudeste de la ciudad.','Un buen libro también necesita un lugar tranquilo.'],['Las rosas crecen entre las raíces de Briar.','Los jardines pequeños necesitan tanto cuidado como los del palacio.']]
starts=[]
for p in pois:
 if not p['id'].startswith('puente_') and not p['id'].startswith('puerta_'):
  for j in range(22):starts.append(nearest_free(p['x']+rng.randint(-420,420),p['y']+rng.randint(-220,400),True))
for _ in range(660):starts.append(list(rng.choice(valid)))
for i,a in enumerate(starts):
 b=nearest_free(a[0]+rng.randint(-512,512),a[1]+rng.randint(-416,416),True);path=route(a,b)
 if not path or len(path)<3:continue
 role=1 if any(math.dist(a,[x,y])<512 for _,x,y in gates) else rng.randrange(6)
 residents.append({'id':i,'role':role,'name':roles[role],'route':path,'speed':rng.randint(30,56),'start_index':rng.randrange(len(path)),'pause':rng.choice([1.5,2,3,4]),'line':lines[role][i%2]})
boats=[]
for i,(a,b) in enumerate([(15,72),(92,150),(174,220),(236,282),(303,346),(360,408),(424,465)]):
 a=min(a,len(river)-12);b=min(b,len(river)-5)
 if b-a<8:continue
 boats.append({'id':i,'asset':'b1_barca_carga' if i%2==0 else 'b1_barca_pesca','route':river[a:b:2],'speed':24+i*2,'start_index':(i*5)%max(1,len(river[a:b:2]))})
# Low arches carry the octagonal wall across the river without creating land gates.
for expected in [[2704,2160],[12128,11968]]:
 x,y=min(river,key=lambda p:math.dist(p,expected));add('puerta_rio',x,y+96,'watergate',solid=False)
for o in objects:
 if o['id'] in ['farola','antorcha']:effects.append({'type':'lamp','x':o['x'],'y':o['y']-88})
 if o['id']=='fuente':effects.append({'type':'fountain','x':o['x'],'y':o['y']-53})
 if o['id']=='estandarte':effects.append({'type':'flag','x':o['x'],'y':o['y']-104})
meta={'version':'3.0.0','title':'Briar B.1 — Barrios entrelazados','pixel_width':PW,'pixel_height':PH,'screen_width':960,'screen_height':540,'screens':[15,27],'tile_size':32,'width':W,'height':H,'seed':1012026,'river':'noroeste a sudeste','river_path':river,'river_width':352,'wall_polygon':shape,'gates':[{'id':n,'x':x,'y':y} for n,x,y in gates],'objects':objects,'bridges':bridges,'docks':docks,'pois':pois,'regions':regions,'spawn':[spawn['x'],spawn['y']],'roads':roads,'residents':residents,'boats':boats,'effects':effects,'atlas_mode':'marching_squares_16','diagonal_atlases':C['diagonal_atlases'],'layers':{'base':'mapa/base.bin','overlay':'mapa/overlay.bin','collision':'mapa/colision.bin'}}
(R/'mapa/ciudad.json').write_text(json.dumps(meta,ensure_ascii=False,separators=(',',':')))
(R/'mapa/base.bin').write_bytes(terrain.astype('<u2').tobytes());(R/'mapa/overlay.bin').write_bytes(overlay.astype('<u2').tobytes());(R/'mapa/colision.bin').write_bytes(collision.tobytes());(R/'mapa/agua.bin').write_bytes(water_grid.tobytes())
counts=collections.Counter(o['id'] for o in objects)
report={'size':[PW,PH],'screens':[15,27],'grid':[W,H],'wall_sides':8,'land_gates':4,'placed_objects':len(objects),'buildings':sum(1 for o in objects if o['kind'] in ['building','landmark']),'bridges':len(bridges),'bridge_materials':dict(collections.Counter(b['material'] for b in bridges)),'residents':len(residents),'boats':len(boats),'roads':len(roads),'all_pois_reachable':not bad,'reachable_cells':int(seen.sum()),'counts':dict(counts)}
(R/'docs/layout_validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps({k:v for k,v in report.items() if k!='counts'},indent=2),flush=True)
