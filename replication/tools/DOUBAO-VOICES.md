# 豆包语音(火山 openspeech)音色目录 · 参考

> 配合公共工具 `replication/tools/generate-speech.sh`：音色 ID 填 `--speaker <voice_type>`（或 JSON `.speaker`）。
> 录入日期 2026-09-17，来源：官方在线音色列表（用户提供）。ID 会随版本增减，以官方页为准。
> 官方页：docs.volcengine.com/docs/6561/1257544 与 /6561/97465。

## 用哪一组 ID？
- 本工具默认 `model=seed-audio-1.0`，端点 `/api/v3/tts/create`，`speaker` 字段**吃「豆包语音合成模型2.0」音色**（`*_uranus_bigtts` 与 `ICL_uranus_*_tob`）或声音复刻音色。→ **优先用下方「模型2.0」表。**
- `*_mars_bigtts` / `*_moon_bigtts` 属「模型1.0」；`*_jupiter_bigtts` / `saturn_*` 属端到端实时 S2S。这两组走各自模型/端点，附在文末备查。
- 2.0 音色多为「指令遵循」：情感/语气用自然语言写进 `text_prompt` 即可（如「用温柔害羞的语气说：……」）。中文音色多兼具英文能力，但纯英文场景更推荐英文音色。
- 已证：seed-audio 必带 `X-Api-Resource-Id: volc.service_type.10074`（工具已默认）；计费按 `original_duration`（≤120s）；原始电平偏低（mean≈-38dB），后期 loudnorm 归一。

## ★ 本项目(甜美/雀跃/心旷神怡)选角建议
- 女声：甜美小源 `zh_female_tianmeixiaoyuan_uranus_bigtts`、甜美桃子 `zh_female_tianmeitaozi_uranus_bigtts`、甜美悦悦 `zh_female_tianmeiyueyue_uranus_bigtts`、邻家女孩 `zh_female_linjianvhai_uranus_bigtts`、元气甜妹 `ICL_uranus_zh_female_yuanqitianmei_tob`、清新女声 `zh_female_qingxinnvsheng_uranus_bigtts`、初恋女友 `ICL_uranus_zh_female_chuliannvyou_tob`。
- 男声：邻家男孩 `zh_male_linjiananhai_uranus_bigtts`、阳光青年 `zh_male_yangguangqingnian_uranus_bigtts`、温柔小哥 `zh_male_wenrouxiaoge_uranus_bigtts`、温柔男友 `ICL_uranus_zh_male_wenrounanyou_tob`、清爽男大 `zh_male_qingshuangnanda_uranus_bigtts`、活力小哥 `zh_male_huolixiaoge_uranus_bigtts`。
- 亿万合唱可批量取多个不同音色 + 每条改 `--speaker` 与轻微 speech_rate/pitch，得真·多音色层叠。

---

# 一、模型2.0 音色（seed-audio `speaker` 主用）

