from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont


ROOT = Path(__file__).parent
SOURCE = ROOT / "xhs" / "source"
OUTPUT = ROOT / "xhs" / "final"
OUTPUT.mkdir(parents=True, exist_ok=True)

FONT_BOLD = "/Users/wmzuo/Library/Fonts/SourceHanSansSC-Bold.otf"
FONT_NORMAL = "/Users/wmzuo/Library/Fonts/SourceHanSansSC-Normal.otf"

PAGES = [
    ("01-cover", "最亲的人\n后来成了路人", "迟来情深 · 雨夜天台", (255, 216, 105, 255)),
    ("02-goodbye", "没有争吵\n也没有正式告别", "离别来得太匆忙", (255, 255, 255, 255)),
    ("03-unsaid", "真正放不下的\n是没说出口的再见", "成年人的遗憾 往往没有结局", (255, 255, 255, 255)),
    ("04-silence", "从无话不说\n到杳无音讯", "像从未出现过一样", (255, 255, 255, 255)),
    ("05-question", "你也有一个\n没来得及告别的人吗？", "把名字留在心里 就好", (255, 216, 105, 255)),
]


def cover_crop(image: Image.Image, size=(1080, 1440)) -> Image.Image:
    target_ratio = size[0] / size[1]
    source_ratio = image.width / image.height
    if source_ratio < target_ratio:
        height = int(image.width / target_ratio)
        top = max(0, int(image.height * 0.40 - height * 0.40))
        top = min(top, image.height - height)
        image = image.crop((0, top, image.width, top + height))
    else:
        width = int(image.height * target_ratio)
        left = (image.width - width) // 2
        image = image.crop((left, 0, left + width, image.height))
    return image.resize(size, Image.Resampling.LANCZOS)


title_font = ImageFont.truetype(FONT_BOLD, 76)
footer_font = ImageFont.truetype(FONT_NORMAL, 34)

for index, (name, title, footer, accent) in enumerate(PAGES, start=1):
    image = cover_crop(Image.open(SOURCE / f"{index:02d}.jpg").convert("RGB"))
    image = ImageEnhance.Contrast(image).enhance(1.04).convert("RGBA")
    shade = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    shade_draw.rectangle((0, 0, 1080, 390), fill=(0, 0, 0, 112))
    shade_draw.rectangle((0, 1290, 1080, 1440), fill=(0, 0, 0, 90))
    image = Image.alpha_composite(image, shade)

    draw = ImageDraw.Draw(image)
    draw.multiline_text(
        (74, 92),
        title,
        font=title_font,
        fill=accent,
        spacing=14,
        stroke_width=3,
        stroke_fill=(10, 10, 10, 190),
    )
    draw.text(
        (74, 1340),
        footer,
        font=footer_font,
        fill=(245, 245, 245, 235),
        stroke_width=2,
        stroke_fill=(10, 10, 10, 180),
    )
    image.convert("RGB").save(OUTPUT / f"{name}.jpg", quality=94, subsampling=0)
