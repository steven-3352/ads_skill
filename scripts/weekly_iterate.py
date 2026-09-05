#!/usr/bin/env python3
"""Generate a weekly creative-performance review from user-supplied CSV data."""

import argparse
import csv
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path
import time


REQUIRED = {
    "date", "platform", "category", "creative_id", "hook", "proof", "cta",
    "impressions", "views_3s", "completes", "clicks", "conversions",
}


def number(row, key):
    try:
        return float(row.get(key, 0) or 0)
    except (TypeError, ValueError):
        return 0.0


def rate(value, base):
    return value / base if base else 0.0


def pct(value):
    return f"{value * 100:.2f}%"


def load_rows(path, start, end):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            raise ValueError("CSV 缺少字段: " + ", ".join(sorted(missing)))
        rows = []
        for row in reader:
            try:
                day = date.fromisoformat(row["date"])
            except ValueError:
                continue
            if start <= day <= end:
                row["_day"] = day
                rows.append(row)
        return rows


def aggregate(rows):
    total = defaultdict(float)
    groups = defaultdict(lambda: defaultdict(float))
    for row in rows:
        keys = ["all", row["platform"], row["category"]]
        for key in keys:
            for metric in ("impressions", "views_3s", "completes", "clicks", "conversions"):
                groups[key][metric] += number(row, metric)
        total["impressions"] += number(row, "impressions")
    return groups


def score(row):
    """Directional score; use for ranking, not as a causal attribution claim."""
    return (
        rate(number(row, "views_3s"), number(row, "impressions")) * 0.35
        + rate(number(row, "completes"), number(row, "impressions")) * 0.25
        + rate(number(row, "clicks"), number(row, "impressions")) * 0.25
        + rate(number(row, "conversions"), number(row, "clicks")) * 0.15
    )


SAFE_CLEAN_DIRS = {"tmp", "cache", "research/inbox", "evaluation/generated"}
PROTECTED_SUFFIXES = {".csv", ".md", ".py", ".yaml", ".yml", ".json"}


def cleanup(root, max_mb, older_days, delete=False):
    """Clean only allow-listed temporary directories; never follow symlinks."""
    cutoff = time.time() - older_days * 86400
    max_bytes = max_mb * 1024 * 1024
    candidates = []
    for relative_dir in SAFE_CLEAN_DIRS:
        directory = root / relative_dir
        if not directory.is_dir():
            continue
        for path in directory.rglob("*"):
            if not path.is_file() or path.is_symlink():
                continue
            if path.suffix.lower() in PROTECTED_SUFFIXES:
                continue
            stat = path.stat()
            if stat.st_size >= max_bytes and stat.st_mtime <= cutoff:
                candidates.append((path, stat.st_size))
    for path, _ in candidates:
        if delete:
            path.unlink()
    return candidates


