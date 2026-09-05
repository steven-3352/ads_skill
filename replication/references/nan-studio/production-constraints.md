# Nan Studio 全局制作约束

本文件适用于所有主题、故事、人物图、封面和视频提示词。

## 内容与构图优先级

**情绪价值 > 台词语言 > 眼神与微表情 > 环境氛围 > 简单剧情动作 > 道具 > 复杂动作。**

## 非商品展示

- 所有图片和视频以人物情绪为主体，道具仅作为叙事线索。
- 杯子、雨伞、手机、礼物、食品、服饰配件等单个道具默认不超过画面约 10%。
- 道具不贴近镜头、不居中陈列、不单独特写、不旋转展示，不使用商品摄影式景深和打光。
- 不出现品牌、包装正面、标签、价格、规格、口味、功能卖点、购买引导或可读商品文字。
- 封面、首帧和情绪高潮必须先看到人物脸、眼神或关系动作，不能先看到物品。
- 只有当道具是不可替代的剧情信息时才能短暂突出；随后必须立即回到人物反应，并在 `story.md` 说明必要性。
- 验收时若第一眼先看到物品而不是人物关系，该画面不通过。
- 每个图片和视频提示词固定加入：`Human-first composition. The face, direct eye contact and micro-expressions are the visual focus. Props are small, unbranded, de-emphasized story details occupying less than about 10 percent of the frame. No product-focused framing, product close-up, package display, readable label, price, feature demonstration or commercial lighting.`

## 生成前硬约束检查（不可被故事动作覆盖）

- 视频默认使用稳定中景或中远景；人物脸保持完整头肩/上半身关系构图，不做脸部、眼睛、嘴唇或皮肤纹理特写，不使用 `tight close-up`、`face fills the frame`、`close view` 等镜头指令。
- 商品和道具只能作为画面边缘的小型叙事线索（默认小于 5%，上限 10%），不得出现道具插入镜头、物件特写、镜头朝道具移动、镜头看道具、把道具放到镜头前或推向镜头。
- 正向镜头动作不得与上述规则冲突；“不要特写”不能抵消“镜头看伞/杯子”“放到镜头前”等诱发特写的措辞，冲突时必须删除正向诱因后才能提交。
- 生成脚本提交前必须运行 `scripts/check-generation-constraints.sh <prompt-file>`；检查失败不得调用视频接口。

## 动作复杂度

- 一个镜头只做一个主要动作。
- 无必要不拍穿衣、开门、倒水、翻包、撑伞、快速走路或连续交接。
- 能用物品已在手上、人物已到位置解决，就不生成完整过程。
- 情绪变化主要通过台词、停顿、眼神、呼吸、眉眼、嘴角和轻微镜头移动表达。

## 真人画面质感

- 保留毛孔、肤色不均、眼下细纹、胡茬、自然油光、湿润眼神和方向性阴影。
- 禁止 beauty filter、airbrushed skin、waxy skin、plastic skin、porcelain face、CGI render 和 perfect symmetry。
