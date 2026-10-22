// Shared native-pixel surface rules used by both the exported pairs and previews.
const clamp=(x,a=0,b=1)=>Math.max(a,Math.min(b,x));
const smooth=(a,b,x)=>{let t=clamp((x-a)/(b-a));return t*t*(3-2*t);};
function hash(x,y,s=0){let n=Math.imul(x+137*s,374761393)^Math.imul(y+71*s,668265263);n=Math.imul(n^(n>>>13),1274126177);return((n^(n>>>16))>>>0)/4294967295;}
function noise(x,y,z=8,s=0){x/=z;y/=z;let ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy;fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy);return(1-fy)*((1-fx)*hash(ix,iy,s)+fx*hash(ix+1,iy,s))+fy*((1-fx)*hash(ix,iy+1,s)+fx*hash(ix+1,iy+1,s));}
function sample(d,x,y,w=1024,h=576){x=(Math.floor(x)%w+w)%w;y=(Math.floor(y)%h+h)%h;const i=(y*w+x)*4;return[d[i],d[i+1],d[i+2]];}
const mix=(a,b,t)=>{t=Math.round(clamp(t)*8)/8;return a.map((v,k)=>Math.round(v+(b[k]-v)*t));};
const shade=(a,t)=>a.map(v=>Math.round(clamp(v*t,0,255)));
const natural=[2,3,6,8,14],timber=[9,10];
const kind=id=>natural.includes(id)?'natural':timber.includes(id)?'madera':'construida';
function bank(ctx,id,d,x,y,normal=[1,0]){
 const type=kind(id),base=sample(ctx.fields[id],x,y),mid=sample(ctx.water[1],x,y),deep=sample(ctx.water[0],x,y);
 if(type==='natural'){
  const rough=(noise(x,y,5,77)-.5)*1.4+(hash(x,y,71)-.5)*.5;d+=rough;
  if(d<-2.3)return base;
  if(d<0){const dark=shade(base,.79);return d>-1.1?mix(dark,sample(ctx.water[3],x,y),.4):dark;}
  const shallow=sample(ctx.water[2],x,y);
  let c=mix(shallow,mid,smooth(1.5,12,d));c=mix(c,deep,smooth(22,76,d+(noise(x,y,78,21)-.5)*12));
  if(d<1.3)c=mix(shade(base,.68),c,.62);
  return c;
 }
 // Constructed banks have a narrow cap on land, a short face, and contact shade.
 // No broad muddy shore is painted over urban floors.
 const cap=type==='madera'?2:3,face=type==='madera'?3:4;
 if(d<-cap)return base;
 let edge=sample(type==='madera'?ctx.fields[id]:ctx.coping,x,y);
 if(d<0){let c=type==='madera'?shade(edge,.82):mix(base,edge,id===16?.25:.58);return shade(c,d>-.9?1.13:1.01);}
 if(d<face){const orientation=clamp(.65-.10*normal[1],.53,.77),course=Math.floor(d)%3===2?.87:1;return shade(edge,orientation*course);}
 const wd=d-face;let c=mix(mid,deep,smooth(12,66,wd));
 if(wd<1.7)c=shade(c,.54);else if(wd<3.5)c=shade(c,.80);
 return c;
}
function landPair(ctx,a,b,d,x,y){
 const e=d+(noise(x,y,3,34)-.5)*1.3+(hash(x,y,17)-.5)*.5;
 const chosen=e>=0?a:b;let c=sample(ctx.fields[chosen],x,y);
 // One pixel of tucked earth under grass at a stone edge, without a soil halo.
 if([3,14].includes(b)&&!natural.includes(a)&&e>=0&&e<.8&&hash(x,y,5)>.30)c=shade(c,.87);
 return c;
}
function blob(mask,x,y){const east=x>=15.5,south=y>=15.5,u=Math.abs(x-15.5)/32,v=Math.abs(y-15.5)/32,h=!!(mask&(east?2:8)),k=!!(mask&(south?4:1)),d=!!(mask&(east?(south?32:16):(south?64:128)));const z=(1-u)*(1-v)+Number(h)*u*(1-v)+Number(k)*(1-u)*v+Number(d)*u*v;return h&&k&&!d?Math.min(z,.30+.042*Math.hypot(x-(east?31:0),y-(south?31:0))):z;}
function diagonal(m,x,y){const u=x/31,v=y/31,a=(m&1)?1:0,b=(m&2)?1:0,c=(m&4)?1:0,e=(m&8)?1:0;return(1-v)*((1-u)*a+u*b)+v*((1-u)*e+u*c);}
function distance(field,x,y,threshold){const value=field(x,y)-threshold,gx=(field(x+.25,y)-field(x-.25,y))*2,gy=(field(x,y+.25)-field(x,y-.25))*2,g=Math.hypot(gx,gy);return {d:clamp(value/Math.max(g,.008),-96,96),normal:g>.0001?[gx/g,gy/g]:[0,1]};}
module.exports={clamp,smooth,hash,noise,sample,mix,shade,kind,bank,landPair,blob,diagonal,distance};
