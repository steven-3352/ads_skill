#!/usr/bin/env bash
# 构建 zhanv stage4 的 13 条 H3 视频提示词 JSON。
# 每条：I2VA/FL2VA content(首/尾帧 local_path) + duration + ratio 16:9 + prompt +
# h3_prompt_review(sha256 从最终 .prompt 用 `jq -jr` 复算，与校验器同法)。
# 可反复运行；改时长/对白后重跑即可。
set -Eeuo pipefail
cd /home/ubuntu/ads_skill
DIR=replication/output/zhanv
PDIR=$DIR/prompts/shots
SHOTS=replication/output/zhanv/shots
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

wp(){ cat > "$TMP/$1.txt"; }   # 写某单元的 prompt 原文到临时文件

i2va(){ printf '[{"type":"image_url","image_url":{"url":"pending"},"local_path":"%s/%s-first.png","role":"first_frame"}]' "$SHOTS" "$1"; }

CHECKS='["instruction-line-first","three-core-fields-in-order","speakers-S1-lin-S2-zhou-stable","dialogue-zh-verbatim-in-d-tags","delivery-and-action-outside-d","anti-wax-neutral-white-LED-4800K","constant-bright-no-fade-no-dim","no-burned-subtitles","east-asian-casting","no-brand-no-logo-props","16:9-ratio"]'

build(){ # id mode duration content-json
  local id="$1" mode="$2" dur="$3" content="$4"
  local out="$PDIR/$id-video.json"
  jq -n --rawfile p "$TMP/$id.txt" --arg id "$id" --arg mode "$mode" \
     --argjson dur "$dur" --argjson content "$content" --argjson checks "$CHECKS" '
    { id:$id, provider:"minimax", model:"MiniMax-H3", mode:$mode,
      duration:$dur, ratio:"16:9", generate_audio:true,
      content:$content, prompt:$p,
      h3_prompt_review:{
        skill:"h3-prompt-writing", authorship:"generated_by_skill",
        result:"pass", asset_type:"video", mode:$mode,
        checks:$checks, unresolved_blockers:[],
        reviewed_prompt_sha256:"PENDING" } }' > "$out"
  local h; h="$(jq -jr '.prompt' "$out" | sha256sum | awk '{print $1}')"
  jq --arg h "$h" '.h3_prompt_review.reviewed_prompt_sha256=$h' "$out" > "$out.tmp" && mv "$out.tmp" "$out"
  ./replication/tools/validate-h3-prompt-review.sh "$out" video >/dev/null
  echo "OK $id ($mode ${dur}s) sha=${h:0:12}"
}

# ============ 提示词原文 ============
STY='Live-action, cinematic, iPhone handheld realistic footage with fine sensor grain, real skin texture and visible pores, no plastic or waxy CGI look and no beauty-smoothing. The late-night living room stays evenly and brightly lit by neutral-white LED ceiling light around 4800K, skin tones neutral rather than amber, faces matte without oily glare; the lighting stays constant and bright the whole clip with no dimming, no vignette and no fade to black, and no subtitles or captions are burned into the frame.'

wp U01 <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY Two East Asian women sit on a sofa exactly as in <Picture 1>, preserving their faces, clothing, the two glasses of red wine on the coffee table and the room layout. On the left, the 28-year-old woman with a translucent skincare gel on her face and a knitted home cardigan (S1) keeps a dark-screen unbranded phone face-down on her knee; on the right, the 29-year-old woman with clean bare skin and a loose cotton shirt (S2) has just set down her wine glass. The camera holds a mostly static handheld two-shot with slight natural sway. The right woman, quick and dry (S2), flicks her eyes to the phone and says: <d>[Chinese] 又看。</d> The left woman, a half-beat late and defensive (S1), answers: <d>[Chinese] 没有。</d> The right woman (S2), brisk and pointed with concern underneath, presses without a pause: <d>[Chinese] 三天了。他一条没回，你这手机翻了多少遍。</d> The left woman (S1), voice shrinking, replies weakly: <d>[Chinese] ……我就看几点。</d>

