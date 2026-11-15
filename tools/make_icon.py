"""湯とも！配布用アプリアイコン（1024px）を作るスクリプト。
Pillow でフラットデザインの温泉マーク（湯船と蒸気）を描く。生成物:
  - app/assets/icon/app_icon.png      （flutter_launcher_icons のソース）
"""
from PIL import Image, ImageDraw

SIZE = 1024
BG = (232, 236, 242)        # ライトグレー（シリーズ共通の落ち着いた背景色）
TUB = (46, 58, 74)          # 湯船（ダークネイビー）
WATER = (56, 130, 246)      # 湯面（ブルー）
ACCENT = (245, 158, 11)     # アクセント（オレンジ）
STEAM = (148, 163, 176)     # 蒸気（スレート）


def rounded(im: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def draw_bath():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # 背景（角丸ライトグレー）
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=192, fill=BG + (255,))

    # 湯船（温泉マーク ♨ の形: 上辺が直線の半カプセル）
    d.pieslice([212, 430, 812, 930], start=0, end=180, fill=TUB + (255,))
    d.rectangle([212, 430, 812, 560], fill=TUB + (255,))

    # 湯面（湯船の上端に水色の帯）
    d.rectangle([212, 430, 812, 492], fill=WATER + (255,))

    # 湯に浮かぶドンブリ浮き（オレンジ）
    d.ellipse([430, 700, 594, 864], fill=ACCENT + (255,))

    # 蒸気（3本の縦の半円弧。湯船の上）
    for x in (350, 512, 674):
        d.arc([x - 70, 200, x + 70, 340], start=270, end=90, fill=STEAM + (255,), width=28)

    return im


if __name__ == "__main__":
    im = draw_bath()
    im = rounded(im, 192)
    out = r"..\app\assets\icon\app_icon.png"
    im.save(out)
    print("saved:", out)
