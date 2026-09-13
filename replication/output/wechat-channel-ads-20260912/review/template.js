/* wechat-channel-ads-20260912 · 3A 评审页渲染器
 * 契约为唯一事实源:动态 fetch contracts/*.json,不写死内容。
 * 页面靠 <body data-shot="NN"> 区分:空=首页;"01"..="09"=分镜页。
 */
(function () {
  const $ = (sel, root) => (root || document).querySelector(sel);
  const el = (tag, cls, html) => {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (html != null) n.innerHTML = html;
    return n;
  };
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]));
  const getSafe = async (p) => {
    try {
      const r = await fetch("../" + p, { cache: "no-store" });
      if (!r.ok) return null;
      if (p.endsWith(".json")) return await r.json();
      return await r.text();
    } catch (e) { return null; }
  };

  const CHANNEL_LABEL = {
    picture: "画面", dialogue: "对白/旁白", action_sound: "动作·拟音",
    ambience: "环境声", transition: "转场", onscreen_text: "屏幕字",
  };

  // slot：显示一个媒体位(图/视频)与其状态
  function mediaSlot(path, kind, label) {
    const box = el("div", "slot");
    box.appendChild(el("div", "slot-label", esc(label)));
    if (!path) { box.appendChild(el("div", "slot-empty", "契约未定义")); return box; }
    const url = "../" + path;
    if (kind === "video") {
      const v = document.createElement("video");
      v.src = url; v.controls = true; v.playsInline = true;
      v.onerror = () => { v.replaceWith(el("div", "slot-empty", "待生成 · " + esc(path))); };
      box.appendChild(v);
    } else {
      const img = document.createElement("img");
      img.src = url; img.loading = "lazy";
      img.onerror = () => { img.replaceWith(el("div", "slot-empty", "待生成 · " + esc(path))); };
      box.appendChild(img);
    }
    box.appendChild(el("div", "slot-path", esc(path)));
    return box;
  }

  // 提示词卡：内嵌展示 .prompt 全文 + 闸门状态
  async function promptCard(path, label) {
    const box = el("div", "prompt");
    const head = el("div", "prompt-head");
    head.appendChild(el("span", "prompt-label", esc(label)));
    box.appendChild(head);
    const j = await getSafe(path);
    if (!j) { box.appendChild(el("div", "slot-empty", "提示词未写 · " + esc(path))); return box; }
    const gates = [];
    if (j.seedance_prompt_review) gates.push("图片闸门 seedance:" + (j.seedance_prompt_review.result || "?"));
    if (j.h3_prompt_review) gates.push("H3:" + (j.h3_prompt_review.result || "?"));
    head.appendChild(el("span", "prompt-gate " + (gates.every((g) => g.includes("pass")) ? "ok" : "no"), esc(gates.join(" · ") || "未过闸门")));
    if (j.mode) head.appendChild(el("span", "tag", esc(j.mode)));
    box.appendChild(el("pre", "prompt-body", esc(j.prompt || "(空)")));
    box.appendChild(el("div", "slot-path", esc(path)));
    return box;
  }

  function coverageOwners(shot) {
    const owners = {}; // key beatId:channel -> [labels]
    for (const u of shot.generationUnits || []) {
      for (const c of u.cuts || []) {
        for (const cov of c.coverage || []) {
          for (const ch of cov.channels || []) {
            const k = cov.beatId + ":" + ch;
            (owners[k] = owners[k] || []).push(`剪辑 ${u.id}/${c.id}`);
          }
        }
      }
    }
    for (const t of shot.postTasks || []) {
      for (const cov of t.coverage || []) {
        for (const ch of cov.channels || []) {
          const k = cov.beatId + ":" + ch;
          (owners[k] = owners[k] || []).push(`后期 ${t.id}(${t.type})`);
        }
      }
    }
    return owners;
  }

  async function renderHome(root, intake, plan, screenplay, assets) {
    const meta = intake?.brief || {};
    root.appendChild(el("h1", "title", esc(plan?.title || intake?.pilot || "评审页")));
    const chips = el("div", "chips");
    const chip = (k, v) => chips.appendChild(el("span", "chip", `<b>${esc(k)}</b> ${esc(v)}`));
    chip("模型", plan?.promptPolicy?.model || meta.model);
    chip("提示词技能", plan?.promptPolicy?.authoringSkill);
    chip("画幅", meta.aspect);
    chip("目标时长", (meta.duration_target_seconds ?? "") + "s");
    chip("镜数", (plan?.narrativeShots?.length ?? "") + " 镜");
    chip("阶段", intake?.stage);
    chip("付费", plan?.generation_allowed ? "已放行" : "未放行(本页零付费)");
    root.appendChild(chips);

    // 信息确认横幅
    root.appendChild(el("div", "banner", "本页供确认信息,<b>不产生任何付费</b>。确认 9 镜分镜 / 商品100%还原 / 事实闸门后,才进入关键帧(图片闸门)→报总价→付费生视频。"));

    // 成片位(尚无)
    const film = el("section", "card");
    film.appendChild(el("h2", null, "成片"));
    film.appendChild(mediaSlot("edit/03-final.mp4", "video", "覆盖剪辑成片(待生成)"));
    root.appendChild(film);

    // 驱动四层
    if (plan?.driver) {
      const d = plan.driver, s = el("section", "card");
      s.appendChild(el("h2", null, "驱动四层"));
      const rows = [["主引擎", d.mainEngine], ["动力", d.momentum], ["点睛", d.highlight], ["缝合", d.stitch], ["氛围", d.ambienceNote]];
      const t = el("table", "kv");
      rows.forEach(([k, v]) => { const tr = el("tr"); tr.appendChild(el("th", null, esc(k))); tr.appendChild(el("td", null, esc(v))); t.appendChild(tr); });
      s.appendChild(t); root.appendChild(s);
    }

    // 商品 100% 还原
    if (intake?.productFidelity || plan?.productFidelity) {
      const pf = plan?.productFidelity || {}, ipf = intake?.productFidelity || {};
      const s = el("section", "card warn");
      s.appendChild(el("h2", null, "商品 100% 还原"));
      s.appendChild(el("p", null, esc(pf.rule || ipf.rule)));
      s.appendChild(el("p", null, "涉及镜头:" + esc((ipf.affectedShots || pf.shots || []).join("、"))));
      s.appendChild(el("p", "muted", "真图素材:" + esc(pf.asset || ipf.asset) + " — " + esc(pf.note || "")));
      root.appendChild(s);
    }

    // 事实闸门
    if (intake?.factGate) {
      const fg = intake.factGate, s = el("section", "card danger");
      s.appendChild(el("h2", null, "事实闸门(未核验不进成片)"));
      const mk = (title, arr) => {
        s.appendChild(el("h3", null, esc(title)));
        const ul = el("ul");
        (arr || []).forEach((x) => ul.appendChild(el("li", null, esc(x))));
        s.appendChild(ul);
      };
      mk("禁用/待举证", fg["禁用_未核验前不进成片"]);
      mk("允许表现", fg["允许表现"]);
      root.appendChild(s);
    }

    // 剧本节拍 + 旁白
    if (screenplay) {
      const s = el("section", "card");
      s.appendChild(el("h2", null, `剧本节拍 · ${esc(screenplay.coreAction || "")}`));
      const t = el("table", "grid");
      t.appendChild(headRow(["镜", "节拍", "声画通道"]));
      (screenplay.beats || []).forEach((b) => {
        const tr = el("tr");
        tr.appendChild(el("td", null, esc(b.shot)));
        tr.appendChild(el("td", null, esc(b.text)));
        tr.appendChild(el("td", null, (b.channels || []).map((c) => CHANNEL_LABEL[c] || c).join(" · ")));
        t.appendChild(tr);
      });
      s.appendChild(t);
      if ((screenplay.voiceover || []).length) {
        s.appendChild(el("h3", null, "旁白(点睛)"));
        const ul = el("ul");
        screenplay.voiceover.forEach((v) => ul.appendChild(el("li", null, `<b>${esc(v.beat)}</b> ${esc(v.who)}:「${esc(v.line)}」`)));
        s.appendChild(ul);
      }
      root.appendChild(s);
    }

    // 分镜清单
    const s = el("section", "card");
    s.appendChild(el("h2", null, "分镜清单(9 镜)"));
    const t = el("table", "grid");
    t.appendChild(headRow(["镜", "标题", "模式", "时长", "机位", "声音", ""]));
    (plan?.narrativeShots || []).forEach((sh) => {
      const tr = el("tr");
      tr.appendChild(el("td", null, esc(sh.id)));
      tr.appendChild(el("td", null, esc(sh.title)));
      tr.appendChild(el("td", null, `<span class="tag">${esc(sh.inputMode)}</span>`));
      const dur = (sh.generationUnits || []).reduce((a, u) => a + (u.durationSeconds || 0), 0);
      const content = (sh.generationUnits || []).reduce((a, u) => a + (u.contentSeconds || u.durationSeconds || 0), 0);
      tr.appendChild(el("td", null, `${content}s<span class="muted"> / 计费${dur}s</span>`));
      tr.appendChild(el("td", null, esc(sh.camera)));
      tr.appendChild(el("td", null, esc(sh.soundNote)));
      tr.appendChild(el("td", null, `<a href="shot-${esc(sh.id)}.html">查看 ›</a>`));
      t.appendChild(tr);
    });
    s.appendChild(t);
    root.appendChild(s);

    // 成本预估
    if (intake?.costEstimate) {
      const c = intake.costEstimate, sc = el("section", "card");
      sc.appendChild(el("h2", null, "成本预估(仅估算,未付费)"));
      const t2 = el("table", "kv");
      const add = (k, v) => { const tr = el("tr"); tr.appendChild(el("th", null, esc(k))); tr.appendChild(el("td", null, esc(v))); t2.appendChild(tr); };
      add("关键帧", `${c.keyframes_count_estimate} → ${c.keyframes_yuan_estimate}`);
      add("视频", `${c.video_seconds_estimate}s → ${c.video_yuan_estimate}`);
      add("合计", c.total_yuan_estimate);
      add("说明", c.note);
      sc.appendChild(t2);
      root.appendChild(sc);
    }

    // 素材/来源
    const src = el("section", "card muted-card");
    src.appendChild(el("h2", null, "来源与素材"));
    const ul = el("ul");
    ul.appendChild(el("li", null, "拍摄脚本:<a href='md-viewer.html?f=stories/03-3a-shooting-script.md'>stories/03-3a-shooting-script.md</a>"));
    ul.appendChild(el("li", null, "内容锁定稿:03-六商品详细内容脚本.md「03 3A」"));
    ul.appendChild(el("li", null, "事实卡:01-产品事实与核验边界.md「03」"));
    (assets?.list || []).forEach((a) => ul.appendChild(el("li", null, esc(a))));
    src.appendChild(ul);
    root.appendChild(src);
  }

  async function renderShot(root, shotId, intake, plan, screenplay) {
    const shot = (plan?.narrativeShots || []).find((s) => s.id === shotId);
    root.appendChild(el("p", "back", `<a href="index.html">‹ 返回首页</a>`));
    if (!shot) { root.appendChild(el("h1", "title", `未找到分镜 ${esc(shotId)}`)); return; }
    root.appendChild(el("h1", "title", `S${esc(shot.id)} · ${esc(shot.title)}`));

    // 导演卡
    const dc = el("section", "card");
    dc.appendChild(el("h2", null, "导演卡"));
    const t = el("table", "kv");
    const add = (k, v) => { const tr = el("tr"); tr.appendChild(el("th", null, esc(k))); tr.appendChild(el("td", null, esc(v))); t.appendChild(tr); };
    add("输入模式", shot.inputMode);
    add("机位/运镜", shot.camera);
    add("声音", shot.soundNote);
    add("声画对齐", shot.alignment);
    dc.appendChild(t);
    dc.appendChild(el("blockquote", "verbatim", "原文:" + esc(shot.source?.verbatim)));
    root.appendChild(dc);

    // 旁白(本镜)
    const beatIds = new Set((shot.requiredBeats || []).map((b) => b.id));
    const vos = (screenplay?.voiceover || []).filter((v) => beatIds.has(v.beat));
    if (vos.length) {
      const s = el("section", "card");
      s.appendChild(el("h2", null, "本镜旁白"));
      const ul = el("ul");
      vos.forEach((v) => ul.appendChild(el("li", null, `${esc(v.who)}:「${esc(v.line)}」`)));
      s.appendChild(ul);
      root.appendChild(s);
    }

    // 节拍与声画认领
    const owners = coverageOwners(shot);
    const bs = el("section", "card");
    bs.appendChild(el("h2", null, "节拍与声画认领(每通道恰好一次)"));
    (shot.requiredBeats || []).forEach((b) => {
      bs.appendChild(el("h3", null, `${esc(b.id)} · ${esc(b.text)}`));
      const t2 = el("table", "grid");
      t2.appendChild(headRow(["通道", "认领者"]));
      (b.channels || []).forEach((ch) => {
        const tr = el("tr");
        tr.appendChild(el("td", null, CHANNEL_LABEL[ch] || ch));
        tr.appendChild(el("td", null, esc((owners[b.id + ":" + ch] || ["<未认领>"]).join(" / "))));
        t2.appendChild(tr);
      });
      bs.appendChild(t2);
    });
    root.appendChild(bs);

    // 生成单元
    for (const u of shot.generationUnits || []) {
      const s = el("section", "card");
      s.appendChild(el("h2", null, `生成单元 ${esc(u.id)} · <span class="tag">${esc(u.inputMode)}</span> · 内容${esc(u.contentSeconds ?? u.durationSeconds)}s / 计费${esc(u.durationSeconds)}s`));
      if ((u.references || []).length) s.appendChild(el("p", "muted", "参考图:" + esc(u.references.join("、"))));
      // 关键帧图
      const frames = el("div", "frames");
      frames.appendChild(mediaSlot(u.media?.firstFrame, "img", "首帧"));
      if (u.media?.lastFrame) frames.appendChild(mediaSlot(u.media.lastFrame, "img", "尾帧(FL2VA)"));
      frames.appendChild(mediaSlot(u.media?.video, "video", "视频"));
      s.appendChild(frames);
      // 提示词内嵌
      const imgs = u.prompts?.images || [];
      for (let i = 0; i < imgs.length; i++) {
        s.appendChild(await promptCard(imgs[i], imgs.length > 1 ? (i === 0 ? "首帧提示词" : "尾帧提示词") : "关键帧提示词"));
      }
      if (u.prompts?.video) s.appendChild(await promptCard(u.prompts.video, "H3 视频提示词"));
      // 剪辑
      const t3 = el("table", "grid");
      t3.appendChild(headRow(["剪辑", "秒", "认领通道"]));
      (u.cuts || []).forEach((c) => {
        const tr = el("tr");
        tr.appendChild(el("td", null, esc(c.id)));
        tr.appendChild(el("td", null, esc(c.seconds)));
        tr.appendChild(el("td", null, esc((c.coverage || []).map((cv) => cv.beatId + ":" + (cv.channels || []).map((x) => CHANNEL_LABEL[x] || x).join(",")).join(" | "))));
        t3.appendChild(tr);
      });
      s.appendChild(t3);
      root.appendChild(s);
    }

    // 后期任务
    if ((shot.postTasks || []).length) {
      const s = el("section", "card");
      s.appendChild(el("h2", null, "后期任务"));
      const t4 = el("table", "grid");
      t4.appendChild(headRow(["ID", "类型", "说明", "认领通道"]));
      shot.postTasks.forEach((pt) => {
        const tr = el("tr");
        tr.appendChild(el("td", null, esc(pt.id)));
        tr.appendChild(el("td", null, `<span class="tag">${esc(pt.type)}</span>`));
        tr.appendChild(el("td", null, esc(pt.description)));
        tr.appendChild(el("td", null, esc((pt.coverage || []).map((cv) => cv.beatId + ":" + (cv.channels || []).map((x) => CHANNEL_LABEL[x] || x).join(",")).join(" | ") || "—")));
        t4.appendChild(tr);
      });
      s.appendChild(t4);
      root.appendChild(s);
    }
  }

  function headRow(cols) {
    const tr = el("tr", "head");
    cols.forEach((c) => tr.appendChild(el("th", null, esc(c))));
    return tr;
  }

  async function main() {
    const root = $("#app") || document.body;
    const [intake, plan, screenplay] = await Promise.all([
      getSafe("contracts/project-intake.json"),
      getSafe("contracts/production-plan.json"),
      getSafe("contracts/screenplay.json"),
    ]);
    const assets = { list: (window.PUBLIC_ASSETS || {}).list || [] };
    const shotId = document.body.dataset.shot;
    if (shotId) await renderShot(root, shotId, intake, plan, screenplay);
    else await renderHome(root, intake, plan, screenplay, assets);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", main);
  else main();
})();
