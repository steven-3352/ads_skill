# U3-first 语义否决记录（倒酒物理不符 → 改 FL2VA 双帧）

- **资产**: U3-first（output: shots/shot-U3/images/U3-first.png，cost ¥0.25 已花，沉没）
- **审阅方式**: 人工业务审阅（公网 https://www.tonbird.top/ads-review/jiuheover/review/index.html）
- **否决理由（用户指令）**: U3 是唯一双人立局·倒酒镜；用户指出「倒酒时不能出现红色瓶盖。红色瓶盖是盖子，倒酒时要打开的」。原 U3-first 为 I2VA 单首帧、瓶口红盖盖着，让视频去演「拧盖+倒酒」两个状态变化，H3 演精细拧盖易穿帮（盖凭空消失/手畸形/盖着还倒）。
- **用户裁决（业务）**: 升级为 FL2VA 双帧（首帧+尾帧），用静态帧状态把「拧盖」消化掉，视频只演倒酒→推杯→放瓶，禁止镜内拧盖。
- **补救**:
  - U3 由 I2VA 单首帧改为 FL2VA 首尾帧驱动（plan images 加 U3-last；U3-video mode=FL2VA·首尾帧驱动）。
  - 首帧 U3-first-r2：陈叙执瓶将倒、红盖已拧开单独搁桌旁、瓶口敞开、正倒第一杯。
  - 尾帧 U3-last：两杯倒满、一杯推给苏晚、瓶直立放回、红盖始终搁桌旁没盖回。
  - 视频显式禁止拧瓶盖/开瓶盖动作，音效删「起瓶盖轻响」改「放瓶轻响」。
  - 三个提示词由独立子 agent 重写并盖章，validate-h3-prompt-review.sh 三文件均 exit 0。
- **处置**: reject 本 U3-first 留痕 → 授权 U3-first-r2 + U3-last 重生（FL2VA 双帧）→ 生成后人工审阅公网首尾帧 → accept 后 supersede U3-first by U3-first-r2。
- **reviewer**: human-canary-review（用户业务裁决，编排代记）
