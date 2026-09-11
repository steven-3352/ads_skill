import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

const output = path.resolve('replication/output');
const esc = (s='') => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const encPath = s => s.split('/').map(encodeURIComponent).join('/');
const exists = p => fs.existsSync(p);
const read = p => exists(p) ? fs.readFileSync(p, 'utf8') : '';
const json = p => { try { return JSON.parse(read(p)); } catch { return null; } };
const promptHash = value => createHash('sha256').update(String(value ?? '')).digest('hex');
const hasPassedVideoReview = data => {
  const review=data?.h3_prompt_review || data?.seedance_feasibility_review;
  return typeof data?.prompt==='string' && data.prompt.length>0 &&
    review?.skill && review?.result==='pass' &&
    review?.asset_type==='video' && Array.isArray(review?.checks) && review.checks.length>0 &&
    Array.isArray(review?.unresolved_blockers) && review.unresolved_blockers.length===0 &&
    review?.reviewed_prompt_sha256===promptHash(data.prompt);
};
const hasUniversalReview=(data,type)=>{const r=data?.seedance_prompt_review;return typeof data?.prompt==='string'&&r?.skill==='seedance-prompt-zh'&&r?.authorship==='generated_by_skill'&&r?.result==='pass'&&r?.asset_type===type&&Array.isArray(r?.checks)&&r.checks.length>0&&Array.isArray(r?.unresolved_blockers)&&r.unresolved_blockers.length===0&&r?.reviewed_prompt_sha256===promptHash(data.prompt);};
const projects = fs.readdirSync(output, {withFileTypes:true}).filter(d => d.isDirectory() && !d.name.startsWith('_')).map(d => d.name).sort();
const cssHref = depth => '../'.repeat(depth) + '_review-assets/style.css';
const shell = (title, body, depth=0) => `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(title)}</title><link rel="stylesheet" href="${cssHref(depth)}"></head><body><header><a class="brand" href="${'../'.repeat(depth)}index.html">Production Review</a><span>只读素材审阅</span></header><main>${body}</main></body></html>`;
const write = (p,s) => { fs.mkdirSync(path.dirname(p),{recursive:true}); fs.writeFileSync(p,s); };
const renderSlotContract=(contract,dir,project)=>{
 const slots=Array.isArray(contract?.slots)?contract.slots:[];
 const pathRef=(p)=>p?encPath('../'+p):'';
 const fileAt=(p)=>p&&exists(path.join(dir,p));
 const promptBlock=(p,type,label)=>{
  if(!p) return '<div class="empty"><strong>暂无'+(label|| (type==='video'?'视频':'图片'))+'提示词</strong></div>';
  const data=json(path.join(dir,p));
  if(!data?.prompt) return '<div class="empty"><strong>提示词文件为空</strong><small>'+esc(p)+'</small></div>';
  const ok=type==='video'?hasPassedVideoReview(data):hasUniversalReview(data,type);
  return '<div class="meta"><span class="'+(ok?'':'warning')+'">'+(ok?'Seedance 生成前校验通过':'未通过生成前校验')+'</span><span>文件 '+esc(p)+'</span></div><pre>'+esc(data.prompt)+'</pre>';
 };
 const media=(p,label,kind)=>{
  if(!fileAt(p)) return '<div class="empty"><strong>暂无'+label+'</strong></div>';
  const src=pathRef(p);
  if(kind==='video') return '<div class="video-wrap"><video controls preload="metadata" playsinline src="'+src+'"></video></div>';
  return '<figure class="primary"><img src="'+src+'" loading="eager"><figcaption>'+esc(p)+'</figcaption></figure>';
 };
 if(!slots.length) return '<section><h2>生成槽位</h2><div class="empty"><strong>暂无槽位定义</strong></div></section>';
 return '<section class="slot-contract"><h2>生成槽位</h2><p class="lead">页面只读取当前分镜的 slots.json；槽位为空就显示空，不扫描旧文件或使用 fallback。</p><div class="slot-grid">'+slots.map(slot=>{
  const refs=(Array.isArray(slot.references)?slot.references:[]).filter(fileAt);
  return '<article class="slot-card"><div class="unit-title"><span>'+esc(slot.id||'未命名槽位')+'</span><strong>'+esc(slot.title||'')+'</strong></div><p>'+esc(slot.description||'')+'</p><div class="slot-status"><span>契约：'+esc(contract.status||'未定义')+'</span><span>首帧图片：'+(fileAt(slot.first_frame)?'已生成文件':'待生成')+'</span><span>尾帧图片：'+(fileAt(slot.last_frame)?'已生成文件':'待生成')+'</span><span>视频：'+(fileAt(slot.video)?'已生成文件':'待生成')+'</span></div><h3>首帧图片提示词</h3>'+promptBlock(slot.first_frame_prompt,'image','首帧图片')+'<h3>尾帧图片提示词</h3>'+promptBlock(slot.last_frame_prompt,'image','尾帧图片')+'<h3>视频提示词</h3>'+promptBlock(slot.video_prompt,'video','视频')+'<h3>首帧图片</h3>'+media(slot.first_frame,'首帧图片','image')+'<h3>尾帧图片</h3>'+media(slot.last_frame,'尾帧图片','image')+'<h3>视频</h3>'+media(slot.video,'视频','video')+'<h3>实际引用资源</h3><div class="refs">'+(refs.length?refs.map(r=>'<figure><img src="'+pathRef(r)+'" loading="lazy"><figcaption>'+esc(r)+'</figcaption></figure>').join(''):'<p class="muted">暂无引用资源</p>')+'</div></article>';
 }).join('')+'</div></section>';
};

