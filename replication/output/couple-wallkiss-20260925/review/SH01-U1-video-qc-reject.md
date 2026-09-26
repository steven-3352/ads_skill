# 视频语义QC — SH01-U1-video（第1次生成·reject）

- 结论：reject（管线缺陷致废片，已定位根因并修复，重生成）
- 证据：status.json 显示 `input_image_count: 0` —— H3 未收到任何输入图。

## 问题
1. **首帧未挂进管线**：视频 prompt 缺 `.images` 字段，generate-video.sh 无图可传 → 纯文生视频。H3 自行脑补人物：男主变成偏老方脸炸毛头（非母板 26 岁清爽男主）、女主换成白色短袖（首帧为米色针织）、构图偏离首帧（正面对峙 vs 背身抱臂）。身份/服装/构图全漂。
2. **H3 烧字幕**：2.5s/3.5s 帧底部烧录"别生气了我错了好不好"，违反成片零字幕（prompt 已含 anti-subtitle，属 H3 非确定性烧字）。

## 修复
- 给 5 个视频 prompt 补 `.images`（帧族驱动：I2VA 挂首帧 / FL2VA 挂首尾帧），`.images` 为 `.prompt` 兄弟字段不改串、sha256 不变、评审门仍过。
- 重生成 SH01 作 canary-2，复查 input_image_count≥1 + 无烧字幕 + 身份对齐母板。