overall_soundscape: A low late-night room tone hums underneath with a faint wall clock and a refrigerator drone. A soft fabric rustle as the phone shifts on her knee and the light clink of a wine glass being set on the table.

non_diegetic_music: N/A
EOF

wp U02a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY The two East Asian women continue their late-night talk on the sofa exactly as in <Picture 1>, preserving faces, clothing, the wine glasses and the room. The left woman with a translucent skincare gel and a knitted cardigan (S1) holds her wine glass; the right woman with bare skin and a loose cotton shirt (S2) leans in slightly. The camera holds a static handheld two-shot with slight sway, brisk overlapping turn-taking and no dead pauses between lines. The right woman (S2) asks: <d>[Chinese] 他上周说忙？</d> The left woman (S1), a half-beat late, nods and answers: <d>[Chinese] 嗯。说这阵子忙。</d> The right woman (S2): <d>[Chinese] 那陈默呢。</d> The left woman (S1), softer: <d>[Chinese] 陈默……挺好。</d> The right woman (S2), pointed and caring: <d>[Chinese] 给你热了五年早饭。</d>

overall_soundscape: A low late-night room tone with a faint wall clock and a refrigerator drone underneath. Soft fabric movement and the small clink of a wine glass.

non_diegetic_music: N/A
EOF

wp U02b <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY A closer handheld shot on the left woman as in <Picture 1>, the 28-year-old with a translucent skincare gel on her face and a knitted cardigan (S1); the right woman with bare skin and a loose cotton shirt (S2) stays partly in frame. The exchange is fast and overlapping with no pauses between lines. The right woman (S2) presses, quick and blunt: <d>[Chinese] 那个三天不回的，偶尔回你一句，你是不是整个人就——</d> The left woman (S1), cutting in low: <d>[Chinese] ……就活了。</d> The right woman (S2): <d>[Chinese] 陈默天天在，你咋没这反应。</d> The left woman (S1) picks at the edge of her face mask, her hand pausing as she says, quieter: <d>[Chinese] 他太稳了。稳得我踏实。</d> The right woman (S2), flat and knowing: <d>[Chinese] 踏实到没感觉。</d> The left woman (S1), barely above a breath: <d>[Chinese] 你别这么说。</d>

overall_soundscape: A low late-night room tone with a faint clock and fridge hum. A small dry peel-and-stop sound as her fingers lift the edge of the face mask and go still.

non_diegetic_music: N/A
EOF

wp U03a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY The two East Asian women on the sofa as in <Picture 1>, faces, clothing and room preserved. Left woman with a translucent skincare gel and knitted cardigan (S1); right woman with bare skin and loose cotton shirt (S2). Static handheld two-shot with slight sway, brisk turn-taking, no dead tails. The right woman (S2): <d>[Chinese] 他三天不找你，你干嘛呢。</d> The left woman (S1), a half-beat late, admits low: <d>[Chinese] ……瞎想。想他是不是不要我了。</d> The right woman (S2): <d>[Chinese] 他偶尔回你一次呢。</d> The left woman (S1), a small helpless lift in her voice: <d>[Chinese] 就……特别高兴。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. Light fabric movement on the sofa.

non_diegetic_music: N/A
EOF

wp U03b <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY The two East Asian women as in <Picture 1>, framing favoring the right woman speaking while the left woman listens. Left woman with a translucent skincare gel and knitted cardigan (S1); right woman with bare skin and a loose cotton shirt (S2). Static handheld with slight sway; delivery quick and even, no pauses. The right woman (S2), plain and steady like a home truth: <d>[Chinese] 跟拉老虎机一样。不知道这把中不中，你才停不下来。</d> The left woman (S1) lowers her head, silent. The right woman (S2), landing it: <d>[Chinese] 陈默每次都给你。你当然不稀罕。</d>

overall_soundscape: A low late-night room tone with a faint clock and fridge hum. A soft rustle as the left woman lowers her head.

non_diegetic_music: N/A
EOF