## 1.1 中文·通用/角色/配音等（`*_uranus_bigtts`）
| 音色名 | voice_type | 场景 | 备注 |
|---|---|---|---|
| Vivi 2.0 | zh_female_vv_uranus_bigtts | 通用/S2S主打 | 多语种+粤/沪/豫/京/津/川/陕/东北方言 |
| 小何 2.0 | zh_female_xiaohe_uranus_bigtts | 通用/S2S主打 | 中文+八方言 |
| 云舟 2.0 | zh_male_m191_uranus_bigtts | 通用/S2S主打 | 中文+八方言 |
| 小天 2.0 | zh_male_taocheng_uranus_bigtts | 通用/S2S主打 | 中文+八方言 |
| 刘飞 2.0 | zh_male_liufei_uranus_bigtts | 通用 | |
| 魅力苏菲 2.0 | zh_female_sophie_uranus_bigtts | 通用 | |
| 清新女声 2.0 | zh_female_qingxinnvsheng_uranus_bigtts | 通用 | |
| 知性灿灿 2.0 | zh_female_cancan_uranus_bigtts | 角色扮演 | |
| 撒娇学妹 2.0 | zh_female_sajiaoxuemei_uranus_bigtts | 角色扮演 | |
| 甜美小源 2.0 | zh_female_tianmeixiaoyuan_uranus_bigtts | 通用 | |
| 甜美桃子 2.0 | zh_female_tianmeitaozi_uranus_bigtts | 通用 | |
| 爽快思思 2.0 | zh_female_shuangkuaisisi_uranus_bigtts | 通用 | |
| 佩奇猪 2.0 | zh_female_peiqi_uranus_bigtts | 视频配音 | 抖音/豆包/剪映同款 |
| 邻家女孩 2.0 | zh_female_linjianvhai_uranus_bigtts | 通用 | |
| 少年梓辛 2.0 | zh_male_shaonianzixin_uranus_bigtts | 通用 | |
| 猴哥 2.0 | zh_male_sunwukong_uranus_bigtts | 视频配音 | |
| Tina老师 2.0 | zh_female_yingyujiaoxue_uranus_bigtts | 教育 | 中文+英式英语 |
| 暖阳女声 2.0 | zh_female_kefunvsheng_uranus_bigtts | 客服 | |
| 儿童绘本 2.0 | zh_female_xiaoxue_uranus_bigtts | 有声阅读 | |
| 大壹 2.0 | zh_male_dayi_uranus_bigtts | 视频配音 | |
| 黑猫侦探社咪仔 2.0 | zh_female_mizai_uranus_bigtts | 视频配音 | |
| 鸡汤女 2.0 | zh_female_jitangnv_uranus_bigtts | 视频配音 | |
| 魅力女友 2.0 | zh_female_meilinvyou_uranus_bigtts | 通用 | |
| 流畅女声 2.0 | zh_female_liuchangnv_uranus_bigtts | 视频配音 | |
| 儒雅逸辰 2.0 | zh_male_ruyayichen_uranus_bigtts | 视频配音 | |
| 温柔妈妈 2.0 | zh_female_wenroumama_uranus_bigtts | 通用 | |
| 解说小明 2.0 | zh_male_jieshuoxiaoming_uranus_bigtts | 通用 | |
| TVB女声 2.0 | zh_female_tvbnv_uranus_bigtts | 通用 | |
| 译制片男 2.0 | zh_male_yizhipiannan_uranus_bigtts | 通用 | |
| 俏皮女声 2.0 | zh_female_qiaopinv_uranus_bigtts | 通用 | |
| 直率英子 2.0 | zh_female_zhishuaiyingzi_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 邻家男孩 2.0 | zh_male_linjiananhai_uranus_bigtts | 通用 | |
| 四郎 2.0 | zh_male_silang_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 儒雅青年 2.0 | zh_male_ruyaqingnian_uranus_bigtts | 通用 | 番茄/豆包/剪映同款 |
| 擎苍 2.0 | zh_male_qingcang_uranus_bigtts | 角色扮演 | 番茄/豆包/抖音/剪映同款 |
| 熊二 2.0 | zh_male_xionger_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 樱桃丸子 2.0 | zh_female_yingtaowanzi_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 温暖阿虎 2.0 | zh_male_wennuanahu_uranus_bigtts | 通用 | |
| 奶气萌娃 2.0 | zh_male_naiqimengwa_uranus_bigtts | 通用 | 剪映/豆包同款 |
| 婆婆 2.0 | zh_female_popo_uranus_bigtts | 通用 | 抖音/豆包/剪映同款 |
| 高冷御姐 2.0 | zh_female_gaolengyujie_uranus_bigtts | 通用 | |
| 傲娇霸总 2.0 | zh_male_aojiaobazong_uranus_bigtts | 通用 | |
| 懒音绵宝 2.0 | zh_male_lanyinmianbao_uranus_bigtts | 角色扮演 | |
| 反卷青年 2.0 | zh_male_fanjuanqingnian_uranus_bigtts | 通用 | |
| 温柔淑女 2.0 | zh_female_wenroushunv_uranus_bigtts | 通用 | 番茄/豆包/剪映同款 |
| 古风少御 2.0 | zh_female_gufengshaoyu_uranus_bigtts | 角色扮演 | |
| 活力小哥 2.0 | zh_male_huolixiaoge_uranus_bigtts | 通用 | |
| 霸气青叔 2.0 | zh_male_baqiqingshu_uranus_bigtts | 有声阅读 | 番茄/豆包/剪映同款 |
| 悬疑解说 2.0 | zh_male_xuanyijieshuo_uranus_bigtts | 有声阅读 | 抖音/豆包/剪映同款 |
| 萌丫头 2.0 | zh_female_mengyatou_uranus_bigtts | 通用 | |
| 贴心女声 2.0 | zh_female_tiexinnvsheng_uranus_bigtts | 通用 | |
| 鸡汤妹妹 2.0 | zh_female_jitangmei_uranus_bigtts | 通用 | 抖音/豆包同款 |
| 磁性解说男声 2.0 | zh_male_cixingjieshuonan_uranus_bigtts | 通用 | 抖音/剪映同款 |
| 亮嗓萌仔 2.0 | zh_male_liangsangmengzai_uranus_bigtts | 通用 | |
| 开朗姐姐 2.0 | zh_female_kailangjiejie_uranus_bigtts | 通用 | |
| 高冷沉稳 2.0 | zh_male_gaolengchenwen_uranus_bigtts | 通用 | 猫箱同款 |
| 深夜播客 2.0 | zh_male_shenyeboke_uranus_bigtts | 通用 | |
| 鲁班七号 2.0 | zh_male_lubanqihao_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 娇喘女声 2.0 | zh_female_jiaochuannv_uranus_bigtts | 通用 | 抖音/剪映同款 |
| 林潇 2.0 | zh_female_linxiao_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 玲玲姐姐 2.0 | zh_female_lingling_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 春日部姐姐 2.0 | zh_female_chunribu_uranus_bigtts | 角色扮演 | 抖音/豆包/剪映同款 |
| 唐僧 2.0 | zh_male_tangseng_uranus_bigtts | 角色扮演 | 抖音/豆包同款 |
| 庄周 2.0 | zh_male_zhuangzhou_uranus_bigtts | 角色扮演 | 抖音/剪映同款 |
| 开朗弟弟 2.0 | zh_male_kailangdidi_uranus_bigtts | 通用 | 抖音/剪映同款 |
| 猪八戒 2.0 | zh_male_zhubajie_uranus_bigtts | 角色扮演 | 豆包/剪映同款 |
| 感冒电音姐姐 2.0 | zh_female_ganmaodianyin_uranus_bigtts | 角色扮演 | 抖音/剪映同款 |
| 谄媚女声 2.0 | zh_female_chanmeinv_uranus_bigtts | 通用 | 抖音/剪映同款 |
| 女雷神 2.0 | zh_female_nvleishen_uranus_bigtts | 角色扮演 | 剪映/豆包同款 |
| 亲切女声 2.0 | zh_female_qinqienv_uranus_bigtts | 通用 | 豆包同款 |
| 快乐小东 2.0 | zh_male_kuailexiaodong_uranus_bigtts | 通用 | 豆包同款 |
| 开朗学长 2.0 | zh_male_kailangxuezhang_uranus_bigtts | 通用 | 豆包同款 |
| 悠悠君子 2.0 | zh_male_youyoujunzi_uranus_bigtts | 通用 | 豆包同款 |
| 文静毛毛 2.0 | zh_female_wenjingmaomao_uranus_bigtts | 通用 | 豆包同款 |
| 知性女声 2.0 | zh_female_zhixingnv_uranus_bigtts | 通用 | |
| 清爽男大 2.0 | zh_male_qingshuangnanda_uranus_bigtts | 通用 | 豆包同款 |
| 渊博小叔 2.0 | zh_male_yuanboxiaoshu_uranus_bigtts | 通用 | |
| 阳光青年 2.0 | zh_male_yangguangqingnian_uranus_bigtts | 通用 | |
| 清澈梓梓 2.0 | zh_female_qingchezizi_uranus_bigtts | 通用 | |
| 甜美悦悦 2.0 | zh_female_tianmeiyueyue_uranus_bigtts | 通用 | |
| 心灵鸡汤 2.0 | zh_female_xinlingjitang_uranus_bigtts | 通用 | |
| 温柔小哥 2.0 | zh_male_wenrouxiaoge_uranus_bigtts | 通用 | |
| 柔美女友 2.0 | zh_female_roumeinvyou_uranus_bigtts | 通用 | |
| 东方浩然 2.0 | zh_male_dongfanghaoran_uranus_bigtts | 通用 | |
| 温柔小雅 2.0 | zh_female_wenrouxiaoya_uranus_bigtts | 通用 | |
| 天才童声 2.0 | zh_male_tiancaitongsheng_uranus_bigtts | 通用 | |
| 武则天 2.0 | zh_female_wuzetian_uranus_bigtts | 角色扮演 | 剪映同款 |
| 顾姐 2.0 | zh_female_gujie_uranus_bigtts | 角色扮演 | 抖音/剪映同款 |
| 广告解说 2.0 | zh_male_guanggaojieshuo_uranus_bigtts | 通用 | 剪映同款 |
| 少儿故事 2.0 | zh_female_shaoergushi_uranus_bigtts | 有声阅读 | |

