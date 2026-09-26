#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《分手后要不要做朋友》EDL 装配:20 条正片 trim→交叉硬切→叠 8 条 VO→拍5声画交叉→拍9匹配剪辑→黑场。
所有 trim/overlay 数值集中在 SEGS/VO_CUT 表,便于按实测总时长微调。产出 final/fenshou-pengyou-final.mp4。
仅做工程装配(不做媒体语义 QC);成片交人工经公网 HTML 审。"""
import os, subprocess

PROJ = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
os.chdir(PROJ)
WORK = "automation/edit"
SEGDIR = f"{WORK}/seg"
VODIR = f"{WORK}/vo"
os.makedirs(SEGDIR, exist_ok=True)
os.makedirs(VODIR, exist_ok=True)
os.makedirs("final", exist_ok=True)

W, H, FPS = 1344, 768, 25
VSCALE = f"scale={W}:{H}:force_original_aspect_ratio=decrease,pad={W}:{H}:(ow-iw)/2:(oh-ih)/2,setsar=1,fps={FPS}"

def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def dur(f):
    return float(subprocess.check_output(
        ["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",f]).strip())

SRC = lambda sh: f"shots/shot-{sh.split('-')[0]}/videos/{sh}.mp4"
VO = lambda cap: f"assets/audio/vo/{cap}.mp4"

# ---- VO 说话段裁剪(取清晰第一遍;loudnorm 归一到 -18 LUFS 匹配出镜对白响度) ----
VO_CUT = {   # id : (start, end)
    "CAP-friend-p2":  (0.00, 1.98),
    "CAP-sis-p2":     (0.00, 2.19),
    "CAP-friend-p35": (0.24, 2.04),
    "CAP-sis-p35":    (0.30, 1.90),
    "CAP-friend-p4a": (0.24, 1.94),
    "CAP-friend-p4b": (0.26, 2.28),
    "CAP-friend-p6":  (0.33, 3.92),
    "CAP-friend-p8":  (0.38, 1.95),
}

def build_vo_cuts():
    for cid,(s,e) in VO_CUT.items():
        out = f"{VODIR}/{cid}.wav"
        run(["ffmpeg","-y","-ss",str(s),"-to",str(e),"-i",VO(cid),"-vn",
             "-af","loudnorm=I=-18:TP=-2:LRA=11,aresample=48000",
             "-ar","48000","-ac","2",out])
        print(f"  VO {cid}: {e-s:.2f}s -> {out}")

# ---- 逐拍段落表 ----
# (name, shot, tin, tout, [(vo_id, offset_s), ...])
SEGS = [
    ("01_SH01U1", "SH01-U1", 0.0, 1.6, []),
    ("02_SH01U2", "SH01-U2", 0.0, 1.6, []),
    ("03_SH02U1", "SH02-U1", 0.2, 2.4, [("CAP-friend-p2", 0.10)]),
    ("04_SH02U2", "SH02-U2", 0.2, 2.4, [("CAP-sis-p2", 0.10)]),
    ("05_SH03U1", "SH03-U1", 0.2, 3.3, []),
    ("06_SH03U2", "SH03-U2", 0.2, 3.6, []),
    ("07_SH04U1", "SH04-U1", 0.0, 3.3, [("CAP-friend-p35", 0.0)]),
    ("08_SH04U2", "SH04-U2", 0.0, 3.9, [("CAP-sis-p35", 0.0)]),
    ("09_SH05U1", "SH05-U1", 0.3, 6.2, [("CAP-friend-p4a", 0.0), ("CAP-friend-p4b", 4.05)]),
    ("10_SH05U2", "SH05-U2", 0.3, 2.9, []),
    ("11_SH06U1", "SH06-U1", 0.3, 6.4, []),
    ("12_PAI5",   None, None, None, []),
    ("13_SH08U1", "SH08-U1", 0.3, 4.7, [("CAP-friend-p6", 0.20)]),
    ("14_SH09U1", "SH09-U1", 0.2, 3.3, []),
    ("15_SH09U2", "SH09-U2", 0.2, 3.7, []),
    ("16_SH10U1", "SH10-U1", 0.0, 2.3, [("CAP-friend-p8", 0.0)]),
    ("17_SH10U2", "SH10-U2", 1.4, 3.6, []),
    ("18_SH11U1", "SH11-U1", 0.0, 2.6, []),
    ("19_SH11U2", "SH11-U2", 0.0, 2.4, []),
]

# 拍5:男主问句 A1 人声延续跨到女画面(全片唯一声画错位)
PAI5_MV_IN, PAI5_MV_OUT = 0.3, 4.3
PAI5_FV_IN, PAI5_FV_OUT = 0.0, 2.2
PAI5_AUD_IN, PAI5_AUD_OUT = 0.3, 6.5

def build_plain_seg(name, shot, tin, tout, vos):
    out = f"{SEGDIR}/{name}.mp4"
    if not vos:
        run(["ffmpeg","-y","-ss",str(tin),"-to",str(tout),"-i",SRC(shot),
             "-vf",VSCALE,"-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",
             "-c:a","aac","-ar","48000","-ac","2","-af","aresample=48000",out])
    else:
        cmd = ["ffmpeg","-y","-ss",str(tin),"-to",str(tout),"-i",SRC(shot)]
        for vid,_ in vos:
            cmd += ["-i", f"{VODIR}/{vid}.wav"]
        parts = [f"[0:v]{VSCALE}[v]"]
        amix_ins = ["[0:a]"]
        for i,(vid,off) in enumerate(vos, start=1):
            ms = int(off*1000)
            parts.append(f"[{i}:a]adelay={ms}|{ms}[a{i}]")
            amix_ins.append(f"[a{i}]")
        parts.append("".join(amix_ins)+f"amix=inputs={len(vos)+1}:duration=first:normalize=0,alimiter=limit=0.95[a]")
        fc = ";".join(parts)
        cmd += ["-filter_complex",fc,"-map","[v]","-map","[a]",
                "-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",
                "-c:a","aac","-ar","48000","-ac","2",out]
        run(cmd)
    return out

def build_pai5():
    mv = f"{SEGDIR}/12a_mv.mp4"
    run(["ffmpeg","-y","-ss",str(PAI5_MV_IN),"-to",str(PAI5_MV_OUT),"-i",SRC("SH07-U1"),
         "-an","-vf",VSCALE,"-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",mv])
    fv = f"{SEGDIR}/12b_fv.mp4"
    run(["ffmpeg","-y","-ss",str(PAI5_FV_IN),"-to",str(PAI5_FV_OUT),"-i",SRC("SH07-U2"),
         "-an","-vf",VSCALE,"-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",fv])
    vcat = f"{SEGDIR}/12v.mp4"
    lst = f"{SEGDIR}/12list.txt"
    with open(lst,"w") as f:
        f.write(f"file '{os.path.abspath(mv)}'\nfile '{os.path.abspath(fv)}'\n")
    run(["ffmpeg","-y","-f","concat","-safe","0","-i",lst,"-c","copy",vcat])
    aud = f"{SEGDIR}/12a.wav"
    run(["ffmpeg","-y","-ss",str(PAI5_AUD_IN),"-to",str(PAI5_AUD_OUT),"-i",SRC("SH07-U1"),
         "-vn","-af","aresample=48000","-ar","48000","-ac","2",aud])
    out = f"{SEGDIR}/12_PAI5.mp4"
    run(["ffmpeg","-y","-i",vcat,"-i",aud,"-map","0:v","-map","1:a",
         "-c:v","copy","-c:a","aac","-ar","48000","-ac","2","-shortest",out])
    return out

def build_black():
    out = f"{SEGDIR}/20_BLACK.mp4"
    run(["ffmpeg","-y","-f","lavfi","-i",f"color=c=black:s={W}x{H}:r={FPS}:d=0.5",
         "-f","lavfi","-i","anullsrc=channel_layout=stereo:sample_rate=48000",
         "-t","0.5","-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",
         "-c:a","aac","-ar","48000","-ac","2","-shortest",out])
    return out

def main():
    print("=== 1. 裁 VO 说话段 ===")
    build_vo_cuts()
    print("=== 2. 逐段构建 + 累计时长 ===")
    order = []
    cum = 0.0
    for name, shot, tin, tout, vos in SEGS:
        if name == "12_PAI5":
            seg = build_pai5()
        else:
            seg = build_plain_seg(name, shot, tin, tout, vos)
        d = dur(seg)
        cum += d
        order.append(seg)
        vtag = " +VO:"+",".join(v for v,_ in vos) if vos else ""
        print(f"  {name:12s} {d:5.2f}s  累计 {cum:6.2f}s{vtag}")
    black = build_black()
    order.append(black); cum += dur(black)
    print(f"  {'BLACK':12s} {dur(black):5.2f}s  累计 {cum:6.2f}s")
    print("=== 3. 总拼接 ===")
    lst = f"{WORK}/concat.txt"
    with open(lst,"w") as f:
        for s in order:
            f.write(f"file '{os.path.abspath(s)}'\n")
    final = "final/fenshou-pengyou-final.mp4"
    run(["ffmpeg","-y","-f","concat","-safe","0","-i",lst,
         "-c:v","libx264","-preset","medium","-crf","18","-pix_fmt","yuv420p",
         "-c:a","aac","-ar","48000","-ac","2","-movflags","+faststart",final])
    fd = dur(final)
    print(f"\n>>> 成片: {final}  时长 {fd:.2f}s  ({'≤65 OK' if fd<=65 else '超 65,需回表微调!'})")

if __name__ == "__main__":
    main()
