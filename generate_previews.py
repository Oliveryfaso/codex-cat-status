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
        lift = [1, 0, -1, -2, -1, 0, 1, 0][phase % 8]
        self.rect(base_x, base_y + 2 + lift, 5, 2, OUTLINE)
        self.rect(base_x + 3, base_y + lift, 2, 4, OUTLINE)
        self.rect(base_x + 1, base_y + 3 + lift, 4, 1, FUR_DARK)
        self.rect(base_x + 4, base_y + 1 + lift, 1, 3, FUR)

    def running(self, frame):
        phase = frame % 8
        bob = [1, 0, -1, -2, -1, 0, 1, 0][phase]
        lean = [0, 1, 1, 0, -1, -1, 0, 1][phase]
        front_leg = [2, 1, 0, -1, -2, -1, 0, 1][phase]
        back_leg = [-2, -1, 0, 1, 2, 1, 0, -1][phase]
        front_drop = [1, 0, 0, 0, 1, 1, 0, 0][phase]
        back_drop = [0, 1, 1, 0, 0, 0, 1, 1][phase]
        self.draw_tail(22 + lean, 10 + bob, phase)
        self.draw_body(8 + lean, 8 + bob)
        self.draw_head(3 + lean, 5 + bob)
        self.rect(11 + lean + front_leg, 17 + bob + front_drop, 3, 2, OUTLINE)
        self.rect(12 + lean + front_leg, 16 + bob + front_drop, 2, 2, FUR_DARK)
        self.rect(20 + lean + back_leg, 17 + bob + back_drop, 3, 2, OUTLINE)
        self.rect(21 + lean + back_leg, 16 + bob + back_drop, 2, 2, FUR_DARK)
        self.rect(14 + lean, 10 + bob, 2, 1, FUR_LIGHT)
        self.rect(18 + lean, 10 + bob, 2, 1, FUR_LIGHT)

    def idle(self, frame):
        phase = frame % 12
        breathe = 0 if phase < 6 else 1
        tail_lift = [0, 0, -1, -1, 0, 1, 1, 0, 0, -1, 0, 1][phase]
        sleep_shift = 0 if phase < 6 else 1
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
        self.rect(20, 13 + tail_lift, 5, 3, OUTLINE)
        self.rect(21, 14 + tail_lift, 4, 1, FUR_DARK)
        self.rect(18, 15 + tail_lift, 4, 2, OUTLINE)
        self.rect(18, 15 + tail_lift, 3, 1, FUR)
        if phase < 6:
            self.rect(23 + sleep_shift, 4, 2, 1, SLEEP)
            self.rect(24 + sleep_shift, 3, 2, 1, SLEEP)
            self.rect(23 + sleep_shift, 2, 3, 1, SLEEP)
        else:
            self.rect(24 + sleep_shift, 3, 2, 1, SLEEP)
            self.rect(25 + sleep_shift, 2, 2, 1, SLEEP)
            self.rect(24 + sleep_shift, 1, 3, 1, SLEEP)

    def review(self, frame):
        phase = frame % 4
        shake = [-2, 1, 2, -1][phase]
        bob = [0, -1, 0, 1][phase]
        mark_shift = [0, 1, 0, -1][phase]
        self.draw_body(9 + shake, 9 + bob)
        self.draw_head(4 + shake, 4 + bob, surprised=True)
        self.draw_tail(22 + shake, 11 + bob, phase)
        self.rect(25 + mark_shift, 2 + bob, 2, 10, ALERT)
        self.rect(25 + mark_shift, 14 + bob, 2, 2, ALERT)
        self.rect(14 + shake, 17 + bob, 3, 2, OUTLINE)
        self.rect(20 + shake, 17 + bob, 3, 2, OUTLINE)


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