## 1.2 中文·角色扮演/客服/情感（`ICL_uranus_zh_*_tob`，含 S2S-SC 标记）
> 女声
| 音色名 | voice_type |
|---|---|
| 客服婉君 | ICL_uranus_zh_female_kefuwanjun_tob |
| 营销小楠 | ICL_uranus_zh_female_yingxiaokefu_v2_tob |
| 傲娇女友(S2S-SC) | ICL_uranus_zh_female_aojiaonvyou_tob |
| 傲慢娇声 | ICL_uranus_zh_female_aomanjiaosheng_tob |
| 邪魅女王(S2S-SC) | ICL_uranus_zh_female_xiemeinvwang_tob |
| 病娇姐姐 | ICL_uranus_zh_female_bingjiaojiejie_tob |
| 病娇萌妹 | ICL_uranus_zh_female_bingjiaomengmei_tob |
| 病弱少女 | ICL_uranus_zh_female_bingruoshaonv_tob |
| 成熟温柔 | ICL_uranus_zh_female_chengshuwenrou_tob |
| 成熟姐姐(S2S-SC) | ICL_uranus_zh_female_chengshujiejie_tob |
| 纯真少女 | ICL_uranus_zh_female_chunzhenshaonv_tob |
| 纯澈女生 | ICL_uranus_zh_female_chunchenvsheng_tob |
| 妩媚可人 | ICL_uranus_zh_female_wumeikeren_tob |
| 乖巧可儿 | ICL_uranus_zh_female_guaiqiaokeer_tob |
| 和蔼奶奶 | ICL_uranus_zh_female_heainainai_tob |
| 活泼刁蛮 | ICL_uranus_zh_female_huopodiaoman_tob |
| 活泼女孩 | ICL_uranus_zh_female_huoponvhai_tob |
| 娇憨女王 | ICL_uranus_zh_female_jiaohannvwang_tob |
| 娇弱萝莉 | ICL_uranus_zh_female_jiaoruoluoli_tob |
| 假小子 | ICL_uranus_zh_female_jiaxiaozi_tob |
| 精灵向导 | ICL_uranus_zh_female_jinglingxiangdao_tob |
| 开朗婷婷 | ICL_uranus_zh_female_kailangtingting_tob |
| 外呼凌凌 | ICL_uranus_zh_female_kefunvshengwenhecuishou_tob |
| 开心小鸿(S2S-SC) | ICL_uranus_zh_female_kaixinxiaohong_tob |
| 可爱女生 | ICL_uranus_zh_female_keainvsheng_tob |
| 灵动欣欣 | ICL_uranus_zh_female_lingdongxinxin_tob |
| 邻居阿姨 | ICL_uranus_zh_female_linjuayi_tob |
| 甜美娇俏 | ICL_uranus_zh_female_tianmeijiaoqiao_tob |
| 清冷高雅 | ICL_uranus_zh_female_qinglenggaoya_tob |
| 理性圆子 | ICL_uranus_zh_female_lixingyuanzi_tob |
| 性感魅惑 | ICL_uranus_zh_female_xingganmeihuo_tob |
| 暖心茜茜(S2S-SC) | ICL_uranus_zh_female_nuanxinqianqian_tob |
| 暖心学姐 | ICL_uranus_zh_female_nuanxinxuejie_tob |
| 清甜莓莓 | ICL_uranus_zh_female_qingtianmeimei_tob |
| 清甜桃桃 | ICL_uranus_zh_female_qingtiantaotao_tob |
| 清晰小雪 | ICL_uranus_zh_female_qingxixiaoxue_tob |
| 倾心少女 | ICL_uranus_zh_female_qingxinshaonv_tob |
| 柔骨魂师 | ICL_uranus_zh_female_rouguhunshi_tob |
| 软萌糖糖 | ICL_uranus_zh_female_ruanmengtangtang_tob |
| 软萌团子 | ICL_uranus_zh_female_ruanmengtuanzi_tob |
| 甜美活泼 | ICL_uranus_zh_female_tianmeihuopo_tob |
| 甜美小橘 | ICL_uranus_zh_female_tianmeixiaoju_tob |
| 甜美小雨 | ICL_uranus_zh_female_tianmeixiaoyu_tob |
| 调皮公主 | ICL_uranus_zh_female_tiaopigongzhu_tob |
| 贴心女友(S2S-SC) | ICL_uranus_zh_female_tiexinnvyou_tob |
| 温柔女神 | ICL_uranus_zh_female_wenrounvshen_tob |
| 温柔文雅(S2S-SC) | ICL_uranus_zh_female_wenrouwenya_tob |
| 知心姐姐 | ICL_uranus_zh_female_zhixinjiejie_tob |
| 妩媚御姐(S2S-SC) | ICL_uranus_zh_female_wumeiyujie_tob |
| 元气甜妹 | ICL_uranus_zh_female_yuanqitianmei_tob |
| 邪魅御姐 | ICL_uranus_zh_female_xiemeiyujie_tob |
| 性感御姐(S2S-SC) | ICL_uranus_zh_female_xingganyujie_tob |
| 秀丽倩倩 | ICL_uranus_zh_female_xiuliqianqian_tob |
| 贴心闺蜜 | ICL_uranus_zh_female_tiexinguimi_tob |
| 贴心妹妹 | ICL_uranus_zh_female_tiexinmeimei_tob |
| 温柔白月光 | ICL_uranus_zh_female_wenroubaiyueguang_tob |
| 初恋女友 | ICL_uranus_zh_female_chuliannvyou_tob |
| 知性温婉 | ICL_uranus_zh_female_zhixingwenwan_tob |
| 温婉珊珊 | ICL_uranus_zh_female_wenwanshanshan_tob |
| 热情艾娜 | ICL_uranus_zh_female_reqingaina_tob |
| 轻盈朵朵 | ICL_uranus_zh_female_qingyingduoduo_tob |

