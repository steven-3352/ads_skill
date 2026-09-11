import fs from 'node:fs';
import path from 'node:path';
const root=path.dirname(new URL(import.meta.url).pathname), review=path.join(root,'review');
fs.mkdirSync(review,{recursive:true});
const shell=(title,shot='')=>'<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><link rel="stylesheet" href="../../_review-assets/style.css"></head><body data-shot="'+shot+'"><main id="app">加载中…</main><script src="template.js"></script></body></html>';
fs.writeFileSync(path.join(review,'index.html'),shell('《虾壳》项目首页'));
for(let i=1;i<=8;i++){const n=String(i).padStart(2,'0');fs.writeFileSync(path.join(review,'shot-'+n+'.html'),shell('分镜'+n+' · 虾壳',n));}
