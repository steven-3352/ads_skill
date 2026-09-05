# WILD MODE production log

## 01 - Black panther pair to shoes

- Status: approved
- Model: `doubao-seedance-2-0-mini-260615`
- Duration: 5 seconds
- Resolution: 720p
- Mode: first frame + last frame
- First frame: `keyframes/production/shoes-state-a-animal-v2.png`
- Last frame: `keyframes/production/shoes-state-c-product-v3.png`
- Prompt: `prompts/video-shoes-transform-v1.json`
- Video: `videos/video-shoes-transform-v1-task.mp4`
- Task ID: `task_hrvRL1Pebk6tl652zoSmxUwWKr5DK7ry`

### Review

- Exactly two real black panther cubs at the opening.
- Mechanical-animal intermediate state remains readable.
- Both bodies lower and fold into a matched pair of shoes.
- Room, table and wardrobe remain substantially stable.
- No person, hand, third animal, smoke or full-screen magic transition.
- A small cobalt mechanical glow appears during the final lock; acceptable as a product accent unless a fully non-emissive mechanical style is preferred.

### API lesson

Seedance 2.0 mini first/last-frame mode (`flf2v`) rejects the `camera_fixed` parameter. Camera stability must be requested in the prompt, and the field must be omitted from the request.

## 02 - Jewel beetle to watch

- Status: approved
- Model: `doubao-seedance-2-0-mini-260615`
- Duration: 5 seconds
- Resolution: 720p
- Mode: first frame + last frame
- First frame: `keyframes/production/watch-state-a-animal-v1.png`
- Last frame: `keyframes/production/watch-state-c-product-v1.png`
- Prompt: `prompts/video-watch-transform-v1.json`
- Video: `videos/video-watch-transform-v1-task.mp4`
- Task ID: `task_yZoOnnzCmRgIosJH2YoEc8lu6n2UMq7d`

### Review

- Emerald wing cases open to reveal the watch mechanism.
- Body core resolves into the watch face; legs and shell segments become the strap.
- Stable macro tabletop framing and consistent room background.
- User approved without revision.

## 03 - Dragonfly to sunglasses

- Status: approved
- Model: `doubao-seedance-2-0-mini-260615`
- Duration: 5 seconds
- Resolution: 720p
- Mode: first frame + last frame
- First frame: `keyframes/production/glasses-state-a-animal-v1.png`
- Last frame: `keyframes/production/glasses-state-c-product-v1.png`
- Prompt: `prompts/video-glasses-transform-v1.json`
- Video: `videos/video-glasses-transform-v1-task.mp4`
- Task ID: `task_L3qigRF31cgEeVvBcKuhIDrKlFQfjmJz`

### Review

- Compound eyes visibly expand into the two lenses.
- Wings and abdomen remain identifiable through the mechanical middle state, then fold into the frame and temples.
- Final eyewear is complete and commercially wearable.
- Background and tabletop remain stable.

## 04 - King snake to belt

- Status: approved
- Model: `doubao-seedance-2-0-mini-260615`
- Duration: 5 seconds
- Resolution: 720p
- Mode: first frame + last frame
- First frame: `keyframes/production/belt-state-a-animal-v1.png`
- Last frame: `keyframes/production/belt-state-c-product-v1.png`
- Prompt: `prompts/video-belt-transform-v1.json`
- Video: `videos/video-belt-transform-v1-task.mp4`
- Task ID: `task_54IQvYsV1vnXIx3wTjg6RKPq0BLPT77k`

### Review

- Original S curve and full body length are preserved through the transformation.
- Scales become articulated mechanical segments; head resolves into the buckle.
- Final belt is clean and complete with a stable background.
- Minor cobalt mechanical glints appear but do not obscure the transformation.

## 05 - Peregrine falcon to cap

- Status: approved
- Model: `doubao-seedance-2-0-mini-260615`
- Duration: 5 seconds
- Resolution: 720p
- Mode: first frame + last frame
- First frame: `keyframes/production/hat-state-a-animal-v1.png`
- Last frame: `keyframes/production/hat-state-c-product-v1.png`
- Prompt: `prompts/video-hat-transform-v1.json`
- Video: `videos/video-hat-transform-v1-task.mp4`
- Task ID: `task_wYfoejbRQl8X6cRXRoBcz4ixESthSizF`

### Review

- Crown panels emerge from the back and wing structure; the wings close toward the center.
- Final cap is complete, stable and matches the approved design.
- During the middle state, the cap briefly reads as covering the bird before the remaining body resolves; this is the main point to review.

## Final edit - Fast cut v1

- Status: completed and technically verified
- Output: `final/wild-mode-fast-cut-v1.mp4`
- Duration: 15.033 seconds
- Delivery: 720 x 1256, 30 fps, H.264 video, AAC stereo audio
- Music: extracted from the supplied `原来是陶阿狗君-暗夜赴会，月亮缺席。_#沙漏变装_#暗黑-20260905061621.mp4`
- Edit script: `edit/build-wild-mode-v1.sh`
- Timeline: `edit/timeline-v1.md`

### Edit structure

- A 0.662-second room establishing shot sets up the shared morning location.
- The panther transformation establishes the visual rule; the other four transformations accelerate progressively on the music beats.
- Five rapid result shots verify shoes, watch, belt, sunglasses and cap before revealing the complete outfit.
- The final back-view exit closes the morning departure story without adding text, branding or logos.

### QA

- No black frames, broken dimensions or missing audio track detected.
- Music and cuts retain the supplied reference track's approximately 129 BPM momentum.
- All five animal, mechanical and product states remain visible after speed changes.
- Result-shot crops correspond to the intended accessories and retain the same character and room.
- Audio peak is limited to 0 dBFS; generated mechanical sounds remain subordinate to the music.

## Final edit - Fast cut v2

- Status: completed and technically verified
- Output: `final/wild-mode-fast-cut-v2.mp4`
- Duration: 15.033 seconds
- Delivery: 720 x 1256, 30 fps, H.264 video, AAC stereo audio
- Music: unchanged from the user-supplied reference video
- Edit script: `edit/build-wild-mode-v2.sh`
- Timeline: `edit/timeline-v2.md`

### Changes from v1

- Retained all approved animal-to-product transformation videos.
- Rebuilt accessory confirmation as four 0.26-second beat flashes.
- Extended the complete outfit reveal to 1.25 seconds and added a restrained cobalt scan treatment.
- Shortened and enlarged the exit shot so the ending moves forward and the footwear mismatch is not visible.
- Added a circular mechanical closure, scan whoosh and final lock impact instead of letting the walk simply run out.
- Unified the generated clips with mild color, contrast, vignette, sharpening and grain treatment.

### QA

- Output contains 451 frames with a continuous stereo audio track.
- No unintended black frames; the final 0.13-second black hold is deliberate punctuation.
- No missing dimensions, frame stretching or audio decoding errors detected.
- Final peak reaches 0 dBFS under the limiter; average level is approximately -10.3 dBFS.
