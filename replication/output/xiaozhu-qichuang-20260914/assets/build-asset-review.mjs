#!/usr/bin/env node
// 生成资产母图审阅页 review.html：扫描 prompts/*.json 与 images/*.png，逐张展示图 + 提示词 + 校验状态。
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const promptsDir = join(here, 'prompts');
const imagesDir = join(here, 'images');
const gate = '/home/ubuntu/ads_skill/replication/tools/validate-h3-prompt-review.sh';

const order = [
  'A1-CH01-male', 'A2-CH02-female',
  'A3-LOC01-bedroom-warm', 'A4-LOC01-bedroom-cold',
  'A5-LOC02-dining-warm', 'A6-LOC02-dining-cold',
];
const groupLabel = {
  'identity-master': '身份母图',
  'location-master-warm': '场景母图·暖回忆',
  'location-master-cold': '场景母图·冷现实',
};

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function gatePass(file) {
  try { execSync(`${gate} ${file} image`, { stdio: 'pipe' }); return true; } catch { return false; }
}

const ids = order.filter((id) => existsSync(join(promptsDir, `${id}.json`)));
const cards = ids.map((id) => {
  const p = JSON.parse(readFileSync(join(promptsDir, `${id}.json`), 'utf8'));
  const img = join(imagesDir, `${id}.png`);
  const hasImg = existsSync(img);
  const pass = gatePass(join(promptsDir, `${id}.json`));
  return { id, p, hasImg, pass };
});

const rows = cards.map((c) => `
  <section class="card">
    <div class="imgwrap">
      ${c.hasImg
        ? `<img loading="lazy" src="images/${c.id}.png" alt="${esc(c.id)}">`
        : `<div class="missing">（未生成 / 生成失败）</div>`}
    </div>
    <div class="meta">
      <h2>${esc(c.p.title || c.id)} <span class="tag">${esc(groupLabel[c.p.mode] || c.p.mode)}</span></h2>
      <div class="sub">
        <code>${esc(c.id)}.png</code>
        <span class="pill ${c.p.size === '1344x768' ? 'ok' : 'warn'}">size ${esc(c.p.size || '?')}（H3 16:9 匹配）</span>
        <span class="pill ${c.pass ? 'ok' : 'bad'}">提示词闸门 ${c.pass ? 'pass' : 'FAIL'}</span>
      </div>
      <details><summary>提示词全文</summary><p class="prompt">${esc(c.p.prompt)}</p></details>
      ${Array.isArray(c.p.h3_prompt_review?.checks)
        ? `<ul class="checks">${c.p.h3_prompt_review.checks.map((x) => `<li>${esc(x)}</li>`).join('')}</ul>` : ''}
    </div>
  </section>`).join('\n');

const html = `<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《小猪起床了》资产母图审阅</title>
<style>
 :root{color-scheme:light dark}
 body{margin:0;font:15px/1.6 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif;background:#0f1115;color:#e8eaed}
 header{padding:22px 26px;border-bottom:1px solid #2a2e37;position:sticky;top:0;background:#0f1115;z-index:2}
 header h1{margin:0 0 4px;font-size:20px}
 header p{margin:0;color:#9aa0aa;font-size:13px}
 main{padding:22px;display:grid;gap:22px;grid-template-columns:repeat(auto-fill,minmax(460px,1fr));max-width:1500px;margin:0 auto}
 .card{background:#171a21;border:1px solid #262b35;border-radius:12px;overflow:hidden;display:flex;flex-direction:column}
 .imgwrap{aspect-ratio:16/9;background:#000;display:flex;align-items:center;justify-content:center}
 .imgwrap img{width:100%;height:100%;object-fit:cover;display:block}
 .missing{color:#e06c6c}
 .meta{padding:14px 16px}
 .meta h2{margin:0 0 6px;font-size:16px}
 .tag{font-size:12px;color:#8ab4ff;border:1px solid #34507f;border-radius:20px;padding:1px 9px;margin-left:6px;vertical-align:middle}
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
  <h1>《小猪起床了》— 资产母图审阅（${ids.length} 张）</h1>
  <p>横屏 16:9 · gpt-image-2 锁 1344×768（H3 768P 16:9）· 请确认：选角(中国人)/服装、卧室与餐厅的空间与冷暖、道具状态是否 OK。回复「资产通过」我再派生逐镜关键帧。</p>
</header>
<main>
${rows}
</main>
</body></html>`;

const out = join(here, 'review.html');
writeFileSync(out, html);
console.log(`wrote ${out} (${ids.length} assets)`);