> 男声
| 音色名 | voice_type |
|---|---|
| 傲气凌人(S2S-SC) | ICL_uranus_zh_male_aoqilingren_tob |
| 黯刃秦主 | ICL_uranus_zh_male_anrenqinzhu_tob |
| 傲娇公子(S2S-SC) | ICL_uranus_zh_male_aojiaogongzi_tob |
| 傲娇精英(S2S-SC) | ICL_uranus_zh_male_aojiaojingying_tob |
| 傲慢青年 | ICL_uranus_zh_male_aomanqingnian_tob |
| 傲慢少爷(S2S-SC) | ICL_uranus_zh_male_aomanshaoye_tob |
| 枕边低语 | ICL_uranus_zh_male_zhenbiandiyu_tob |
| 霸道少爷(S2S-SC) | ICL_uranus_zh_male_badaoshaoye_tob |
| 霸道总裁 | ICL_uranus_zh_male_badaozongcai_tob |
| 病娇白莲(S2S-SC) | ICL_uranus_zh_male_bingjiaobailian_tob |
| 病娇弟弟(S2S-SC) | ICL_uranus_zh_male_bingjiaodidi_tob |
| 病娇哥哥 | ICL_uranus_zh_male_bingjiaogege_tob |
| 病娇男友 | ICL_uranus_zh_male_bingjiaonanyou_tob |
| 病娇少年 | ICL_uranus_zh_male_bingjiaoshaonian_tob |
| 病弱公子 | ICL_uranus_zh_male_bingruogongzi_tob |
| 病弱少年 | ICL_uranus_zh_male_bingruoshaonian_tob |
| 不羁青年 | ICL_uranus_zh_male_bujiqingnian_tob |
| 醇厚低音 | ICL_uranus_zh_male_chunhoudiyin_tob |
| 咆哮小哥 | ICL_uranus_zh_male_paoxiaoxiaoge_tob |
| 炀炀 | ICL_uranus_zh_male_yangyang_tob |
| 孱弱少爷 | ICL_uranus_zh_male_chanruoshaoye_tob |
| 成熟总裁(S2S-SC) | ICL_uranus_zh_male_chengshuzongcai_tob |
| 沉稳明仔 | ICL_uranus_zh_male_chenwenmingzai_tob |
| 清逸苏感 | ICL_uranus_zh_male_qingyisugan_tob |
| 纯真学弟 | ICL_uranus_zh_male_chunzhenxuedi_tob |
| 磁性男嗓(S2S-SC) | ICL_uranus_zh_male_cixingnansang_tob |
| 醋精男生 | ICL_uranus_zh_male_cujingnansheng_tob |
| 醋精男友(S2S-SC) | ICL_uranus_zh_male_cujingnanyou_tob |
| 低音沉郁(S2S-SC) | ICL_uranus_zh_male_diyinchenyu_tob |
| 风发少年 | ICL_uranus_zh_male_fengfashaonian_tob |
| 儒雅公子 | ICL_uranus_zh_male_ruyagongzi_tob |
| 腹黑公子(S2S-SC) | ICL_uranus_zh_male_fuheigongzi_tob |
| 干净少年 | ICL_uranus_zh_male_ganjingshaonian_tob |
| 高冷总裁 | ICL_uranus_zh_male_gaolengzongcai_tob |
| 孤傲公子 | ICL_uranus_zh_male_guaogongzi_tob |
| 孤高公子 | ICL_uranus_zh_male_gugaogongzi_tob |
| 诡异神秘 | ICL_uranus_zh_male_guiyishenmi_tob |
| 固执病娇 | ICL_uranus_zh_male_guzhibingjiao_tob |
| 憨厚敦实 | ICL_uranus_zh_male_hanhoudunshi_tob |
| 活力青年 | ICL_uranus_zh_male_huoliqingnian_tob |
| 活泼男友 | ICL_uranus_zh_male_huoponanyou_tob |
| 活泼爽朗 | ICL_uranus_zh_male_huoposhuanglang_tob |
| 胡子叔叔 | ICL_uranus_zh_male_huzishushu_tob |
| 机甲智能 | ICL_uranus_zh_male_jijiazhineng_tob |
| 精英青年 | ICL_uranus_zh_male_jingyingqingnian_tob |
| 俊逸公子 | ICL_uranus_zh_male_junyigongzi_tob |
| 开朗轻快 | ICL_uranus_zh_male_kailangqingkuai_tob |
| 开朗青年 | ICL_uranus_zh_male_kailangqingnian_tob |
| 蓝银草魂师 | ICL_uranus_zh_male_lanyincaohunshi_tob |
| 冷傲总裁 | ICL_uranus_zh_male_lengaozongcai_tob |
| 冷淡疏离 | ICL_uranus_zh_male_lengdanshuli_tob |
| 冷峻高智 | ICL_uranus_zh_male_lengjungaozhi_tob |
| 冷峻上司 | ICL_uranus_zh_male_lengjunshangsi_tob |
| 冷酷哥哥 | ICL_uranus_zh_male_lengkugege_tob |
| 冷脸兄长 | ICL_uranus_zh_male_lenglianxiongzhang_tob |
| 冷脸学霸 | ICL_uranus_zh_male_lenglianxueba_tob |
| 冷漠男友 | ICL_uranus_zh_male_lengmonanyou_tob |
| 冷漠兄长 | ICL_uranus_zh_male_lengmoxiongzhang_tob |
| 凌云青年 | ICL_uranus_zh_male_lingyunqingnian_tob |
| 清冷矜贵 | ICL_uranus_zh_male_qinglengjingui_tob |
| 绿茶小哥 | ICL_uranus_zh_male_lvchaxiaoge_tob |
| 懵懂青年 | ICL_uranus_zh_male_mengdongqingnian_tob |
| 闷油瓶小哥 | ICL_uranus_zh_male_menyoupingxiaoge_tob |
| 嚣张小哥 | ICL_uranus_zh_male_xiaozhangxiaoge_tob |
| 粘人男友 | ICL_uranus_zh_male_nianrennanyou_tob |
| 内敛才俊 | ICL_uranus_zh_male_neiliancaijun_tob |
| 暖心体贴 | ICL_uranus_zh_male_nuanxintitie_tob |
| 翩翩公子 | ICL_uranus_zh_male_pianpiangongzi_tob |
| 沉稳优雅 | ICL_uranus_zh_male_chenwenyouya_tob |
| 青涩小生 | ICL_uranus_zh_male_qingsexiaosheng_tob |
| 青涩青年 | ICL_uranus_zh_male_qingseqingnian_tob |
| 清爽少年 | ICL_uranus_zh_male_qingshuangshaonian_tob |
| 清新波波 | ICL_uranus_zh_male_qingxinbobo_tob |
| 亲切青年 | ICL_uranus_zh_male_qinqieqingnian_tob |
| 亲切小卓 | ICL_uranus_zh_male_qinqiexiaozhuo_tob |
| 清朗温润 | ICL_uranus_zh_male_qinglangwenrun_tob |
| 热血少年 | ICL_uranus_zh_male_rexueshaonian_tob |
| 儒雅才俊 | ICL_uranus_zh_male_ruyacaijun_tob |
| 儒雅君子 | ICL_uranus_zh_male_ruyajunzi_tob |
| 儒雅总裁 | ICL_uranus_zh_male_ruyazongcai_tob |
| 撒娇男生 | ICL_uranus_zh_male_sajiaonansheng_tob |
| 撒娇男友 | ICL_uranus_zh_male_sajiaonanyou_tob |
| 撒娇粘人 | ICL_uranus_zh_male_sajiaonianren_tob |
| 洒脱青年 | ICL_uranus_zh_male_satuoqingnian_tob |
| 少年将军 | ICL_uranus_zh_male_shaonianjiangjun_tob |
| 深沉总裁 | ICL_uranus_zh_male_shenchenzongcai_tob |
| 机灵小伙 | ICL_uranus_zh_male_jilingxiaohuo_tob |
| 神秘法师 | ICL_uranus_zh_male_shenmifashi_tob |
| 率真小伙 | ICL_uranus_zh_male_shuaizhenxiaohuo_tob |
| 爽朗小阳 | ICL_uranus_zh_male_shuanglangxiaoyang_tob |
| 低沉缱绻 | ICL_uranus_zh_male_dichenqianquan_tob |
| 斯文青年 | ICL_uranus_zh_male_siwenqingnian_tob |
| 甜系男友 | ICL_uranus_zh_male_tianxinanyou_tob |
| 贴心男友 | ICL_uranus_zh_male_tiexinnanyou_tob |
| 温柔男同桌 | ICL_uranus_zh_male_wenrounantongzhuo_tob |
| 温柔男友 | ICL_uranus_zh_male_wenrounanyou_tob |
| 温柔学长 | ICL_uranus_zh_male_wenrouxuezhang_tob |
| 温润学者 | ICL_uranus_zh_male_wenrunxuezhe_tob |
| 温顺少年 | ICL_uranus_zh_male_wenshunshaonian_tob |
| 寡言小哥 | ICL_uranus_zh_male_guayanxiaoge_tob |
| 小侯爷 | ICL_uranus_zh_male_xiaohouye_tob |
| 奶气小生 | ICL_uranus_zh_male_naiqixiaosheng_tob |
| 潇洒随性 | ICL_uranus_zh_male_xiaosasuixing_tob |
| 温柔内敛 | ICL_uranus_zh_male_wenrouneilian_tob |
| 学霸男同桌 | ICL_uranus_zh_male_xuebanantongzhuo_tob |
| 学霸同桌 | ICL_uranus_zh_male_xuebatongzhuo_tob |
| 阳光洋洋 | ICL_uranus_zh_male_yangguangyangyang_tob |
| 温暖少年 | ICL_uranus_zh_male_wennuanshaonian_tob |
| 意气少年 | ICL_uranus_zh_male_yiqishaonian_tob |
| 油腻大叔 | ICL_uranus_zh_male_younidashu_tob |
| 幽默大爷 | ICL_uranus_zh_male_youmodaye_tob |
| 幽默叔叔 | ICL_uranus_zh_male_youmoshushu_tob |
| 优柔帮主 | ICL_uranus_zh_male_youroubangzhu_tob |
| 优柔公子 | ICL_uranus_zh_male_yourougongzi_tob |
| 元气少年 | ICL_uranus_zh_male_yuanqishaonian_tob |
| 仗剑君子 | ICL_uranus_zh_male_zhangjianjunzi_tob |
| 仗剑侠客 | ICL_uranus_zh_male_zhangjianxiake_tob |
| 正直青年 | ICL_uranus_zh_male_zhengzhiqingnian_tob |
| 直率青年 | ICL_uranus_zh_male_zhishuaiqingnian_tob |
| 中二青年 | ICL_uranus_zh_male_zhongerqingnian_tob |
| 自负青年 | ICL_uranus_zh_male_zifuqingnian_tob |
| 自信青年 | ICL_uranus_zh_male_zixinqingnian_tob |
| 天才同桌 | ICL_uranus_zh_male_tiancaitongzhuo_tob |
| 清新沐沐 | ICL_uranus_zh_male_qingxinmumu_tob |
| 爽朗少年 | ICL_uranus_zh_male_shuanglangshaonian_tob |

