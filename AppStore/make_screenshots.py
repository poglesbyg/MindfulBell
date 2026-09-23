"""Builds the App Store screenshots from the raw full-screen captures in AppStore/screenshots/raw.

For each shot it writes a plain version (cropped to 16:10 from the top, so the menu bar stays,
then resized to 2880x1800 without an alpha channel, which App Store Connect rejects) and a
captioned version on the icon's dusk gradient. Captions use Inter; pass the folder holding
Inter-SemiBold.ttf with --fonts (https://github.com/rsms/inter/releases).

Run from the repository root:  python3 AppStore/make_screenshots.py --fonts ~/Downloads/Inter
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAW = Path('AppStore/screenshots/raw')
OUT = Path('AppStore/screenshots/final')
SIZE = (2880, 1800)

# (capture time in the raw file name, output name, caption); order is upload order.
# Matched by time because macOS puts a narrow no-break space before "PM".
SHOTS = [
    ('2.15.54', '01-menu', 'Meditation, one click away'),
    ('2.16.20', '02-sitting', 'Just you and the bell'),
    ('2.16.52', '03-history', 'See your practice grow'),
    ('2.16.35', '04-mindful-day', 'A bell to come back to your breath'),
]
IAP_REVIEW = ('2.17.39', 'iap-review-pro-window')

SKY_TOP, SKY_BOTTOM = (30, 34, 78), (104, 78, 142)
CAPTION = (250, 236, 210)


def raw_capture(time):
    matches = sorted(RAW.glob(f'Screenshot * at {time}*.png'))
    if len(matches) != 1:
        raise SystemExit(f'Expected one raw capture taken at {time}, found {len(matches)}')
    return matches[0]


def to_16x10(path):
    """Crop to 16:10 keeping the top edge (menu bar), resize to 2880x1800, drop alpha."""
    image = Image.open(path).convert('RGB')
    width, height = image.size
    if width / height > 1.6:
        crop_width = round(height * 1.6)
        left = (width - crop_width) // 2
        image = image.crop((left, 0, left + crop_width, height))
    else:
        image = image.crop((0, 0, width, round(width / 1.6)))
    return image.resize(SIZE, Image.LANCZOS)


def captioned(shot, caption, font):
    canvas = Image.new('RGB', SIZE)
    draw = ImageDraw.Draw(canvas)
    for y in range(SIZE[1]):
        t = y / (SIZE[1] - 1)
        draw.line([(0, y), (SIZE[0], y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM)))

    # Caption, centred in the band above the screenshot
    box = draw.textbbox((0, 0), caption, font=font)
    draw.text(((SIZE[0] - (box[2] - box[0])) / 2 - box[0], 118 - box[1]), caption, font=font, fill=CAPTION)

    # Screenshot at 2560x1600, rounded top corners, soft shadow, bleeding off the bottom edge
    frame_size, top = (2560, 1600), 290
    left = (SIZE[0] - frame_size[0]) // 2
    frame = shot.resize(frame_size, Image.LANCZOS)
    mask = Image.new('L', frame_size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, frame_size[0], frame_size[1] + 60], 36, fill=255)
    shadow = Image.new('L', SIZE, 0)
    ImageDraw.Draw(shadow).rounded_rectangle([left, top + 16, left + frame_size[0], SIZE[1] + 80], 36, fill=150)
    canvas.paste((10, 10, 30), (0, 0), shadow.filter(ImageFilter.GaussianBlur(40)))
    canvas.paste(frame, (left, top), mask)
    return canvas


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fonts', required=True, help='folder containing Inter-SemiBold.ttf')
    font = ImageFont.truetype(str(Path(parser.parse_args().fonts).expanduser() / 'Inter-SemiBold.ttf'), 104)

    (OUT / 'plain').mkdir(parents=True, exist_ok=True)
    (OUT / 'captioned').mkdir(parents=True, exist_ok=True)
    for raw, name, caption in SHOTS:
        shot = to_16x10(raw_capture(raw))
        shot.save(OUT / 'plain' / f'{name}.png', optimize=True)
        captioned(shot, caption, font).save(OUT / 'captioned' / f'{name}.png', optimize=True)
    raw, name = IAP_REVIEW
    to_16x10(raw_capture(raw)).save(OUT / f'{name}.png', optimize=True)
    print('Wrote', OUT)


if __name__ == '__main__':
    main()
