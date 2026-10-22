const fs=require('fs'),path=require('path'),D=process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES;
const {createCanvas,loadImage}=require(D?D+'/@napi-rs/canvas':'@napi-rs/canvas');
const R=path.resolve(__dirname,'..');
(async()=>{
 const c=createCanvas(2000,1290),g=c.getContext('2d');g.imageSmoothingEnabled=false;
 g.fillStyle='#0c2119';g.fillRect(0,0,c.width,c.height);
 g.fillStyle='#dac895';g.font='40px serif';g.fillText('BRIAR',32,53);
 g.font='19px sans-serif';g.fillStyle='#c9d4bf';g.fillText('Proyecto principal · Suelos, estructuras y Elías integrados',212,51);
 g.font='14px sans-serif';g.fillStyle='#8eac95';g.fillText('Capturas del juego a 960 × 540 px · Verde, piedra y raíces · Ciudad de 15 × 27 pantallas',32,81);
 const views=[['universidad_960x540.png','01  ARQUITECTURA · Escala nativa y acceso a la universidad'],['puente_centro_960x540.png','02  PUENTE MODULAR · Paso a 45° y encuentros con el río'],['mercado_960x540.png','03  PLAZA Y SUELOS · Losas pequeñas y habitantes en movimiento'],['bosque_960x540.png','04  BOSQUE EXTERIOR · Siluetas y sotobosque variados']];
 for(let i=0;i<views.length;i++){
  const x=32+(i%2)*976,y=112+Math.floor(i/2)*580;
  g.fillStyle='#d9c692';g.font='15px sans-serif';g.fillText(views[i][1],x,y+17);
  g.drawImage(await loadImage(path.join(R,'previews',views[i][0])),x,y+30);
 }
 fs.writeFileSync(path.join(R,'previews/Briar_Ciudad_Integrada.png'),c.toBuffer('image/png'));
})();