def report(rows, start, end):
    groups = aggregate(rows)
    lines = [f"# 广告创意周迭代报告（{start} 至 {end}）", "", "## 数据概况", ""]
    lines.append(f"- 纳入素材：{len(rows)} 条")
    if not rows or sum(number(row, "impressions") for row in rows) <= 0:
        lines.append("- 本周期没有有效展示数据，请补充真实投放数据后重新运行。")
        return "\n".join(lines) + "\n"

    all_stats = groups["all"]
    lines += [
        f"- 展示：{all_stats['impressions']:.0f}",
        f"- 3 秒停留率：{pct(rate(all_stats['views_3s'], all_stats['impressions']))}",
        f"- 完播率：{pct(rate(all_stats['completes'], all_stats['impressions']))}",
        f"- 点击率：{pct(rate(all_stats['clicks'], all_stats['impressions']))}",
        f"- 点击后转化率：{pct(rate(all_stats['conversions'], all_stats['clicks']))}",
        "",
        "## 平台与品类信号",
        "",
        "| 分组 | 3 秒停留率 | 完播率 | 点击率 | 点击后转化率 |",
        "|---|---:|---:|---:|---:|",
    ]
    for key in sorted(k for k in groups if k != "all"):
        stats = groups[key]
        lines.append(
            f"| {key} | {pct(rate(stats['views_3s'], stats['impressions']))} | "
            f"{pct(rate(stats['completes'], stats['impressions']))} | "
            f"{pct(rate(stats['clicks'], stats['impressions']))} | "
            f"{pct(rate(stats['conversions'], stats['clicks']))} |"
        )

    ranked = sorted(rows, key=score, reverse=True)
    lines += ["", "## 本周表现较好的创意组件", ""]
    lines.append("| 素材 | 平台 | 品类 | Hook | 证明方式 | CTA | 方向性评分 |")
    lines.append("|---|---|---|---|---|---|---:|")
    for row in ranked[:5]:
        lines.append(
            f"| {row['creative_id']} | {row['platform']} | {row['category']} | "
            f"{row['hook']} | {row['proof']} | {row['cta']} | {score(row):.4f} |"
        )

    lines += ["", "## 下周迭代建议", "", "### 保留并放大", ""]
    best = ranked[0]
    lines.append(f"- 优先保留 `{best['hook']}` 这一类开场，沿用 `{best['proof']}` 证明方式；先只替换一个变量。")
    lines += ["", "### 需要验证", "", "- 分别测试 Hook、证明方式和 CTA，避免同一轮同时改变多个变量。",
              "- 对高停留低点击素材，优先检查产品出现时间、利益点清晰度和落地页承接。",
              "- 对高点击低转化素材，检查商品页价格、规格、证据和购买路径。",
              "- 样本不足时只记录为方向性信号，不把相关性写成因果结论。", "",
              "## 规则沉淀（供下周 Skill 使用）", "",
              f"- 推荐平台：{best['platform']}",
              f"- 推荐品类：{best['category']}",
              f"- 候选 Hook：{best['hook']}",
              f"- 候选证明：{best['proof']}",
              f"- 候选 CTA：{best['cta']}",
              "- 以上为本周数据产生的候选规则，下一周需用新素材复验后再长期采纳。", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="生成广告创意周迭代报告")
    parser.add_argument("--input", required=True, type=Path, help="用户填写的 CSV 数据")
    parser.add_argument("--week-start", required=True, type=date.fromisoformat)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--update-memory", action="store_true", help="将本周最佳组件追加到经验记忆")
    parser.add_argument("--memory", type=Path, default=Path("references/learned-patterns.md"))
    parser.add_argument("--clean", action="store_true", help="删除允许范围内过大且长期未使用的临时文件")
    parser.add_argument("--max-mb", type=float, default=50, help="清理文件大小阈值，默认 50MB")
    parser.add_argument("--older-days", type=int, default=30, help="文件至少多少天未修改，默认 30 天")
    args = parser.parse_args()
    end = args.week_start + timedelta(days=6)
    rows = load_rows(args.input, args.week_start, end)
    output = args.output or Path(f"weekly-report-{args.week_start.isoformat()}.md")
    output.write_text(report(rows, args.week_start, end), encoding="utf-8")
    if args.update_memory and rows and sum(number(row, "impressions") for row in rows) > 0:
        best = max(rows, key=score)
        args.memory.parent.mkdir(parents=True, exist_ok=True)
        if not args.memory.exists():
            args.memory.write_text(
                "# 已验证的创意规律\n\n这里只记录由实际数据产生、仍需复验的候选规律。\n",
                encoding="utf-8",
            )
        with args.memory.open("a", encoding="utf-8") as stream:
            stream.write(
                f"\n## {args.week_start.isoformat()} 周候选规律\n"
                f"- 平台/品类：{best['platform']} / {best['category']}\n"
                f"- Hook：{best['hook']}\n"
                f"- 证明方式：{best['proof']}\n"
                f"- CTA：{best['cta']}\n"
                f"- 素材：{best['creative_id']}；方向性评分：{score(best):.4f}\n"
                "- 状态：候选，至少下一周复验一次后再固化。\n"
            )
    candidates = cleanup(Path.cwd(), args.max_mb, args.older_days, delete=args.clean)
    if candidates:
        action = "已删除" if args.clean else "待清理"
        print(f"{action}临时文件 {len(candidates)} 个（阈值 {args.max_mb:g}MB，超过 {args.older_days} 天）")
        if not args.clean:
            for path, size in candidates:
                print(f"  - {path} ({size / 1024 / 1024:.1f}MB)")
    print(f"已生成：{output}（{len(rows)} 条素材）")


if __name__ == "__main__":
    main()
