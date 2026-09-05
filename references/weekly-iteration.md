# 每周数据迭代规则

## 数据输入

每周由用户提供 `data/weekly_metrics.csv`，一行代表一个素材在一个平台上的一个统计周期。至少填写：日期、平台、品类、素材 ID、Hook、证明方式、CTA、展示、3 秒停留、完播、点击和转化。未提供的数据填 0，不要估算。

## 运行

```text
python3 scripts/weekly_iterate.py \
  --input data/weekly_metrics.csv \
  --week-start 2026-08-24 \
  --output evaluation/weekly-report-2026-08-24.md \
  --update-memory \
  --clean
```

## 迭代原则

- 方向性评分只用于排序，不代表因果结论。
- 每轮优先只改变 Hook、证明方式或 CTA 中的一个变量。
- 高停留低点击：检查产品利益点、产品出现时间和落地页承接。
- 高点击低转化：检查价格、规格、证据、信任信息和购买路径。
- 新规则必须下一周用新素材复验，连续两周稳定后才进入长期品类参考。
- 使用 `--update-memory` 才会追加到 `references/learned-patterns.md`；默认只生成报告，避免误写经验库。
- 使用 `--clean` 才会删除临时文件；默认只列出候选文件。清理仅限 `tmp/`、`cache/`、`research/inbox/`、`evaluation/generated/`，且文件需超过 50MB、连续 30 天未修改；CSV、Markdown、脚本、配置和符号链接永不删除。
- 投放数据只能改变经验规则，不能覆盖合规要求；无证据的功效、比较、评价和数据仍不得使用。

## 外部资料补充

外部网站或行业案例作为“研究输入”，先记录来源、发布日期、适用平台、可迁移机制和证据等级，再决定是否写入 `references/`。外部案例不能直接当作本品牌事实，也不能替代实际投放数据。
