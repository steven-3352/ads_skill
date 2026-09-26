#!/usr/bin/env python3
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
CARDS = ROOT / "cards"
VISUALS = ROOT / "visuals"
MOTION_FRAMES = ROOT / "motion-frames"
for directory in (ASSETS, CARDS, VISUALS, MOTION_FRAMES):
    directory.mkdir(parents=True, exist_ok=True)

W, H = 1080, 1920
FONT_REG = "/System/Library/Fonts/PingFang.ttc"
FONT_BOLD = "/System/Library/Fonts/PingFang.ttc"


PRODUCTS = {
    "A": {
        "sources": [Path("/Users/wmzuo/Downloads/A-1.PNG"), Path("/Users/wmzuo/Downloads/A-2.PNG")],
        "crops": [(0, 690, 1206, 1920), (0, 690, 1206, 1920)],
        "colors": ("#151515", "#F2E2D2", "#D84B42"),
        "lines": [
            ("一双鞋，两套配色", "厚底轮廓，穿搭不单调"),
            ("黑红醒目", "利落运动感"),
            ("棕绿复古", "日常更有层次"),
            ("今天想穿哪一双？", "点进商品，看看更多细节"),
        ],
    },
    "B": {
        "sources": [Path("/Users/wmzuo/Downloads/B-1.PNG"), Path("/Users/wmzuo/Downloads/B-2.PNG")],
        "crops": [(150, 260, 1120, 1300), (420, 300, 1206, 1120)],
        "colors": ("#17131C", "#F4EEF6", "#7A3C86"),
        "lines": [
            ("不穿高跟，也能有气场", "尖头浅口，把精致留在脚下"),
            ("紫色水钻", "走动之间，自带细闪"),
            ("低跟通勤", "裙装裤装都好搭"),
            ("到手价 149 元", "点进商品，查看尺码"),
        ],
    },
    "C": {
        "sources": [Path("/Users/wmzuo/Downloads/C.PNG")],
        "crops": [(450, 300, 1206, 1120)],
        "erase_left": 60,
        "colors": ("#5C241E", "#F6ECDD", "#C69B4A"),
        "lines": [
            ("新中式，不只穿在衣服上", "一双鞋，把东方细节穿出来"),
            ("提花鞋面", "低调纹理，近看更精致"),
            ("方头玛丽珍", "粗跟稳住整体比例"),
            ("到手价 148 元", "点进商品，查看尺码"),
        ],
    },
    "D": {
        "sources": [Path("/Users/wmzuo/Downloads/D.PNG")],
        "crops": [(140, 270, 1100, 1370)],
        "colors": ("#2A1A13", "#F3E2C6", "#B9783F"),
        "lines": [
            ("出门一包，装下体面", "棕色拼接，日常不挑衣服"),
            ("手提有气场", "通勤见客，利落大方"),
            ("斜挎更轻松", "一只包，两种背法"),
            ("到手价 139 元", "点进商品，查看容量细节"),
        ],
    },
}


def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size)


