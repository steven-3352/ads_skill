import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve('replication/output/love-story-nagging-20260913');
const review = path.join(root, 'review');
const plan = JSON.parse(fs.readFileSync(path.join(root, 'contracts/production-plan.json'), 'utf8'));
const intake = JSON.parse(fs.readFileSync(path.join(root, 'contracts/project-intake.json'), 'utf8'));
const batch = JSON.parse(fs.readFileSync(path.join(root, 'automation/batch-shots-01-04.json'), 'utf8'));
const cost = JSON.parse(fs.readFileSync(path.join(root, 'automation/cost-plan.json'), 'utf8'));
const characterPromptFiles = ['zhou-mingyuan-master.json', 'lin-jing-master.json', 'han-lei-master.json'];
const characterPrompts = characterPromptFiles
  .map((file) => path.join(root, 'prompts', file))
  .filter((file) => fs.existsSync(file))
  .map((file) => JSON.parse(fs.readFileSync(file, 'utf8')));
const firstFramePromptFiles = [
  'shot-01-first.json',
  'shot-02-first.json',
  'shot-03-first.json',
  'shot-04-first-v2.json'
];
const firstFramePrompts = firstFramePromptFiles
  .map((file) => path.join(root, 'prompts', file))
  .map((file) => JSON.parse(fs.readFileSync(file, 'utf8')));
const titleToFile = {
  '周明远人物master': 'zhou-mingyuan-master.png',
  '林静人物master': 'lin-jing-master.png',
  '韩磊人物master': 'han-lei-master.png'
};

const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
})[char]);

const rows = plan.narrativeShots.map((shot) => {
  const seconds = shot.generationUnits.reduce((sum, unit) => sum + unit.durationSeconds, 0);
  const beats = shot.requiredBeats.map((beat) => `${beat.id} ${beat.text}`).join('<br>');
  const dialogue = shot.postTasks.filter((task) => task.type === 'dialogue').map((task) => task.description).join('<br>') || '无对白';
  return `<tr>
    <td><strong>${esc(shot.id)} · ${esc(shot.title)}</strong></td>
    <td>${seconds}s</td>
    <td>${beats}</td>
    <td>${esc(shot.camera)}</td>
    <td>${esc(dialogue)}</td>
    <td><span class="status confirmed">分镜已通过</span></td>
  </tr>`;
}).join('');

const promptCards = characterPrompts.map((item) => `<article class="character-card">
  <img src="../assets/${esc(titleToFile[item.title])}" alt="${esc(item.title)}">
  <p class="eyebrow">角色形象已通过</p>
  <h3>${esc(item.title)}</h3>
  <p>${esc(item.output_dimensions)} · 内部检查通过</p>
  <small>文件指纹：${esc(item.output_sha256)}</small>
</article>`).join('');

const firstFrameCards = firstFramePrompts.map((item, index) => `<details class="prompt-card"${index === 0 ? ' open' : ''}>
  <summary><strong>${esc(item.title)}</strong><span>首帧已生成 · 已通过</span></summary>
  <p>${esc(item.prompt)}</p>
  <dl><dt>引用角色</dt><dd>${item.references.map(esc).join(' · ')}</dd><dt>故事节拍</dt><dd>${item.narrative_alignment.related_beats.map(esc).join(' · ')}</dd><dt>检查项</dt><dd>${item.h3_prompt_review.checks.map(esc).join('；')}</dd></dl>
</details>`).join('');

const videoStatus = {
  accepted: ['通过', 'confirmed'],
  accepted_with_user_override: ['接受 · 有已知偏差', 'confirmed'],
  rejected_pending_user_decision: ['未通过 · 待决定', 'rejected'],
  not_submitted_after_stop: ['尚未提交', 'pending']
};
const mediaCards = ['01', '02', '03', '04'].map((shot) => {
  const imageName = shot === '04' ? 'unit-04-first-v2.png' : `unit-${shot}-first.png`;
  const imagePath = `../shots/shot-${shot}/images/${imageName}`;
  const videoPath = path.join(root, 'shots', `shot-${shot}`, 'video', `unit-${shot}.mp4`);
  const record = batch.assets.find((asset) => asset.id === `shot-${shot}-video`);
  const [label, className] = videoStatus[record?.status] || ['状态未知', 'pending'];
  const media = fs.existsSync(videoPath)
    ? `<video controls preload="metadata" src="../shots/shot-${shot}/video/unit-${shot}.mp4"></video>`
    : `<div class="video-empty">停止后未提交，无视频费用</div>`;
  const reason = record?.rejectionReason ? `<p class="failure">${esc(record.rejectionReason)}</p>` : '';
  return `<article class="media-card">
    <div class="media-head"><h3>分镜${shot}</h3><span class="status ${className}">${label}</span></div>
    <img src="${imagePath}" alt="分镜${shot}首帧">
    ${media}
    ${reason}
  </article>`;
}).join('');