## 1.3 外语音色（`*_uranus_bigtts` / `ICL_uranus_en_*_tob`）
> 推理模式 QA=指令遵循，Context=上下文遵循（部分**仅单向流、不支持双向流**，见备注）。此处按语种归并，只列 名/ID/语种/模式/备注。
| 名 | voice_type | 语种 | 模式 | 备注 |
|---|---|---|---|---|
| Charlie 2.0 | ICL_uranus_en_female_charlie_tob | 美式英语 | | |
| Ethan 2.0 | ICL_uranus_en_male_ethan_tob | 澳洲英语 | | |
| Alastor 2.0 | ICL_uranus_en_male_alastor_tob | 英式英语 | | |
| Chucky 2.0 | ICL_uranus_en_male_chucky_tob | 美式英语 | | |
| Noah 2.0 | ICL_uranus_en_male_noah_tob | 美式英语 | | |
| Jigsaw 2.0 | ICL_uranus_en_male_jigsaw_tob | 美式英语 | | |
| Clown Man 2.0 | ICL_uranus_en_male_clown_man_tob | 美式英语 | | |
| Cartoon Chef 2.0 | ICL_uranus_en_male_cartoon_chef_tob | 美式英语 | | |
| Frosty Man 2.0 | ICL_uranus_en_male_frosty_man_tob | 美式英语 | | 豆包同款 |
| The Grinch 2.0 | ICL_uranus_en_male_the_grinch_tob | 美式英语 | | 豆包同款 |
| Kevin McCallister 2.0 | ICL_uranus_en_male_kevin_mccallister_tob | 美式英语 | | 豆包同款 |
| Michael 2.0 | ICL_uranus_en_male_michael_tob | 美式英语 | | 豆包同款 |
| Big Boogie 2.0 | ICL_uranus_en_male_big_boogie_tob | 美式英语 | | 豆包同款 |
| Xavier 2.0 | ICL_uranus_en_male_xavier_tob | 美式英语 | | |
| Zayne 2.0 | ICL_uranus_en_male_zayne_tob | 美式英语 | | |
| Dina | ar_female_dina_uranus_bigtts | 阿拉伯语(埃及) | QA | |
| Fatma | ar_female_fatma_uranus_bigtts | 阿拉伯语 | QA | |
| Youssef | ar_male_youssef_uranus_bigtts | 阿拉伯语 | QA | |
| Stella | de_female_bv081_uranus_bigtts | 德语 | QA | |
| Sven | de_male_sven_uranus_bigtts | 德语 | Context | 仅单向流 |
| Rowan | en_male_adam-imitation_uranus_bigtts | 美式英语 | QA | |
| Alberto | en_male_alberto_uranus_bigtts | 美式英语 | QA | |
| Alex | en_male_alex_uranus_bigtts | 美式英语 | QA | |
| Allison | en_female_allison_uranus_bigtts | 美式英语 | QA | |
| Charlotte | en_female_authoritative-british_uranus_bigtts | 美式英语 | QA | |
| Margaret | en_female_authoritative-informative_uranus_bigtts | 美式英语 | QA | |
| Jones | en_male_bill-jones_uranus_bigtts | 美式英语 | QA | |
| Bill | en_male_bill_jones_corey_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Brad_Pitt | en_male_brad_pitt_p1_uranus_bigtts | 美式英语 | QA | |
| Brittney | en_female_brittney_uranus_bigtts | 美式英语 | QA | |
| Zoe | en_female_brittney_pimintel_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Adrian | en_male_bruce_uranus_bigtts | 美式英语 | QA | |
| Leo | en_male_chandler_p1_uranus_bigtts | 美式英语 | QA | |
| Bob | en_male_cowboy-bob_uranus_bigtts | 美式英语 | QA | |
| John | en_male_cowboy_john_b_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| David | en_male_david_uranus_bigtts | 美式英语 | QA | |
| Orion | en_male_deep-voice_uranus_bigtts | 美式英语 | QA | |
| Julian | en_male_diyuwenrounan_uranus_bigtts | 美式英语 | QA | |
| Harrison | en_male_evil-guy-oxley_uranus_bigtts | 美式英语 | QA | |
| Jasper | en_male_excited-male-voice_uranus_bigtts | 美式英语 | QA | |
| Alfred | en_male_father-christmas_uranus_bigtts | 美式英语 | QA | |
| Holly | en_female_female_tutor_ms-jenny_uranus_bigtts | 美式英语 | Context | |
| Felix | en_male_fernando-martinez_uranus_bigtts | 美式英语 | QA | |
| Godfather | en_male_godfather_uranus_bigtts | 美式英语 | QA | |
| Gollum | en_male_gollum_uranus_bigtts | 美式英语 | QA | |
| Beau | en_male_hades_uranus_bigtts | 美式英语 | QA | |
| Hayley | en_female_hayley_uranus_bigtts | 美式英语 | QA | |
| Jamie | en_male_jamie_uranus_bigtts | 美式英语 | QA | |
| Jane | en_female_jane_uranus_bigtts | 美式英语 | QA | |
| Jenny | en_female_jenny_uranus_bigtts | 美式英语 | QA | |
| Blaze | en_male_jidongchuanjiaoshi_uranus_bigtts | 美式英语 | QA | |
| Jimmy | en_male_jimmy_uranus_bigtts | 美式英语 | QA | |
| Joanne | en_female_joanne_uranus_bigtts | 美式英语 | QA | |
| Joker | en_male_joker_uranus_bigtts | 美式英语 | QA | |
| Josh | en_male_josh_uranus_bigtts | 美式英语 | QA | |
| Josiah | en_male_josh_coery_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Kevin | en_male_kevin_uranus_bigtts | 美式英语 | QA | |
| Knightley | en_male_knightley_uranus_bigtts | 美式英语 | QA | |
| Lynn | en_female_lana_del_rey_kelley_d_p1_uranus_bigtts | 美式英语 | QA | |
| Ivy | en_female_lana_del_rey_parky_s_p1_uranus_bigtts | 美式英语 | QA | |
| Marcus | en_male_marcus_uranus_bigtts | 美式英语 | QA | |
| Mel | en_female_mel_uranus_bigtts | 美式英语 | QA | |
| Hank | en_male_michael_uranus_bigtts | 美式英语 | QA | |
| Chip | en_male_michael-mouse_uranus_bigtts | 美式英语 | QA | |
| Michael_Kevin | en_male_michael_kevin_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Rory | en_male_motivational-coach_uranus_bigtts | 美式英语 | QA | |
| Myra | en_female_myra_uranus_bigtts | 美式英语 | QA | |
| Sunny | en_female_myra_cmb_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Blair | en_female_nadia_uranus_bigtts | 美式英语 | QA | |
| Natasha | en_female_natasha_uranus_bigtts | 美式英语 | QA | 仅单向流 |
| Elaine | en_female_pleasant-female_uranus_bigtts | 美式英语 | QA | |
| Rachel | en_female_rachel_p1_uranus_bigtts | 美式英语 | QA | |
| Ronald | en_male_ronald_uranus_bigtts | 美式英语 | QA | |
| Russell | en_male_russell_uranus_bigtts | 美式英语 | QA | |
| Scarlet | en_female_scarlet_p1_uranus_bigtts | 美式英语 | QA | |
| Sharron | en_female_sharron_uranus_bigtts | 美式英语 | QA | |
| Simba | en_male_simba_p1_uranus_bigtts | 美式英语 | QA | |
| Skye | en_female_skye_uranus_bigtts | 美式英语 | QA | |
| Tom | en_male_tom_hiddleston_p1_uranus_bigtts | 美式英语 | QA | |
| Valentino | en_male_valentino_uranus_bigtts | 美式英语 | QA | |
| Clark | en_male_valentino_corey_uranus_bigtts | 美式英语 | Context | 仅单向流 |
| Megan | en_female_wenrouzhishijieshuonv_uranus_bigtts | 美式英语 | QA | |
| Kayla | en_female_xinwenjieshuonv_uranus_bigtts | 美式英语 | QA | |
| Dylan | en_male_yangguangjieshuonan_uranus_bigtts | 美式英语 | QA | |
| Zendaya | en_female_zendaya_p1_uranus_bigtts | 美式英语 | QA | |
| Gracie | es_female_bv084_uranus_bigtts | 西班牙语 | QA | |
| Dani | es_male_dani_uranus_bigtts | 西班牙语 | QA | |
| Guillem | es_male_guillem_uranus_bigtts | 西班牙语 | QA | |
| Marisol | es_female_ht_mx_f6_uranus_bigtts | 西班牙语 | QA | |
| Simone | fr_female_fr_bv078_uranus_bigtts | 法语 | QA | |
| Camille | fr_female_fr_f47_uranus_bigtts | 法语 | QA | |
| Maurice | fr_male_fr_m29_uranus_bigtts | 法语 | QA | |
| Usseau | fr_male_usseau_uranus_bigtts | 法语 | Context | 仅单向流 |
| Rocco | id_male_bv160_uranus_bigtts | 印尼语 | QA | |
| Jude | id_male_bv160dialogue_uranus_bigtts | 印尼语 | QA | |
| Hugo | id_male_bv160narration_uranus_bigtts | 印尼语 | QA | |
| Clara | id_female_bv161_uranus_bigtts | 印尼语 | QA | |
| Sylvia | id_female_bv161dialogue_uranus_bigtts | 印尼语 | QA | |
| Celeste | id_female_bv161narration_uranus_bigtts | 印尼语 | QA | |
| Crew | id_female_bv164_uranus_bigtts | 印尼语 | QA | |
| Elian | id_male_bv164dialogue_uranus_bigtts | 印尼语 | QA | |
| Ronan | id_male_bv164narration_uranus_bigtts | 印尼语 | QA | |
| Chloe | id_female_f20_uranus_bigtts | 印尼语 | QA | |
| Han | id_male_han_uranus_bigtts | 印尼语 | Context | |
| Kyle | id_male_m08_uranus_bigtts | 印尼语 | QA | |
| Phulia | id_female_phulia_uranus_bigtts | 印尼语 | QA | |
| Bonnie | ja_female_bv024_uranus_bigtts | 日语 | QA | |
| Poppy | ja_female_bv520_uranus_bigtts | 日语 | QA | |
| Aoi | ja_female_bv521_uranus_bigtts | 日语 | QA | |
| Hana | ja_female_bv522_uranus_bigtts | 日语 | QA | |
| Lily | ja_female_bv523_uranus_bigtts | 日语 | QA | |
| Ken | ja_male_bv524_uranus_bigtts | 日语 | QA | |
| Minimi | ja_female_minimi_uranus_bigtts | 日语 | Context | 仅单向流 |
| Shirou | ja_female_shirou_uranus_bigtts | 日语 | QA | |
| Jay | ko_male_bv545_uranus_bigtts | 韩语 | QA | |
| Momo | ko_female_bv546_uranus_bigtts | 韩语 | QA | |
| Minho | ko_male_m03_uranus_bigtts | 韩语 | QA | |
| Shane | ko_male_shane_uranus_bigtts | 韩语 | Context | 仅单向流 |
| Ham | ms_male_ham_uranus_bigtts | 马来语 | QA | |
| Naim | ms_male_naim_uranus_bigtts | 马来语 | QA | |
| Irene | mx_female_bv065_uranus_bigtts | 墨西哥西语 | QA | |
| Diego | mx_male_bv165dialogue_uranus_bigtts | 墨西哥西语 | QA | |
| Marcos | mx_male_bv165narrator_uranus_bigtts | 墨西哥西语 | QA | |
| Lucy | mx_female_bv166dialogue_uranus_bigtts | 墨西哥西语 | QA | |
| Rosa | mx_female_bv166emotion_uranus_bigtts | 墨西哥西语 | QA | |
| Freya | mx_female_bv166narrator_uranus_bigtts | 墨西哥西语 | QA | |
| Felipe | mx_male_felipe_uranus_bigtts | 墨西哥西语 | Context | 仅单向流 |
| Derek | mx_male_ht_mx_m012_uranus_bigtts | 墨西哥西语 | QA | |
| Leslie | mx_female_leslie_uranus_bigtts | 墨西哥西语 | QA | |
| Marcelo | mx_male_marcelo_uranus_bigtts | 墨西哥西语 | QA | |
| Sam | pt_male_bv172_uranus_bigtts | 巴西葡语 | QA | |
| Walter | pt_male_bv172dialogue_uranus_bigtts | 巴西葡语 | QA | |
| Vincent | pt_male_bv172emotion_uranus_bigtts | 巴西葡语 | QA | |
| Miles | pt_male_bv172narrator_uranus_bigtts | 巴西葡语 | QA | |
| Diana | pt_female_bv173_uranus_bigtts | 巴西葡语 | QA | |
| Elena | pt_female_bv173dialogue_uranus_bigtts | 巴西葡语 | QA | |
| Lola | pt_female_bv173emotion_uranus_bigtts | 巴西葡语 | QA | |
| Emma | pt_female_bv173narrator_uranus_bigtts | 巴西葡语 | QA | |
| Sofia | pt_female_bv530_uranus_bigtts | 巴西葡语 | QA | |
| Arthur | pt_male_bv531_uranus_bigtts | 巴西葡语 | QA | |
| Mari | pt_female_mari_uranus_bigtts | 巴西葡语 | QA | |
| Toby | pt_male_martins_uranus_bigtts | 巴西葡语 | Context | 仅单向流 |
| Rael | pt_male_rael_uranus_bigtts | 巴西葡语 | QA | |
| Amelia | ru_female_af07_uranus_bigtts | 俄语 | QA | |
| Irinae | ru_female_irinae_uranus_bigtts | 俄语 | QA | |
| Pavel | ru_male_pavel_uranus_bigtts | 俄语 | QA | |
| Ksenia | ru_female_sophie_uranus_bigtts | 俄语 | QA | |
| Silas | ru_male_vlad_uranus_bigtts | 俄语 | QA | |
| Valeria | th_female_bv568_angry_uranus_bigtts | 泰语 | QA | |
| Iris | th_female_bv568_fear_uranus_bigtts | 泰语 | QA | |
| Zara | th_female_bv568_happy_uranus_bigtts | 泰语 | QA | |
| Valentina | th_female_bv568_hate_uranus_bigtts | 泰语 | QA | |
| Mildred | th_female_bv568_neutral_uranus_bigtts | 泰语 | QA | |
| Lydia | th_female_bv568_sad_uranus_bigtts | 泰语 | QA | |
| Phoebe | th_female_bv568_suprise_uranus_bigtts | 泰语 | QA | |
| Annika | tl_female_annika_uranus_bigtts | 菲律宾语 | QA | |
| Ed | tl_male_ed_uranus_bigtts | 菲律宾语 | QA | |
| Hervie | tl_female_hervie_uranus_bigtts | 菲律宾语 | QA | |
| Hong | vi_female_hong_uranus_bigtts | 越南语 | QA | |
| Ling | vi_female_ling_uranus_bigtts | 越南语 | QA | |
| Linh | vi_female_linh_uranus_bigtts | 越南语 | QA | |
| Partner | vi_female_partner_uranus_bigtts | 越南语 | QA | |
| Ruan | vi_female_ruan_uranus_bigtts | 越南语 | QA | |
| Wu | vi_female_wu_uranus_bigtts | 越南语 | QA | |
| Wumg | vi_male_wumg_uranus_bigtts | 越南语 | QA | |
| Enzo | it_male_enzo_uranus_bigtts | 意大利语 | Context | 仅单向流 |

