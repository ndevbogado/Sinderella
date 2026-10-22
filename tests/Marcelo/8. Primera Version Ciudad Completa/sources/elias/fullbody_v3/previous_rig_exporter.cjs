/* Elías B.1.4: generated cutout art + deterministic joint animation.
   All source parts stay identical between poses. Native nearest-neighbour sampling. */
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/sharp':'sharp');
const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p);
const DIRS=['sur','oeste','este','norte'],N=12,COLS=25,TAU=2*Math.PI;
const mod=x=>(x%1+1)%1,lerp=(a,b,t)=>a+(b-a)*t;
function solveKnee(hip,ankle,a=12,b=13){
 const dx=ankle[0]-hip[0],dy=ankle[1]-hip[1],d=Math.max(.01,Math.hypot(dx,dy));
 const reach=Math.min(d,a+b-.05),along=(a*a-b*b+reach*reach)/(2*reach),height=Math.sqrt(Math.max(0,a*a-along*along));
 return [hip[0]+dx/d*along+dy/d*height,hip[1]+dy/d*along-dx/d*height];
}
function footPath(t,run,idle){
 if(idle)return {z:0,lift:0,contact:true};
 const stance=run?.32:.5,reach=run?15:12;
 if(t<stance)return {z:lerp(reach,-reach,t/stance),lift:0,contact:true};
 const u=(t-stance)/(1-stance),smooth=u*u*(3-2*u);
 return {z:lerp(-reach,reach,smooth),lift:Math.sin(Math.PI*u)*(run?14:7),contact:false};
}
// Inverse textured sampling: no antialiasing and no transformed alpha fringes.
function blit(dst,part,ax,ay,a,b,c,d,tx,ty,shade=1,flip=false){
 const det=a*d-b*c;if(Math.abs(det)<.01)return;
 for(let y=0;y<64;y++)for(let x=0;x<64;x++){
  const px=x+.5-tx,py=y+.5-ty;
  let u=Math.floor((d*px-c*py)/det+ax),v=Math.floor((-b*px+a*py)/det+ay);
  if(flip)u=part.w-1-u;
  if(u<0||v<0||u>=part.w||v>=part.h)continue;
  const s=(v*part.w+u)*4;if(!part.data[s+3])continue;const o=(y*64+x)*4;
  dst[o]=Math.round(part.data[s]*shade);dst[o+1]=Math.round(part.data[s+1]*shade);dst[o+2]=Math.round(part.data[s+2]*shade);dst[o+3]=255;
 }
}
function upright(dst,p,x,y,angle=0,shade=1,flip=false,anchorY=p.h,anchorX=p.w/2){const c=Math.cos(angle),s=Math.sin(angle);blit(dst,p,anchorX,anchorY,c,s,-s,c,Math.round(x),Math.round(y),shade,flip);}
function limb(dst,p,start,end,sourceLength,shade=1,flip=false,anchorX=p.w/2){
 const dx=end[0]-start[0],dy=end[1]-start[1],len=Math.max(1,Math.hypot(dx,dy));
 blit(dst,p,anchorX,.5,dy/len,-dx/len,dx/sourceLength,dy/sourceLength,start[0],start[1],shade,flip);
}
function render(parts,dir,mode,index){
 const run=mode==='run',idle=mode==='idle',t=idle?0:index/N,side=dir===1||dir===2,sign=dir===1?-1:1;
 const bob=idle?0:run?Math.round(1.5+2.2*Math.cos(TAU*2*t-.6)):Math.round(.8*Math.cos(TAU*2*t));
 const hipY=(idle?35:37)+bob,lean=idle?0:run?4:1;
 const project=(z,y,lateral=0)=>side?[32+sign*z+lateral*.23,y]:[32+lateral,y+(dir===3?-.17:.17)*z];
 const legs=[],arms=[];
 for(let i=0;i<2;i++){
  const phase=mod(t+i*.5),f=footPath(phase,run,idle),lat=i===0?-3.5:3.5;
  const hip=[0,hipY],ankle=[f.z,(idle?58:57)-f.lift],knee=idle?[0,46]:solveKnee(hip,ankle);
  legs.push({hip:project(...hip,lat),knee:project(...knee,lat),ankle:project(...ankle,lat),contact:f.contact,z:f.z,lift:f.lift,side:i});
  const angle=idle?.06:-(run?.95:.60)*Math.cos(TAU*phase),bend=run?1.50:.22;
  const shoulder=[lean*.65,hipY-14],elbow=[shoulder[0]+Math.sin(angle)*8,shoulder[1]+Math.cos(angle)*8];
  const wrist=[elbow[0]+Math.sin(angle+bend)*7,elbow[1]+Math.cos(angle+bend)*7];
  const al=i===0?-9:9;
  arms.push({shoulder:project(...shoulder,al),elbow:project(...elbow,al),wrist:project(...wrist,al),z:wrist[0],side:i});
 }
 const out=Buffer.alloc(64*64*4),[head,torso,sleeve,hand,thigh,boot,sword,sash]=parts;
 const bootFlip=side; // Generated profile boots point away; flip only the toe texture.
 function leg(i){
  const l=legs[i],shade=side&&i===0?.78:1;
  limb(out,thigh,l.hip,l.knee,thigh.h-1,shade);
  const axis=bootFlip?boot.w-boot.axis:boot.axis;
  limb(out,boot.shin,l.knee,l.ankle,boot.h-4,shade,bootFlip,axis);
  const tilt=side?sign*(run?.6:.3)*l.lift/(run?14:7):0;
  upright(out,boot.foot,l.ankle[0],l.ankle[1],tilt,shade,bootFlip,.5,axis);
 }
 function arm(i){const a=arms[i],shade=side&&i===0?.82:1;limb(out,sleeve,a.shoulder,a.elbow,sleeve.h-1,shade);limb(out,hand,a.elbow,a.wrist,hand.h-2,shade);}
 const swordLat=dir===3?-7:7,swordPos=project(side?-2:0,hipY-3,swordLat);
 const swordAngle=side?-sign*(.14+(run?.10:.055)*Math.sin(TAU*t)):dir===3?.08:-.08;
 const drawSword=()=>upright(out,sword,swordPos[0],swordPos[1],swordAngle,dir===2?.8:1,false,3);
 const drawTorso=()=>upright(out,torso,32,hipY+2,side?-sign*(run?.16:idle?0:.03):0);
 if(dir===2)drawSword();
 if(side){arm(0);leg(0);leg(1);}else{leg(legs[0].ankle[1]<legs[1].ankle[1]?0:1);leg(legs[0].ankle[1]<legs[1].ankle[1]?1:0);}
 const tail=project(side?-2:0,hipY,swordLat);upright(out,sash,tail[0],tail[1],side?sign*(.12+(run?.25:.1)*Math.sin(TAU*t-.5)):.06*Math.sin(TAU*t),1,false,1);
 if(!side){arm(0);arm(1);}
 drawTorso();if(dir!==2)drawSword();
 if(side)arm(1);else{for(let i=0;i<2;i++)if(arms[i].z*(dir===3?-1:1)>0){const a=arms[i];limb(out,hand,a.elbow,a.wrist,hand.h-2);}}
 const headPos=project(lean*1.12,hipY-16.5,0);upright(out,head,headPos[0],headPos[1]);
 return {data:out,joints:{dir,mode,index,head:headPos,legs,arms}};
}
(async()=>{
 const src=await sharp(P('sources/elias/rig_v2/parts_source.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const X=[0,285,565,740,931,1131,1348,1541,1774],Y=[0,248,460,668,887],all=[];
 const sizes=[[18,17],[18,21],[6,10],[5,9],[7,13],[8,15],[5,23],[4,14]];
 fs.mkdirSync(P('assets/elias/parts'),{recursive:true});
 for(let row=0;row<4;row++){
  const parts=[];
  for(let col=0;col<8;col++){
   let l=X[col+1],r=-1,t=Y[row+1],b=-1;
   for(let y=Y[row];y<Y[row+1];y++)for(let x=X[col];x<X[col+1];x++){const i=(y*src.info.width+x)*4;if(src.data[i+3]>=200){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}}
   if(r<l)throw Error('Missing rig part '+row+','+col);
   let [w,h]=sizes[col];if((row===1||row===2)&&col===1)w=13;if((row===1||row===2)&&col===5)w=10;
   const data=Buffer.alloc(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++){const sx=Math.min(r,l+Math.floor((x+.5)*(r-l+1)/w)),sy=Math.min(b,t+Math.floor((y+.5)*(b-t+1)/h)),i=(sy*src.info.width+sx)*4,o=(y*w+x)*4;if(src.data[i+3]>=200){src.data.copy(data,o,i,i+3);data[o+3]=255;}}
   const part={w,h,data};
   if(col===5){let total=0,sum=0;for(let y=0;y<5;y++)for(let x=0;x<w;x++)if(data[(y*w+x)*4+3]){total++;sum+=x+.5;}part.axis=sum/total;part.shin={w,h:h-3,data:data.subarray(0,(h-3)*w*4)};part.foot={w,h:4,data:data.subarray((h-4)*w*4)};}
   parts.push(part);await sharp(data,{raw:{width:w,height:h,channels:4}}).png().toFile(P('assets/elias/parts',DIRS[row]+'_'+col+'.png'));
  }all.push(parts);
 }
 const atlas=Buffer.alloc(COLS*64*256*4),poses=[];
 for(let row=0;row<4;row++)for(let col=0;col<COLS;col++){
  const mode=col<12?'walk':col<24?'run':'idle',f=render(all[row],row,mode,col%12);poses.push(f.joints);
  for(let y=0;y<64;y++)f.data.copy(atlas,((row*64+y)*COLS*64+col*64)*4,y*64*4,(y+1)*64*4);
 }
 const file=P('assets/elias_64.png');await sharp(atlas,{raw:{width:COLS*64,height:256,channels:4}}).png({palette:true,colours:64,dither:0}).toFile(file);
 const frames=P('assets/elias/frames');fs.rmSync(frames,{recursive:true,force:true});fs.mkdirSync(frames,{recursive:true});
 const report={revision:'B.1.4',dimensions:[COLS*64,256],cell:[64,64],minimum_height:64,maximum_height:0,directions:[],binary_alpha:true};
 for(let row=0;row<4;row++){
  const hashes={walk:new Set(),run:new Set()};
  for(let col=0;col<COLS;col++){
   const mode=col<12?'walk':col<24?'run':'idle',b=await sharp(file).extract({left:col*64,top:row*64,width:64,height:64}).png().toBuffer();
   fs.writeFileSync(path.join(frames,DIRS[row]+'_'+mode+'_'+String(col%12).padStart(2,'0')+'.png'),b);
   const raw=await sharp(b).ensureAlpha().raw().toBuffer();let top=64,bottom=-1,left=64,right=-1;
   for(let y=0;y<64;y++)for(let x=0;x<64;x++){const a=raw[(y*64+x)*4+3];if(a!==0&&a!==255)report.binary_alpha=false;if(a){top=Math.min(top,y);bottom=Math.max(bottom,y);left=Math.min(left,x);right=Math.max(right,x);}}
   if(top===0||bottom===63||left===0||right===63)throw Error('Clipped pose '+row+','+col);
   report.minimum_height=Math.min(report.minimum_height,bottom-top+1);report.maximum_height=Math.max(report.maximum_height,bottom-top+1);
   if(mode!=='idle')hashes[mode].add(crypto.createHash('sha256').update(raw).digest('hex'));
  }
  report.directions.push({direction:DIRS[row],unique_walk:hashes.walk.size,unique_run:hashes.run.size,distinct_gaits:[...hashes.walk].every(h=>!hashes.run.has(h))});
 }
 report.gait_checks=[];
 for(let dir=0;dir<4;dir++)for(const mode of ['walk','run']){
  const p=poses.filter(q=>q.dir===dir&&q.mode===mode),z=p.map(q=>q.legs[0].z),h=p.map(q=>q.arms[0].z),mean=a=>a.reduce((s,v)=>s+v,0)/a.length,zm=mean(z),hm=mean(h);
  const corr=z.reduce((s,v,i)=>s+(v-zm)*(h[i]-hm),0)/Math.sqrt(z.reduce((s,v)=>s+(v-zm)**2,0)*h.reduce((s,v)=>s+(v-hm)**2,0));
  const flight=p.filter(q=>q.legs.every(l=>!l.contact)).length,lift=Math.max(...p.map(q=>q.legs[0].lift)),travel=Math.max(...z)-Math.min(...z);
  report.gait_checks.push({direction:DIRS[dir],mode,foot_travel:travel,foot_lift:lift,arm_leg_correlation:corr,airborne_frames:flight,passed:travel>=23&&corr<-.6&&(mode==='walk'?flight===0&&lift>=6:flight>=2&&lift>=13)});
 }
 report.passed=report.binary_alpha&&report.maximum_height<=64&&report.directions.every(d=>d.unique_walk===12&&d.unique_run===12&&d.distinct_gaits)&&report.gait_checks.every(c=>c.passed);
 fs.writeFileSync(P('sources/elias/rig_v2/joints.json'),JSON.stringify(poses,null,2));
 const cat=JSON.parse(fs.readFileSync(P('catalogo.json')));cat.version='3.3.0';cat.player={name:'Elías',file:'assets/elias_64.png',cell:[64,64],columns:COLS,rows:DIRS,frames_per_direction:N,idle_frame:24,fps:16,run_fps:24,walk_speed:160,run_speed:320,max_character_height:report.maximum_height,anchor:[32,64],animations:{walk:{frames:Array.from({length:12},(_,i)=>i),fps:16,loop:true},run:{frames:Array.from({length:12},(_,i)=>i+12),fps:24,loop:true},idle:{frames:[24],fps:1,loop:false}}};
 fs.writeFileSync(P('catalogo.json'),JSON.stringify(cat,null,2));fs.writeFileSync(P('docs/elias_asset_validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
})();
