/* Browser QA: actual keyboard input, camera follow, bridge traversal, solid water,
   named destinations, catalog downloads and a bounded streaming cache. */
const fs=require('fs'),path=require('path');
const {chromium}=require(process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES?process.env.CODEX_PRIMARY_RUNTIME_NODE_MODULES+'/playwright':'playwright');
const root=path.resolve(__dirname,'..');
async function main(){
 const browser=await chromium.launch({executablePath:process.env.BRIAR_CHROME||undefined,headless:true,args:['--no-sandbox']});
 const page=await browser.newPage({viewport:{width:1280,height:900},deviceScaleFactor:1});
 const errors=[],requests=[];page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(/^https?:/.test(r.url()))requests.push(r.url())});
 await page.goto('file://'+path.join(root,'Briar_Jugable.html'));await page.waitForFunction(()=>window.__ready===true);
 await page.screenshot({path:path.join(root,'previews/Briar_Jugable_Navegador.png')});
 const native=await page.locator('#game').boundingBox();
 const before=await page.evaluate(()=>({y:__briar.player.y,cameraY:__briar.camera.y}));
 await page.locator('#game').click();await page.keyboard.down('s');await page.waitForTimeout(800);await page.keyboard.up('s');
 const after=await page.evaluate(()=>({y:__briar.player.y,cameraY:__briar.camera.y}));
 if(after.y-before.y<80)errors.push('Keyboard did not move player');
 if(Math.abs((after.cameraY-before.cameraY)-(after.y-before.y))>1)errors.push('Camera did not follow');
 await page.keyboard.press('m');if(!await page.locator('#map-modal').isVisible())errors.push('Map key failed');
 await page.screenshot({path:path.join(root,'previews/Briar_Mapa_Interactivo.png')});
 await page.locator('[data-poi="castillo"]').click();
 const travel=await page.evaluate(()=>{const p=__briar.map.pois.find(p=>p.id==='castillo');return Math.hypot(__briar.player.x-p.x,__briar.player.y-p.y)<1;});if(!travel)errors.push('Map travel failed');
 await page.keyboard.press('t');let counts={materials:await page.locator('.tile-card').count()};
 await page.screenshot({path:path.join(root,'previews/Briar_Catalogo_16.png')});
 for(const family of ['piedra','tierra','agua','assets','diagonals','characters']){await page.locator('[data-tab="'+family+'"]').click();counts[family]=await page.locator('.tile-card').count();}
 await page.locator('[data-tab="agua"]').click();await page.screenshot({path:path.join(root,'previews/Briar_Catalogo_47.png')});
 const downloadPromise=page.waitForEvent('download');await page.locator('.tile-card a').first().click();const download=await downloadPromise;await download.saveAs(path.join(root,'docs/qa_download.png'));
 const png=fs.readFileSync(path.join(root,'docs/qa_download.png'));if(png.readUInt32BE(16)!==32||png.readUInt32BE(20)!==32)errors.push('Catalog download is not 32x32');fs.unlinkSync(path.join(root,'docs/qa_download.png'));
 await page.keyboard.press('Escape');
 const navigation=await page.evaluate(()=>{
  const c=__briar,failed=[],visited=[];for(const p of c.map.pois){if(!c.visit(p.id))failed.push(p.id);else visited.push(p.id)}
  const bridges=[];for(const b of c.map.bridges){c.player.x=b.a[0];c.player.y=b.a[1];const dx=b.b[0]-b.a[0],dy=b.b[1]-b.a[1];for(let i=0;i<Math.ceil(Math.hypot(dx,dy)/320*60);i++)c.move(dx,dy,1/60,true);bridges.push({id:b.id,passed:Math.hypot(c.player.x-b.b[0],c.player.y-b.b[1])<8});}
  const solids={river:c.blocked(7200,6688),wall:c.blocked(6000,768),octagonal_corner:c.blocked(4096,768)};
  const gates=c.map.gates.every(g=>!c.blocked(g.x,g.y));
  const sideGates=[];for(const g of c.map.gates.filter(g=>g.id==='este'||g.id==='oeste'))for(const dir of [-1,1]){c.player.x=g.x-dir*240;c.player.y=g.y;for(let i=0;i<90;i++)c.move(dir,0,1/60,true);sideGates.push({id:g.id,direction:dir,passed:Math.abs(c.player.x-(g.x+dir*240))<8});}
  let edge=null;for(let y=3504;y<4112&&!edge;y+=32){for(let x=2704;x<4600;x+=32){if(!c.blocked(x,y)&&c.blocked(x+32,y)&&c.tiles.overlay[Math.floor(y/32)*c.map.width+Math.floor((x+32)/32)]===208){edge={x,y};break;}}}
  let riverStops=false;if(edge){c.player.x=edge.x;c.player.y=edge.y;for(let i=0;i<60;i++)c.move(1,0,1/60,true);riverStops=c.player.x<edge.x+32;}
  c.visit('mercado');c.follow();return{visited:visited.length,failed,bridges,solids,gates,sideGates,riverStops};
 });
 if(navigation.sideGates.some(g=>!g.passed)||navigation.failed.length||navigation.bridges.some(b=>!b.passed)||!Object.values(navigation.solids).every(Boolean)||!navigation.gates||!navigation.riverStops)errors.push('Navigation validation failed');
 if(counts.materials!==17||counts.piedra!==47||counts.tierra!==47||counts.agua!==47||counts.assets!==71||counts.diagonals!==48||counts.characters!==2)errors.push('Catalog counts');
 for(const id of ['mercado','castillo','catedral','biblioteca','mando','herreria','muelles','puente_4','puerta_norte','universidad','bosque']){
  const data=await page.evaluate(id=>{__briar.visit(id);__briar.draw(document.getElementById('game').getContext('2d'));return document.getElementById('game').toDataURL('image/png');},id);
  fs.writeFileSync(path.join(root,'previews',id+'_960x540.png'),Buffer.from(data.split(',')[1],'base64'));
 }
 const bridgeData=await page.evaluate(()=>{const b=__briar.map.bridges[3];__briar.player.x=b.x;__briar.player.y=b.y;__briar.follow();__briar.draw(document.getElementById('game').getContext('2d'));return document.getElementById('game').toDataURL('image/png');});fs.writeFileSync(path.join(root,'previews/puente_centro_960x540.png'),Buffer.from(bridgeData.split(',')[1],'base64'));
 const playerAnimation=await page.evaluate(()=>{
  const c=__briar,details=[];let origin=null;
  for(let y=1200;y<4000&&!origin;y+=64)for(let x=1200;x<4000&&!origin;x+=64){let clear=true;for(let d=-384;d<=384;d+=8)if(c.blocked(x+d,y)||c.blocked(x,y+d)){clear=false;break;}if(clear)origin=[x,y];}
  if(!origin)return {passed:false,error:'No clear motion area'};
  for(const [dir,dx,dy]of [[0,0,1],[1,-1,0],[2,1,0],[3,0,-1]])for(const running of [false,true]){
   const frames=new Set();c.player.x=origin[0];c.player.y=origin[1];c.player.time=0;
   for(let i=0;i<60;i++){c.move(dx,dy,1/60,running);frames.add(c.player.frame);}
   const directionCorrect=c.player.dir===dir,mode=running?'run':'walk',selected=c.player.animation===mode;
   c.move(0,0,1/60);const expected=c.cat.player.animations[mode].frames;
   details.push({direction:c.cat.player.rows[dir],mode,frames:[...frames].sort((a,b)=>a-b),directionCorrect,idleFrame:c.player.frame,passed:selected&&directionCorrect&&frames.size===8&&expected.every(f=>frames.has(f))&&c.player.frame===16});
  }
  c.player.x=origin[0];c.player.y=origin[1];c.player.time=0;
  c.move(1,0,.1);const beforeSwitch=c.player.time;c.move(1,0,.05,true);
  const switchPreservesPhase=Math.abs(c.player.time-((beforeSwitch+.1)%1))<.00001&&c.player.frame>=8;
  c.move(0,0,1/60);const resetPhase=c.player.time;
  const image=c.images[c.cat.player.file],dimensions=[image.naturalWidth,image.naturalHeight];
  const blocked=c.blocked;c.blocked=()=>true;c.move(1,0,.1,true);
  const blockedIdle=!c.player.moving&&c.player.frame===16&&c.player.time===0;c.blocked=blocked;
  c.visit('mercado');return {name:c.cat.player.name,dimensions,details,switchPreservesPhase,blockedIdle,resetPhase,passed:dimensions[0]===1088&&dimensions[1]===256&&details.every(d=>d.passed)&&switchPreservesPhase&&blockedIdle&&resetPhase===0};
 });
 if(!playerAnimation.passed)errors.push('Elias animation validation');
 const activity=await page.evaluate(()=>{
  const c=__briar,before=c.residents.map(n=>[n.x,n.y]),boatBefore=c.boats.map(n=>[n.x,n.y]);for(let i=0;i<180;i++)c.tick(1/60);
  const moved=c.residents.filter((n,i)=>Math.hypot(n.x-before[i][0],n.y-before[i][1])>1).length,boatsMoved=c.boats.filter((n,i)=>Math.hypot(n.x-boatBefore[i][0],n.y-boatBefore[i][1])>1).length;
  const blockedResidents=c.residents.filter(n=>c.blocked(n.x,n.y)).map(n=>n.id);
  const n=c.residents.find(n=>!c.blocked(n.x+32,n.y));c.player.x=n.x+32;c.player.y=n.y;c.follow();
  return{residents:c.residents.length,moved,boatsMoved,blockedResidents};
 });
 if(activity.moved<activity.residents*.8||activity.boatsMoved<6||activity.blockedResidents.length)errors.push('Ambient motion');
 await page.keyboard.press('e');if(!await page.locator('#conversation').isVisible())errors.push('Conversation key');
 await page.keyboard.press('e');await page.keyboard.press('n');if(!await page.evaluate(()=>__briar.night))errors.push('Evening key');
 await page.evaluate(()=>__briar.visit('mercado'));
 const nightData=await page.evaluate(()=>{__briar.draw(document.getElementById('game').getContext('2d'));return document.getElementById('game').toDataURL('image/png')});fs.writeFileSync(path.join(root,'previews/mercado_noche_960x540.png'),Buffer.from(nightData.split(',')[1],'base64'));
 await page.keyboard.press('n');
 const rendering=await page.evaluate(()=>{const t=performance.now();for(let i=0;i<100;i++)__briar.draw(document.getElementById('game').getContext('2d'));return{mean_frame_ms:(performance.now()-t)/100,cache_chunks:__briar.chunks.size};});
 if(rendering.cache_chunks>32)errors.push('Chunk cache exceeded limit');
 await page.setViewportSize({width:390,height:844});await page.evaluate(()=>__briar.visit('mercado'));await page.screenshot({path:path.join(root,'previews/Briar_Movil.png')});
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);if(overflow)errors.push('Mobile horizontal overflow');
 const report={browser:await browser.version(),viewport:native,keyboard_delta:after.y-before.y,camera_delta:after.cameraY-before.cameraY,catalog_counts:counts,navigation,playerAnimation,activity,rendering,external_requests:requests.length,mobile_no_horizontal_overflow:!overflow,errors,passed:errors.length===0};
 fs.writeFileSync(path.join(root,'docs/browser_validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));await browser.close();if(errors.length)process.exitCode=1;
}
main().catch(e=>{console.error(e);process.exit(1)});