wp U04a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY The two East Asian women on the sofa as in <Picture 1>, faces, clothing and room preserved. Left woman with a translucent skincare gel and knitted cardigan (S1); right woman with bare skin and a loose cotton shirt (S2), who leans in and counts items off fast, brisk and overlapping with no pauses. The left woman (S1), defensive: <d>[Chinese] 可陈默对我好，是应该的呀。</d> The right woman (S2): <d>[Chinese] 那个男的对你好一次，你记一年。</d> The right woman (S2), rattling it off: <d>[Chinese] 陈默记你姨妈期，记你不吃葱，记你下班走哪条路。</d> The right woman (S2), pointed: <d>[Chinese] 那个人，记你生日吗。</d> The left woman (S1), voice shrinking: <d>[Chinese] ……他忙。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. Light fabric movement as she leans forward on the sofa.

non_diegetic_music: N/A
EOF

wp U04b <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY An over-the-shoulder close framing on the left woman's face as in <Picture 1>, the 28-year-old with a translucent skincare gel and knitted cardigan (S1); the right woman with bare skin and a loose cotton shirt (S2) speaks from over the shoulder. The right woman (S2) speaks the key line not as a scolding but as someone who aches for her friend, steady and low: <d>[Chinese] 林夏。爱你的人心疼你。你爱的那个——</d> The right woman (S2), quiet and final: <d>[Chinese] 他在遛你。</d> On the left woman's face her eyes soften and her lips press together, holding it in, no tears and no reddened or glowing eyes, as she answers barely audibly (S1): <d>[Chinese] ……我知道。</d> The right woman (S2): <d>[Chinese] 知道还等。</d> The left woman (S1), a small crack held down: <d>[Chinese] 我控制不住。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum barely rising under the key line without covering the voices. A single soft breath from the left woman.

non_diegetic_music: N/A
EOF

wp U05a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY An over-the-shoulder close framing between the two East Asian women as in <Picture 1>, the right woman with bare skin and a loose cotton shirt (S2) speaking, the left woman with a translucent skincare gel and knitted cardigan (S1) listening. Delivery is quick and even, landing like a quiet exposure rather than a lecture, no pauses. The right woman (S2): <d>[Chinese] 你不是离不开他。</d> The right woman (S2): <d>[Chinese] 你是离不开那句——"终于有人看见我了"。</d> The left woman (S1) lifts her eyes to her, lips pressed, holding it in, no tears and no glowing eyes. The right woman (S2): <d>[Chinese] 你要的根本不是他爱你。</d> The right woman (S2), landing the line: <d>[Chinese] 你要的是——他居然选了我。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. A single quiet breath as the left woman lifts her eyes.

non_diegetic_music: N/A
EOF

wp U05b <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY An over-the-shoulder close framing between the two East Asian women as in <Picture 1>. Left woman with a translucent skincare gel and knitted cardigan (S1); right woman with bare skin and a loose cotton shirt (S2). Fast overlapping turn-taking, no pauses. The left woman (S1), her voice dropping lower: <d>[Chinese] 你干嘛突然说这个。</d> The right woman (S2), quick and even: <d>[Chinese] 你小时候，你妈是不是也这样。考好了才理你，考不好就不搭理。</d> The right woman (S2), landing it: <d>[Chinese] 忽冷忽热的你才当是爱。陈默这种一直在的，你反倒慌。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. Soft fabric movement on the sofa.

non_diegetic_music: N/A
EOF

wp U06a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY The two East Asian women on the sofa as in <Picture 1>, a tense quiet beat; the left woman with a translucent skincare gel and knitted cardigan (S1) now holds the unbranded phone in her hand, its screen glowing faintly on her face; the right woman with bare skin and a loose cotton shirt (S2) watches her. Static handheld two-shot with slight sway; short clipped lines, no dead tails. The right woman (S2): <d>[Chinese] 谁。</d> The left woman (S1), a half-beat late: <d>[Chinese] ……陈默。</d> The right woman (S2): <d>[Chinese] 那个三天没回的呢。</d> The left woman (S1), lower: <d>[Chinese] ……还没。</d> The right woman (S2), quiet and direct: <d>[Chinese] 你现在，想回谁。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. A soft plastic-and-fabric sound as she holds the phone.

