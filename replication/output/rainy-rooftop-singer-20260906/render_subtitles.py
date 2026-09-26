from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH, HEIGHT = 768, 1344
FONT = "/Users/wmzuo/Library/Fonts/SourceHanSansSC-Bold.otf"
OUTPUT = Path(__file__).parent / "subtitle_layers"
OUTPUT.mkdir(exist_ok=True)

LINES = [
    ("01", "你就那样\n断崖似的转身", (255, 255, 255, 255)),
    ("02", "没有回头\n也没有下文", (255, 255, 255, 255)),
    ("03", "从此 再没有你的消息", (255, 255, 255, 255)),
    ("04", "杳无音讯\n像从未出现过一样", (255, 255, 255, 255)),
    ("05", "昔日的爱人\n曾经最亲的人", (255, 255, 255, 255)),
    ("06", "如今 隔着咫尺\n却成了最陌生的路人", (255, 216, 105, 255)),
]

font = ImageFont.truetype(FONT, 46)
for name, text, color in LINES:
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    box = draw.multiline_textbbox(
        (0, 0), text, font=font, spacing=12, align="center", stroke_width=4
    )
    text_width = box[2] - box[0]
    text_height = box[3] - box[1]
    position = ((WIDTH - text_width) / 2, HEIGHT - 118 - text_height)
    draw.multiline_text(
        position,
        text,
        font=font,
        fill=color,
        spacing=12,
        align="center",
        stroke_width=4,
        stroke_fill=(16, 16, 16, 225),
    )
    image.save(OUTPUT / f"{name}.png")
