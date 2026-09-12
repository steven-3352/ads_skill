(async () => {
  const e = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const get = (p) => fetch('../' + p).then((r) => { if (!r.ok) throw new Error(p + ' ' + r.status); return r.json(); });
  const getSafe = (p) => get(p).catch(() => null);

  const n = document.body.dataset.shot;
  const assets = window.PUBLIC_ASSETS ? window.PUBLIC_ASSETS : await getSafe('review/public-assets.json');

  const [intake, screenplay, grammar, plan, prompts] = await Promise.all([
    getSafe('contracts/project-intake.json'),
    getSafe('contracts/screenplay.json'),
    getSafe('contracts/visual-grammar.json'),
    getSafe('contracts/production-plan.json'),
    getSafe('contracts/shot-prompts.json'),
  ]);

  const shots = plan?.narrativeShots || [];
  const beatById = {};
  (screenplay?.beats || []).forEach((b) => { beatById[b.id] = b; });
  const title = plan?.title || intake?.creativeLocked?.title || '项目';
  const storyMd = screenplay?.source || (intake?.input?.storyFile) || '';
  const diaWho = (d) => d.speaker || d.who || '';

  const claimsFor = (shot) => {
    const claims = {};
    (shot.generationUnits || []).forEach((u) => (u.cuts || []).forEach((cut) => {
      (cut.coverage || []).forEach((cov) => (cov.channels || []).forEach((ch) => {
        claims[cov.beatId + ':' + ch] = { owner: '切镜 ' + cut.id, kind: 'cut' };
      }));
    }));
    (shot.postTasks || []).forEach((t) => (t.coverage || []).forEach((cov) => {
      (cov.channels || []).forEach((ch) => { claims[cov.beatId + ':' + ch] = { owner: t.type + ' · ' + t.id, kind: 'post' }; });
    }));
    return claims;
  };

  const CH_LABEL = { picture: '画面', dialogue: '对白', action_sound: '动作声', ambience: '环境声', transition: '转场', onscreen_text: '屏幕文字' };
  const tlBadge = (tl) => tl === 'then'
    ? '<span class="badge badge-then">四年前·暖</span>'
    : '<span class="badge badge-now">现在·冷</span>';

  const STYLE = '<style>'
    + '.badge{display:inline-block;font-size:11px;font-weight:800;padding:2px 7px;border-radius:4px;border:1px solid var(--line)}'
    + '.badge-now{color:#bcd6ff;background:#12202f;border-color:#274763}'
    + '.badge-then{color:#ffcf9a;background:#241c0f;border-color:#5a421d}'
    + '.grid2{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:14px;margin:0 0 10px}'
    + '.card{background:var(--panel);border:1px solid var(--line);border-radius:6px;padding:14px 16px;margin:0 0 12px}'
    + '.card-now{border-left:3px solid #4a90d9}.card-then{border-left:3px solid var(--accent)}'
    + '.card h3,.card h4{margin:2px 0 8px}.card p{margin:4px 0}'
    + '.tbl{width:100%;border-collapse:collapse;margin:6px 0 18px;font-size:14px}'
    + '.tbl th,.tbl td{border:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}'
    + '.tbl th{background:#111419;color:var(--muted);font-size:12px}'
    + '.dia{max-width:820px}.dia li{margin:3px 0}'
    + '.shotlist li{margin:5px 0}'
    + '.own-cut{color:#bcd6ff}.own-post{color:#ffd48a}'
    + '.note{color:var(--muted)}.empty{color:var(--muted);background:#0a0c0f;border:1px dashed var(--line);padding:10px;border-radius:5px}'
    + '.asset-img{max-height:520px;max-width:100%;width:auto;object-fit:contain;border:1px solid var(--line);border-radius:5px;margin-top:8px}'
    + '.slots{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px;margin:6px 0 10px}'
    + '.slot{background:#0a0c0f;border:1px solid var(--line);border-radius:5px;padding:10px}'
    + '.slot figcaption{font-size:12px;color:var(--muted);word-break:break-all;margin:0 0 6px}'
    + '.rhyme{display:grid;grid-template-columns:1fr 1fr;gap:14px;align-items:start;margin:6px 0 16px}'
    + '.rhyme .slot{border-width:2px}.rhyme .warm{border-color:#5a421d}.rhyme .cold{border-color:#274763}'
    + '.lb-masters{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;margin:6px 0 16px}'
    + 'pre.align{color:#9bd6a0;background:#0c140d}'
    + '@media(max-width:640px){.rhyme{grid-template-columns:1fr}}'
    + '</style>';

  const nav = STYLE + '<nav><a href="index.html">项目首页</a>'
    + (storyMd ? ' · <a href="md-viewer.html?file=../' + e(storyMd) + '">原始故事 MD</a>' : '')
    + ' · <a href="md-viewer.html?file=../characters.md">人物圣经 MD</a></nav>';

  let h = nav;

  const assetCardImg = (a) => a?.path
    ? '<img class="asset-img" loading="lazy" src="../' + e(a.path) + '" alt="' + e(a.id) + '">'
    : '<div class="empty">待生成</div>';

  if (!n) {
    // ---------- Homepage ----------
    h += '<h1>《' + e(title) + '》 · 导演层 + 看板评审</h1>';
    h += '<p>阶段：' + e(intake?.stage) + ' · 状态：' + e(assets?.status || intake?.status)
      + ' · 锁定模型：' + e(plan?.promptPolicy?.model || intake?.brief?.model)
      + ' · 分镜数：' + shots.length
      + ' · 时长上限：' + e(plan?.constraints?.durationCeilingSeconds) + 's（不拖沓不注水）</p>';
    h += '<p class="note">主题：' + e(plan?.title && (screenplay?.theme || intake?.creativeLocked?.theme)) + '</p>';

    // ===== FINAL FILM (成片) =====
    h += '<h2>🎬 成片（≈48.6s · 竖屏 9:16 · 15 镜全生成）</h2>';
    h += '<video class="asset-img" style="max-height:78vh" controls preload="metadata" '
      + 'src="../edit/passenger-seat-final.mp4" '
      + 'onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'block\'"></video>';
    h += '<div class="empty" style="display:none">成片 edit/passenger-seat-final.mp4 未就绪（媒体不入库，本地/目录服务播放）。</div>';
    h += '<p class="note">覆盖剪辑：15 镜按 keep 变时长裁窗 → 连续性剪（视线/动作匹配）→ 冷暖分级（暖 4600K 金橙 / 冷 8600K 青蓝）→ 09→10 签名 A 暖硬切冷（同机位右手伸向空副驾）→ 对白/主题 ASS（Noto Serif CJK SC，仅 05/06/13 三句对白）→ loudnorm I=-16:TP=-1.5:LRA=11 → 2s 主题卡「你习惯了她在，就忘了她已经不在。」</p>';

    // ===== LOOK BOARD (current review focus) =====
    const lb = assets?.lookBoard;
    if (lb) {
      h += '<h2>① 看板：锁脸 / 车 / 机位</h2>';
      h += '<p class="note">' + e(lb.note) + '</p>';
      h += '<h3>身份/空间锚（master）</h3><div class="lb-masters">';
      (lb.masters || []).forEach((a) => {
        h += '<figure class="slot"><figcaption>' + e(a.id) + '（' + e(a.status) + '）</figcaption>'
          + assetCardImg(a) + '<p class="note" style="font-size:12px">' + e(a.usage) + '</p></figure>';
      });
      h += '</div>';
      if (lb.signatureA) {
        const s = lb.signatureA;
        h += '<h3>' + e(s.name) + '</h3>';
        h += '<div class="rhyme">';
        h += '<figure class="slot warm"><figcaption>' + tlBadge('then') + ' shot-07 · ' + e(s.has?.usage) + '</figcaption>' + assetCardImg(s.has) + '</figure>';
        h += '<figure class="slot cold"><figcaption>' + tlBadge('now') + ' shot-10 · ' + e(s.empty?.usage) + '</figcaption>' + assetCardImg(s.empty) + '</figure>';
        h += '</div>';
        h += '<p class="note"><b>对仗规则</b>：' + e(s.rule) + '</p>';
      }
      if ((lb.pending || []).length) {
        h += '<p class="note">看板阶段暂缓：' + (lb.pending || []).map((a) => e(a.id)).join('、') + '（看板通过后随全量15镜生成）。</p>';
      }
    }

    // Visual grammar (two timelines)
    if (grammar?.timelines) {
      h += '<h2>② 视觉语法（两条时间线）</h2><div class="grid2">';
      ['now', 'then'].forEach((k) => {
        const t = grammar.timelines[k];
        if (!t) return;
        h += '<article class="card ' + (k === 'then' ? 'card-then' : 'card-now') + '">'
          + '<h3>' + e(t.label) + '</h3>'
          + '<p><b>场景</b>：' + e((t.scenes || []).join('、')) + '</p>'
          + '<p><b>色彩</b>：' + e(t.color) + '</p>'
          + '<p><b>光线</b>：' + e(t.lighting) + '</p>'
          + '<p><b>景别/构图</b>：' + e(t.framing) + '</p>'
          + '<p><b>相机</b>：' + e(t.camera) + '</p>'
          + '<p><b>声音</b>：' + e(t.sound) + '</p>'
          + '<p><b>表演</b>：' + e(t.performance) + '</p>'
          + '<p><b>意义</b>：' + e(t.meaning) + '</p></article>';
      });
      h += '</div>';
      h += '<h3>签名机关</h3><ul>';
      Object.entries(grammar.matchCuts || {}).forEach(([key, mc]) => {
        h += '<li><b>签名' + e(key) + '｜' + e(mc.name) + '</b>（' + e(mc.type) + '）：' + e(mc.rule) + '</li>';
      });
      if (grammar.endingCallback) {
        h += '<li><b>结尾回扣</b>：过去=' + e(grammar.endingCallback.then)
          + '；现在=' + e(grammar.endingCallback.now) + '（' + e(grammar.endingCallback.rule) + '）</li>';
      }
      h += '</ul>';
    }

    // Screenplay structure
    if (screenplay) {
      h += '<h2>③ 剧本结构（场景锚定节拍）</h2>';
      h += '<p>' + e(screenplay.coreAction) + '<br>主题：' + e(screenplay.theme) + '</p>';
      h += '<table class="tbl"><thead><tr><th>节拍</th><th>时间线</th><th>场景</th><th>分镜</th><th>内容</th></tr></thead><tbody>';
      (screenplay.beats || []).forEach((b) => {
        h += '<tr><td>' + e(b.id) + '</td><td>' + tlBadge(b.timeline) + '</td><td>' + e(b.sceneId)
          + '</td><td><a href="shot-' + e(b.shot) + '.html">' + e(b.shot) + '</a></td><td>' + e(b.text) + '</td></tr>';
      });
      h += '</tbody></table>';

      h += '<h3>对白（' + (screenplay.dialogue || []).length + ' 句，与原故事逐字一致）</h3><ol class="dia">';
      (screenplay.dialogue || []).forEach((d) => {
        h += '<li><b>' + e(diaWho(d)) + '</b>（' + e(d.beat) + '）：「' + e(d.line) + '」</li>';
      });
      h += '</ol>';
      h += '<h3>旁白</h3><ol class="dia">';
      (screenplay.voiceover || []).forEach((d) => {
        h += '<li><b>' + e(diaWho(d) || '旁白') + '</b>（' + e(d.beat || d.at || '') + '，唇闭合）：「' + e(d.line) + '」</li>';
      });
      h += '</ol>';
    }

    // Beat coverage table
    if (shots.length) {
      h += '<h2>④ 节拍通道覆盖（每个节拍:通道恰好认领一次）</h2>';
      h += '<table class="tbl"><thead><tr><th>分镜</th><th>节拍</th><th>通道</th><th>由谁承担</th></tr></thead><tbody>';
      shots.forEach((shot) => {
        const claims = claimsFor(shot);
        (shot.requiredBeats || []).forEach((beat) => {
          (beat.channels || []).forEach((ch, i) => {
            const c = claims[beat.id + ':' + ch];
            h += '<tr>'
              + (i === 0 ? '<td rowspan="' + beat.channels.length + '"><a href="shot-' + e(shot.id) + '.html">' + e(shot.id) + '</a></td>' : '')
              + (i === 0 ? '<td rowspan="' + beat.channels.length + '">' + e(beat.id) + '</td>' : '')
              + '<td>' + e(CH_LABEL[ch] || ch) + '</td>'
              + '<td class="' + (c?.kind === 'post' ? 'own-post' : 'own-cut') + '">' + e(c ? c.owner : '⚠ 未认领') + '</td></tr>';
          });
        });
      });
      h += '</tbody></table>';
    }

    // Shot list
    h += '<h2>⑤ 分镜（' + shots.length + '）</h2><ul class="shotlist">';
    shots.forEach((s) => {
      const dur = (s.generationUnits || []).reduce((a, u) => a + (u.durationSeconds || 0), 0);
      const done = ' · ✅已出视频(5s)';
      h += '<li><a href="shot-' + e(s.id) + '.html">分镜 ' + e(s.id) + '</a> · ' + tlBadge(s.timeline)
        + ' · ' + e(s.title) + ' · ' + e(s.inputMode) + ' · ' + dur + 's' + done + '</li>';
    });
    h += '</ul>';

    // Public assets (all)
    h += '<h2>⑥ 公共资产与提示词</h2><div class="grid2">';
    (assets?.publicAssets || []).forEach((a) => {
      h += '<article class="card"><h3>' + e(a.id) + '</h3>'
        + '<p>类型：' + e(a.type) + ' · 状态：' + e(a.status) + '</p>'
        + '<p>用途：' + e(a.usage) + '</p>'
        + assetCardImg(a)
        + '<details><summary>提示词（' + e(a.prompt || '空') + '）</summary><pre>' + e(a.prompt_text || '空') + '</pre></details></article>';
    });
    h += '</div>';
  } else {
    // ---------- Shot page ----------
    const shot = shots.find((s) => s.id === n);
    if (!shot) {
      h += '<h1>分镜 ' + e(n) + '</h1><p class="empty">未在 production-plan.json 找到该分镜。</p>';
      document.querySelector('#app').innerHTML = h;
      return;
    }
    const tl = shot.timeline;
    const g = grammar?.timelines?.[shot.visualGrammar] || grammar?.timelines?.[tl];
    const claims = claimsFor(shot);
    const assetByPath = {};
    (assets?.publicAssets || []).forEach((a) => { if (a.path) assetByPath[a.path] = a; });

    h += '<h1>分镜 ' + e(shot.id) + '｜' + e(shot.title) + '</h1>';
    h += '<p>' + tlBadge(tl) + ' · 输入模式 ' + e(shot.inputMode)
      + (shot.matchCut ? ' · 签名机关 ' + e(shot.matchCut) : '') + '</p>';

    h += '<h2>导演卡</h2><div class="card">';
    h += '<p><b>相机</b>：' + e(shot.camera) + '</p>';
    if (g) {
      h += '<p><b>视觉语法（' + e(g.label) + '）</b>：' + e(g.color) + '；' + e(g.lighting)
        + '；' + e(g.framing) + '；相机 ' + e(g.camera) + '；声音 ' + e(g.sound) + '</p>';
    }
    h += '<p><b>原故事对应（verbatim）</b>：' + e(shot.source?.verbatim) + '</p>';
    h += '</div>';

    h += '<h2>节拍与通道覆盖</h2>';
    (shot.requiredBeats || []).forEach((beat) => {
      h += '<article class="card"><h3>' + e(beat.id) + '</h3><p>' + e(beat.text) + '</p><ul>';
      (beat.channels || []).forEach((ch) => {
        const c = claims[beat.id + ':' + ch];
        h += '<li>' + e(CH_LABEL[ch] || ch) + ' → <span class="' + (c?.kind === 'post' ? 'own-post' : 'own-cut') + '">'
          + e(c ? c.owner : '⚠ 未认领') + '</span></li>';
      });
      h += '</ul></article>';
    });

    const dia = (screenplay?.dialogue || []).filter((d) => beatById[d.beat]?.shot === n);
    const vo = (screenplay?.voiceover || []).filter((d) => beatById[d.beat]?.shot === n);
    if (dia.length || vo.length) {
      h += '<h2>本镜对白 / 旁白</h2><ol class="dia">';
      dia.forEach((d) => { h += '<li><b>' + e(diaWho(d)) + '</b>：「' + e(d.line) + '」</li>'; });
      vo.forEach((d) => { h += '<li><b>' + e(diaWho(d) || '旁白') + '</b>（旁白，唇闭合）：「' + e(d.line) + '」</li>'; });
      h += '</ol>';
    }

    h += '<h2>生成单元（H3 ≤15s/单元）</h2>';
    const kfPaths = [];
    (shot.generationUnits || []).forEach((u) => (u.prompts?.images || []).forEach((p) => kfPaths.push(p)));
    const kfDocs = {};
    await Promise.all([...new Set(kfPaths)].map((p) => getSafe(p).then((d) => { kfDocs[p] = d; })));

    const onerr = ' onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'block\'"';
    for (const u of (shot.generationUnits || [])) {
      const vp = prompts?.units?.[u.id];
      h += '<div class="card"><h3>' + e(u.id) + ' · ' + e(u.inputMode) + ' · ' + e(u.durationSeconds) + 's</h3>';
      h += '<p><b>切镜</b>：' + (u.cuts || []).map((c) => e(c.id) + '(' + e(c.seconds) + 's：' + e(c.camera) + ')').join(' → ') + '</p>';

      if ((u.references || []).length) {
        h += '<h4>参考资源</h4><div class="slots">';
        (u.references || []).forEach((r) => {
          const a = assetByPath[r];
          h += '<figure class="slot"><figcaption>' + e(r) + (a ? ' · ' + e(a.id) + '（' + e(a.status) + '）' : '') + '</figcaption>'
            + '<img class="asset-img" loading="lazy" src="../' + e(r) + '" alt="' + e(r) + '"' + onerr + '>'
            + '<div class="empty" style="display:none">资源缺失（媒体不入库，线上由目录服务提供）</div>'
            + (a ? '<details><summary>参考资源提示词（' + e(a.model || '') + '）</summary><pre>' + e(a.prompt_text || '空') + '</pre></details>' : '')
            + '</figure>';
        });
        h += '</div>';
      }

      const imgByKind = {};
      (u.prompts?.images || []).forEach((p) => { imgByKind[/-last\./.test(p) ? 'last' : 'first'] = p; });
      const frameSlot = (label, mediaPath, promptPath) => {
        let s = '<figure class="slot"><figcaption>' + e(label) + (mediaPath ? '：' + e(mediaPath) : '') + '</figcaption>';
        if (mediaPath) {
          s += '<img class="asset-img" loading="lazy" src="../' + e(mediaPath) + '" alt="' + e(label) + '"' + onerr + '>'
            + '<div class="empty" style="display:none">待生成（generation_allowed=' + e(String(plan?.generation_allowed)) + '）</div>';
        } else { s += '<div class="empty">本单元无此帧</div>'; }
        const d = promptPath ? kfDocs[promptPath] : null;
        if (promptPath && d) {
          const gate = d.seedance_prompt_review || d.h3_prompt_review;
          const gateName = d.seedance_prompt_review ? 'seedance' : (d.h3_prompt_review ? 'h3' : '—');
          const gen = d.generator || d.model || '';
          const sha = gate?.reviewed_prompt_sha256;
          s += '<p class="note">提示词 ' + e(promptPath) + ' · 模式 ' + e(d.mode)
            + (gen ? ' · 生成 ' + e(gen) : '')
            + ' · 门禁(' + e(gateName) + ') ' + (gate?.result === 'pass' ? '✅ pass' : '⚠ 未过')
            + (sha ? ' · SHA ' + e(sha.slice(0, 12)) + '…' : '') + '</p>'
            + '<details><summary>关键帧提示词</summary><pre>' + e(d.prompt) + '</pre></details>';
        } else if (promptPath) {
          s += '<p class="empty">提示词文件缺失：' + e(promptPath) + '</p>';
        }
        return s + '</figure>';
      };
      h += '<h4>首帧 / 尾帧</h4><div class="slots">';
      h += frameSlot('首帧', u.media?.firstFrame, imgByKind.first);
      h += frameSlot('尾帧', u.media?.lastFrame, imgByKind.last);
      h += '</div>';

      h += '<h4>视频（H3 视频内含对白/拟音/环境声）</h4><div class="slots"><figure class="slot">'
        + '<figcaption>' + e(u.media?.video || '（未定义视频目标）') + '</figcaption>';
      if (u.media?.video) {
        h += '<video class="asset-img" controls preload="none" src="../' + e(u.media.video) + '"' + onerr + '></video>'
          + '<div class="empty" style="display:none">待生成（generation_allowed=' + e(String(plan?.generation_allowed)) + '）</div>';
      } else { h += '<div class="empty">未定义视频目标</div>'; }
      h += '</figure></div>';
      if (vp) {
        h += '<p class="note">H3 视频提示词状态：' + e(vp.status) + '</p>';
        if (vp.alignment_instruction) h += '<pre class="align">' + e(vp.alignment_instruction) + '</pre>';
        h += '<pre>integrated_multimodal_description: ' + e(vp.integrated_multimodal_description) + '\n\n'
          + 'overall_soundscape: ' + e(vp.overall_soundscape) + '\n\n'
          + 'non_diegetic_music: ' + e(vp.non_diegetic_music) + '</pre>';
      }
      h += '</div>';
    }

    if ((shot.postTasks || []).length) {
      h += '<h2>后期任务</h2><ul>';
      (shot.postTasks || []).forEach((t) => { h += '<li><b>' + e(t.type) + '</b>（' + e(t.id) + '）：' + e(t.description) + '</li>'; });
      h += '</ul>';
    }
  }

  document.querySelector('#app').innerHTML = h;
})().catch((err) => {
  document.querySelector('#app').textContent = '页面加载失败：' + err.message;
});
