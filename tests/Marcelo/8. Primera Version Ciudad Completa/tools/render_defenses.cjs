const fs=require('fs'),path=require('path');const {createCanvas,loadImage}=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/@napi-rs/canvas':'@napi-rs/canvas');const {BriarCity}=require('./city_b1.js');const R=path.resolve(__dirname,'..'),P=(...p)=>path.join(R,...p);
(async()=>{const catalog=JSON.parse(fs.readFileSync(P('catalogo.json'))),map=JSON.parse(fs.readFileSync(P('mapa/ciudad.json'))),layers={};for(const n of ['base','overlay']){const b=fs.readFileSync(P('mapa',n+'.bin'));layers[n]=new Uint16Array(b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength));}layers.collision=new Uint8Array(fs.readFileSync(P(map.layers.collision)));const images={};for(const f of [...catalog.assets.flatMap(a=>a.foreground?[a.file,a.foreground]:[a.file]),...catalog.materials.map(m=>m.field),...catalog.terrain_revision.water,catalog.terrain_revision.coping,catalog.terrain_revision.control,catalog.terrain_revision.river,catalog.player.file,catalog.npcs.file,...catalog.diagonal_atlases,'atlases/terrenos_32.png'])images[f]=await loadImage(P(f));const engine=new BriarCity({catalog,map,layers},images,createCanvas),c=createCanvas(960,540),ctx=c.getContext('2d');
const cross=map.defenses.river_crossings;
const views=[
['horizontal_original','REFERENCIA · Muralla horizontal',6000,768],
['vertical_original','REFERENCIA · Muralla vertical',13632,6000],
['diagonal_ne','MURALLA DIAGONAL / · Piedra y vegetación de Briar',1856,3008],
['diagonal_se','MURALLA DIAGONAL \\ · Piedra y vegetación de Briar',11520,1984],
['puerta_este','PUERTA ESTE · Acceso lateral',13632,7296],
['puerta_oeste','PUERTA OESTE · Acceso lateral',768,7296],
['rio_noroeste','RÍO NOROESTE · Arco alineado con la muralla',...cross.find(c=>c.side===7).point],
['rio_sudeste','RÍO SUDESTE · Arco alineado con la muralla',...cross.find(c=>c.side===3).point]];
const board=createCanvas(1280,8/2*520),b=board.getContext('2d');b.imageSmoothingEnabled=false;b.fillStyle='#10231b';b.fillRect(0,0,board.width,board.height);
for(let i=0;i<views.length;i++){let[id,title,x,y]=views[i];engine.camera={x:Math.round(x-480),y:Math.round(y-334)};engine.draw(ctx);fs.writeFileSync(P('previews',id+'_960x540.png'),c.toBuffer('image/png'));
 const context=createCanvas(1280,960),cc=context.getContext('2d');cc.imageSmoothingEnabled=false;for(const oy of [0,540])for(const ox of [0,960]){engine.camera={x:Math.round(x-640+ox),y:Math.round(y-480+oy)};engine.draw(ctx);cc.drawImage(c,ox,oy);}const xx=i%2*640,yy=Math.floor(i/2)*520;b.fillStyle='#dacd9e';b.font='bold 15px sans-serif';b.fillText(title,xx+14,yy+26);b.drawImage(context,xx,yy+40,640,480);}
fs.writeFileSync(P('previews/Briar_Murallas_Corregidas.png'),board.toBuffer('image/png'));console.log('Eight contextual views, native screenshots and style comparison exported.');
})();
