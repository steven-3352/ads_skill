# Nan Studio 素材制作与确认流程

本流程适用于所有主题。

1. 创作者先审核主题目录中的 `story.md`。
2. 生成一张人物母图，下载到 `/home/ubuntu/tonbirds-studio/public/uploads/1/user_upload/image/`，返回公网地址并等待确认。
3. 人物确认后，将公网地址写入该主题的 `references.json`，再生成封面；封面同样下载到公网目录，返回地址并等待确认。
4. 封面确认后，提交 `video-1`。视频不下载，只返回并记录接口 `task_id`，等待确认。
5. 若主题包含 `video-2`，先从视频一提取最后一帧并放到公网目录，返回末帧地址等待确认；确认后再提交视频二。
6. 视频二必须同时引用人物图和视频一末帧。其他被后续步骤引用的图片也必须先保存到公网目录。
7. 未经过当前素材确认，不自动执行下一步；被拒绝的素材不写入正式参考配置。
8. API Key 只从环境变量读取，不写入文档、提示词、日志或 Git。

公网映射：

```text
/home/ubuntu/tonbirds-studio/public/uploads/1/user_upload/image/<文件名>
https://www.tonbird.top/uploads/1/user_upload/image/<文件名>
```