---

# 二、端到端实时 S2S（`*_jupiter_bigtts` / `saturn_*_tob`）— 另用 S2S 端点
| 版本 | 音色名 | voice_type |
|---|---|---|
| S2S-Omni | vivi | zh_female_vv_jupiter_bigtts |
| S2S-Omni | 小何 | zh_female_xiaohe_jupiter_bigtts |
| S2S-Omni | 云舟 | zh_male_yunzhou_jupiter_bigtts |
| S2S-Omni | 小天 | zh_male_xiaotian_jupiter_bigtts |
| SC2.0 | 傲娇女友 | saturn_zh_female_aojiaonvyou_tob |
| SC2.0 | 病娇姐姐 | saturn_zh_female_bingjiaojiejie_tob |
| SC2.0 | 成熟姐姐 | saturn_zh_female_chengshujiejie_tob |
| SC2.0 | 可爱女生 | saturn_zh_female_keainvsheng_tob |
| SC2.0 | 暖心学姐 | saturn_zh_female_nuanxinxuejie_tob |
| SC2.0 | 贴心女友 | saturn_zh_female_tiexinnvyou_tob |
| SC2.0 | 温柔文雅 | saturn_zh_female_wenrouwenya_tob |
| SC2.0 | 妩媚御姐 | saturn_zh_female_wumeiyujie_tob |
| SC2.0 | 性感御姐 | saturn_zh_female_xingganyujie_tob |
| SC2.0 | 傲气凌人 | saturn_zh_male_aiqilingren_tob |
| SC2.0 | 傲娇公子 | saturn_zh_male_aojiaogongzi_tob |
| SC2.0 | 傲娇精英 | saturn_zh_male_aojiaojingying_tob |
| SC2.0 | 傲慢少爷 | saturn_zh_male_aomanshaoye_tob |
| SC2.0 | 霸道少爷 | saturn_zh_male_badaoshaoye_tob |
| SC2.0 | 病娇白莲 | saturn_zh_male_bingjiaobailian_tob |
| SC2.0 | 不羁青年 | saturn_zh_male_bujiqingnian_tob |
| SC2.0 | 成熟总裁 | saturn_zh_male_chengshuzongcai_tob |
| SC2.0 | 磁性男嗓 | saturn_zh_male_cixingnansang_tob |
| SC2.0 | 醋精男友 | saturn_zh_male_cujingnanyou_tob |
| SC2.0 | 风发少年 | saturn_zh_male_fengfashaonian_tob |
| SC2.0 | 腹黑公子 | saturn_zh_male_fuheigongzi_tob |

