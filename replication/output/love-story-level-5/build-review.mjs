import fs from 'node:fs';
import path from 'node:path';
const root=path.dirname(new URL(import.meta.url).pathname), review=path.join(root,'review'); fs.mkdirSync(review,{recursive:true});
const esc=s=>String(s).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
const shell=(title,body)=>`<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><link rel="stylesheet" href="../../../_review-assets/style.css"></head><body><main>${body}</main></body></html>`;
const nav='<nav><a href="index.html">《虾壳》项目首页</a></nav>';
const story=fs.readFileSync(path.join(root,'01-虾壳.md'),'utf8');
for(let i=1;i<=8;i++){const n=String(i).padStart(2,'0');fs.writeFileSync(path.join(review,`shot-${n}.html`),shell(`分镜${n} · 虾壳`,`${nav}<h1>分镜 ${n}</h1><p>当前阶段：待完成剧本与分镜契约。</p><h2>原始故事</h2><pre>${esc(story)}</pre><h2>图片</h2><p>空</p><h2>视频</h2><p>未解锁</p><h2>提示词</h2><p>空</p>`));}
const cards=Array.from({length:8},(_,i)=>{const n=String(i+1).padStart(2,'0');return `<li><a href="shot-${n}.html">分镜 ${n}</a>：契约未建立 · 图片空 · 视频未解锁</li>`}).join('');
fs.writeFileSync(path.join(review,'index.html'),shell('《虾壳》项目首页',`${nav}<h1>《虾壳》</h1><p>新项目，已收到用户原故事。当前等待多轮对话补全 Brief。</p><h2>项目状态</h2><p>dialogue_pending</p><h2>原故事</h2><pre>${esc(story)}</pre><h2>公共基础资产</h2><p>空（尚未提取与确认）</p><h2>分镜</h2><ul>${cards}</ul><p><a href="../EXECUTION.md">执行清单 EXECUTION.md</a></p>`));