const html = `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>《别嫌她唠叨》生产计划审阅</title>
  <link rel="stylesheet" href="../../_review-assets/style.css">
  <style>
    .facts{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}.fact,.character-card,.media-card{border:1px solid #d9d9d9;padding:14px;background:#fff}.fact b{display:block;font-size:22px;margin-top:4px}.character-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}.character-card img{display:block;width:100%;aspect-ratio:3/4;object-fit:cover;background:#eee}.character-card h3{margin:10px 0 4px}.character-card small{display:block;overflow-wrap:anywhere}.media-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.media-card img,.media-card video{display:block;width:100%;aspect-ratio:16/9;object-fit:cover;background:#111}.media-card video{margin-top:10px}.media-head{display:flex;align-items:center;justify-content:space-between;gap:12px}.media-head h3{margin:0 0 10px}.video-empty{display:grid;place-items:center;aspect-ratio:16/9;margin-top:10px;background:#ececec;color:#666}.failure{color:#9f1d1d}.status.rejected{background:#fde8e8;color:#9f1d1d}.status.pending{background:#eee;color:#555}.prompt-list{display:grid;gap:10px}.prompt-card{border:1px solid #d9d9d9;background:#fff}.prompt-card summary{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:14px;cursor:pointer}.prompt-card summary span{font-size:13px;color:#5f6b66}.prompt-card>p,.prompt-card>dl{margin:0;padding:0 14px 14px;line-height:1.7}.prompt-card dl{display:grid;grid-template-columns:84px 1fr;gap:6px 12px;font-size:13px}.prompt-card dt{font-weight:700}.prompt-card dd{margin:0;overflow-wrap:anywhere}table{font-size:14px}td{vertical-align:top;min-width:90px}.notice{border-left:4px solid #d97706;padding:12px 16px;background:#fff8eb}.wide{overflow-x:auto}@media(max-width:760px){.character-grid,.media-grid{grid-template-columns:1fr}.prompt-card summary{align-items:flex-start;flex-direction:column}.prompt-card dl{grid-template-columns:1fr}}
  </style>
</head>
<body>
  <header><a class="brand" href="../../index.html">Production Review</a><span>当前契约版本</span></header>
  <main>
    <section class="intro compact">
      <p class="eyebrow">PROJECT · PRODUCTION PLAN REVIEW</p>
      <h1>《别嫌她唠叨》</h1>
      <p>抖音横版生活情感短片。保留全部对白，使用全新人物和场景。</p>
    </section>
    <section class="facts">
      <div class="fact">模型<b>${esc(intake.brief.model)}</b></div>
      <div class="fact">画幅<b>${esc(intake.brief.aspect)}</b></div>
      <div class="fact">目标成片<b>115–120s</b></div>
      <div class="fact">动态素材<b>110s</b></div>
      <div class="fact">生成单元<b>${plan.narrativeShots.length}</b></div>
      <div class="fact">当前累计<b>¥${cost.spent.toFixed(2)}</b></div>
    </section>
    <section class="notice"><strong>生产已暂停在分镜03。</strong> 分镜01通过，分镜02带已知口型偏差获用户接受；分镜03首版后半段出现说话口型并起身，等待决定。分镜04未提交，分镜05–12仍待定。</section>
    <section>
      <h2>人物定妆图（已通过）</h2>
      <div class="character-grid">${promptCards}</div>
    </section>
    <section>
      <h2>分镜01–04 图片与视频</h2>
      <div class="media-grid">${mediaCards}</div>
    </section>
    <section>
      <h2>4 张已生成首帧提示词</h2>
      <p>点击每一镜展开查看完整画面要求。分镜04使用用户接受的 v2 首帧。</p>
      <div class="prompt-list">${firstFrameCards}</div>
    </section>
    <section>
      <h2>生产分镜</h2>
      <div class="wide"><table>
        <thead><tr><th>分镜</th><th>时长</th><th>故事节拍</th><th>画面任务</th><th>后期对白</th><th>状态</th></tr></thead>
        <tbody>${rows}</tbody>
      </table></div>
    </section>
    <section>
      <h2>下一步</h2>
      <p>接受分镜03首版后，可继续生成分镜04，剩余已授权费用 ¥1.60；若重做分镜03，新增10秒视频费用 ¥2.00，仍只重做这一镜。</p>
    </section>
  </main>
</body>
</html>`;

fs.mkdirSync(review, { recursive: true });
fs.writeFileSync(path.join(review, 'index.html'), html);
console.log(`review built: ${path.join(review, 'index.html')}`);
