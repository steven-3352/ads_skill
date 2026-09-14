#!/usr/bin/env node
// 生成逐镜关键帧审阅页 keyframe-review.html：扫描 prompts/KF-*.json 与 images/KF-*.png，
// 按镜头(S01..S10)分组展示 端点帧图 + 提示词 + 校验状态。文生图，1344x768(H3 768P 16:9)。
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const promptsDir = join(here, 'prompts');
const imagesDir = join(here, 'images');
const gate = '/home/ubuntu/ads_skill/replication/tools/validate-h3-prompt-review.sh';

// 逐镜端点帧顺序（15 张）。first=首帧，last=尾帧(FL2VA)，ref=正反打参考帧。
const order = [
  { id: 'KF-S01-first', shot: 'S01 现在·习惯性走回卧室看到空的另一半（触发）', role: '首帧', mode: 'I2VA' },
  { id: 'KF-S02-first', shot: 'S02 回忆·掀被叫起', role: '首帧', mode: 'I2VA' },
  { id: 'KF-S03-first', shot: 'S03 回忆·裹被蚕蛹赖床', role: '首帧·极近景', mode: 'I2VA' },
  { id: 'KF-S04-first', shot: 'S04 回忆·假睡正反打', role: '首帧·男中景', mode: 'I2VA' },
  { id: 'KF-S04-ref', shot: 'S04 回忆·假睡正反打', role: '参考·女假睡CU', mode: 'I2VA' },
  { id: 'KF-S05-first', shot: 'S05 回忆·拽人入被', role: '首帧·拽前', mode: 'FL2VA' },
  { id: 'KF-S05-last', shot: 'S05 回忆·拽人入被', role: '尾帧·拖入相依', mode: 'FL2VA' },
  { id: 'KF-S06-first', shot: 'S06 回忆·亲亲抱抱数条件', role: '首帧·点脸颊', mode: 'FL2VA' },
  { id: 'KF-S06-last', shot: 'S06 回忆·亲亲抱抱数条件', role: '尾帧·搂住竖二指', mode: 'FL2VA' },
  { id: 'KF-S07-first', shot: 'S07 回忆·举高高爬背', role: '首帧·竖三指', mode: 'FL2VA' },
  { id: 'KF-S07-last', shot: 'S07 回忆·举高高爬背', role: '尾帧·趴背绕颈(复用S10封面)', mode: 'FL2VA' },
  { id: 'KF-S08-first', shot: 'S08 回忆·背起走向餐厅', role: '首帧·背起晃动', mode: 'FL2VA' },
  { id: 'KF-S08-last', shot: 'S08 回忆·背起走向餐厅', role: '尾帧·近餐桌两煎蛋热气', mode: 'FL2VA' },
  { id: 'KF-S09-first', shot: 'S09 现在·独坐收尾', role: '首帧·冷调一副碗筷', mode: 'I2VA' },
  { id: 'KF-S10-first', shot: 'S10 现在·手机"一年前的今天"回忆推送', role: '首帧·冷桌暖封面(留字位)', mode: 'I2VA' },
];

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function gatePass(file) {
  try { execSync(`${gate} ${file} image`, { stdio: 'pipe' }); return true; } catch { return false; }
}
function pngSize(file) {
  try {
    const out = execSync(`file "${file}"`, { encoding: 'utf8' });
    const m = out.match(/(\d+)\s*x\s*(\d+)/);
    return m ? `${m[1]}x${m[2]}` : '?';
  } catch { return '?'; }
}

const cards = order.map((o) => {
  const pf = join(promptsDir, `${o.id}.json`);
  const img = join(imagesDir, `${o.id}.png`);
  const hasPrompt = existsSync(pf);
  const p = hasPrompt ? JSON.parse(readFileSync(pf, 'utf8')) : null;
  const hasImg = existsSync(img);
  const pass = hasPrompt ? gatePass(pf) : false;
  const size = hasImg ? pngSize(img) : null;
  return { ...o, p, hasPrompt, hasImg, pass, size };
});

