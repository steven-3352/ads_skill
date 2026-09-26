#!/usr/bin/env node
// 自建预告片分镜审阅页：内容全部写死进 HTML，零 JS、零外链、UTF-8。
// 教训：build-* 脚本经 /ads-review/ 常渲空壳，故自建（见记忆 public-review-via-ads-review-nginx）。
import fs from 'node:fs';
import path from 'node:path';

const PROJ = '/home/ubuntu/ads_skill/replication/output/jiuheover';
const plan = JSON.parse(fs.readFileSync(path.join(PROJ, 'contracts/trailer-production-plan.json'), 'utf8'));

// 读付费状态：按 prompt 找「最新有效产物」(非 rejected 且文件存在)，让审阅页显示重拍后的帧而非被否的旧帧
const outByPrompt = {};
try {
  const paid = JSON.parse(fs.readFileSync(path.join(PROJ, 'automation/trailer.paid-state.json'), 'utf8'));
  for (const a of (paid.assets || [])) {
    if (!a.prompt_file || a.status === 'rejected' || !a.output) continue;
    const base = path.basename(a.prompt_file);
    const rel = a.output.replace(/^replication\/output\/jiuheover\//, '');
    if (fs.existsSync(path.join(PROJ, rel))) outByPrompt[base] = rel; // 后出现者(如 -r2)覆盖前者
  }
} catch { /* paid-state 缺失时退化为无图 */ }

const esc = (s) => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');

function readPrompt(rel) {
  try { return JSON.parse(fs.readFileSync(path.join(PROJ, rel), 'utf8')); } catch { return null; }
}
// 从 H3 提示词的 prompt 文本里抽【对白】段
function extractDialogue(text) {
  if (!text) return '';
  const out = [];
  const re = /【对白】([^【]*)/g; let m;
  while ((m = re.exec(text))) out.push(m[1].trim());
  return out.join(' ／ ');
}

let cards = '';
for (const shot of plan.narrativeShots) {
  const unit = (shot.generationUnits && shot.generationUnits[0]) || {};
  const dur = unit.durationSeconds ?? '?';
  const beatText = (shot.requiredBeats || []).map(b => b.text).join(' ');
  const refs = (unit.references || []).join('、') || '（无人物·空镜/字幕）';
  const vid = readPrompt(`prompts/${unit.id}-video.json`) || readPrompt(`prompts/${shot.id}-video.json`);
  const firstRel = (unit.prompts?.images || [])[0];
  const img = firstRel ? readPrompt(firstRel) : null;
  const dialogue = extractDialogue(vid?.prompt) || '（无对白/环境声）';
  const size = img?.size || '—';
  const ratio = vid?.ratio || '9:16';
  const mode = vid?.h3_prompt_review?.mode || (unit.prompts?.images?.length > 1 ? 'FL2VA·首尾帧' : 'I2VA·首帧');

  // 内嵌已生成的最新有效关键帧（按 paid-state 选非 rejected 且存在的产物，重拍帧优先）
  const imgOuts = (unit.prompts?.images || []).map(rel => outByPrompt[path.basename(rel)]).filter(Boolean);
  let imgHtml = '';
  for (const io of imgOuts) {
    imgHtml += `<a href="../${io}" target="_blank"><img class="kf" src="../${io}" alt="${esc(io)}"></a>`;
  }
  if (imgHtml) imgHtml = `<div class="kfwrap">${imgHtml}</div>`;

  cards += `
  <div class="card">
    <div class="hd"><span class="u">${esc(unit.id || shot.id)}</span> <span class="t">${esc(shot.title)}</span> <span class="d">${esc(dur)}s</span></div>
    <div class="meta">
      <span class="badge">画幅 ${esc(ratio)} / 关键帧 ${esc(size)}</span>
      <span class="badge">模式 ${esc(mode)}</span>
      <span class="badge">母板 ${esc(refs)}</span>
    </div>
    ${imgHtml}
    <div class="row"><b>对白</b>${esc(dialogue)}</div>
    <div class="row"><b>画面/节拍</b>${esc(beatText)}</div>
    <details><summary>H3 视频提示词全文</summary><pre>${esc(vid?.prompt || '（缺）')}</pre></details>
    <details><summary>关键帧提示词全文</summary><pre>${esc(img?.prompt || '（缺）')}</pre></details>
  </div>`;
}

const totalSec = plan.narrativeShots.reduce((a,s)=>a+((s.generationUnits?.[0]?.durationSeconds)||0),0);

const html = `<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《酒喝完了，我们散了》预告片 · 分镜审阅</title>
<style>
body{font-family:-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;background:#f5f5f7;color:#1d1d1f;margin:0;padding:24px;line-height:1.7}
.wrap{max-width:960px;margin:0 auto}
h1{font-size:24px;margin:0 0 4px}
.sub{color:#86868b;font-size:14px;margin-bottom:8px}
.warn{background:#fff7e6;border:1px solid #ffd591;border-radius:8px;padding:10px 14px;font-size:13px;color:#874d00;margin:12px 0 24px}
.card{background:#fff;border-radius:12px;padding:16px 20px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,.08)}
.hd{font-size:17px;margin-bottom:8px}
.hd .u{display:inline-block;background:#1d1d1f;color:#fff;border-radius:6px;padding:1px 9px;font-weight:600;margin-right:6px}
.hd .t{font-weight:600}
.hd .d{color:#86868b;font-size:14px;margin-left:6px}
.meta{margin-bottom:10px}
.badge{display:inline-block;background:#f0f0f2;border-radius:6px;padding:2px 9px;margin:0 6px 6px 0;font-size:12px;color:#444}
.row{font-size:14px;margin:6px 0}
.row b{display:inline-block;min-width:64px;color:#06c;margin-right:8px}
details{margin-top:8px}
summary{cursor:pointer;color:#06c;font-size:13px}
pre{white-space:pre-wrap;background:#fafafa;border:1px solid #eee;border-radius:8px;padding:12px;font-size:12px;color:#333;margin:8px 0 0}
.kfwrap{margin:8px 0 4px;display:flex;flex-wrap:wrap;gap:8px}
.kf{max-width:240px;width:100%;border-radius:8px;border:1px solid #e5e5e7;display:block}
</style></head><body><div class="wrap">
<h1>《酒喝完了，我们散了》预告片 · 分镜审阅</h1>
<div class="sub">竖屏 9:16 ｜ ${plan.narrativeShots.length} 个生成单元 ｜ 生成总时长约 ${totalSec}s ｜ H3 对白同期直出 ｜ 母板复用 苏晚=master-A / 陈叙=master-B</div>
<div class="warn">⚠️ 合规红线：全片无任何品牌商品/logo/酒名。<b>stage3 金丝雀 U1 已第三次重拍(r3，¥0.25)</b>——按用户参考图重生：白酒瓶(乳白瓷直筒圆柱+红盖金环，对齐 1.jpeg)+ 透明玻璃高脚小酒杯(对齐 1白酒.png)。前两版(日式清酒壶 v1、白瓷盅 r2)已按流程 reject 留痕。U1 卡片内嵌的是 r3。请确认①选角=苏晚②竖屏③明亮暖调④白酒瓶/杯是否 OK。点头后批量其余 9 张。</div>
${cards}
<div class="sub">— 生成后关键帧会补充预览；本页由 automation/gen-trailer-review.mjs 自建，内容写死、无外链。</div>
</div></body></html>`;

fs.mkdirSync(path.join(PROJ, 'review'), { recursive: true });
fs.writeFileSync(path.join(PROJ, 'review/index.html'), html, 'utf8');
console.log('wrote review/index.html', html.length, 'bytes,', plan.narrativeShots.length, 'units, total', totalSec, 's');
