#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 44
HEIGHT = 28
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
        lean = [-1, 1, 2, 2, 0, -2, -2, 0][phase]
        wave = [0, 1, 2, 1, 0, -1, -2, -1][phase]
        reach = [6, 3, 0, -4, -6, -2, 2, 5][phase]
        push = [-6, -3, 1, 5, 6, 2, -2, -5][phase]
        self.speed_lines(phase)
        self.run_tail(35 + lean, 11 + bob, phase)
        self.run_body(13 + lean, 10 + bob, wave)
        self.run_head(4 + lean, 6 + bob + min(1, wave), phase)
        self.run_legs(16 + lean, 18 + bob, reach, push, phase)

    def idle(self, frame):
        phase = frame % 12
        breathe = 0 if phase < 6 else 1
        sleep_shift = 0 if phase < 6 else 2
        self.curled_body(9, 10, breathe)
        self.curled_head(8, 9 + breathe)
        self.curled_tail(23, 13 + breathe)
        if phase < 6:
            self.rect(30 + sleep_shift, 4, 2, 1, SIGNAL)
            self.rect(31 + sleep_shift, 3, 2, 1, SIGNAL)
            self.rect(30 + sleep_shift, 2, 4, 1, SIGNAL)
        else:
            self.rect(31 + sleep_shift, 3, 2, 1, SIGNAL)
            self.rect(33 + sleep_shift, 2, 2, 1, SIGNAL)
            self.rect(31 + sleep_shift, 1, 4, 1, SIGNAL)

    def review(self, frame):
        phase = frame % 4
        wobble = [-1, 1, 2, -2][phase]
        pop = [0, -1, 0, 1][phase]
        self.sitting_body(15 + wobble, 12 + pop)
        self.review_head(10 + wobble, 5 + pop, phase)
        self.sitting_tail(29 + wobble, 17 + pop, phase)
        self.review_mark(35 - wobble, 2 + pop, phase)

    def run_head(self, x, y, phase):
        self.rect(x + 1, y + 2, 10, 8, OUTLINE)
        self.rect(x + 2, y + 3, 8, 6, FUR)
        self.rect(x + 2, y + 1, 2, 3, OUTLINE)
        self.rect(x + 8, y + 1, 2, 3, OUTLINE)
        self.rect(x + 3, y + 4, 6, 2, FUR_LIGHT)
        self.rect(x + 5, y + 6, 1, 1, MID)
        self.rect(x + 4, y + 5, 1, 2, EYE)
        self.rect(x + 8, y + 5, 1, 2, EYE)
        self.rect(x + 6, y + 8, 2, 1, OUTLINE)

    def run_body(self, x, y, wave):
        front_lift = max(0, -wave)
        back_lift = max(0, wave)
        self.rect(x + 1, y + 2 + front_lift, 25, 7, OUTLINE)
        self.rect(x, y + 5 + front_lift, 27, 4, OUTLINE)
        self.rect(x + 3, y + 1 + back_lift, 18, 5, OUTLINE)
        self.rect(x + 3, y + 3 + front_lift, 21, 5, FUR)
        self.rect(x + 7, y + 4 + front_lift, 13, 3, FUR_LIGHT)
        self.rect(x + 21, y + 4 + back_lift, 4, 3, FUR_DARK)
        self.rect(x + 5, y + 2 + back_lift, 4, 1, MID)

    def run_legs(self, x, y, reach, push, phase):
        self.connected_leg(x + 2, y - 2, x + 4 + reach, y + 5 + (phase % 2), True)
        self.connected_leg(x + 19, y - 2, x + 18 + push, y + 5 + ((phase + 1) % 2), False)

    def connected_leg(self, hip_x, hip_y, foot_x, foot_y, front):
        knee_x = (hip_x + foot_x) // 2
        knee_y = hip_y + 3
        self.rect(min(hip_x, knee_x), hip_y, abs(knee_x - hip_x) + 3, 3, OUTLINE)
        self.rect(min(knee_x, foot_x), knee_y, abs(foot_x - knee_x) + 3, 3, OUTLINE)
        self.rect(min(hip_x, knee_x) + 1, hip_y + 1, max(1, abs(knee_x - hip_x) + 1), 1, FUR if front else FUR_DARK)
        self.rect(min(knee_x, foot_x) + 1, knee_y + 1, max(1, abs(foot_x - knee_x) + 1), 1, FUR if front else FUR_DARK)
        self.rect(foot_x - 1, foot_y, 6, 2, OUTLINE)
        self.rect(foot_x, foot_y - 1, 4, 2, FUR if front else FUR_DARK)

    def run_tail(self, base_x, base_y, phase):
        lift = [4, 2, -1, -4, -2, 1, 4, 3][phase % 8]
        self.rect(base_x, base_y + 2 + lift, 8, 2, OUTLINE)
        self.rect(base_x + 6, base_y - 1 + lift, 2, 6, OUTLINE)
        self.rect(base_x + 1, base_y + 3 + lift, 6, 1, FUR_DARK)
        self.rect(base_x + 7, base_y + lift, 1, 5, FUR)

    def speed_lines(self, phase):
        alpha = 190 if phase % 2 == 0 else 90
        self.rect(0, 23, 6, 1, (174, 174, 174, alpha))
        self.rect(3, 21, 5, 1, (174, 174, 174, int(alpha * 0.7)))
        self.rect(1, 18, 3, 1, (174, 174, 174, int(alpha * 0.45)))

    def curled_body(self, x, y, breathe):
        self.rect(x + 8, y, 14, 3, OUTLINE)
        self.rect(x + 4, y + 2, 24, 5, OUTLINE)
        self.rect(x + 1, y + 6, 30, 8 + breathe, OUTLINE)
        self.rect(x + 3, y + 14 + breathe, 26, 5, OUTLINE)
        self.rect(x + 8, y + 19 + breathe, 16, 2, OUTLINE)
        self.rect(x + 6, y + 4, 20, 12 + breathe, FUR)
        self.rect(x + 10, y + 5, 13, 8 + breathe, FUR_LIGHT)
        self.rect(x + 18, y + 11, 6, 3, MID)
        self.rect(x + 9, y + 17 + breathe, 13, 2, FUR_DARK)

    def curled_head(self, x, y):
        self.rect(x + 1, y + 2, 11, 9, OUTLINE)
        self.rect(x + 2, y + 3, 9, 7, FUR)
        self.rect(x + 2, y, 2, 4, OUTLINE)
        self.rect(x + 9, y, 2, 4, OUTLINE)
        self.rect(x + 4, y + 5, 5, 2, FUR_LIGHT)
        self.rect(x + 4, y + 7, 2, 1, OUTLINE)
        self.rect(x + 8, y + 7, 2, 1, OUTLINE)

    def curled_tail(self, x, y):
        self.rect(x, y - 1, 9, 3, OUTLINE)
        self.rect(x + 7, y - 5, 3, 8, OUTLINE)
        self.rect(x + 2, y + 2, 8, 3, OUTLINE)
        self.rect(x + 1, y, 7, 1, FUR_DARK)
        self.rect(x + 8, y - 4, 1, 6, FUR)
        self.rect(x + 3, y + 3, 6, 1, FUR_DARK)

    def sitting_body(self, x, y):
        self.rect(x + 2, y, 14, 13, OUTLINE)
        self.rect(x, y + 6, 18, 8, OUTLINE)
        self.rect(x + 3, y + 1, 12, 12, FUR)
        self.rect(x + 5, y + 3, 8, 8, FUR_LIGHT)
        self.rect(x + 1, y + 14, 7, 3, OUTLINE)
        self.rect(x + 12, y + 14, 7, 3, OUTLINE)
        self.rect(x + 2, y + 13, 4, 2, FUR_DARK)
        self.rect(x + 13, y + 13, 4, 2, FUR_DARK)
        self.rect(x - 2, y + 7, 4, 2, OUTLINE)
        self.rect(x + 16, y + 7, 4, 2, OUTLINE)

    def review_head(self, x, y, phase):
        self.rect(x + 1, y + 2, 12, 10, OUTLINE)
        self.rect(x + 2, y + 3, 10, 8, FUR)
        self.rect(x + 2, y, 3, 4, OUTLINE)
        self.rect(x + 9, y, 3, 4, OUTLINE)
        self.rect(x + 4, y + 5, 6, 2, FUR_LIGHT)
        self.rect(x + 4, y + 6, 2, 2, EYE)
        self.rect(x + 9, y + 6, 2, 2, EYE)
        self.rect(x + 6, y + 9, 3, 2, SIGNAL)
        self.rect(x + 3, y + 12, 2, 2, OUTLINE)
        self.rect(x + 10, y + 12, 2, 2, OUTLINE)

    def sitting_tail(self, x, y, phase):
        curl = [0, 1, 0, -1][phase]
        self.rect(x, y + curl, 8, 3, OUTLINE)
        self.rect(x + 6, y - 4 + curl, 3, 7, OUTLINE)
        self.rect(x + 1, y + 1 + curl, 6, 1, FUR_DARK)
        self.rect(x + 7, y - 3 + curl, 1, 5, FUR)

    def review_mark(self, x, y, phase):
        hop = [0, -1, 0, 1][phase]
        self.rect(x, y + hop, 3, 13, SIGNAL)
        self.rect(x, y + 16 + hop, 3, 3, SIGNAL)
        self.rect(x - 1, y + hop, 1, 13, (10, 10, 10, 140))
        self.rect(x + 3, y + hop, 1, 13, (10, 10, 10, 140))


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