const cards = projects.map(name => {
  return `<a class="project" href="${encPath(name)}/review/index.html"><strong>${esc(name)}</strong><span>进入已确认生产资源</span></a>`;
}).join('');
write(path.join(output,'index.html'), shell('项目素材审阅', `<section class="intro"><p class="eyebrow">REPLICATION OUTPUT</p><h1>项目素材审阅</h1><p>按项目进入，只展示当前生产资源。原始目录通过 Nginx 只读提供。</p></section><section class="projects">${cards}</section>`,0));

for (const name of projects) {
  const dir=path.join(output,name), review=path.join(dir,'review'); fs.mkdirSync(review,{recursive:true});
  if(name==='love-story-level-5') continue;
  const body=`<nav><a href="../../index.html">全部项目</a></nav><section class="intro compact"><p class="eyebrow">PROJECT</p><h1>${esc(name)}</h1></section><section><h2>尚未启用</h2><p class="muted">当前先验证《虾壳》项目模板，其他项目暂不生成审阅页面。</p></section>`;
  write(path.join(review,'index.html'),shell(name,body,2));
}

const project='love-story-level-5', dir=path.join(output,project), review=path.join(dir,'review');
const state=json(path.join(dir,'automation/orchestrator-state.json'))||{assets:[],budget:{}};
const storyboard=read(path.join(dir,'storyboards/01-虾壳-storyboard.md'));
const originalStory=read(path.join(dir,'01-虾壳.md'));
const sceneBlocks={};
for(const m of originalStory.matchAll(/【场景\s*(\d+)[^】]*】([\s\S]*?)(?=【场景\s*\d+|## 视听锚点|$)/g)) sceneBlocks[m[1]]=m[2].trim();
const storyByShot={'01':sceneBlocks['1'],'02':sceneBlocks['2'],'03':sceneBlocks['2'],'04':sceneBlocks['3'],'05':sceneBlocks['4'],'06':sceneBlocks['5'],'07':sceneBlocks['5'],'08':sceneBlocks['5']};
const shot01NarrativeReview={
 title:'一个完整叙事分镜，拆成两个生成单元和后期任务',
 targetDuration:'约 15 秒（不是固定 8 秒）',
 beats:[
  ['01-B01','完整白灼虾在林晚小碟中，筷子停在碟边','画面','01A'],
  ['01-B02','小周从公盘夹来第二只虾','画面','01A'],
  ['01-B03','小周：“这盘就你没动。减肥啊？”','后期对白','POST-01'],
  ['01-B04','林晚把虾夹回公盘','画面','01B'],
  ['01-B05','林晚：“懒得剥。”','后期对白','POST-01'],
  ['01-B06','小周：“喜欢吃还懒。”','后期对白','POST-01'],
  ['01-B07','旁人继续聊天，筷子碰碗','后期环境声','POST-02'],
  ['01-B08','虾壳被掰开，发出清脆一声','后期拟音 / 声音桥','POST-02'],
  ['01-B09','林晚抬眼，脆响触发下一段回忆','画面 + 转场','01B / POST-03'],
 ],
 units:[
  {id:'01A',duration:'约 6 秒',title:'小周夹虾',cuts:['小碟里的第一只虾与停住的筷子','小周从公盘夹来第二只虾'],coverage:'01-B01、01-B02',state:'拆分已确认，等待 Seedance 生产提示词'},
  {id:'01B',duration:'约 9 秒',title:'林晚夹回并抬眼',cuts:['林晚把虾夹回公盘','筷子碰碗与林晚抬眼'],coverage:'01-B04、01-B09',state:'拆分已确认；等待完整 01B 生产提示词'},
 ],
 post:[
  ['POST-01','对白','小周与林晚三句对白，后期配音并按动作对齐','01-B03、01-B05、01-B06'],
  ['POST-02','环境 / 拟音','餐馆谈话、筷子碰碗、虾壳脆响','01-B07、01-B08'],
  ['POST-03','转场','用虾壳脆响跨切到四年前同样的脆响','01-B09'],
 ],
};
const rows={};
for(const line of storyboard.split('\n')) if(/^\| (0[1-8]) \|/.test(line)){ const c=line.split('|').slice(1,-1).map(x=>x.trim()); rows[c[0]]={duration:c[1],place:c[2],action:c[3],camera:c[4],sound:c[5],purpose:c[6]}; }
const frameAsset={'02':'shot02-action-fix-v3','03':'shot03-frame-repair','04':'shot04-frame-repair','05':'shot05-first-frame-v2','06':'shot06-first-frame-v2','07':'shot07-first-frame-v2','08':'shot08-first-frame-v2'};
const videoAsset={'05':'shot05-video-v2','06':'shot06-video-v2','07':'shot07-video-v2'};
const shots=[];
for(let i=1;i<=8;i++){
 const n=String(i).padStart(2,'0'), plan=rows[n]||{};
 const slotContract=json(path.join(dir,'shots',`shot-${n}`,'slots.json'));
 const slotHtml=slotContract?renderSlotContract(slotContract,dir,project):'';
 const fa=n==='01'?null:state.assets.find(a=>a.id===frameAsset[n]);
 const va=n==="01"?null:(state.assets.find(a=>a.id===videoAsset[n])||state.assets.find(a=>a.id===`shot${n}-video`)||state.assets.find(a=>a.id===`shot${n}-video-v3`));
 const fallbackImagePrompt={'05':'prompts/01-shot-05-first-frame.json'}[n];
 const imagePromptFile=fa?.prompt_file||fallbackImagePrompt;
 const fallbackVideoPrompt={}[n];
 const videoPromptFile=va?.prompt_file||fallbackVideoPrompt;
 const resolvePromptFile=p=>p?.startsWith('replication/')?path.resolve(p):path.join(dir,p||'');
 const actualFp=imagePromptFile?json(resolvePromptFile(imagePromptFile)):null;
 const actualVp=videoPromptFile?json(resolvePromptFile(videoPromptFile)):null;
 const fallbackFrame={'01':'replication/output/love-story-level-5/shots/shot-01/images/first-frame.png','05':'replication/output/love-story-level-5/shots/shot-05/images/first-frame.png'}[n];
 const frameOutput=fa?.output||fallbackFrame;
 const rawFrameExists=frameOutput && exists(path.resolve(frameOutput));
 const auditMatches=(asset,promptData)=>{if(!asset||!promptData?.prompt)return false;const submitted=json(path.join(dir,`automation/requests/${asset.id}/source-prompt.json`));return submitted?.prompt===promptData.prompt;};
 const frameExists=rawFrameExists && auditMatches(fa,actualFp);
 const videoExists=va?.output && exists(path.resolve(va.output)) && auditMatches(va,actualVp);
 const frameApproved=fa?.semantic_qc?.result==='accept' && frameExists;
 const slotVideosReady=slotContract ? slotContract.slots.length>0 && slotContract.slots.every(s=>Boolean(s.video) && exists(path.join(dir,s.video))) : false; const videoApproved=slotContract ? slotVideosReady : (videoExists && va?.technical_qc?.result==='pass');
 const framePath=rawFrameExists?'../'+frameOutput.slice(`replication/output/${project}/`.length):null;
 const videoPath=videoExists?'../'+va.output.slice(`replication/output/${project}/`.length):null;
 const videoInputHtml=rawFrameExists?`<figure class="primary"><img src="${encPath(framePath)}" loading="eager"><figcaption><strong>@图片1 · 视频首帧${frameApproved?'（已验收）':'（候选）'}</strong><br>${esc(frameOutput)}</figcaption></figure>`:'<div class="empty"><strong>首帧文件尚未生成</strong></div>';
 const relRef=r=>r.startsWith(`replication/output/${project}/`)?'../'+r.slice(`replication/output/${project}/`.length):null;
 const allRefs=[...(actualFp?.references||[]),...(actualVp?.images||[])].filter((v,i,a)=>a.indexOf(v)===i);
 const availableRefs=allRefs.map((r,index)=>({src:relRef(r),label:r,ref:`@图片${index+1}`})).filter(r=>r.src&&exists(path.resolve(dir,r.src.replace('../',''))));
 const refsHtml=availableRefs.length?availableRefs.map(r=>`<figure><img src="${encPath(r.src)}" loading="eager"><figcaption><strong>${esc(r.ref)}</strong> · 本镜头实际引用<br>${esc(path.basename(r.label))}</figcaption></figure>`).join(''):'<p class="muted">本镜头没有图片引用。</p>';
 const promptConfirmation=(slotContract?.status==='prompts_ready' && !videoApproved)?'待你确认':'已确认';
 const status=`图片 ${frameApproved?'可用':'待生成'} · 视频 ${videoApproved?'通过（生成完成）':'待生成'} · 提示词 ${promptConfirmation}`;
 const frameHtml=frameExists?`<figure class="primary"><img src="${encPath(framePath)}" loading="eager"><figcaption>${esc(frameOutput)} · ${esc(fa?.status||'候选资产')}</figcaption></figure>`:'<div class="empty"><strong>暂无首帧文件</strong></div>';
 const videoHtml=videoExists?`<div class="video-wrap"><video controls preload="metadata" playsinline src="${encPath(videoPath)}"></video></div><div class="meta"><span>费用 ¥${esc(va.cost_yuan)}</span><span>状态 ${esc(va.status)}</span></div>`:'<div class="empty"><strong>暂无视频文件</strong></div>';
 const originalHtml=`<section><h2>原始故事</h2><pre class="story">${esc(storyByShot[n]||'未找到对应剧本段落')}</pre></section>`;
 const narrativeReviewHtml=n==='01'?`<section class="narrative-review"><div class="section-heading"><div><p class="eyebrow">NARRATIVE COVERAGE</p><h2>${esc(shot01NarrativeReview.title)}</h2></div><span class="review-state confirmed">已确认</span></div><p class="lead">目标总时长：${esc(shot01NarrativeReview.targetDuration)}。叙事与拆分已确认；下一步才由 seedance-prompt-zh 生成并校验 01A / 01B 的生产提示词。</p><div class="unit-flow"><article><span>完整叙事分镜 01</span><strong>原始故事的全部动作、对白与转场</strong></article><b>→</b><article><span>生成单元</span><strong>01A + 01B</strong></article><b>+</b><article><span>后期任务</span><strong>对白 + 声音 + 转场</strong></article></div><h3>必保留节拍与认领</h3><div class="coverage-table"><table><thead><tr><th>节拍</th><th>原故事内容</th><th>交付通道</th><th>负责单元</th></tr></thead><tbody>${shot01NarrativeReview.beats.map(b=>`<tr><td>${esc(b[0])}</td><td>${esc(b[1])}</td><td>${esc(b[2])}</td><td><strong>${esc(b[3])}</strong></td></tr>`).join('')}</tbody></table></div><h3>生成单元</h3><div class="production-units">${shot01NarrativeReview.units.map(u=>`<article><div class="unit-title"><span>${esc(u.id)} · ${esc(u.duration)}</span><strong>${esc(u.title)}</strong></div><ol>${u.cuts.map(c=>`<li>${esc(c)}</li>`).join('')}</ol><p><b>覆盖：</b>${esc(u.coverage)}</p><p class="unit-state">${esc(u.state)}</p></article>`).join('')}</div><h3>后期任务</h3><div class="coverage-table"><table><thead><tr><th>任务</th><th>类型</th><th>执行内容</th><th>覆盖节拍</th></tr></thead><tbody>${shot01NarrativeReview.post.map(p=>`<tr><td>${esc(p[0])}</td><td>${esc(p[1])}</td><td>${esc(p[2])}</td><td>${esc(p[3])}</td></tr>`).join('')}</tbody></table></div><div class="scope-note"><strong>职责边界</strong><p>原故事由 screenwriting-master 提供；上述拆分由 ads_skill 负责；你确认拆分后，图片和视频生产提示词才交给 seedance-prompt-zh 生成与校验。任何一步都不能静默删除这些节拍。</p></div></section>`:'';
 const tailCandidates=[`shots/shot-${n}/images/last-frame.png`,`shots/shot-${n}/video/shot-${n}-last-frame.png`].filter(p=>exists(path.join(dir,p)));
 const tailHtml=tailCandidates.length?tailCandidates.map(p=>`<figure><img src="${encPath('../'+p)}" loading="eager"><figcaption>尾帧 · ${esc(p)}</figcaption></figure>`).join(''):'<p class="muted">暂无独立尾帧文件；视频尾帧可在播放器中核验。</p>';
 const legacyMediaHtml='<section><h2>需要生成的图片</h2>'+(actualFp?.prompt?'<h3>当前生产提示词</h3><pre>'+esc(actualFp.prompt)+'</pre>':'<div class="empty"><strong>没有图片生成请求</strong></div>')+'<h3>实际引用资源</h3><div class="refs">'+refsHtml+'</div><h3>首帧</h3>'+frameHtml+'<h3>尾帧</h3><div class="refs">'+tailHtml+'</div></section><section><h2>视频</h2>'+(actualVp?.prompt?'<h3>当前生产提示词</h3><pre>'+esc(actualVp.prompt)+'</pre><div class="meta"><span>'+esc(actualVp.duration||'—')+'秒</span></div><h3>实际视频输入</h3>'+videoInputHtml:'<div class="empty"><strong>没有视频生成请求</strong></div>')+videoHtml+'</section>';
 const body=`<nav><a href="index.html">《虾壳》分镜</a><span>${n} / 08</span></nav>
 <section class="shot-head"><div><p class="eyebrow">SHOT ${n}</p><h1>${esc(plan.purpose||'分镜待确认')}</h1><p>${esc(plan.place||'')}</p></div><div class="status ${(!frameApproved||!videoApproved)?'warn':''}">${esc(status)}</div></section>
 ${originalHtml}
 ${narrativeReviewHtml}
 ${n==='01'?'':`<section><h2>分镜计划</h2><dl><dt>时长</dt><dd>${esc(plan.duration||'—')}</dd><dt>动作</dt><dd>${esc(plan.action||'—')}</dd><dt>景别 / 运镜</dt><dd>${esc(plan.camera||'—')}</dd><dt>台词 / 声音</dt><dd>${esc(plan.sound||'—')}</dd></dl></section>`}
 ${slotContract?slotHtml:legacyMediaHtml}
 <footer><a href="shot-${String(Math.max(1,i-1)).padStart(2,'0')}.html">上一镜</a><a href="shot-${String(Math.min(8,i+1)).padStart(2,'0')}.html">下一镜</a></footer>`;
 write(path.join(review,`shot-${n}.html`),shell(`镜头${n} · 虾壳`,body,2));
 shots.push(`<a class="shot-card" href="shot-${n}.html"><span>SHOT ${n}</span><strong>${esc(plan.purpose||'待确认')}</strong><small>${esc(status)}</small></a>`);
}
const baseAssets=[
 {file:'assets/lin-wan-master-v1.png',label:'林晚人物母卡',prompt:'prompts/lin-wan-master.json'},
 {file:'assets/chen-yu-master-v1.png',label:'陈屿人物母卡',prompt:'prompts/chen-yu-master.json'},
 {file:'assets/lin-wan-expressions-v2.png',label:'林晚表情母板',prompt:'prompts/lin-wan-expressions.json'}
].filter(a=>exists(path.join(dir,a.file)));
const baseGallery=baseAssets.map(a=>{const src='../'+a.file; const pp='../'+a.prompt; const promptData=json(path.join(dir,a.prompt)); return `<figure class="asset-card"><img src="${encPath(src)}" loading="lazy"><figcaption><strong>${esc(a.label)}</strong><br>${esc(a.file)}<br><a href="${encPath(pp)}">打开提示词 JSON</a><div class="meta"><span class="${hasUniversalReview(promptData,'image')?'':'warning'}">${hasUniversalReview(promptData,'image')?'Seedance 生成前校验通过':'历史提示词：未通过生成前校验'}</span></div><details><summary>查看生成提示词</summary><pre>${esc(promptData?.prompt||'未找到提示词')}</pre></details></figcaption></figure>`}).join('');
const projectBody=`<nav><a href="../../index.html">全部项目</a></nav><section class="intro compact"><p class="eyebrow">01 · 虾壳</p><h1>公共基础资产</h1><p>这里只展示跨分镜复用的人物与表情基础资产，以及它们各自真实使用的生成提示词。</p></section><section><h2>基础资产</h2><div class="asset-grid">${baseGallery||'<p class="muted">暂无基础资产</p>'}</div></section><section><h2>分镜页面</h2><div class="shot-grid">${shots.join('')}</div></section><section class="links"><a href="../01-虾壳.md">原始剧本</a><a href="../storyboards/01-虾壳-storyboard.md">确认分镜</a><a href="../edit/01-虾壳-editing-pack.md">剪辑包</a></section>`;
write(path.join(review,'index.html'),shell('《虾壳》逐镜素材台',projectBody,2));
console.log(`review site built: ${projects.length} projects, 8 shot pages`);
