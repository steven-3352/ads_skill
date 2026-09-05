# Nan Studio 主题制作规范

每个主题一个独立目录。创作者只审核 `story.md`；审核通过后，执行主题目录中的 `run-curl.sh` 生成素材，再自行剪辑和发布。

## 标准结构

```text
主题编号-主题名/
├── story.md
├── references.json
├── prompts/
│   ├── character.json
│   ├── cover.json
│   ├── video-1.json
│   └── video-2.json
├── run-image-curl.sh
└── run-curl.sh
```

- `story.md`：故事主题、人物、情绪节奏、分镜、发布文案和验收标准。这里不放长 prompt。
- `references.json`：主题所需的公网参考图地址，按 `identity`、`cover`、`video-1`、`video-2` 分组；每组可以放多个地址。
- `prompts/*.json`：只保存提示词文本，不混入故事说明或 curl 命令。
- `run-image-curl.sh`：读取人物或封面提示词，调用图片接口并将 PNG 保存到公共上传目录。
- `run-curl.sh`：读取 prompt JSON，生成请求并调用接口；不需要手动复制或拼接提示词。
- 人物卡和封面图可以由脚本按需生成；视频二使用视频一最后一帧 URL 保持连续性。

## 执行约定

```bash
export DEEPKEY_API_KEY='你的新API Key'
export NAN_IMAGE_URL='人物参考图公网URL'
export NAN_LAST_FRAME_URL='视频一最后一帧公网URL' # 生成视频二前设置
./run-curl.sh character
./run-curl.sh cover
./run-curl.sh video-1
./run-curl.sh video-2
```

API Key 不写入任何文件，不提交到 Git。每个命令只执行一个提示词，输出接口原始响应，便于拿走生成结果继续剪辑发布。

## 全局制作约束

所有主题必须遵守 [Nan Studio 全局制作约束](../production-constraints.md)。其中“非商品展示”是流量红线：人物脸、眼神和关系氛围必须是画面主体；道具默认不超过画面约 10%，不得近镜、居中、特写或展示品牌、包装、价格和卖点。每个图片、封面和视频 prompt 都必须显式写入该约束。

实际生成遵守 [素材制作与确认流程](../production-workflow.md)：图片下载到公网目录并逐张确认；视频只返回 `task_id` 并逐段确认；任何被后续引用的图片必须先得到稳定公网地址。

生成视频前必须运行 `scripts/check-generation-constraints.sh <prompt.json>`。检查会拦截诱发商品/道具或人脸特写的正向措辞；硬约束只改变镜头呈现，不得删改故事的对白、情绪因果或必要动作。
