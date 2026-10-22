/* B.1.5: export complete drawn poses, preserving their aspect ratio.
   No articulated cutout, limb transform, or per-frame bounding-box stretching. */
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp':'sharp');
const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p),DIRS=['sur','oeste','este','norte'],N=8,COLS=17;
const median=a=>[...a].sort((a,b)=>a-b)[Math.floor(a.length/2)];
async function readSheet(name){return sharp(P('sources/elias/fullbody_v3',name+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});}
function cell(source,n,rows){
 const {data,info}=source,x0=Math.round(n%4*info.width/4),x1=Math.round((n%4+1)*info.width/4),y0=Math.round(Math.floor(n/4)*info.height/rows),y1=Math.round((Math.floor(n/4)+1)*info.height/rows);
 let l=x1,r=-1,t=y1,b=-1;
 for(let y=y0;y<y1;y++)for(let x=x0;x<x1;x++)if(data[(y*info.width+x)*4+3]>=200){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
 if(r<l)throw Error('Empty source cell '+n);
 let xs=[];for(let y=t;y<t+(b-t+1)*.31;y++)for(let x=l;x<=r;x++){const i=(y*info.width+x)*4,rr=data[i],g=data[i+1],bb=data[i+2];if(data[i+3]>=200&&rr>95&&g>65&&rr>bb*1.4&&rr>g*1.03)xs.push(x);}
 if(!xs.length)throw Error('No hair anchor '+n);xs.sort((a,b)=>a-b);
 return {source,x0,x1,y0,y1,l,r,t,b,hairX:xs.reduce((s,v)=>s+v,0)/xs.length,hairWidth:xs[Math.floor(xs.length*.99)]-xs[Math.floor(xs.length*.01)]+1};
}
function sample(p,scale,headX,top){
 const out=Buffer.alloc(64*64*4),{data,info}=p.source;
 // Area sampling produces one opaque native pixel per selected cell. The entire
 // figure uses the very same isotropic transform; transparency stays binary.
 for(let y=0;y<64;y++)for(let x=0;x<64;x++){
  const a=p.hairX+(x-headX)/scale,b=p.hairX+(x+1-headX)/scale,c=p.t+(y-top)/scale,d=p.t+(y+1-top)/scale;
  if(b<p.l||a>p.r+1||d<p.t||c>p.b+1)continue;
  let total=0,rr=0,gg=0,bb=0;
  for(let sy=Math.max(p.y0,Math.floor(c));sy<Math.min(p.y1,Math.ceil(d));sy++)for(let sx=Math.max(p.x0,Math.floor(a));sx<Math.min(p.x1,Math.ceil(b));sx++){
   const i=(sy*info.width+sx)*4;if(data[i+3]<180)continue;
   const w=Math.max(0,Math.min(sx+1,b)-Math.max(sx,a))*Math.max(0,Math.min(sy+1,d)-Math.max(sy,c));
   total+=w;rr+=data[i]*w;gg+=data[i+1]*w;bb+=data[i+2]*w;
  }
  if(total/((b-a)*(d-c))<.42)continue;const o=(y*64+x)*4;out[o]=Math.round(rr/total);out[o+1]=Math.round(gg/total);out[o+2]=Math.round(bb/total);out[o+3]=255;
 }
 return out;
}
(async()=>{
 const atlas=Buffer.alloc(COLS*64*256*4),registrations=[],idle=await readSheet('idle');
 for(let row=0;row<4;row++)for(const mode of ['walk','run','idle']){
  const source=mode==='idle'?idle:await readSheet(DIRS[row]+'_'+mode),poses=mode==='idle'?[cell(source,row,1)]:Array.from({length:N},(_,n)=>cell(source,n,2));
  const heights=poses.map(p=>p.b-p.t+1),hairWidth=median(poses.map(p=>p.hairWidth)),headTops=mode==='walk'?[3,4,3,2,3,4,3,2]:mode==='run'?[4,5,3,2,4,5,3,2]:[3];
  const scale=Math.min(20/hairWidth,(61-Math.max(...headTops))/Math.max(...heights));
  const contactTop=median(heights.map(h=>61-h*scale));
  for(let n=0;n<headTops.length;n++)headTops[n]=mode==='run'&&n%4>=2?Math.min(contactTop-(n%4===3?2:1),61-heights[n]*scale):61-heights[n]*scale;
  const hx=mode==='run'?(row===1?29:row===2?35:32):32;
  registrations.push({direction:DIRS[row],mode,uniform_scale:scale,source_head_width:hairWidth,native_head_width:hairWidth*scale,head_x:hx,head_tops:headTops,source_height_range:[Math.min(...heights),Math.max(...heights)]});
  for(let n=0;n<poses.length;n++){
   const col=mode==='walk'?n:mode==='run'?N+n:16,raw=sample(poses[n],scale,hx,headTops[n]);
   for(let y=0;y<64;y++)raw.copy(atlas,((row*64+y)*COLS*64+col*64)*4,y*64*4,(y+1)*64*4);
  }
 }
 const file=P('assets/elias_64.png');await sharp(atlas,{raw:{width:COLS*64,height:256,channels:4}}).png({palette:true,colours:64,dither:0}).toFile(file);
 const frames=P('assets/elias/frames');fs.rmSync(frames,{recursive:true,force:true});fs.mkdirSync(frames,{recursive:true});fs.rmSync(P('assets/elias/parts'),{recursive:true,force:true});
 const report={revision:'B.1.5',method:'complete_drawn_poses_uniform_isotropic_export',dimensions:[COLS*64,256],cell:[64,64],minimum_height:64,maximum_height:0,binary_alpha:true,clipped_frames:[],directions:[],registrations};
 for(let row=0;row<4;row++){
  const hashes={walk:new Set(),run:new Set()};
  for(let col=0;col<COLS;col++){
   const mode=col<8?'walk':col<16?'run':'idle',b=await sharp(file).extract({left:col*64,top:row*64,width:64,height:64}).png().toBuffer();
   fs.writeFileSync(path.join(frames,DIRS[row]+'_'+mode+'_'+String(col%8).padStart(2,'0')+'.png'),b);
   const raw=await sharp(b).ensureAlpha().raw().toBuffer();let top=64,bottom=-1,left=64,right=-1;
   for(let y=0;y<64;y++)for(let x=0;x<64;x++){const a=raw[(y*64+x)*4+3];if(a!==0&&a!==255)report.binary_alpha=false;if(a){top=Math.min(top,y);bottom=Math.max(bottom,y);left=Math.min(left,x);right=Math.max(right,x);}}
   if(top===0||bottom===63||left===0||right===63)report.clipped_frames.push([row,col]);
   report.minimum_height=Math.min(report.minimum_height,bottom-top+1);report.maximum_height=Math.max(report.maximum_height,bottom-top+1);
   if(mode!=='idle')hashes[mode].add(crypto.createHash('sha256').update(raw).digest('hex'));
  }
  report.directions.push({direction:DIRS[row],unique_walk:hashes.walk.size,unique_run:hashes.run.size,distinct_gaits:[...hashes.walk].every(h=>!hashes.run.has(h))});
 }
 report.passed=report.binary_alpha&&!report.clipped_frames.length&&report.maximum_height<=64&&report.directions.every(d=>d.unique_walk===N&&d.unique_run===N&&d.distinct_gaits);
 const cat=JSON.parse(fs.readFileSync(P('catalogo.json')));cat.version='3.4.0';cat.player={name:'Elías',file:'assets/elias_64.png',cell:[64,64],columns:COLS,rows:DIRS,frames_per_direction:N,idle_frame:16,fps:12,run_fps:16,walk_speed:160,run_speed:320,max_character_height:report.maximum_height,anchor:[32,64],animations:{walk:{frames:Array.from({length:N},(_,i)=>i),fps:12,loop:true},run:{frames:Array.from({length:N},(_,i)=>i+N),fps:16,loop:true},idle:{frames:[16],fps:1,loop:false}}};
 fs.writeFileSync(P('catalogo.json'),JSON.stringify(cat,null,2));fs.writeFileSync(P('docs/elias_asset_validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));if(!report.passed)process.exitCode=1;
})();
