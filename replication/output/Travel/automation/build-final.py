#!/usr/bin/env python3
# 成片拼接：逐镜放慢匹配旁白 → 旁白前景+现场音效变速铺底 → 地名花字 → concat
# ¥0 本地 ffmpeg。成片零对白字幕；花字=地名(非对白)。输出 final/travel-final.mp4
import subprocess, pathlib, json, sys, os

PROJ = pathlib.Path("/home/ubuntu/ads_skill/replication/output/Travel")
FONT = "/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc"
WORK = PROJ/"automation/final-work"; WORK.mkdir(parents=True, exist_ok=True)
FINAL = PROJ/"final"; FINAL.mkdir(parents=True, exist_ok=True)
TAIL = 0.35        # 旁白后留白收尾
LEAD = 0.15        # 旁白入点微延迟
W,H = 768,1344; FPS=30

# 地名花字（仅打卡镜；纯地名，非对白字幕）
PLACE = {
 "06":"青海湖","07":"茶卡盐湖","08":"稻城亚丁","09":"川藏线 · 318",
 "10":"拉萨 · 布达拉宫","11":"敦煌 · 鸣沙山月牙泉","12":"额济纳 · 胡杨林",
 "13":"呼伦贝尔草原","14":"洱海",
}
SHOTS=[f"{i:02d}" for i in range(1,19)]

def dur(p):
    r=subprocess.run(["ffprobe","-v","error","-show_entries","format=duration",
                      "-of","csv=p=0",str(p)],capture_output=True,text=True)
    return float(r.stdout.strip())

def run(cmd):
    r=subprocess.run(cmd,capture_output=True,text=True)
    if r.returncode!=0:
        print("FFMPEG FAIL:\n"," ".join(cmd),"\n",r.stderr[-1500:]); sys.exit(1)

parts=[]
report=[]
for n in SHOTS:
    vid=PROJ/f"shots/{n}/video.mp4"; vo=PROJ/f"audio/vo/vo-{n}.wav"
    vd=dur(vid); ad=dur(vo)
    target=max(vd, ad+TAIL)
    sf=target/vd                      # 视频放慢因子 >=1
    atempo=1.0/sf                      # 音效变速保音高(0.5..2)
    # 花字 alpha 淡入淡出表达式
    dt=""
    if n in PLACE:
        tf=WORK/f"place-{n}.txt"; tf.write_text(PLACE[n],encoding="utf-8")
        a=(f"if(lt(t,0.5),0,if(lt(t,1.0),(t-0.5)/0.5,"
           f"if(lt(t,{target-0.9:.3f}),1,if(lt(t,{target-0.4:.3f}),({target-0.4:.3f}-t)/0.5,0))))")
        dt=(f",drawtext=fontfile='{FONT}':textfile='{tf}':fontcolor=white:fontsize=52:"
            f"box=1:boxcolor=black@0.32:boxborderw=20:x=(w-tw)/2:y=h*0.80:"
            f"shadowcolor=black@0.5:shadowx=2:shadowy=2:alpha='{a}'")
    vf=(f"[0:v]setpts=PTS*{sf:.6f},scale={W}:{H},fps={FPS},format=yuv420p{dt}[v]")
    af=(f"[0:a]atempo={atempo:.6f},volume=0.22[amb];"
        f"[1:a]adelay={int(LEAD*1000)}|{int(LEAD*1000)},volume=1.0[vo];"
        f"[amb][vo]amix=inputs=2:duration=longest:normalize=0,"
        f"atrim=0:{target:.3f},asetpts=N/SR/TB,aresample=44100[a]")
    out=WORK/f"seg-{n}.mp4"
    run(["ffmpeg","-y","-i",str(vid),"-i",str(vo),
         "-filter_complex",vf+";"+af,"-map","[v]","-map","[a]",
         "-t",f"{target:.3f}","-r",str(FPS),
         "-c:v","libx264","-crf","18","-preset","medium","-pix_fmt","yuv420p",
         "-c:a","aac","-b:a","192k","-ar","44100","-ac","2",
         "-video_track_timescale","30000",str(out)])
    parts.append(out)
    report.append(f"{n}: vid{vd:.2f}→{target:.2f}s slow{sf:.2f}× vo{ad:.2f}s"+(f" 花字[{PLACE[n]}]" if n in PLACE else ""))
    print(report[-1])

# concat（片段参数一致，demuxer copy）
lst=WORK/"concat.txt"
lst.write_text("".join(f"file '{p}'\n" for p in parts),encoding="utf-8")
final=FINAL/"travel-final.mp4"
run(["ffmpeg","-y","-f","concat","-safe","0","-i",str(lst),
     "-c","copy","-movflags","+faststart",str(final)])
td=dur(final)
print(f"\n=== 成片 {final} 时长 {td:.2f}s ===")
