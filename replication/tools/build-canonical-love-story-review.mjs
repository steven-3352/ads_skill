import fs from 'node:fs';
import path from 'node:path';

const root=path.resolve('replication/output/love-story-level-5');
const review=path.join(root,'review');
const beats=JSON.parse(fs.readFileSync(path.join(root,'contracts/story-beats.json'),'utf8'));
const shots=JSON.parse(fs.readFileSync(path.join(root,'contracts/shots.json'),'utf8')).shots;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const css='../../_review-assets/style.css';
const shell=(title,body)=>`<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(title)}</title><link rel="stylesheet" href="${css}"></head><body><header><a class="brand" href="../../index.html">Production Review</a><span>当前契约版本</span></header><main>${body}</main></body></html>`;
const empty=(label)=>`<div class="empty"><strong>${esc(label)}</strong></div>`;
const nav='<nav><a href="../../index.html">全部项目</a> · <a href="index.html">《虾壳》首页</a></nav>';
const beatRows=beats.beats.map(b=>`<tr><td>${esc(b.id)}</td><td>${esc(b.text)}</td><td>${esc(b.carrier)}</td><td>${esc(b.evidence)}</td></tr>`).join('');
let cards='';
for(const s of shots){
 const ids=s.beats.join('、');
 cards+=`<a class="shot-card" href="shot-${s.id}.html"><span>SHOT ${s.id}</span><strong>节拍 ${esc(ids)}</strong><small>契约已建立 · 图片空 · 视频空 · 待前置确认</small></a>`;
 const beatText=beats.beats.filter(b=>s.beats.includes(b.id)).map(b=>`<li><b>${esc(b.id)}</b> ${esc(b.text)}<br><small>证据：${esc(b.evidence)}</small></li>`).join('');
 const body=`${nav}<section class="shot-head"><div><p class="eyebrow">SHOT ${s.id}</p><h1>分镜 ${s.id}</h1><p>当前版本只展示契约内容，未通过图片闸门前不生成视频。</p></div><div class="status warn">图片空 · 视频空</div></section><section><h2>原始故事节拍</h2><ul>${beatText}</ul></section><section><h2>动作契约</h2><dl><dt>分镜决策</dt><dd>${esc(s.decision)}</dd><dt>图片闸门</dt><dd>${esc(s.image_gate)}</dd><dt>视频生成</dt><dd>generation_allowed = ${esc(s.generation_allowed)}</dd><dt>首帧</dt><dd>${empty('空')}</dd><dt>尾帧</dt><dd>${empty('空')}</dd><dt>视频</dt><dd>${empty('空')}</dd></dl></section><section><h2>提示词槽位</h2>${empty('当前版本尚未锁定提示词；需先完成分镜动作契约与图片验证')}</section><section><h2>引用资源</h2>${empty('本分镜暂无已绑定引用资源')}</section><footer><a href="shot-${String(Math.max(1,Number(s.id)-1)).padStart(2,'0')}.html">上一镜</a><a href="shot-${String(Math.min(8,Number(s.id)+1)).padStart(2,'0')}.html">下一镜</a></footer>`;
 fs.writeFileSync(path.join(review,`shot-${s.id}.html`),shell(`分镜${s.id} · 虾壳`,body));
}
const home=`${nav}<section class="intro compact"><p class="eyebrow">PROJECT · CURRENT CONTRACT</p><h1>《虾壳》</h1><p>当前唯一有效版本。旧页面、旧提示词和旧生成结果不作为本版本生产依据。</p></section><section><h2>原故事</h2><pre class="story">${esc(fs.readFileSync(path.join(root,'01-虾壳.md'),'utf8'))}</pre></section><section><h2>故事节拍契约</h2><table><thead><tr><th>编号</th><th>节拍</th><th>承载</th><th>图片可验证证据</th></tr></thead><tbody>${beatRows}</tbody></table></section><section><h2>公共基础资产</h2><p>人物、道具、背景等契约见 <code>contracts/assets.json</code>；当前页面只列公共基础资产，不列分镜生成产物。</p></section><section><h2>分镜页面</h2><div class="shot-grid">${cards}</div></section><section><h2>手工执行</h2><p><a href="../EXECUTION.md">打开 EXECUTION.md</a>。执行命令完成后先更新契约，再刷新本页面。</p></section>`;
fs.writeFileSync(path.join(review,'index.html'),shell('《虾壳》当前契约',home));
