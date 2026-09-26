# U3-last-r2 在途中断复位记录(response 截断损坏 → 复位重生)

- **资产**: U3-last-r2(FL2VA 尾帧返修版)
- **时间线**:
  - 2026-09-21T15:56 POST 已发起(submission.locked 建立、lifecycle=submitting)。
  - run.sh 被 115s timeout + 工具内部错误打断,进程在写 response 途中被杀。
  - response.json 截断损坏(b64 中途结束、JSON 未闭合,jq/python 均无法解码),无有效 PNG 产物,无 task_id(gpt-image images/edits 同步接口)。
- **计费判断**: 同步图像接口被中断,provider 侧计费未观测到(无完整成功回执);理论上有极小计费可能,如实留痕。paid-state 中 submitting 从未 += committed(见 orchestrator L112-117 仅追加事件),故复位不退款、不减 committed,committed 保持不变。
- **证据处置**: 损坏的 response 已归档为 `response.json.truncated-corrupt` 保留,目录内无有效 response,满足 reconcile-submitting 前置(无已确认结果)。
- **处置**: reconcile-submitting 复位 U3-last-r2 → ready → 重新干净生成(充足超时、后台执行)。
- **reviewer**: human-canary-review(编排把关代记)
