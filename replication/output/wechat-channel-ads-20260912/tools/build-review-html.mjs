#!/usr/bin/env node
// build-review-html.mjs — 确定性项目评审 HTML 构建器 (INFRA-3)
// 扫描本项目产物 (stories / prompts / NN|shots shot-SS images+video / edit) + 解析 contracts/TASKS.md,
// 重生成单页评审 HTML 到 review/index.html。满足契约 §2.5 可见标准。
// 纯 Node,无 npm 依赖。确定性、幂等:同样的磁盘产物 -> 同样的 HTML。
// 媒体一律相对路径引用 (media 不入库,由 nginx 本地提供)。不手写任何商品专属 HTML。

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// 项目根 = 本脚本 (tools/) 的上一级
const PROJECT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const REVIEW_DIR = path.join(PROJECT, 'review');
const OUT = path.join(REVIEW_DIR, 'index.html');
const SERVE_URL = 'https://www.tonbird.top/ads-review/wechat-channel-ads-20260912/';
const VIDEO_YUAN_PER_SEC = 0.2; // [[media-generation-costs]]

// ---------- helpers ----------
const esc = (s = '') => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const exists = p => fs.existsSync(p);
const read = p => (exists(p) ? fs.readFileSync(p, 'utf8') : '');
const json = p => { try { return JSON.parse(read(p)); } catch { return null; } };
const isDir = p => exists(p) && fs.statSync(p).isDirectory();
const lsSorted = p => (isDir(p) ? fs.readdirSync(p).sort() : []);
// review/index.html 引用项目根下产物 => 前缀 '../'; 相对路径按 URL 段编码
const rel = relPath => '../' + relPath.split('/').map(encodeURIComponent).join('/');

