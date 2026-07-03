#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 30
HEIGHT = 22
SCALE = 8

OUTLINE = (20, 20, 20, 255)
FUR = (235, 128, 51, 255)
FUR_LIGHT = (255, 179, 92, 255)
FUR_DARK = (148, 69, 31, 255)
CREAM = (255, 219, 148, 255)
EYE = (56, 235, 138, 255)
ALERT = (255, 46, 51, 255)
SLEEP = (64, 140, 255, 255)
TRANSPARENT = (0, 0, 0, 0)


class Sprite:
    def __init__(self):
        self.img = Image.new("RGBA", (WIDTH, HEIGHT), TRANSPARENT)
        self.draw = ImageDraw.Draw(self.img)

    def rect(self, x, y_from_top, w, h, color):
        self.draw.rectangle(
            [x, y_from_top, x + w - 1, y_from_top + h - 1],
            fill=color,
        )

    def draw_head(self, x, y, blink=False, surprised=False):
        self.rect(x + 1, y + 2, 9, 8, OUTLINE)
        self.rect(x + 2, y + 3, 7, 6, FUR)
        self.rect(x + 2, y + 1, 2, 3, OUTLINE)
        self.rect(x + 7, y + 1, 2, 3, OUTLINE)
        self.rect(x + 3, y + 4, 5, 2, FUR_LIGHT)
        self.rect(x + 5, y + 6, 1, 1, CREAM)

        if blink:
            self.rect(x + 3, y + 5, 2, 1, OUTLINE)
            self.rect(x + 7, y + 5, 2, 1, OUTLINE)
        elif surprised:
            self.rect(x + 3, y + 5, 2, 2, EYE)
            self.rect(x + 7, y + 5, 2, 2, EYE)
            self.rect(x + 5, y + 8, 2, 2, ALERT)
        else:
            self.rect(x + 3, y + 5, 1, 2, EYE)
            self.rect(x + 7, y + 5, 1, 2, EYE)
            self.rect(x + 5, y + 8, 2, 1, OUTLINE)

    def draw_body(self, x, y):
        self.rect(x + 1, y + 1, 15, 7, OUTLINE)
        self.rect(x, y + 3, 17, 4, OUTLINE)
        self.rect(x + 2, y + 2, 13, 5, FUR)
        self.rect(x + 5, y + 3, 6, 3, FUR_LIGHT)
        self.rect(x + 3, y + 2, 2, 1, CREAM)
        self.rect(x + 12, y + 2, 2, 1, FUR_DARK)

    def draw_tail(self, base_x, base_y, phase):
        lift = 0 if phase % 2 == 0 else -1
        self.rect(base_x, base_y + 2 + lift, 5, 2, OUTLINE)
        self.rect(base_x + 3, base_y + lift, 2, 4, OUTLINE)
        self.rect(base_x + 1, base_y + 3 + lift, 4, 1, FUR_DARK)
        self.rect(base_x + 4, base_y + 1 + lift, 1, 3, FUR)

    def running(self, frame):
        phase = frame % 6
        bob = [0, -1, -1, 0, 1, 0][phase]
        leg_a = 1 if phase < 3 else -1
        leg_b = -leg_a
        self.draw_tail(22, 10 + bob, phase)
        self.draw_body(8, 8 + bob)
        self.draw_head(3, 5 + bob)
        self.rect(11 + leg_a, 17 + bob, 3, 2, OUTLINE)
        self.rect(12 + leg_a, 16 + bob, 2, 2, FUR_DARK)
        self.rect(20 + leg_b, 17 + bob, 3, 2, OUTLINE)
        self.rect(21 + leg_b, 16 + bob, 2, 2, FUR_DARK)
        self.rect(14, 10 + bob, 2, 1, FUR_LIGHT)
        self.rect(18, 10 + bob, 2, 1, FUR_LIGHT)

    def idle(self, frame):
        breathe = 0 if (frame // 4) % 2 == 0 else 1
        self.rect(8, 11, 15, 7 + breathe, OUTLINE)
        self.rect(9, 10, 13, 8 + breathe, OUTLINE)
        self.rect(10, 11, 11, 6 + breathe, FUR)
        self.rect(12, 12, 7, 4 + breathe, FUR_LIGHT)
        self.rect(14, 14, 3, 2, CREAM)
        self.rect(4, 8, 9, 8, OUTLINE)
        self.rect(5, 9, 7, 6, FUR)
        self.rect(5, 7, 2, 3, OUTLINE)
        self.rect(10, 7, 2, 3, OUTLINE)
        self.rect(6, 10, 5, 3, FUR_LIGHT)
        self.rect(7, 11, 1, 1, OUTLINE)
        self.rect(10, 11, 1, 1, OUTLINE)
        self.rect(20, 13, 5, 3, OUTLINE)
        self.rect(21, 14, 4, 1, FUR_DARK)
        self.rect(18, 15, 4, 2, OUTLINE)
        self.rect(18, 15, 3, 1, FUR)
        if (frame // 5) % 2 == 0:
            self.rect(23, 4, 2, 1, SLEEP)
            self.rect(24, 3, 2, 1, SLEEP)
            self.rect(23, 2, 3, 1, SLEEP)
        else:
            self.rect(24, 3, 2, 1, SLEEP)
            self.rect(25, 2, 2, 1, SLEEP)
            self.rect(24, 1, 3, 1, SLEEP)

    def review(self, frame):
        shake = -1 if frame % 2 == 0 else 1
        self.draw_body(9 + shake, 9)
        self.draw_head(4 + shake, 4, surprised=True)
        self.draw_tail(22 + shake, 11, 2)
        self.rect(25, 3, 2, 9, ALERT)
        self.rect(25, 14, 2, 2, ALERT)
        self.rect(14 + shake, 17, 3, 2, OUTLINE)
        self.rect(20 + shake, 17, 3, 2, OUTLINE)


def frame(state, n):
    sprite = Sprite()
    getattr(sprite, state)(n)
    return sprite.img.resize((WIDTH * SCALE, HEIGHT * SCALE), Image.Resampling.NEAREST)


def gif(path, state, frames, duration):
    images = [frame(state, n) for n in frames]
    images[0].save(
        path,
        save_all=True,
        append_images=images[1:],
        duration=duration,
        loop=0,
        disposal=2,
    )


def contact_sheet(path):
    rows = [
        ("idle / resting", "idle", [0, 5]),
        ("running", "running", [0, 1, 2, 3, 4, 5]),
        ("review / alert", "review", [0, 1]),
    ]
    cell_w = WIDTH * SCALE
    cell_h = HEIGHT * SCALE
    gap = 22
    margin = 28
    label_h = 28
    row_h = label_h + cell_h + 20
    sheet_w = margin * 2 + 6 * cell_w + 5 * gap
    sheet_h = margin * 2 + len(rows) * row_h
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (248, 248, 248, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for row_i, (label, state, frames) in enumerate(rows):
        top = margin + row_i * row_h
        draw.text((margin, top), label, fill=(25, 25, 25, 255), font=font)
        for frame_i, n in enumerate(frames):
            x = margin + frame_i * (cell_w + gap)
            y = top + label_h
            sheet.alpha_composite(frame(state, n), (x, y))
            draw.text((x, y + cell_h + 4), f"frame {n}", fill=(80, 80, 80, 255), font=font)

    sheet.save(path)


def main():
    out = Path(__file__).resolve().parent / "previews"
    out.mkdir(exist_ok=True)
    gif(out / "idle.gif", "idle", [0, 1, 2, 3, 4, 5, 6, 7], 180)
    gif(out / "running.gif", "running", [0, 1, 2, 3, 4, 5], 110)
    gif(out / "review.gif", "review", [0, 1], 150)
    contact_sheet(out / "states.png")
    print(out)


if __name__ == "__main__":
    main()
