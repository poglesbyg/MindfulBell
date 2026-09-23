"""Draws the Stillpoint app icon and writes every size the asset catalog needs.

A low moon over a singing bowl on still water, on a dusk gradient. Requires Pillow
(pip install pillow). Run from the repository root:  python3 AppStore/make_icon.py
"""
from PIL import Image, ImageDraw, ImageFilter

S = 4096                      # drawn at 4x, then downsampled for smooth edges
k = S / 1024                  # design units are the 1024 px icon grid
CX = 512 * k
# macOS icon grid: an 824 px rounded square with a 185 px corner radius
X0, Y0, X1, Y1, R = [int(v * k) for v in (100, 100, 924, 924, 185)]

SKY_TOP, SKY_BOTTOM = (30, 34, 78), (104, 78, 142)
MOON, GLOW = (247, 205, 140), (255, 196, 120)
BOWL, RIM, BOWL_INSIDE = (226, 170, 84), (250, 222, 160), (150, 102, 48)
WATER = (246, 214, 160)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vertical_gradient(top, bottom, y0, y1):
    image = Image.new('RGBA', (S, S))
    draw = ImageDraw.Draw(image)
    for y in range(S):
        t = min(1, max(0, (y - y0) / (y1 - y0)))
        draw.line([(0, y), (S, y)], fill=lerp(top, bottom, t) + (255,))
    return image


def draw_icon():
    art = vertical_gradient(SKY_TOP, SKY_BOTTOM, Y0, Y1)

    # Moon with a soft glow, well clear of the bowl
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([CX - 190 * k, 140 * k, CX + 190 * k, 520 * k], fill=GLOW + (120,))
    art = Image.alpha_composite(art, glow.filter(ImageFilter.GaussianBlur(60 * k)))
    ImageDraw.Draw(art).ellipse([CX - 120 * k, 210 * k, CX + 120 * k, 450 * k], fill=MOON + (255,))

    # Bowl: lower half-ellipse shaded top to bottom, then rim and inner lip
    rim_y, width, depth = 610 * k, 300 * k, 200 * k
    shape = Image.new('L', (S, S), 0)
    ImageDraw.Draw(shape).pieslice([CX - width, rim_y - depth, CX + width, rim_y + depth], 0, 180, fill=255)
    shade = vertical_gradient(BOWL, lerp(BOWL, (120, 80, 40), 0.55), int(rim_y), int(rim_y + depth))
    body = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    body.paste(shade, (0, 0), shape)
    art = Image.alpha_composite(art, body)
    draw = ImageDraw.Draw(art)
    draw.ellipse([CX - width, rim_y - 26 * k, CX + width, rim_y + 26 * k], fill=RIM + (255,))
    draw.ellipse([CX - width + 22 * k, rim_y - 14 * k, CX + width - 22 * k, rim_y + 14 * k], fill=BOWL_INSIDE + (255,))

    # Still water: three fading lines
    for i, (half, alpha) in enumerate([(230, 170), (170, 120), (110, 80)]):
        y = (835 + i * 30) * k
        draw.rounded_rectangle([CX - half * k, y - 6 * k, CX + half * k, y + 6 * k], 6 * k, fill=WATER + (alpha,))

    # Clip to the rounded square and add the standard soft drop shadow
    icon = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([X0, Y0 + int(12 * k), X1, Y1 + int(12 * k)], R, fill=(0, 0, 0, 90))
    icon = Image.alpha_composite(icon, shadow.filter(ImageFilter.GaussianBlur(28 * k)))
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([X0, Y0, X1, Y1], R, fill=255)
    clipped = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    clipped.paste(art, (0, 0), mask)
    return Image.alpha_composite(icon, clipped).resize((1024, 1024), Image.LANCZOS)


if __name__ == '__main__':
    icon = draw_icon()
    folder = 'MindfulBell/Assets.xcassets/AppIcon.appiconset/'
    for points, scale in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                          (256, 1), (256, 2), (512, 1), (512, 2)]:
        name = f"icon_{points}x{points}{'@2x' if scale == 2 else ''}.png"
        icon.resize((points * scale,) * 2, Image.LANCZOS).save(folder + name, optimize=True)
    icon.save('AppStore/icon-1024.png', optimize=True)
    print('Wrote', folder, 'and AppStore/icon-1024.png')
