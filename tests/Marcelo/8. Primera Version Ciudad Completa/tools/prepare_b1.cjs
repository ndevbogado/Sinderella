const fs=require('fs'),path=require('path');
const modules=process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES;
const sharp=require(modules?modules+'/sharp':'sharp');
const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p),C=JSON.parse(fs.readFileSync(P('catalogo.json')));
async function native(input,w,h,fill=false){
 let {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(let p=0;p<data.length;p+=4){data[p+3]=data[p+3]>=150?255:0;if(!data[p+3])data[p]=data[p+1]=data[p+2]=0;}
 const b=await sharp(data,{raw:info}).trim({background:'#00000000',threshold:0}).resize(w-4,h-4,{fit:fill?'fill':'inside',kernel:'nearest'}).png().toBuffer(),m=await sharp(b).metadata();
 return sharp({create:{width:w,height:h,channels:4,background:'#00000000'}}).composite([{input:b,left:Math.floor((w-m.width)/2),top:h-m.height-2}]).png({palette:true,colours:192,dither:0}).toBuffer();
}
async function main(){
 for(let k=0;k<12;k++){const a=C.assets.find(a=>a.id==='b1_casa_'+String(k+1).padStart(2,'0')),local=k%6;const cut=await sharp(P('sources',k<6?'b1_casas_se.png':'b1_casas_sw.png')).extract({left:local%3*512,top:Math.floor(local/3)*512,width:512,height:512}).png().toBuffer();fs.writeFileSync(P(a.file),await native(cut,a.width,a.height));}
 // Logical cells from the generator are 181 x 181; exported frames are 64 x 64.
 const nm=await sharp(P('sources/b1_habitantes.png')).metadata(),cw=nm.width/8,ch=nm.height/6,frames=[];
 for(let row=0;row<6;row++)for(let col=0;col<8;col++){const cut=await sharp(P('sources/b1_habitantes.png')).extract({left:Math.round(col*cw),top:Math.round(row*ch),width:Math.floor(cw),height:Math.floor(ch)}).png().toBuffer();frames.push({input:await native(cut,64,64),left:col*64,top:row*64});}
 await sharp({create:{width:512,height:384,channels:4,background:'#00000000'}}).composite(frames).png({palette:true,colours:192,dither:0}).toFile(P(C.npcs.file));
 // Connected components isolate the six hand-designed modules even where their
 // bounding boxes overlap; this is a technical sprite-sheet export, not repainting.
 const {data,info}=await sharp(P('sources/b1_rio.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});const n=info.width*info.height,labels=new Int32Array(n),queue=new Int32Array(n),parts=[];let id=0;
 for(let p=0;p<n;p++){if(labels[p]||data[p*4+3]<150)continue;id++;let head=0,tail=1;queue[0]=p;labels[p]=id;let x0=info.width,y0=info.height,x1=0,y1=0;
  while(head<tail){const q=queue[head++],x=q%info.width,y=Math.floor(q/info.width);x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy;if(xx<0||xx>=info.width||yy<0||yy>=info.height)continue;const z=yy*info.width+xx;if(!labels[z]&&data[z*4+3]>=150){labels[z]=id;queue[tail++]=z;}}}
  if(tail>30000)parts.push({id,x0,y0,x1,y1,count:tail});
 }
 parts.sort((a,b)=>a.y0-b.y0||a.x0-b.x0);
 const ids=['b1_puente_piedra','b1_puente_madera','b1_barca_carga','b1_barca_pesca','b1_muralla_ne','b1_muralla_se'];
 for(let k=0;k<parts.length;k++){const p=parts[k],a=C.assets.find(a=>a.id===ids[k]);let left=p.x0,top=p.y0,width=p.x1-p.x0+1,height=p.y1-p.y0+1;if(k>=4){left=Math.floor((p.x0+p.x1)/2)-60;width=120;}
  const buffer=Buffer.alloc(width*height*4);for(let y=0;y<height;y++)for(let x=0;x<width;x++){let src=(top+y)*info.width+left+x;if(labels[src]===p.id){data.copy(buffer,(y*width+x)*4,src*4,src*4+3);buffer[(y*width+x)*4+3]=255;}}
  let cut=await sharp(buffer,{raw:{width,height,channels:4}}).png().toBuffer();if(k===4)cut=await sharp(cut).flop().png().toBuffer();fs.writeFileSync(P(a.file),await native(cut,a.width,a.height,k<2));
 }
 // Exact marching-squares geometry clips existing texture pixels. 16 masks per
 // surface add clean diagonal edges while retaining all 141 legacy blob tiles.
 const polygons={0:[],1:[[[0,0],[16,0],[0,16]]],2:[[[16,0],[32,0],[32,16]]],3:[[[0,0],[32,0],[32,16],[0,16]]],4:[[[32,16],[32,32],[16,32]]],5:[[[0,0],[16,0],[0,16]],[[32,16],[32,32],[16,32]]],6:[[[16,0],[32,0],[32,32],[16,32]]],7:[[[0,0],[32,0],[32,32],[16,32],[0,16]]],8:[[[0,16],[16,32],[0,32]]],9:[[[0,0],[16,0],[16,32],[0,32]]],10:[[[16,0],[32,0],[32,16]],[[0,16],[16,32],[0,32]]],11:[[[0,0],[32,0],[32,16],[16,32],[0,32]]],12:[[[0,16],[32,16],[32,32],[0,32]]],13:[[[0,0],[16,0],[32,16],[32,32],[0,32]]],14:[[[16,0],[32,0],[32,32],[0,32],[0,16]]],15:[[[0,0],[32,0],[32,32],[0,32]]]};
 const contains=(x,y,poly)=>{let c=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if(((a[1]>y)!==(b[1]>y))&&(x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]))c=!c;}return c;};
 C.diagonal_transitions=[];
 for(const [family,mat]of [['piedra',4],['tierra',2],['agua',7]]){const m=C.materials[mat],tex=await sharp(P(m.file)).ensureAlpha().raw().toBuffer(),out=Buffer.alloc(256*64*4);fs.mkdirSync(P('terrenos','diagonales_'+family),{recursive:true});
  for(let mask=0;mask<16;mask++){const tile=Buffer.alloc(32*32*4);for(let y=0;y<32;y++)for(let x=0;x<32;x++)if(polygons[mask].some(p=>contains(x+.5,y+.5,p))){const src=(y*32+x)*4;tex.copy(tile,src,src,src+4);tile[src+3]=255;const dest=((Math.floor(mask/8)*32+y)*256+mask%8*32+x)*4;tile.copy(out,dest,src,src+4);}const file='terrenos/diagonales_'+family+'/'+String(mask).padStart(2,'0')+'.png';await sharp(tile,{raw:{width:32,height:32,channels:4}}).png().toFile(P(file));C.diagonal_transitions.push({family,index:mask,mask,file});}
  await sharp(out,{raw:{width:256,height:64,channels:4}}).png({palette:true,colours:256,dither:0}).toFile(P('atlases','b1_'+family+'_16.png'));
 }
 fs.writeFileSync(P('catalogo.json'),JSON.stringify(C,null,2));console.log('Exported 12 houses, 48 NPC frames, 6 river/wall modules and 48 diagonal transition cells.');
}
main().catch(e=>{console.error(e);process.exit(1)});
