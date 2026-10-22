"""Declare native module sizes before the image processing pass."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
c=json.loads((R/'catalogo_v2.json').read_text())
names=['Vivienda diagonal','Panadería','Posada del Puente','Herbolario diagonal','Taller artesanal','Casas unidas','Vivienda con patio','Librería de barrio','Casa del mercader','Almacén fluvial','Tienda de telas','Forja de barrio']
for n,name in enumerate(names):
 w=[320,352,416,320,384,416][n%6];h=[352,352,416,384,384,384][n%6]
 c['assets'].append({'id':'b1_casa_'+str(n+1).zfill(2),'label':name,'group':'b1_arquitectura','file':'assets/b1_casa_'+str(n+1).zfill(2)+'.png','width':w,'height':h,'anchor':[w/2,h],'solid':True,'ground':False,'collision_polygons':[[[w*.12,h-80],[w*.88,h-80],[w*.88,h-6],[w*.12,h-6]]]})
for id,label,w,h,ground in [('b1_puente_piedra','Puente diagonal de piedra',768,512,True),('b1_puente_madera','Puente diagonal de madera',768,512,True),('b1_barca_carga','Barca de carga',192,160,True),('b1_barca_pesca','Barca de pesca',128,128,True),('b1_muralla_ne','Muralla diagonal ascendente',96,160,False),('b1_muralla_se','Muralla diagonal descendente',96,160,False)]:
 c['assets'].append({'id':id,'label':label,'group':'b1_rio_defensas','file':'assets/'+id+'.png','width':w,'height':h,'anchor':[w/2,h],'solid':False,'ground':ground,'collision_polygons':[]})
c['version']='3.0.0';c['player']['fps']=8;c['npcs']={'file':'assets/habitantes_64.png','cell':[64,64],'columns':8,'rows':['Comerciante','Guardia','Estibador','Vecina','Estudiante','Jardinera'],'direction_columns':{'sur':0,'oeste':2,'este':4,'norte':6},'frames_per_direction':2,'fps':6}
c['world']={'screens':[15,27],'pixels':[14400,14580]}
c['diagonal_atlases']=['atlases/b1_piedra_16.png','atlases/b1_tierra_16.png','atlases/b1_agua_16.png']
(R/'catalogo.json').write_text(json.dumps(c,ensure_ascii=False,indent=2))
print(len(c['assets']),'modules declared')