const rows = cards.map((c) => `
  <section class="card">
    <div class="imgwrap">
      ${c.hasImg
        ? `<img loading="lazy" src="images/${c.id}.png" alt="${esc(c.id)}">`
        : `<div class="missing">（未生成 / 生成失败）</div>`}
    </div>
    <div class="meta">
      <h2>${esc(c.shot)}</h2>
      <div class="sub">
        <span class="tag">${esc(c.role)}</span>
        <span class="tag mode">${esc(c.mode)}</span>
        <code>${esc(c.id)}.png</code>
        ${c.size ? `<span class="pill ${c.size.startsWith('1344') || c.size.startsWith('2048') ? 'ok' : 'warn'}">${esc(c.size)}</span>` : ''}
        <span class="pill ${c.pass ? 'ok' : 'bad'}">闸门 ${c.pass ? 'pass' : (c.hasPrompt ? 'FAIL' : '缺提示词')}</span>
      </div>
      ${c.p ? `<details><summary>提示词全文</summary><p class="prompt">${esc(c.p.prompt)}</p></details>` : ''}
      ${c.p && Array.isArray(c.p.h3_prompt_review?.checks)
        ? `<ul class="checks">${c.p.h3_prompt_review.checks.map((x) => `<li>${esc(x)}</li>`).join('')}</ul>` : ''}
    </div>
  </section>`).join('\n');

const doneImgs = cards.filter((c) => c.hasImg).length;
const donePass = cards.filter((c) => c.pass).length;

const html = `<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《小猪起床了》逐镜关键帧审阅</title>
<style>
 :root{color-scheme:light dark}
 body{margin:0;font:15px/1.6 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif;background:#0f1115;color:#e8eaed}
 header{padding:22px 26px;border-bottom:1px solid #2a2e37;position:sticky;top:0;background:#0f1115;z-index:2}
 header h1{margin:0 0 4px;font-size:20px}
 header p{margin:0;color:#9aa0aa;font-size:13px}
 main{padding:22px;display:grid;gap:22px;grid-template-columns:repeat(auto-fill,minmax(460px,1fr));max-width:1600px;margin:0 auto}
 .card{background:#171a21;border:1px solid #262b35;border-radius:12px;overflow:hidden;display:flex;flex-direction:column}
 .imgwrap{aspect-ratio:16/9;background:#000;display:flex;align-items:center;justify-content:center}
 .imgwrap img{width:100%;height:100%;object-fit:cover;display:block}
 .missing{color:#e06c6c}
 .meta{padding:14px 16px}
 .meta h2{margin:0 0 8px;font-size:15px;line-height:1.4}
 .tag{font-size:12px;color:#8ab4ff;border:1px solid #34507f;border-radius:20px;padding:1px 9px}
 .tag.mode{color:#c8a2ff;border-color:#5a3f8f}
 .sub{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:8px}
 code{background:#0c0e12;padding:1px 6px;border-radius:5px;font-size:12px;color:#c7ccd4}
 .pill{font-size:12px;padding:1px 8px;border-radius:20px}
 .pill.ok{background:#16351f;color:#7fe0a0;border:1px solid #2c6b3f}
 .pill.bad{background:#3a1618;color:#ff9a9a;border:1px solid #7a2b2e}
 .pill.warn{background:#3a3316;color:#e6cf7a;border:1px solid #7a6b2b}
 details{margin:6px 0}
 summary{cursor:pointer;color:#9aa0aa;font-size:13px}
 .prompt{background:#0c0e12;border-radius:8px;padding:10px 12px;font-size:12.5px;color:#b9c0ca;white-space:pre-wrap}
 .checks{margin:8px 0 0;padding-left:18px;color:#9aa0aa;font-size:12.5px}
</style></head>
<body>
<header>
  <h1>《小猪起床了》— 逐镜关键帧审阅（${doneImgs}/${order.length} 张已生成 · 闸门通过 ${donePass}/${order.length}）</h1>
  <p>横屏 16:9 · gpt-image-2 文生图锁 1344×768（H3 768P 16:9）· FL2VA 动作镜含首/尾端点帧 · 中文字幕/片名/日期一律后期渲染，画面留白。请确认：选角一致(中国人)/机位与场景连贯/动作端点/冷暖。回复「关键帧通过」进入付费视频生成。</p>
</header>
<main>
${rows}
</main>
</body></html>`;

const out = join(here, 'keyframe-review.html');
writeFileSync(out, html);
console.log(`wrote ${out} (${doneImgs}/${order.length} images, ${donePass} gate-pass)`);
