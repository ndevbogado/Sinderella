(function(root){'use strict';
class BriarCity{
 constructor(data,images,makeCanvas){this.data=data;this.map=data.map;this.cat=data.catalog;this.images=images;this.makeCanvas=makeCanvas;this.assets=Object.fromEntries(this.cat.assets.map(a=>[a.id,a]));this.tiles=data.layers;this.terrain=new (typeof module!=='undefined'&&module.exports?require('./terrain_r02.js').BriarTerrain:root.BriarTerrain)(this.cat,images,makeCanvas);this.atlases=['atlases/terrenos_32.png',...this.map.diagonal_atlases];this.player={x:this.map.spawn[0],y:this.map.spawn[1],dir:0,frame:this.cat.player.idle_frame??1,time:0,animation:'idle',moving:false};this.camera={x:0,y:0};this.chunks=new Map();this.spatial=new Map();this.grid=false;this.collision=false;this.night=false;this.time=0;this.paused=false;
  this.map.objects.forEach((o,i)=>{const a=this.assets[o.id],x=o.x-a.anchor[0],y=o.y-a.anchor[1];for(let by=Math.floor(y/512);by<=Math.floor((y+a.height)/512);by++)for(let bx=Math.floor(x/512);bx<=Math.floor((x+a.width)/512);bx++){const k=bx+','+by;if(!this.spatial.has(k))this.spatial.set(k,[]);this.spatial.get(k).push(i)}});
  const actor=(n)=>{const i=n.start_index||0,p=n.route[i];return{...n,x:p[0],y:p[1],index:i,step:i===n.route.length-1?-1:1,wait:(n.id%7)*.12,dir:0,phase:n.id*.21,moving:false}};
  this.residents=this.map.residents.map(actor);this.boats=this.map.boats.map(actor);this.follow();
 }
 blocked(x,y){if(x<12||x>this.map.pixel_width-12||y<64||y>this.map.pixel_height-12)return true;const size=this.map.collision_cell_size||32,w=this.map.collision_width||this.map.width;for(const [dx,dy]of [[0,0],[-7,-3],[7,-3],[-7,3],[7,3]])if(this.tiles.collision[Math.floor((y+dy)/size)*w+Math.floor((x+dx)/size)])return true;return false;}

 move(dx,dy,dt,run=false){
  const p=this.player,meta=this.cat.player;dt=Math.min(dt,.1);const len=Math.hypot(dx,dy);p.moving=false;
  if(len){
   dx/=len;dy/=len;const speed=run?(meta.run_speed||320):(meta.walk_speed||160),parts=Math.max(1,Math.ceil(speed*dt/4));
   const sx=dx*speed*dt/parts,sy=dy*speed*dt/parts,ox=p.x,oy=p.y;
   for(let i=0;i<parts;i++){if(!this.blocked(p.x+sx,p.y))p.x+=sx;if(!this.blocked(p.x,p.y+sy))p.y+=sy;}
   const moved=Math.hypot(p.x-ox,p.y-oy);p.moving=moved>.01;
   p.dir=Math.abs(dx)>Math.abs(dy)?(dx<0?1:2):(dy<0?3:0);
   if(p.moving){
    p.animation=run?'run':'walk';const a=meta.animations[p.animation];
    // Normalized phase survives walk/run and direction changes. Actual displacement
    // drives playback, so blocked movement cannot march on the spot.
    p.time=(p.time+moved/speed*a.fps/a.frames.length)%1;
    p.frame=a.frames[Math.floor(p.time*a.frames.length)%a.frames.length];
   }
  }
  if(!p.moving){p.time=0;p.animation='idle';p.frame=meta.idle_frame;}
  this.follow();
 }
 updateActor(n,dt,boat=false){n.moving=false;if(n.wait>0){n.wait-=dt;return;}let target=n.index+n.step;if(target<0||target>=n.route.length){n.step=-n.step;n.wait=boat?.4:n.pause;return;}const p=n.route[target],dx=p[0]-n.x,dy=p[1]-n.y,dist=Math.hypot(dx,dy),step=n.speed*dt;if(dist<=step){n.x=p[0];n.y=p[1];n.index=target;}else{n.x+=dx/dist*step;n.y+=dy/dist*step;}n.dir=Math.abs(dx)>Math.abs(dy)?(dx<0?1:2):(dy<0?3:0);n.phase+=dt;n.moving=true;}
 tick(dt){if(this.paused)return;dt=Math.min(dt,.1);this.time+=dt;for(const n of this.residents)this.updateActor(n,dt);for(const b of this.boats)this.updateActor(b,dt,true);}
 follow(){this.camera.x=Math.round(Math.max(0,Math.min(this.map.pixel_width-960,this.player.x-480)));this.camera.y=Math.round(Math.max(0,Math.min(this.map.pixel_height-540,this.player.y-334)));}
 visit(id){const p=this.map.pois.find(p=>p.id===id);if(!p||this.blocked(p.x,p.y))return false;this.player.x=p.x;this.player.y=p.y;this.player.frame=this.cat.player.idle_frame??8;this.player.time=0;this.player.animation='idle';this.player.dir=0;this.player.moving=false;this.follow();return true;}
 interact(){let closest=null,d=88;for(const n of this.residents){const len=Math.hypot(n.x-this.player.x,n.y-this.player.y);if(len<d){closest=n;d=len;}}if(closest){closest.wait=4;return{title:closest.name,text:closest.line};}let p=this.map.pois.find(p=>Math.hypot(p.x-this.player.x,p.y-this.player.y)<192);return p?{title:p.name,text:p.description}:{title:'Briar',text:'Acercate a un habitante y presioná E para conversar.'};}
 chunk(cx,cy){const key=cx+','+cy;if(this.chunks.has(key)){const c=this.chunks.get(key);this.chunks.delete(key);this.chunks.set(key,c);return c;}const c=this.makeCanvas(512,512),ctx=c.getContext('2d'),im=ctx.createImageData(512,512);im.data.set(this.terrain.render(cx*512,cy*512,512,512));ctx.putImageData(im,0,0);this.chunks.set(key,c);if(this.chunks.size>32)this.chunks.delete(this.chunks.keys().next().value);return c;}

 visible(view){const ids=new Set();for(let y=Math.floor(view.y/512);y<=Math.floor((view.y+view.h)/512);y++)for(let x=Math.floor(view.x/512);x<=Math.floor((view.x+view.w)/512);x++){const list=this.spatial.get(x+','+y);if(list)for(const i of list)ids.add(i);}return [...ids].map(i=>this.map.objects[i]).filter(o=>{const a=this.assets[o.id];return o.x-a.anchor[0]+a.width>=view.x&&o.x-a.anchor[0]<view.x+view.w&&o.y-a.anchor[1]+a.height>=view.y&&o.y-a.anchor[1]<view.y+view.h}).sort((a,b)=>a.y-b.y);}
 drawActor(ctx,n,player=false){const x=Math.round(n.x)-this.camera.x,y=Math.round(n.y)-this.camera.y;ctx.fillStyle='#09221c55';ctx.fillRect(x-10,y-3,20,6);if(player)ctx.drawImage(this.images[this.cat.player.file],n.frame*64,n.dir*64,64,64,x-32,y-64,64,64);else ctx.drawImage(this.images[this.cat.npcs.file],(n.dir*2+(n.moving?Math.floor(n.phase*6)%2:0))*64,n.role*64,64,64,x-32,y-64,64,64);}
 objectEntries(list){return list.flatMap(o=>{const a=this.assets[o.id];if(!a.depth_slices)return [{y:o.y,object:o}];let parts=[];for(let x=0;x<a.width;x+=a.depth_slices){const w=Math.min(a.depth_slices,a.width-x);parts.push({y:o.y-a.anchor[1]+a.baseline.intercept+a.baseline.slope*(x+w/2),object:o,sx:x,sw:w});}return parts;});}
 drawObject(ctx,q){const o=q.object,a=this.assets[o.id],left=o.x-a.anchor[0],top=o.y-a.anchor[1];let hidden;
  if(a.baseline){const local=this.player.x-left,foot=top+a.baseline.intercept+a.baseline.slope*local;hidden=local>=0&&local<a.width&&this.player.y<foot-8&&this.player.y>foot-a.wall_height;}
  else hidden=this.player.y<o.y-8&&this.player.y>top+16&&Math.abs(this.player.x-o.x)<a.width*.42;
  ctx.globalAlpha=hidden&&!a.ground?.4:1;const sx=q.sx||0,sw=q.sw||a.width;
  ctx.drawImage(this.images[a.file],sx,0,sw,a.height,Math.round(left+sx)-this.camera.x,Math.round(top)-this.camera.y,sw,a.height);ctx.globalAlpha=1;
 }
 draw(ctx){const cam=this.camera,t=this.time;ctx.imageSmoothingEnabled=false;ctx.globalAlpha=1;ctx.fillStyle='#243c2d';ctx.fillRect(0,0,960,540);for(let y=Math.floor(cam.y/512);y<=Math.floor((cam.y+540)/512);y++)for(let x=Math.floor(cam.x/512);x<=Math.floor((cam.x+960)/512);x++)ctx.drawImage(this.chunk(x,y),x*512-cam.x,y*512-cam.y);
  // Water glints are confined to complete water tiles, leaving banks untouched.
  ctx.fillStyle=this.night?'#bcdddc16':'#acf0d932';for(let ty=Math.floor(cam.y/32);ty<=Math.floor((cam.y+540)/32);ty++)for(let tx=Math.floor(cam.x/32);tx<=Math.floor((cam.x+960)/32);tx++){const i=ty*this.map.width+tx;if(this.terrain.waterDistance(tx*32+16,ty*32+16)>24&&(tx*7+ty*11)%4===0){const phase=(Math.floor(t*8)+tx*3)%24;ctx.fillRect(tx*32-cam.x+phase,ty*32-cam.y+12,6,1);}}
  for(const b of this.boats){const a=this.assets[b.asset];if(Math.abs(b.x-cam.x-480)>650||Math.abs(b.y-cam.y-270)>480)continue;ctx.drawImage(this.images[a.file],Math.round(b.x-a.width/2)-cam.x,Math.round(b.y-a.height*.6)-cam.y);}
  const list=this.visible({x:cam.x,y:cam.y,w:960,h:540});
  for(const o of list)if(this.assets[o.id].ground)this.drawObject(ctx,{object:o});
  const actors=this.residents.filter(n=>n.x>cam.x-64&&n.x<cam.x+1024&&n.y>cam.y-16&&n.y<cam.y+604);
  const ordered=[...this.objectEntries(list.filter(o=>!this.assets[o.id].ground)),...actors.map(n=>({y:n.y,actor:n})),{y:this.player.y,actor:this.player,hero:true}].sort((a,b)=>a.y-b.y);
  for(const q of ordered)if(q.object)this.drawObject(ctx,q);else this.drawActor(ctx,q.actor,q.hero);
  for(const o of list){const a=this.assets[o.id];if(a.foreground)ctx.drawImage(this.images[a.foreground],Math.round(o.x-a.anchor[0])-cam.x,Math.round(o.y-a.anchor[1])-cam.y);}

  for(const e of this.map.effects){const x=Math.round(e.x-cam.x),y=Math.round(e.y-cam.y);if(x<-100||x>1060||y<-100||y>640)continue;if(e.type==='smoke'){for(let k=0;k<4;k++){const phase=(t*15+k*18+e.x%37)%82,dx=Math.round(Math.sin(phase*.07+e.x)*5+phase*.07),sz=phase>44?5:4;ctx.fillStyle=`rgba(222,221,202,${(.28*(1-phase/82)).toFixed(3)})`;ctx.fillRect(x+dx,y-Math.round(phase),sz,sz);}}if(e.type==='fountain'){ctx.fillStyle='#b5f3e399';for(let k=0;k<3;k++)ctx.fillRect(x-17+k*16,y+Math.round(Math.sin(t*5+k)*2),5,2);}}
  if(this.night){ctx.fillStyle='#091a435c';ctx.fillRect(0,0,960,540);for(const e of this.map.effects){if(e.type!=='lamp')continue;const x=Math.round(e.x-cam.x),y=Math.round(e.y-cam.y);if(x<-80||x>1040||y<-80||y>620)continue;ctx.fillStyle='#ffd3820b';for(let r=38;r>4;r-=7){for(let row=-r;row<=r;row+=4){const half=Math.floor(Math.sqrt(r*r-row*row)/4)*4;ctx.fillRect(x-half,y+row,half*2,4);}}ctx.fillStyle='#fff0a7';ctx.fillRect(x-1,y-1,3,3);}}
  if(this.collision){const step=this.map.collision_cell_size,w=this.map.collision_width;ctx.fillStyle='#ef634c66';for(let y=Math.floor(cam.y/step);y<=Math.floor((cam.y+540)/step);y++)for(let x=Math.floor(cam.x/step);x<=Math.floor((cam.x+960)/step);x++)if(this.tiles.collision[y*w+x])ctx.fillRect(x*step-cam.x,y*step-cam.y,step,step);}

  if(this.grid){ctx.strokeStyle='#c8e4b54a';ctx.lineWidth=1;ctx.beginPath();for(let x=Math.ceil(cam.x/32)*32-cam.x;x<960;x+=32){ctx.moveTo(x+.5,0);ctx.lineTo(x+.5,540);}for(let y=Math.ceil(cam.y/32)*32-cam.y;y<540;y+=32){ctx.moveTo(0,y+.5);ctx.lineTo(960,y+.5);}ctx.stroke();}
  return {objects:list.length,residents:actors.length};
 }
}
root.BriarCity=BriarCity;if(typeof module!=='undefined')module.exports={BriarCity};
})(typeof window!=='undefined'?window:globalThis);
