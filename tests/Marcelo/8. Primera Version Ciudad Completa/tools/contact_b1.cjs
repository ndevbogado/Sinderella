/* Technical contact sheet: the exported PNG assets, shown with nearest sampling. */
const fs=require('fs'),path=require('path'),{createCanvas,loadImage}=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/@napi-rs/canvas':'@napi-rs/canvas');
const R=path.resolve(__dirname,'..');
(async()=>{
 const catalog=JSON.parse(fs.readFileSync(path.join(R,'catalogo.json'))),W=1280,H=1250,c=createCanvas(W,H),x=c.getContext('2d');x.imageSmoothingEnabled=false;
 x.fillStyle='#11251e';x.fillRect(0,0,W,H);x.fillStyle='#e7d59c';x.font='bold 28px sans-serif';x.fillText('BRIAR B.1  /  PIEZAS NUEVAS',28,42);x.fillStyle='#a8bdac';x.font='15px sans-serif';x.fillText('18 módulos de entorno · 6 tipos de habitantes · 48 tiles diagonales adicionales',28,68);
 for(const [i,a]of catalog.assets.filter(a=>a.id.startsWith('b1_')).entries()){
  const col=i%6,row=Math.floor(i/6),left=28+col*207,top=92+row*215,im=await loadImage(path.join(R,a.file));
  x.fillStyle='#1c372a';x.fillRect(left,top,195,176);const s=Math.min(183/a.width,166/a.height),w=Math.round(a.width*s),h=Math.round(a.height*s);x.drawImage(im,left+Math.floor((195-w)/2),top+172-h,w,h);
  x.fillStyle='#d7d5b7';x.font='12px sans-serif';x.fillText(a.label.slice(0,28),left,top+191);x.fillStyle='#879f8a';x.font='10px sans-serif';x.fillText(a.width+' × '+a.height+' px  ·  '+a.id,left,top+207);
 }
 x.fillStyle='#e7d59c';x.font='bold 18px sans-serif';x.fillText('HABITANTES  /  64 × 64 POR CELDA',28,775);
 const npc=await loadImage(path.join(R,catalog.npcs.file));for(let i=0;i<6;i++){x.drawImage(npc,0,i*64,64,64,60+i*207,790,96,96);x.fillStyle='#a8bdac';x.font='12px sans-serif';x.fillText(catalog.npcs.rows[i],45+i*207,909);}
 x.fillStyle='#e7d59c';x.font='bold 18px sans-serif';x.fillText('DIAGONALES  /  16 MÁSCARAS POR FAMILIA',28,945);
 const grass=await loadImage(path.join(R,catalog.materials[3].file));for(const [row,family] of ['piedra','tierra','agua'].entries()){
  x.fillStyle='#c7c7a6';x.font='14px sans-serif';x.fillText(family.toUpperCase(),28,1000+row*80);
  for(let i=0;i<16;i++){let left=144+i*68,top=969+row*80;x.drawImage(grass,left,top,60,60);x.drawImage(await loadImage(path.join(R,'terrenos','diagonales_'+family,String(i).padStart(2,'0')+'.png')),left,top,60,60);x.fillStyle='#a8bdac';x.font='10px sans-serif';x.fillText(String(i).padStart(2,'0'),left+24,top+73);}
 }
 fs.writeFileSync(path.join(R,'previews/Briar_Assets_B1.png'),c.toBuffer('image/png'));console.log('New asset contact sheet exported.');
})();
