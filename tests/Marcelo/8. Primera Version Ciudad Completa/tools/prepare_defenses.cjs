/* Export generated Briar art to native sprites; only alpha, scale and geometric
   registration are changed. Source images and existing art style are preserved. */
const fs=require('fs'),path=require('path');
const sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp':'sharp');
const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p);
async function raw(name){let r=await sharp(P('sources',name+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});for(let i=0;i<r.data.length;i+=4){r.data[i+3]=r.data[i+3]>=150?255:0;if(!r.data[i+3])r.data[i]=r.data[i+1]=r.data[i+2]=0;}return r;}
async function diagonal(name,id,w,h,slope,b,sourceSlope,sourceB,x0,x1,vScale){const {data,info}=await raw(name),out=Buffer.alloc(w*h*4);for(let x=0;x<w;x++){const sx=Math.round(x0+x/(w-1)*(x1-x0));for(let y=0;y<h;y++){const sy=Math.round(sourceSlope*sx+sourceB+(y-(slope*x+b))/vScale);if(sx>=0&&sx<info.width&&sy>=0&&sy<info.height){const p=(sy*info.width+sx)*4;data.copy(out,(y*w+x)*4,p,p+4);}}}await sharp(out,{raw:{width:w,height:h,channels:4}}).png({palette:true,colours:192,dither:0}).toFile(P('assets',id+'.png'));}
async function gate(name,id,sourceAnchor){const {data,info}=await raw(name),scale=.40,w=256,h=640;let out=Buffer.alloc(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const sx=Math.round(sourceAnchor[0]+(x-128)/scale),sy=Math.round(sourceAnchor[1]+(y-360)/scale);if(sx>=0&&sx<info.width&&sy>=0&&sy<info.height){const p=(sy*info.width+sx)*4;data.copy(out,(y*w+x)*4,p,p+4);}}await sharp(out,{raw:{width:w,height:h,channels:4}}).png({palette:true,colours:192,dither:0}).toFile(P('assets',id+'.png'));}
(async()=>{
await diagonal('b12_muralla_ne','b1_muralla_ne',256,416,-1,400,-1.046,1461,80,976,.30);
await diagonal('b12_muralla_se','b1_muralla_se',256,416,1,144,.974,420,66,979,.30);
await diagonal('b12_arco_rio_ne','b12_arco_rio_ne',640,800,-1,784,-.867,1467,40,995,.32);
await gate('b12_puerta_este','b12_puerta_este',[526,905]);
await gate('b12_puerta_oeste','b12_puerta_oeste',[553,858]);
let C=JSON.parse(fs.readFileSync(P('catalogo.json')));
const defs=[
{id:'b1_muralla_ne',label:'Muralla diagonal ascendente · estilo original',width:256,height:416,baseline:{slope:-1,intercept:400},world_anchor:[128,272],connection_points:[[0,400],[256,144]],depth_slices:32,wall_height:144},
{id:'b1_muralla_se',label:'Muralla diagonal descendente · estilo original',width:256,height:416,baseline:{slope:1,intercept:144},world_anchor:[128,272],connection_points:[[0,144],[256,400]],depth_slices:32,wall_height:144},
{id:'b12_arco_rio_ne',label:'Arco fluvial diagonal · Briar',width:640,height:800,baseline:{slope:-1,intercept:784},world_anchor:[344,440],connection_points:[[0,784],[640,144]],depth_slices:32,wall_height:144},
{id:'b12_puerta_este',label:'Puerta este · paso lateral',width:256,height:640,world_anchor:[128,360],connection_points:[[128,100],[128,590]],wall_axis:'north-south',passage_axis:'east-west'},
{id:'b12_puerta_oeste',label:'Puerta oeste · paso lateral',width:256,height:640,world_anchor:[128,360],connection_points:[[128,100],[128,582]],wall_axis:'north-south',passage_axis:'east-west'}];
for(const d of defs){const a={...d,group:'defensas_b12',file:'assets/'+d.id+'.png',anchor:[d.width/2,d.height],solid:false,ground:false,collision_polygons:[]};const i=C.assets.findIndex(a=>a.id===d.id);if(i<0)C.assets.push(a);else C.assets[i]=a;}
C.version='3.1.0';fs.writeFileSync(P('catalogo.json'),JSON.stringify(C,null,2));console.log('B.1.2: five matching defense sprites exported;',C.assets.length,'modules total.');
})();
