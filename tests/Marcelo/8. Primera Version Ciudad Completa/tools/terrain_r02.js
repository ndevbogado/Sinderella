(function(root){
const S=typeof module!=='undefined'&&module.exports?require('./surfaces.cjs'):root.BriarSurfaces;
class BriarTerrain{
 constructor(catalog,images,makeCanvas){
  this.meta=catalog.terrain_revision;this.w=this.meta.control_size[0];this.h=this.meta.control_size[1];
  const raw=im=>{let c=makeCanvas(im.width,im.height),g=c.getContext('2d');g.drawImage(im,0,0);return g.getImageData(0,0,im.width,im.height).data};
  this.fields=catalog.materials.map(m=>raw(images[m.field]));this.water=this.meta.water.map(f=>raw(images[f]));this.coping=raw(images[this.meta.coping]);this.ctx={fields:this.fields,water:this.water,coping:this.coping};
  this.control=raw(images[this.meta.control]);this.river=raw(images[this.meta.river]);
  this.macro=new Float32Array(this.w*this.h);
  for(let y=0;y<this.h;y++)for(let x=0;x<this.w;x++)this.macro[y*this.w+x]=1+(S.noise(x*8,y*8,360,98)-.5)*.10;
 }
 mirror(v,n){v=((v%(2*n))+2*n)%(2*n);return v>=n?2*n-1-v:v}
 interp(data,x,y,ch){const xx=Math.max(0,Math.min(this.w-2,Math.floor(x/8))),yy=Math.max(0,Math.min(this.h-2,Math.floor(y/8))),fx=Math.max(0,Math.min(1,x/8-xx)),fy=Math.max(0,Math.min(1,y/8-yy)),i=(yy*this.w+xx)*4+ch,j=i+this.w*4;return (data[i]*(1-fx)+data[i+4]*fx)*(1-fy)+(data[j]*(1-fx)+data[j+4]*fx)*fy}
 waterDistance(x,y){return this.interp(this.river,x,y,0)-128}
 pixel(x,y,out,i){
  const gx=Math.max(0,Math.min(this.w-1,x>>3)),gy=Math.max(0,Math.min(this.h-1,y>>3)),index=(gy*this.w+gx)*4;
  const d=this.interp(this.control,x,y,2)-128,bg=this.control[index],road=this.control[index+1];
  const wobble=Math.abs(d)<2?(S.hash(x,y,17)-.5)*1.15:0,id=d+wobble>=0?road:bg;
  const sx=this.mirror(x,1024),sy=this.mirror(y,576),p=(sy*1024+sx)*4,waterD=this.waterDistance(x,y);
  if(waterD>-4){
   const normal=[(this.river[index+1]-127)/127,(this.river[index+2]-127)/127],c=S.bank(this.ctx,id,waterD,sx,sy,normal);
   out[i]=c[0];out[i+1]=c[1];out[i+2]=c[2];
  }else{
   const f=this.fields[id],shade=this.macro[gy*this.w+gx]*(Math.abs(d)<1&&bg===3&&id!==3?.91:1);
   out[i]=Math.min(255,Math.round(f[p]*shade));out[i+1]=Math.min(255,Math.round(f[p+1]*shade));out[i+2]=Math.min(255,Math.round(f[p+2]*shade));
  }
  out[i+3]=255;
 }
 render(x0,y0,w,h,step=1){const out=new Uint8ClampedArray(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++)this.pixel(x0+x*step,y0+y*step,out,(y*w+x)*4);return out}
}
root.BriarTerrain=BriarTerrain;if(typeof module!=='undefined')module.exports={BriarTerrain};
})(typeof window!=='undefined'?window:globalThis);