---

# 三、模型1.0 音色（`*_mars_bigtts` / `*_moon_bigtts` 等）+ 情感参数
> 1.0 走各自模型；情感用 `emotion` 参数（下列括号值）。中文情感集：happy/sad/angry/surprised/fear/hate/excited/coldness/neutral/depressed/lovey-dovey/shy/comfort/tension/tender/storytelling/radio/magnetic/advertising/vocal-fry/ASMR(低语)/news/entertainment/dialect。英文：neutral/happy/angry/sad/excited/chat/ASMR/warm/affectionate/authoritative。

## 3.1 多情感（`*_emo_*_mars_bigtts`）
| 音色名 | voice_type | 支持情感 | MIX |
|---|---|---|---|
| 冷酷哥哥(多情感) | zh_male_lengkugege_emo_v2_mars_bigtts | 生气/冷漠/恐惧/开心/厌恶/中性/悲伤/沮丧 | 否 |
| 甜心小美(多情感) | zh_female_tianxinxiaomei_emo_v2_mars_bigtts | 悲伤/恐惧/厌恶/中性 | 否 |
| 广州德哥(多情感) | zh_male_guangzhoudege_emo_mars_bigtts | 生气/恐惧/中性 | 是 |
| 京腔侃爷(多情感) | zh_male_jingqiangkanye_emo_mars_bigtts | 开心/生气/惊讶/厌恶/中性 | 是 |
| 邻居阿姨(多情感) | zh_female_linjuayi_emo_v2_mars_bigtts | 中性/愤怒/冷漠/沮丧/惊讶 | 否 |
| 优柔公子(多情感) | zh_male_yourougongzi_emo_v2_mars_bigtts | 开心/生气/恐惧/厌恶/激动/中性/沮丧 | 否 |
| 儒雅男友(多情感) | zh_male_ruyayichen_emo_v2_mars_bigtts | 开心/悲伤/生气/恐惧/激动/冷漠/中性 | 否 |
| 俊朗男友(多情感) | zh_male_junlangnanyou_emo_v2_mars_bigtts | 开心/悲伤/生气/惊讶/恐惧/中性 | 否 |
| 北京小爷(多情感) | zh_male_beijingxiaoye_emo_v2_mars_bigtts | 生气/惊讶/恐惧/激动/冷漠/中性 | 否 |
| 柔美女友(多情感) | zh_female_roumeinvyou_emo_v2_mars_bigtts | 开心/悲伤/生气/惊讶/恐惧/厌恶/激动/冷漠/中性 | 否 |
| 阳光青年(多情感) | zh_male_yangguangqingnian_emo_v2_mars_bigtts | 开心/悲伤/生气/恐惧/激动/冷漠/中性 | 否 |
| 魅力女友(多情感) | zh_female_meilinvyou_emo_v2_mars_bigtts | 悲伤/恐惧/中性 | 否 |
| 爽快思思(多情感) | zh_female_shuangkuaisisi_emo_v2_mars_bigtts | 开心/悲伤/生气/惊讶/激动/冷漠/中性 | 否 |
| 深夜播客(多情感) | zh_male_shenyeboke_emo_v2_mars_bigtts | 惊讶/悲伤/中性/厌恶/开心/恐惧/激动/沮丧/冷漠/生气 | 否 |
| Candice | en_female_candice_emo_v2_mars_bigtts | 深情/愤怒/ASMR/闲聊/兴奋/愉悦/中性/温暖 | 否 |