// ---------- 极简 markdown -> HTML (无外部依赖,安全:先转义再处理块) ----------
function inline(s) {
  // s 已 HTML 转义
  s = s.replace(/`([^`]+)`/g, '<code>$1</code>');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  return s;
}
function mdToHtml(md) {
  if (!md) return '<p class="muted">(空)</p>';
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const out = [];
  let i = 0;
  const flushPara = buf => { if (buf.length) { out.push('<p>' + inline(esc(buf.join(' '))) + '</p>'); buf.length = 0; } };
  let para = [];
  while (i < lines.length) {
    const line = lines[i];
    const t = line.trim();
    // table: 连续以 | 开头的行
    if (t.startsWith('|')) {
      flushPara(para);
      const tbl = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) { tbl.push(lines[i].trim()); i++; }
      const rows = tbl.filter(r => !/^\|[\s:|-]+\|?$/.test(r)).map(r => r.replace(/^\||\|$/g, '').split('|').map(c => c.trim()));
      if (rows.length) {
        const head = rows[0];
        const body = rows.slice(1);
        out.push('<table><thead><tr>' + head.map(c => '<th>' + inline(esc(c)) + '</th>').join('') + '</tr></thead><tbody>' +
          body.map(r => '<tr>' + r.map(c => '<td>' + inline(esc(c)) + '</td>').join('') + '</tr>').join('') + '</tbody></table>');
      }
      continue;
    }
    // heading
    const h = t.match(/^(#{1,6})\s+(.*)$/);
    if (h) { flushPara(para); const lvl = Math.min(h[1].length + 1, 6); out.push(`<h${lvl}>${inline(esc(h[2]))}</h${lvl}>`); i++; continue; }
    // blockquote
    if (t.startsWith('>')) { flushPara(para); out.push('<blockquote>' + inline(esc(t.replace(/^>\s?/, ''))) + '</blockquote>'); i++; continue; }
    // list (ordered / unordered)
    if (/^([-*]\s+|\d+\.\s+)/.test(t)) {
      flushPara(para);
      const ordered = /^\d+\.\s+/.test(t);
      const items = [];
      while (i < lines.length && /^([-*]\s+|\d+\.\s+)/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^([-*]\s+|\d+\.\s+)/, ''));
        i++;
      }
      out.push(`<${ordered ? 'ol' : 'ul'}>` + items.map(it => '<li>' + inline(esc(it)) + '</li>').join('') + `</${ordered ? 'ol' : 'ul'}>`);
      continue;
    }
    // blank
    if (t === '') { flushPara(para); i++; continue; }
    para.push(t);
    i++;
  }
  flushPara(para);
  return out.join('\n');
}

// 从 story md 抽取 "## 收尾字幕" 段落纯文本
function extractEndingCaption(md) {
  if (!md) return '';
  const m = md.match(/^##\s*收尾字幕[^\n]*\n([\s\S]*?)(?=^##\s|\Z)/m);
  if (!m) return '';
  return m[1].split('\n').map(s => s.trim()).filter(s => s && !s.startsWith('>')).join(' ');
}

// ---------- 提示词校验徽标 (与 build-output-review.mjs 同风格,只读不改数据) ----------
function promptBadge(data) {
  const r = data?.h3_prompt_review;
  const ok = r && r.result === 'pass' && r.skill && Array.isArray(r.checks) && r.checks.length > 0 &&
    Array.isArray(r.unresolved_blockers) && r.unresolved_blockers.length === 0;
  if (ok) return '<span class="badge ok">h3 生成前校验通过</span>';
  if (r) return '<span class="badge warn">未通过生成前校验</span>';
  if (data?.seedance_prompt_review) return '<span class="badge warn">历史 Seedance 记录(非 H3 生成前校验)</span>';
  return '<span class="badge warn">无生成前校验记录</span>';
}

// ---------- 解析 TASKS.md 为任务状态面板 ----------
function parseTasks() {
  const md = read(path.join(PROJECT, 'contracts', 'TASKS.md'));
  const tasks = [];
  const re = /^###\s*\[([^\]]+)\]\s*(.*?)\s*·\s*状态:\s*(\S+)\s*$/gm;
  const heads = [];
  let m;
  while ((m = re.exec(md))) heads.push({ id: m[1], name: m[2].trim(), status: m[3].trim(), idx: m.index });
  for (let k = 0; k < heads.length; k++) {
    const start = heads[k].idx;
    const end = k + 1 < heads.length ? heads[k + 1].idx : md.length;
    const block = md.slice(start, end);
    const grab = label => {
      const mm = block.match(new RegExp('^—\\s*' + label + '[^:：]*[:：]?\\s*(.*)$', 'm'));
      return mm ? mm[1].trim() : '';
    };
    tasks.push({ id: heads[k].id, name: heads[k].name, status: heads[k].status, deliver: grab('交付'), note: grab('自述'), accept: grab('验收') });
  }
  return tasks;
}

const STATUS_CLASS = { '待办': 'todo', '分派中': 'assigned', '完成待审': 'review', '已过审': 'passed', '打回': 'rejected' };
function taskPanel(tasks) {
  if (!tasks.length) return '<p class="muted">TASKS.md 未找到任务块。</p>';
  const rows = tasks.map(t => {
    const cls = STATUS_CLASS[t.status] || 'todo';
    return `<tr><td class="mono">${esc(t.id)}</td><td>${esc(t.name)}</td><td><span class="status-badge ${cls}">${esc(t.status)}</span></td><td>${esc(t.deliver) || '<span class="muted">—</span>'}</td><td>${esc(t.note) || '<span class="muted">—</span>'}</td></tr>`;
  }).join('');
  return `<table class="task-table"><thead><tr><th>任务ID</th><th>单元</th><th>状态</th><th>交付</th><th>自述</th></tr></thead><tbody>${rows}</tbody></table>`;
}

// ---------- 产物发现 ----------
// 商品编号 = stories / prompts / 产品目录名 中出现的两位前缀 的并集
function discoverProducts() {
  const set = new Set();
  for (const f of lsSorted(path.join(PROJECT, 'stories'))) { const m = f.match(/^(\d{2})-/); if (m) set.add(m[1]); }
  for (const f of lsSorted(path.join(PROJECT, 'prompts'))) { const m = f.match(/^(\d{2})-/); if (m) set.add(m[1]); }
  for (const d of lsSorted(PROJECT)) { if (/^\d{2}$/.test(d) && isDir(path.join(PROJECT, d))) set.add(d); }
  return [...set].sort();
}

// 商品的分镜媒体根: 优先 PP/shots,缺失则回退顶层 shots (03 试点即用顶层 shots)
function mediaBase(pp) {
  if (isDir(path.join(PROJECT, pp, 'shots'))) return pp + '/shots';
  if (isDir(path.join(PROJECT, 'shots'))) return 'shots';
  return null;
}

function shotNumbers(pp, base) {
  const set = new Set();
  if (base) for (const d of lsSorted(path.join(PROJECT, base))) { const m = d.match(/^shot-(\d+)$/); if (m) set.add(m[1]); }
  for (const f of lsSorted(path.join(PROJECT, 'prompts'))) { const m = f.match(new RegExp('^' + pp + '-shot-(\\d+)-')); if (m) set.add(m[1]); }
  return [...set].sort((a, b) => Number(a) - Number(b));
}

function pngsIn(dir) {
  return lsSorted(dir).filter(f => f.toLowerCase().endsWith('.png') && !f.startsWith('.'));
}
function mp4sIn(dir) {
  return lsSorted(dir).filter(f => f.toLowerCase().endsWith('.mp4') && !f.startsWith('.'));
}

function promptFile(pp, ss, kind) {
  const p = path.join(PROJECT, 'prompts', `${pp}-shot-${ss}-${kind}.json`);
  return exists(p) ? { relPath: `prompts/${pp}-shot-${ss}-${kind}.json`, data: json(p) } : null;
}

function mediaFig(relPath, caption) {
  return `<figure><img loading="lazy" src="${rel(relPath)}"><figcaption>${esc(caption)}</figcaption></figure>`;
}
function videoTag(relPath, caption) {
  return `<div class="video-wrap"><video controls preload="metadata" playsinline src="${rel(relPath)}"></video><small>${esc(caption)}</small></div>`;
}

function promptSection(label, pf) {
  if (!pf) return '';
  if (!pf.data?.prompt) return `<div class="prompt-block"><div class="prompt-head"><strong>${esc(label)}</strong><span class="badge warn">提示词文件缺 prompt 字段</span><span class="mono">${esc(pf.relPath)}</span></div></div>`;
  const d = pf.data;
  const meta = [];
  if (d.mode) meta.push(esc(d.mode));
  if (d.duration) meta.push(esc(d.duration) + 's');
  if (d.ratio) meta.push(esc(d.ratio));
  return `<div class="prompt-block"><div class="prompt-head"><strong>${esc(label)}</strong>${promptBadge(d)}${meta.length ? '<span class="mono">' + meta.join(' · ') + '</span>' : ''}<span class="mono">${esc(pf.relPath)}</span></div><pre>${esc(d.prompt)}</pre></div>`;
}

// 从视频 status json 取 时长/成本
function clipStats(base, ss) {
  const st = json(path.join(PROJECT, base, `shot-${ss}`, 'video', 'clip.json.status.json'));
  const task = st?.task;
  if (!task) return null;
  const dur = task.duration ?? task.usage?.total_seconds ?? null;
  const secs = task.usage?.total_seconds ?? task.duration ?? 0;
  return { status: task.status, duration: dur, cost: secs ? (secs * VIDEO_YUAN_PER_SEC) : null };
}

// ---------- 渲染商品 ----------
function renderProduct(pp) {
  const base = mediaBase(pp);
  // story
  const storyName = lsSorted(path.join(PROJECT, 'stories')).find(f => f.startsWith(pp + '-') && f.endsWith('.md'));
  const storyMd = storyName ? read(path.join(PROJECT, 'stories', storyName)) : '';
  const endingCaption = extractEndingCaption(storyMd);

  const parts = [];
  parts.push(`<section class="product" id="p-${esc(pp)}"><div class="product-head"><h2>商品 ${esc(pp)}</h2><span class="mono">${base ? esc('media base: ' + base) : '无分镜媒体'}</span></div>`);

  // 剧本
  if (storyMd) {
    parts.push(`<details class="script" open><summary>拍摄脚本 · ${esc(storyName)}</summary><div class="md">${mdToHtml(storyMd)}</div></details>`);
  } else {
    parts.push('<p class="muted">未找到拍摄脚本 md。</p>');
  }

  // hook 提示词
  const hook = exists(path.join(PROJECT, 'prompts', `${pp}-hook.json`)) ? { relPath: `prompts/${pp}-hook.json`, data: json(path.join(PROJECT, 'prompts', `${pp}-hook.json`)) } : null;
  if (hook) parts.push('<h3>Hook 提示词</h3>' + promptSection('Hook', hook));

  // masters
  const mastersDir = path.join(PROJECT, pp, 'masters');
  const masters = pngsIn(mastersDir);
  if (masters.length) {
    parts.push('<h3>母版 / 参考</h3><div class="gallery">' + masters.map(f => mediaFig(`${pp}/masters/${f}`, `${pp}/masters/${f}`)).join('') + '</div>');
  }

  // 分镜
  const shots = shotNumbers(pp, base);
  if (shots.length) {
    parts.push('<h3>逐镜</h3>');
    for (const ss of shots) {
      const shotDir = base ? path.join(PROJECT, base, `shot-${ss}`) : null;
      const imgs = shotDir ? pngsIn(path.join(shotDir, 'images')) : [];
      const vids = shotDir ? mp4sIn(path.join(shotDir, 'video')) : [];
      const stats = base ? clipStats(base, ss) : null;

      const first = promptFile(pp, ss, 'first');
      const last = promptFile(pp, ss, 'last');
      const video = promptFile(pp, ss, 'video');

      const chunks = [];
      chunks.push(`<div class="shot"><div class="shot-head"><strong>SHOT ${esc(ss)}</strong>${stats ? `<span class="badge ${stats.status === 'succeeded' ? 'ok' : 'warn'}">视频 ${esc(stats.status)}</span>` : ''}${stats?.duration != null ? `<span class="mono">${esc(stats.duration)}s</span>` : ''}${stats?.cost != null ? `<span class="mono">¥${esc(stats.cost.toFixed(2))}</span>` : ''}</div>`);

      // 提示词
      chunks.push(promptSection('首帧图片提示词', first));
      chunks.push(promptSection('尾帧图片提示词', last));
      chunks.push(promptSection('视频提示词', video));

      // 图片
      if (imgs.length) {
        chunks.push('<div class="gallery">' + imgs.map(f => mediaFig(`${base}/shot-${ss}/images/${f}`, f)).join('') + '</div>');
      } else {
        chunks.push('<p class="muted">暂无图片。</p>');
      }
      // 视频
      if (vids.length) {
        chunks.push(vids.map(f => videoTag(`${base}/shot-${ss}/video/${f}`, `${base}/shot-${ss}/video/${f}`)).join(''));
      }
      chunks.push('</div>');
      parts.push(chunks.join(''));
    }
  }

  // 成片
  const finalRel = `edit/${pp}-final.mp4`;
  if (exists(path.join(PROJECT, finalRel))) {
    // 汇总时长/成本 (来自本商品各镜 clip status)
    let totDur = 0, totCost = 0, haveStats = false;
    if (base) for (const ss of shots) { const s = clipStats(base, ss); if (s) { haveStats = true; if (s.duration) totDur += Number(s.duration); if (s.cost) totCost += s.cost; } }
    const metaBits = [];
    if (haveStats) metaBits.push(`<span class="mono">合计视频时长 ${totDur}s</span>`);
    if (haveStats) metaBits.push(`<span class="mono">合计生成成本 ¥${totCost.toFixed(2)}</span>`);
    parts.push('<h3>成片</h3>' + videoTag(finalRel, finalRel) +
      `<div class="final-meta">${metaBits.join('')}${endingCaption ? `<div class="ending"><strong>收尾字幕:</strong> ${esc(endingCaption)}</div>` : ''}</div>`);
  } else if (endingCaption) {
    parts.push(`<div class="final-meta"><div class="ending"><strong>收尾字幕(脚本已定,成片待合成):</strong> ${esc(endingCaption)}</div></div>`);
  }

  parts.push('</section>');
  return parts.join('\n');
}

// ---------- CSS (自包含,评审页独立) ----------
const CSS = `
:root{--bg:#0f1115;--panel:#171a21;--line:#2a2f3a;--fg:#e6e8ec;--mut:#8b93a1;--acc:#6ea8fe}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI","PingFang SC","Microsoft YaHei",sans-serif}
header{position:sticky;top:0;z-index:5;background:#0b0d11;border-bottom:1px solid var(--line);padding:14px 22px}
header h1{margin:0;font-size:18px}header .serve{color:var(--mut);font-size:12px;word-break:break-all}
main{max-width:1180px;margin:0 auto;padding:22px}
h2{font-size:22px;border-bottom:1px solid var(--line);padding-bottom:6px;margin-top:34px}
h3{font-size:16px;color:#cfd5df;margin-top:24px}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;color:var(--mut)}
.muted{color:var(--mut)}
table{border-collapse:collapse;width:100%;margin:12px 0;font-size:13px}
th,td{border:1px solid var(--line);padding:6px 9px;text-align:left;vertical-align:top}
th{background:#1c2128}
.task-table td:first-child{white-space:nowrap}
.status-badge,.badge{display:inline-block;padding:1px 8px;border-radius:10px;font-size:12px;font-weight:600}
.status-badge.todo{background:#3a3f4b;color:#c7ccd6}
.status-badge.assigned{background:#3a2f12;color:#ffd479}
.status-badge.review{background:#12324a;color:#7cc4ff}
.status-badge.passed{background:#13391f;color:#68d391}
.status-badge.rejected{background:#4a1420;color:#ff8095}
.badge.ok{background:#13391f;color:#68d391}
.badge.warn{background:#4a2a12;color:#ffb066}
.product{margin:30px 0;padding:0}
.product-head{display:flex;align-items:baseline;gap:14px}
details.script{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:8px 14px;margin:10px 0}
details.script summary{cursor:pointer;font-weight:600}
.md{border-top:1px solid var(--line);margin-top:8px;padding-top:8px}
.md h2,.md h3,.md h4{border:0;margin:14px 0 4px}
.md table{font-size:12.5px}
.md blockquote{border-left:3px solid var(--line);margin:6px 0;padding:2px 12px;color:var(--mut)}
.prompt-block{background:var(--panel);border:1px solid var(--line);border-radius:8px;margin:8px 0;overflow:hidden}
.prompt-head{display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:8px 12px;background:#1c2128;border-bottom:1px solid var(--line)}
pre{margin:0;padding:12px;white-space:pre-wrap;word-break:break-word;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12.5px;color:#d6dbe4}
.shot{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:12px 14px;margin:14px 0}
.shot-head{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-bottom:8px}
.shot-head strong{font-size:15px}
.gallery{display:flex;flex-wrap:wrap;gap:10px;margin:8px 0}
figure{margin:0;background:#0b0d11;border:1px solid var(--line);border-radius:8px;padding:6px}
figure img{max-width:220px;max-height:360px;display:block;border-radius:4px}
figcaption{color:var(--mut);font-size:11px;margin-top:4px;max-width:220px;word-break:break-all}
.video-wrap{margin:10px 0}
.video-wrap video{width:100%;max-width:360px;border-radius:8px;background:#000;display:block}
.video-wrap small{color:var(--mut);font-size:11px;word-break:break-all}
.final-meta{display:flex;flex-wrap:wrap;gap:14px;align-items:center;margin:8px 0}
.ending{background:#12324a;border-radius:8px;padding:6px 12px;color:#cfe6ff}
code{background:#0b0d11;padding:1px 4px;border-radius:4px;font-size:12px}
nav.toc{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0}
nav.toc a{background:#1c2128;border:1px solid var(--line);border-radius:6px;padding:4px 10px;color:var(--acc);text-decoration:none;font-size:13px}
`;

// ---------- 组装 ----------
function build() {
  fs.mkdirSync(REVIEW_DIR, { recursive: true });
  const tasks = parseTasks();
  const products = discoverProducts();
  const toc = products.map(p => `<a href="#p-${esc(p)}">商品 ${esc(p)}</a>`).join('');
  const productHtml = products.map(renderProduct).join('\n');
  const html = `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>微信视频号广告 · 项目评审</title><style>${CSS}</style></head><body>
<header><h1>微信视频号广告 (wechat-channel-ads-20260912) · 项目评审</h1><div class="serve">${esc(SERVE_URL)} · 媒体走相对路径,由 nginx 本地提供(不入库)</div></header>
<main>
<section><h2>任务台账状态</h2><p class="muted">派生自 contracts/TASKS.md(唯一协作总线)。</p>${taskPanel(tasks)}</section>
<section><h2>商品导航</h2><nav class="toc">${toc || '<span class="muted">无商品</span>'}</nav></section>
${productHtml}
</main></body></html>`;
  fs.writeFileSync(OUT, html);
  return { tasks, products };
}

const { tasks, products } = build();
console.log(`[build-review-html] wrote ${path.relative(process.cwd(), OUT)}`);
console.log(`  tasks: ${tasks.length} (${tasks.map(t => t.id + ':' + t.status).join(', ')})`);
console.log(`  products: ${products.join(', ')}`);
