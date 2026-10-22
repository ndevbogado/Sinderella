/* Technical sprite export: common scale per direction, head registration and a
   shared palette. All gait poses come from the supplied generated sources. */
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp':'sharp');
const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p),dirs=['sur','oeste','este','norte'];
(async()=>{const cells=[],orders={sur:[0,1,6,2,3,2,8,7,8],oeste:[0,2,1,3,4,6,5,7,8],este:[0,2,1,3,4,6,5,7,8],norte:[0,1,2,3,6,8,4,7,8]},report={revision:'B.1.3',directions:[],cell:[64,64],walk_frames:8,idle_frames:1};
for(let row=0;row<4;row++){
 const final=await sharp(P('sources/elias',dirs[row]+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});const initial=row===0?await sharp(P('sources/elias/sur_initial.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true}):final;let parts=[];
 for(let outIndex=0;outIndex<9;outIndex++){const n=orders[dirs[row]][outIndex],source=row===0&&outIndex===5?initial:final,{data,info}=source;const x0=Math.round(n%3*info.width/3),y0=Math.round(Math.floor(n/3)*info.height/3),x1=Math.round((n%3+1)*info.width/3),y1=Math.round((Math.floor(n/3)+1)*info.height/3);let l=x1,t=y1,r=-1,b=-1;
  for(let y=y0;y<y1;y++)for(let x=x0;x<x1;x++)if(data[(y*info.width+x)*4+3]>=170){l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);}
  if(r<l)throw Error('Empty source cell '+dirs[row]+n);
  let hx=0,weight=0;for(let y=t;y<t+(b-t)*.24;y++)for(let x=l;x<=r;x++){const i=(y*info.width+x)*4,rr=data[i],g=data[i+1],bb=data[i+2];if(data[i+3]>=170&&rr>100&&g>60&&rr>bb*1.35){hx+=x;weight++;}}
  parts.push({l,t,r,b,head:weight?hx/weight:(l+r)/2,source});
 }
 const scale=60/Math.max(...parts.map(p=>p.b-p.t+1));
 const metrics=[];
 for(let n=0;n<9;n++){const p=parts[n],{data,info}=p.source,out=Buffer.alloc(64*64*4);for(let y=0;y<64;y++)for(let x=0;x<64;x++){const sx=Math.round(p.head+(x-32)/scale),sy=Math.round(p.b+(y-61)/scale);if(sx<p.l||sx>p.r||sy<p.t||sy>p.b)continue;const src=(sy*info.width+sx)*4,dst=(y*64+x)*4;if(data[src+3]>=170){data.copy(out,dst,src,src+3);out[dst+3]=255;}}
  cells.push({input:await sharp(out,{raw:{width:64,height:64,channels:4}}).png().toBuffer(),left:n*64,top:row*64});metrics.push({source_bbox:[p.l,p.t,p.r-p.l+1,p.b-p.t+1],head_center:p.head,scale});
 }
 report.directions.push({id:dirs[row],source_order:orders[dirs[row]],registration:metrics});
}
const atlas=P('assets/elias_64.png');await sharp({create:{width:576,height:256,channels:4,background:'#00000000'}}).composite(cells).png({palette:true,colours:64,dither:0}).toFile(atlas);
report.maximum_height=0;report.minimum_height=64;report.unique_walk_frames=[];
for(let row=0;row<4;row++){let hashes=new Set();for(let col=0;col<9;col++){const file='assets/elias/frames/'+dirs[row]+'_'+(col===8?'reposo':String(col).padStart(2,'0'))+'.png';const b=await sharp(atlas).extract({left:col*64,top:row*64,width:64,height:64}).png().toBuffer();fs.writeFileSync(P(file),b);const raw=await sharp(b).ensureAlpha().raw().toBuffer();let y0=64,y1=-1;for(let y=0;y<64;y++)for(let x=0;x<64;x++)if(raw[(y*64+x)*4+3]){y0=Math.min(y0,y);y1=y;}
 report.maximum_height=Math.max(report.maximum_height,y1-y0+1);report.minimum_height=Math.min(report.minimum_height,y1-y0+1);if(col<8)hashes.add(crypto.createHash('sha256').update(raw).digest('hex'));
}report.unique_walk_frames.push({direction:dirs[row],count:hashes.size});}
let C=JSON.parse(fs.readFileSync(P('catalogo.json')));C.version='3.2.0';C.player={name:'Elías',file:'assets/elias_64.png',cell:[64,64],columns:9,rows:dirs,frames_per_direction:8,idle_frame:8,fps:16,run_fps:24,max_character_height:60,anchor:[32,64],animations:{walk:{frames:[0,1,2,3,4,5,6,7],fps:16,loop:true},run:{frames:[0,1,2,3,4,5,6,7],fps:24,loop:true},idle:{frames:[8],fps:1,loop:false}}};fs.writeFileSync(P('catalogo.json'),JSON.stringify(C,null,2));
report.passed=report.maximum_height<=64&&report.unique_walk_frames.every(d=>d.count===8);fs.writeFileSync(P('docs/elias_asset_validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify({dimensions:[576,256],height:[report.minimum_height,report.maximum_height],unique_frames:report.unique_walk_frames,passed:report.passed}));
})();