## 3.2 通用/趣味口音/角色/配音/有声阅读（1.0，节选常用）
| 音色名 | voice_type | 语种/口音 | 对应2.0 |
|---|---|---|---|
| 亲切女声 | zh_female_qinqienvsheng_moon_bigtts | 中文 | 亲切女声 2.0 |
| 快乐小东 | zh_male_xudong_conversation_wvae_bigtts | 中文 | 快乐小东 2.0 |
| 开朗学长 | en_male_jason_conversation_wvae_bigtts | 中文 | 开朗学长 2.0 |
| 甜美桃子 | zh_female_tianmeitaozi_mars_bigtts | 中文 | 甜美桃子 2.0 |
| 清新女声 | zh_female_qingxinnvsheng_mars_bigtts | 中文 | 清新女声 2.0 |
| 知性女声 | zh_female_zhixingnvsheng_mars_bigtts | 中文 | 知性女声 2.0 |
| 清爽男大 | zh_male_qingshuangnanda_mars_bigtts | 中文 | 清爽男大 2.0 |
| 邻家女孩 | zh_female_linjianvhai_moon_bigtts | 中文 | 邻家女孩 2.0 |
| 甜美小源 | zh_female_tianmeixiaoyuan_moon_bigtts | 中文 | 甜美小源 2.0 |
| 灿灿/Shiny | zh_female_cancan_mars_bigtts | 中文,美式英语 | 知性灿灿 2.0 |
| 爽快思思/Skye | zh_female_shuangkuaisisi_moon_bigtts | 中文,美式英语 | 爽快思思 2.0 |
| 温暖阿虎/Alvin | zh_male_wennuanahu_moon_bigtts | 中文,美式英语 | 温暖阿虎 2.0 |
| 少年梓辛/Brayan | zh_male_shaonianzixin_moon_bigtts | 中文,美式英语 | 少年梓辛 2.0 |
| 粤语小溏 | zh_female_yueyunv_mars_bigtts | 中文-粤语 | |
| 湾湾小何 | zh_female_wanwanxiaohe_moon_bigtts | 中文-台湾 | 小何 2.0 |
| 北京小爷 | zh_male_beijingxiaoye_moon_bigtts | 中文-北京 | |
| 天才童声 | zh_male_tiancaitongsheng_mars_bigtts | 中文 | 天才童声 2.0 |
| 猴哥 | zh_male_sunwukong_mars_bigtts | 中文 | 猴哥 2.0 |
| 佩奇猪 | zh_female_peiqi_mars_bigtts | 中文 | 佩奇猪 2.0 |
| 悬疑解说 | zh_male_changtianyi_mars_bigtts | 中文 | 悬疑解说 2.0 |
| 儒雅青年 | zh_male_ruyaqingnian_mars_bigtts | 中文 | 儒雅青年 2.0 |
| 擎苍 | zh_male_qingcang_mars_bigtts | 中文 | 擎苍 2.0 |
| 温柔淑女 | zh_female_wenroushunv_mars_bigtts | 中文 | 温柔淑女 2.0 |

> 外语(1.0)：Adam `en_male_adam_mars_bigtts`、Amanda `en_female_amanda_mars_bigtts`、Jackson `en_male_jackson_mars_bigtts`、Smith `en_male_smith_mars_bigtts`(英式)、Anna `en_female_anna_mars_bigtts`(英式)、Sarah `en_female_sarah_mars_bigtts`(澳)、Dryw `en_male_dryw_mars_bigtts`(澳)。多语种 `multi_*_bigtts`（西/日等，见官方页）。

> 注：1.0 完整表另见官方页；本项目主用「模型2.0」表，1.0 仅备查。