non_diegetic_music: N/A
EOF

wp U06b <<EOF
How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; Picture 2 (from Shot 1) aligns with the 8.00-second mark of the target video.

integrated_multimodal_description: [Shot 1] $STY A single continuous medium shot on the left woman, the 28-year-old with a translucent skincare gel and knitted cardigan (S1), with a phone-screen insert. She begins in the state of Picture 1, an unbranded phone lying dark-screen on her knee, her hand at rest. The camera pushes in with small amplitude at slow speed as the phone lights up and she picks it up; the screen shows a chat message that reads "下班给你带了糖水，少冰，你上次说那家。" She stares at it and does not move. Her thumb hovers over a second, separate chat thread, opens it, then closes it again. She settles into the pose, hand position and framing of Picture 2, the phone lit in her hand and her thumb just leaving the other chat thread. At the very end she murmurs, quiet and almost to herself (S1): <d>[Chinese] ……我回陈默。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum kept present so the pause never goes dead. A single soft phone notification chime as the screen lights, and light taps as her thumb touches the screen.

non_diegetic_music: N/A
EOF

wp U07a <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY A closer handheld shot on the left woman as in <Picture 1>, the 28-year-old with a translucent skincare gel and knitted cardigan (S1), thumbing a reply on her unbranded phone; the right woman with bare skin and a loose cotton shirt (S2) watches from the side. Delivery brisk, no dead tails. The right woman (S2), lighter now: <d>[Chinese] 你知道你刚才那表情像啥吗。</d> The left woman (S1): <d>[Chinese] 像啥。</d> The right woman (S2): <d>[Chinese] 像个刚睡醒的人。</d>

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum. Soft quick taps of her thumb typing on the phone screen.

non_diegetic_music: N/A
EOF

wp U07b <<EOF
For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.

integrated_multimodal_description: [Shot 1] $STY A close handheld shot on the left woman as in <Picture 1>, the 28-year-old with a translucent skincare gel and knitted cardigan (S1); the right woman with bare skin and a loose cotton shirt (S2) is beside her. The left woman (S1), quiet: <d>[Chinese] ……我才醒。</d> The right woman (S2), gentle: <d>[Chinese] 不晚，他还在楼下等你呢。</d> The left woman lifts her head toward her friend; her eyes well up and a single tear slips down as a small, relieved smile breaks across her face; it reads as relief, not crying from being scolded, with no reddened or glowing eyes. Her face stays fully and evenly lit and readable all the way through the final frame; the shot does not darken and does not fade to black.

overall_soundscape: A low late-night room tone with a faint clock and refrigerator hum settling softly toward the end. A single quiet breath as she smiles.

non_diegetic_music: N/A
EOF

# ============ 装配 ============
build U01  I2VA  5 "$(i2va U01)"
build U02a I2VA  7 "$(i2va U02a)"
build U02b I2VA  9 "$(i2va U02b)"
build U03a I2VA  6 "$(i2va U03a)"
build U03b I2VA  6 "$(i2va U03b)"
build U04a I2VA  10 "$(i2va U04a)"
build U04b I2VA  7 "$(i2va U04b)"
build U05a I2VA  8 "$(i2va U05a)"
build U05b I2VA  9 "$(i2va U05b)"
build U06a I2VA  6 "$(i2va U06a)"
build U06b FL2VA 8 "[{\"type\":\"image_url\",\"image_url\":{\"url\":\"pending\"},\"local_path\":\"$SHOTS/U06b-first.png\",\"role\":\"first_frame\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"pending\"},\"local_path\":\"$SHOTS/U06b-last-v2.png\",\"role\":\"last_frame\"}]"
build U07a I2VA  6 "$(i2va U07a)"
build U07b I2VA  4 "$(i2va U07b)"

echo "===== 13 条视频提示词已装配并过 h3 校验门 ====="
