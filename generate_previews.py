#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 34
HEIGHT = 24
SCALE = 8

OUTLINE = (10, 10, 10, 255)
FUR = (230, 230, 230, 255)
FUR_LIGHT = (255, 255, 255, 255)
FUR_DARK = (92, 92, 92, 255)
MID = (174, 174, 174, 255)
EYE = (8, 8, 8, 255)
SIGNAL = (242, 242, 242, 255)
TRANSPARENT = (0, 0, 0, 0)


class Sprite:
    def __init__(self):
        self.img = Image.new("RGBA", (WIDTH, HEIGHT), TRANSPARENT)
        self.draw = ImageDraw.Draw(self.img)

    def rect(self, x, y_from_top, w, h, color):
        if w <= 0 or h <= 0:
            return
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
        self.rect(x + 5, y + 6, 1, 1, MID)

        if blink:
            self.rect(x + 3, y + 5, 2, 1, OUTLINE)
            self.rect(x + 7, y + 5, 2, 1, OUTLINE)
        elif surprised:
            self.rect(x + 3, y + 5, 2, 2, EYE)
            self.rect(x + 7, y + 5, 2, 2, EYE)
            self.rect(x + 5, y + 8, 2, 2, SIGNAL)
        else:
            self.rect(x + 3, y + 5, 1, 2, EYE)
            self.rect(x + 7, y + 5, 1, 2, EYE)
            self.rect(x + 5, y + 8, 2, 1, OUTLINE)

    def draw_body(self, x, y, stretch=0):
        self.rect(x + 1, y + 1, 15 + stretch, 7, OUTLINE)
        self.rect(x, y + 3, 17 + stretch, 4, OUTLINE)
        self.rect(x + 2, y + 2, 13 + stretch, 5, FUR)
        self.rect(x + 5, y + 3, 7 + stretch, 3, FUR_LIGHT)
        self.rect(x + 4, y + 2, 2, 1, MID)
        self.rect(x + 13 + stretch, y + 2, 2, 1, FUR_DARK)

    def draw_tail(self, base_x, base_y, phase, wild=False):
        lift = ([3, 1, -2, -4, -2, 1, 3, 2] if wild else [1, 0, -1, -2, -1, 0, 1, 0])[phase % 8]
        self.rect(base_x, base_y + 2 + lift, 6, 2, OUTLINE)
        self.rect(base_x + 4, base_y - 1 + lift, 2, 5, OUTLINE)
        self.rect(base_x + 1, base_y + 3 + lift, 5, 1, FUR_DARK)
        self.rect(base_x + 5, base_y + lift, 1, 4, FUR)

    def running(self, frame):
        phase = frame % 8
        bob = [2, 0, -2, -3, -1, 1, 3, 1][phase]
        lean = [-1, 1, 2, 1, -1, -2, -1, 0][phase]
        stretch = [0, 1, 2, 1, 0, 1, 2, 1][phase]
        front_leg = [4, 2, 0, -3, -5, -2, 1, 3][phase]
        back_leg = [-5, -2, 1, 4, 5, 2, -1, -4][phase]
        front_drop = [2, 1, 0, 0, 1, 2, 2, 1][phase]
        back_drop = [0, 1, 2, 2, 1, 0, 0, 1][phase]
        self.draw_tail(25 + lean, 10 + bob, phase, wild=True)
        self.draw_body(9 + lean, 8 + bob, stretch)
        self.draw_head(3 + lean, 4 + bob)
        self.rect(12 + lean + front_leg, 18 + bob + front_drop, 5, 2, OUTLINE)
        self.rect(13 + lean + front_leg, 17 + bob + front_drop, 3, 2, FUR_DARK)
        self.rect(22 + lean + back_leg, 18 + bob + back_drop, 5, 2, OUTLINE)
        self.rect(23 + lean + back_leg, 17 + bob + back_drop, 3, 2, FUR_DARK)
        self.rect(0, 21, 3, 1, (174, 174, 174, 190 if phase % 2 == 0 else 90))
        self.rect(3, 20, 4, 1, (174, 174, 174, 140 if phase % 2 == 0 else 50))

    def idle(self, frame):
        phase = frame % 12
        breathe = 0 if phase < 6 else 1
        tail_lift = [0, -1, -2, -2, -1, 0, 1, 2, 1, 0, -1, 0][phase]
        sleep_shift = 0 if phase < 6 else 2
        self.rect(9, 12, 16, 7 + breathe, OUTLINE)
        self.rect(10, 11, 14, 8 + breathe, OUTLINE)
        self.rect(11, 12, 12, 6 + breathe, FUR)
        self.rect(13, 13, 8, 4 + breathe, FUR_LIGHT)
        self.rect(16, 15, 3, 2, MID)
        self.rect(4, 8, 10, 8, OUTLINE)
        self.rect(5, 9, 8, 6, FUR)
        self.rect(5, 6, 2, 4, OUTLINE)
        self.rect(11, 6, 2, 4, OUTLINE)
        self.rect(6, 10, 6, 3, FUR_LIGHT)
        self.rect(7, 11, 2, 1, OUTLINE)
        self.rect(11, 11, 2, 1, OUTLINE)
        self.rect(22, 13 + tail_lift, 7, 3, OUTLINE)
        self.rect(23, 14 + tail_lift, 5, 1, FUR_DARK)
        self.rect(19, 15 + tail_lift, 5, 2, OUTLINE)
        self.rect(20, 15 + tail_lift, 3, 1, FUR)
        if phase < 6:
            self.rect(27 + sleep_shift, 4, 2, 1, SIGNAL)
            self.rect(28 + sleep_shift, 3, 2, 1, SIGNAL)
            self.rect(27 + sleep_shift, 2, 4, 1, SIGNAL)
        else:
            self.rect(28 + sleep_shift, 3, 2, 1, SIGNAL)
            self.rect(30 + sleep_shift, 2, 2, 1, SIGNAL)
            self.rect(28 + sleep_shift, 1, 4, 1, SIGNAL)

    def review(self, frame):
        phase = frame % 4
        shake = [-3, 2, 3, -2][phase]
        bob = [0, -2, 0, 2][phase]
        mark_shift = [0, 1, 0, -1][phase]
        self.draw_body(10 + shake, 9 + bob)
        self.draw_head(4 + shake, 4 + bob, surprised=True)
        self.draw_tail(25 + shake, 11 + bob, phase, wild=True)
        self.rect(29 + mark_shift, 1 + bob, 2, 11, SIGNAL)
        self.rect(29 + mark_shift, 14 + bob, 2, 2, SIGNAL)
        self.rect(14 + shake, 18 + bob, 4, 2, OUTLINE)
        self.rect(22 + shake, 18 + bob, 4, 2, OUTLINE)


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
        ("idle / resting", "idle", [0, 3, 6, 9]),
        ("running", "running", [0, 1, 2, 3, 4, 5, 6, 7]),
        ("review / alert", "review", [0, 1, 2, 3]),
    ]
    cell_w = WIDTH * SCALE
    cell_h = HEIGHT * SCALE
    gap = 22
    margin = 28
    label_h = 28
    row_h = label_h + cell_h + 20
    max_frames = max(len(frames) for _, _, frames in rows)
    sheet_w = margin * 2 + max_frames * cell_w + (max_frames - 1) * gap
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
    gif(out / "idle.gif", "idle", list(range(12)), 150)
    gif(out / "running.gif", "running", list(range(8)), 90)
    gif(out / "review.gif", "review", list(range(4)), 110)
    contact_sheet(out / "states.png")
    print(out)


if __name__ == "__main__":
    main()
