from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
FONT_PATH = "/System/Library/Fonts/PingFang.ttc"
WIDTH, HEIGHT = 1080, 1920
BURGUNDY = (74, 15, 29, 242)
IVORY = (255, 248, 236, 255)
GOLD = (229, 193, 122, 255)


def font(size: int):
    return ImageFont.truetype(FONT_PATH, size)


def centered(draw, text, y, size, fill):
    active_font = font(size)
    box = draw.textbbox((0, 0), text, font=active_font)
    x = (WIDTH - (box[2] - box[0])) // 2
    draw.text((x, y), text, font=active_font, fill=fill)


def save_caption(name, lines, box):
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rectangle(box, fill=BURGUNDY)
    for text, y, size, fill in lines:
        centered(draw, text, y, size, fill)
    image.save(ROOT / name)


save_caption(
    "caption-checklist.png",
    [("西装  ✓   红包  ✓   胸花  ✓", 164, 46, IVORY)],
    (48, 126, 1032, 252),
)
save_caption(
    "caption-all-ready.png",
    [("所有人的事，都准备好了", 1535, 50, IVORY)],
    (48, 1492, 1032, 1644),
)
save_caption(
    "caption-last-item.png",
    [("最后一项：妈妈自己", 1531, 54, GOLD)],
    (48, 1492, 1032, 1644),
)
save_caption(
    "caption-best-self.png",
    [
        ("儿子的大日子", 1448, 48, IVORY),
        ("妈妈也要有最好的状态", 1518, 58, GOLD),
    ],
    (48, 1410, 1032, 1620),
)

product = Image.new("RGB", (WIDTH, HEIGHT), (74, 15, 29))
source = Image.open(ROOT.parent / "assets" / "product-clean.png").convert("RGB")
source = source.crop((0, 185, source.width, source.height))
source.thumbnail((WIDTH, 1422), Image.Resampling.LANCZOS)
product.paste(source, ((WIDTH - source.width) // 2, 258))
draw = ImageDraw.Draw(product)
centered(draw, "婚礼婆婆包", 76, 66, IVORY)
centered(draw, "体面赴喜宴", 169, 48, GOLD)
centered(draw, "COALIEA & HAEFLI", 1773, 28, IVORY)
product.save(ROOT / "product-hero.png")
