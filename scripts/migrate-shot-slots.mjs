import fs from 'node:fs';
import path from 'node:path';

const projectRoot=path.resolve('replication/output/love-story-level-5');
const storyboard=fs.readFileSync(path.join(projectRoot,'storyboards/01-虾壳-storyboard.md'),'utf8');
const story=fs.readFileSync(path.join(projectRoot,'01-虾壳.md'),'utf8');
const blocks={};
for(const m of story.matchAll(/【场景\s*(\d+)[^】]*】([\s\S]*?)(?=【场景\s*\d+|## 视听锚点|$)/g)) blocks[m[1]]=m[2].trim();
const rows={};
for(const line of storyboard.split('\n')) if(/^\| (0[1-8]) \|/.test(line)){ const c=line.split('|').slice(1,-1).map(x=>x.trim()); rows[c[0]]={duration:c[1],place:c[2],action:c[3],camera:c[4],sound:c[5],purpose:c[6]}; }
const sceneByShot={ '01':'1','02':'2','03':'2','04':'3','05':'4','06':'5','07':'5','08':'5'};
const imageFiles={'02':'01-shot-02-first-frame-v3.json','03':'01-shot-03-first-frame.json','04':'01-shot-04-first-frame.json','05':'01-shot-05-first-frame.json','06':'01-shot-06-first-frame.json','07':'01-shot-07-first-frame.json','08':'01-shot-08-first-frame.json'};
const videoFiles={'02':'01-shot-02-video.json','03':'01-shot-03-video.json','04':'01-shot-04-video.json','05':'01-shot-05-video.json','06':'01-shot-06-video.json','07':'01-shot-07-video.json','08':'01-shot-08-video.json'};
const readJson=(p)=>JSON.parse(fs.readFileSync(p,'utf8'));
const relAsset=(p)=>p?.replace('replication/output/love-story-level-5/','');
for(const n of ['02','03','04','05','06','07','08']){
 const row=rows[n]||{};
 const imagePrompt=`prompts/${imageFiles[n]}`;
 const videoPrompt=`prompts/${videoFiles[n]}`;
 const imageData=readJson(path.join(projectRoot,imagePrompt));
 const videoData=readJson(path.join(projectRoot,videoPrompt));
 const refs=[...(imageData.references||[]),...(videoData.images||[])].map(relAsset).filter(p=>p?.startsWith('assets/')).filter((p,i,a)=>a.indexOf(p)===i);
 const duration=Number(videoData.duration)||Number.parseFloat(row.duration)||8;
 const contract={schemaVersion:1,shotId:n,status:'prompts_ready',source:{story_file:'01-虾壳.md',scene:`场景 ${sceneByShot[n]}`,verbatim:blocks[sceneByShot[n]]||''},slot_count:1,slots:[{id:n,title:row.purpose||`分镜 ${n}`,description:row.action||'',duration_seconds:duration,image_prompt:imagePrompt,video_prompt:videoPrompt,first_frame:`shots/shot-${n}/images/first-frame.png`,last_frame:`shots/shot-${n}/images/last-frame.png`,video:`shots/shot-${n}/video/shot-${n}.mp4`,references:refs}],post_tasks:[{id:`${n}-post-audio`,type:'sound_and_dialogue',description:row.sound||'对白、环境声和拟音由后期完成'}]};
 const dir=path.join(projectRoot,'shots',`shot-${n}`); fs.mkdirSync(dir,{recursive:true}); fs.writeFileSync(path.join(dir,'slots.json'),JSON.stringify(contract,null,2)+'\n');
 console.log(`[migration] shot-${n}: ${imagePrompt} + ${videoPrompt} -> prompts_ready`);
}
console.log('[migration] completed shots 02-08; no generation submitted');
