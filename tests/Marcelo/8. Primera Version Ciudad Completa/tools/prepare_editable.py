"""One-time conversion input. Does not run the layout generator or overwrite scenes."""
from pathlib import Path
import ast,json,math
import numpy as np
from PIL import Image,ImageDraw
from scipy.spatial import cKDTree
R=Path(__file__).resolve().parents[1]
M=json.loads((R/'mapa/ciudad.json').read_text());C=json.loads((R/'catalogo.json').read_text())
assets={a['id']:a for a in C['assets']}
PW,PH,S=M['pixel_width'],M['pixel_height'],8
W,H=M['collision_width'],M['collision_height']
out=R/'godot/migracion';out.mkdir(parents=True,exist_ok=True)
def rects(mask):
 active,result={},[]
 for y,row in enumerate(mask):
  edges=np.diff(np.r_[False,row,False].astype(np.int8));runs=set(zip(np.flatnonzero(edges==1),np.flatnonzero(edges==-1)))
  for key in list(active):
   if key not in runs:
    start=active.pop(key);result.append([int(key[0]*8),start*8,int((key[1]-key[0])*8),(y-start)*8])
  for key in runs:active.setdefault(key,y)
 for key,start in active.items():result.append([int(key[0]*8),start*8,int((key[1]-key[0])*8),(len(mask)-start)*8])
 return result
tree=ast.parse((R/'tools/integrate_approved.py').read_text())
for n in tree.body:
 if isinstance(n,ast.FunctionDef) and n.name=='stroke_distance':exec(compile(ast.Module(body=[n],type_ignores=[]),'<distance>','exec'))
water_d=np.full((H,W),-128,np.float32);road_mat=np.zeros((H,W),np.uint8)
stroke_distance(water_d,M['river_path'],M['river_width']);water=water_d>-3
(out/'agua8.bin').write_bytes(water.astype(np.uint8).tobytes())
im=Image.new('L',(W,H));d=ImageDraw.Draw(im);points=[(x/8,y/8) for x,y in M['wall_polygon']]
d.line(points+[points[0]],fill=1,width=9,joint='curve');wall=np.asarray(im).copy().astype(bool)
for g in M['gates']:
 x,y=g['x']//8,g['y']//8;wall[y-13:y+14,x-13:x+14]=False
wi=[i for i,o in enumerate(M['objects']) if o['kind'] in ['wall','gate','watergate']]
lookup=cKDTree([[M['objects'][i]['x'],M['objects'][i]['y']] for i in wi]);yy,xx=np.nonzero(wall);_,nearest=lookup.query(np.c_[xx*8+4,yy*8+4]);wr={}
for j,i in enumerate(wi):
 sel=nearest==j
 if not sel.any():continue
 xs,ys=xx[sel],yy[sel];x0,y0=xs.min(),ys.min();mask=np.zeros((ys.max()-y0+1,xs.max()-x0+1),bool);mask[ys-y0,xs-x0]=True;o=M['objects'][i]
 wr[i]=[[x+x0*8-o['x'],y+y0*8-o['y'],w,h] for x,y,w,h in rects(mask)]
for a in C['assets']:
 w,h=a['width'],a['height'];im=Image.new('L',(math.ceil(w/8)+2,math.ceil(h/8)+2));d=ImageDraw.Draw(im)
 for p in a.get('collision_polygons',[]):d.polygon([(x/8,y/8) for x,y in p],fill=1)
 ax,ay=a['anchor'];a['editable_collision_rects']=[[x-ax,y-ay,w,h] for x,y,w,h in rects(np.asarray(im)>0)]
for i,o in enumerate(M['objects']):
 o['migration_id']=i;a=assets[o['id']];o['editable_collision_rects']=wr.get(i,[])
 if i not in wi and a.get('solid') and o.get('solid',True):
  ax,ay=a['anchor'];dx=math.floor((o['x']-ax)/8)*8-(o['x']-ax);dy=math.floor((o['y']-ay)/8)*8-(o['y']-ay)
  o['editable_collision_rects']=[[x+dx,y+dy,w,h] for x,y,w,h in a['editable_collision_rects']]
 if o['kind']=='dock':
  o['editable_passage_rects']=[[-24,-208,56,224],[-112,-208,224,64]];a['editable_passage_rects']=o['editable_passage_rects']
 if o['kind']=='bridge':
  sx,sy=a['step'];x0,y0=-32,min(0,sy)-32;im=Image.new('L',((sx+64)//8,(abs(sy)+64)//8))
  ImageDraw.Draw(im).line([(-x0//8,-y0//8),((sx-x0)//8,(sy-y0)//8)],fill=1,width=7)
  o['editable_passage_rects']=[[x+x0,y+y0,w,h] for x,y,w,h in rects(np.asarray(im)>0)];a['editable_passage_rects']=o['editable_passage_rects']
(out/'conversion.json').write_text(json.dumps({'map':M,'catalog':C},ensure_ascii=False,default=lambda x:x.item()))
print(json.dumps({'objects':len(M['objects']),'water_cells':int(water.sum())}))
