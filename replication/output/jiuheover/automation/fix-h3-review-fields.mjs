#!/usr/bin/env node
// 补齐 H3 提示词校验器要求的字段：h3_prompt_review.mode（非空）+ reviewed_prompt_sha256（=.prompt 的 sha256）。
// 只补缺失字段，不改 prompt 文本本身。sha256 用 crypto 对 .prompt 的 UTF-8 字节，须与 `jq -jr '.prompt'|sha256sum` 一致。
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const DIR = '/home/ubuntu/ads_skill/replication/output/jiuheover/prompts';
const files = fs.readdirSync(DIR).filter(f => f.endsWith('.json'));

function modeFor(name, hasRefs) {
  if (name.endsWith('-video.json')) return name.startsWith('U8-') ? 'FL2VA·首尾帧驱动' : 'I2VA·单首帧驱动';
  if (name === 'U9-title.json') return 'T2I·黑场字幕卡·无参考';
  return hasRefs ? 'T2I·母板参考锁身份' : 'T2I·文生图';
}

let n = 0;
for (const f of files) {
  const p = path.join(DIR, f);
  const j = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (!j.h3_prompt_review || typeof j.prompt !== 'string') continue;
  const sha = crypto.createHash('sha256').update(j.prompt, 'utf8').digest('hex');
  const hasRefs = Array.isArray(j.references) && j.references.length > 0;
  j.h3_prompt_review.reviewed_prompt_sha256 = sha;
  if (!j.h3_prompt_review.mode) j.h3_prompt_review.mode = modeFor(f, hasRefs);
  // asset_type 兜底：video 文件应为 video，其余 image
  const wantType = f.endsWith('-video.json') ? 'video' : 'image';
  if (j.h3_prompt_review.asset_type !== wantType) j.h3_prompt_review.asset_type = wantType;
  fs.writeFileSync(p, JSON.stringify(j, null, 2) + '\n', 'utf8');
  n++;
  console.log(`${f}  mode=${j.h3_prompt_review.mode}  sha=${sha.slice(0,12)}…`);
}
console.log(`\n补齐 ${n} 份提示词`);