def cover(image, size):
    ratio = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def contain(image, size):
    ratio = min(size[0] / image.width, size[1] / image.height)
    return image.resize((round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS)


def centered_text(draw, text, y, face, fill, max_width=940):
    box = draw.textbbox((0, 0), text, font=face)
    width = box[2] - box[0]
    if width > max_width:
        face = font(max(28, int(face.size * max_width / width)), face.size >= 60)
        box = draw.textbbox((0, 0), text, font=face)
        width = box[2] - box[0]
    draw.text(((W - width) / 2, y), text, font=face, fill=fill)


def make_card(code, scene, title, subtitle, product_images, palette):
    dark, light, accent = palette
    canvas = Image.new("RGB", (W, H), light)
    draw = ImageDraw.Draw(canvas)

    if scene == 0:
        draw.rectangle((0, 0, W, 330), fill=dark)
        draw.rounded_rectangle((56, 72, 214, 128), radius=28, fill=accent)
        draw.text((91, 79), f"好物 {code}", font=font(28, True), fill="white")
        centered_text(draw, title, 158, font(72, True), "white")
        centered_text(draw, subtitle, 258, font(34), "#F2E9DF")
        hero = contain(product_images[0], (970, 1250))
        canvas.paste(hero, ((W - hero.width) // 2, 420))
        draw.rectangle((0, 1740, W, H), fill=dark)
        centered_text(draw, "15 秒看懂这件好物", 1792, font(36, True), "white")
    elif scene in (1, 2):
        source = product_images[(scene - 1) % len(product_images)]
        hero = cover(source, (W, 1320))
        canvas.paste(hero, (0, 0))
        draw.rectangle((0, 1320, W, H), fill=dark)
        draw.rectangle((64, 1384, 78, 1568), fill=accent)
        draw.text((112, 1370), title, font=font(66, True), fill="white")
        draw.text((112, 1470), subtitle, font=font(38), fill="#F2E9DF")
        draw.rounded_rectangle((112, 1628, 460, 1690), radius=31, fill=accent)
        draw.text((164, 1640), "看得见的细节", font=font(30, True), fill="white")
    else:
        draw.rectangle((0, 0, W, H), fill=dark)
        if len(product_images) == 2:
            for idx, image in enumerate(product_images):
                tile = cover(image, (470, 940))
                canvas.paste(tile, (55 + idx * 500, 140))
        else:
            hero = contain(product_images[0], (960, 1040))
            canvas.paste(hero, ((W - hero.width) // 2, 80))
        draw.rounded_rectangle((60, 1180, 1020, 1740), radius=42, fill=light)
        centered_text(draw, title, 1270, font(76, True), dark)
        centered_text(draw, subtitle, 1390, font(38), dark)
        draw.rounded_rectangle((250, 1540, 830, 1650), radius=55, fill=accent)
        centered_text(draw, "立即查看商品", 1567, font(40, True), "white")
        centered_text(draw, "价格与活动以商品页为准", 1818, font(28), "#D8CABB")

    path = CARDS / f"{code}-{scene + 1}.png"
    canvas.save(path, quality=96)
    return path


def render_video(code, cards):
    durations = [3.0, 3.5, 3.5, 5.0]
    inputs = []
    filters = []
    for idx, (card, duration) in enumerate(zip(cards, durations)):
        inputs += ["-loop", "1", "-framerate", "30", "-t", str(duration), "-i", str(card)]
        zoom = "min(zoom+0.00028,1.035)" if idx % 2 == 0 else "max(1.035-0.00022*on,1.0)"
        filters.append(
            f"[{idx}:v]scale=1120:1992,crop=1080:1920,"
            f"zoompan=z='{zoom}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
            f"d=1:s=1080x1920:fps=30,trim=duration={duration},"
            f"fade=t=in:st=0:d=0.18,fade=t=out:st={duration-0.18}:d=0.18,"
            f"format=yuv420p,setpts=PTS-STARTPTS[v{idx}]"
        )
    concat = "".join(f"[v{i}]" for i in range(4)) + "concat=n=4:v=1:a=0[v]"
    output = VISUALS / f"product-{code}-15s-visual.mp4"
    cmd = ["ffmpeg", "-y", *inputs, "-filter_complex", ";".join(filters + [concat]), "-map", "[v]",
           "-t", "15", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
           "-movflags", "+faststart", str(output)]
    subprocess.run(cmd, check=True)
    return output


def make_motion_frame(code, product_image, palette):
    dark, light, accent = palette
    canvas = Image.new("RGB", (W, H), light)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, W, 150), fill=dark)
    draw.rectangle((0, H - 150, W, H), fill=dark)
    draw.ellipse((92, 270, 988, 1166), fill="#FFFFFF")
    hero = contain(product_image, (960, 1180))
    canvas.paste(hero, ((W - hero.width) // 2, 300))
    draw.rounded_rectangle((330, 1580, 750, 1598), radius=9, fill=accent)
    path = MOTION_FRAMES / f"{code}-first-frame.png"
    canvas.save(path)
    return path


def main():
    for code, spec in PRODUCTS.items():
        product_images = []
        for idx, source in enumerate(spec["sources"]):
            image = Image.open(source).convert("RGB").crop(spec["crops"][idx])
            if erase_left := spec.get("erase_left"):
                ImageDraw.Draw(image).rectangle((0, 0, erase_left, image.height), fill="white")
            clean_path = ASSETS / f"{code}-{idx + 1}.jpg"
            image.save(clean_path, quality=95)
            product_images.append(image)
        cards = [
            make_card(code, scene, title, subtitle, product_images, spec["colors"])
            for scene, (title, subtitle) in enumerate(spec["lines"])
        ]
        make_motion_frame(code, product_images[0], spec["colors"])
        render_video(code, cards)


if __name__ == "__main__":
    main()
