#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 52
HEIGHT = 28
SCALE = 8
TRANSPARENT = (0, 0, 0, 0)

OUTLINE = (33, 31, 28, 255)
FUR = (250, 245, 232, 255)
CREAM = (255, 220, 154, 255)
SHADE = (168, 145, 120, 255)
PINK = (255, 160, 188, 255)
SHADOW = (0, 0, 0, 55)
SIGNAL = (255, 220, 66, 255)
SLEEP = (188, 188, 188, 210)


class Sprite:
    def __init__(self):
        self.img = Image.new("RGBA", (WIDTH, HEIGHT), TRANSPARENT)
        self.draw = ImageDraw.Draw(self.img)

    def rect(self, x, y, w, h, color):
        if w > 0 and h > 0:
            self.draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)

    def oval(self, x, y, w, h, color):
        if w > 0 and h > 0:
            self.draw.ellipse((x, y, x + w - 1, y + h - 1), fill=color)

    def tri(self, points, color):
        self.draw.polygon(points, fill=color)

    def line(self, points, color, width=1):
        self.draw.line(points, fill=color, width=width, joint="curve")

    def running(self, frame):
        p = frame % 8
        bob = [0, -1, -2, -1, 0, 1, 0, -1][p]
        lean = [0, 1, 1, 0, -1, -1, 0, 0][p]
        stretch = [0, 1, 2, 1, 0, -1, 0, 1][p]
        arch = [0, -1, -2, -1, 0, 1, 0, -1][p]

        self.oval(14, 24, 30, 3, SHADOW)
        self.speed(p)
        self.run_tail(34 + lean + stretch, 9 + bob + arch, p)
        self.run_body(15 + lean, 10 + bob + arch, stretch)
        self.head(3 + lean, 6 + bob + arch, p, "run")
        self.run_legs(20 + lean, 19 + bob, stretch, p)

    def idle(self, frame):
        p = frame % 12
        breathe = 0 if p < 6 else 1
        shift = 0 if p < 6 else 2
        self.oval(11, 24, 31, 3, SHADOW)
        self.curled_body(10, 11 + breathe, breathe)
        self.head(7, 6 + breathe, p, "sleep")
        self.curled_tail(34, 12 + breathe)
        if p < 6:
            self.rect(43 + shift, 6, 3, 1, SLEEP)
            self.rect(45 + shift, 4, 3, 1, SLEEP)
            self.rect(43 + shift, 2, 5, 1, SLEEP)
        else:
            self.rect(44 + shift, 5, 3, 1, SLEEP)
            self.rect(46 + shift, 3, 3, 1, SLEEP)
            self.rect(44 + shift, 1, 5, 1, SLEEP)

    def review(self, frame):
        p = frame % 4
        wobble = [-1, 1, 0, -1][p]
        pop = [0, -1, 0, 1][p]
        self.oval(17, 24, 24, 3, SHADOW)
        self.sitting_body(21 + wobble, 11 + pop)
        self.head(14 + wobble, 4 + pop, p, "alert")
        self.sitting_tail(35 + wobble, 15 + pop, p)
        self.review_mark(45 - wobble, 3 + pop, p)

    def head(self, x, y, p, mood):
        self.tri([(x + 5, y + 1), (x + 9, y + 8), (x + 2, y + 8)], OUTLINE)
        self.tri([(x + 15, y + 1), (x + 18, y + 8), (x + 11, y + 8)], OUTLINE)
        self.oval(x + 2, y + 5, 17, 16, OUTLINE)
        self.oval(x + 4, y + 7, 13, 12, FUR)
        self.tri([(x + 6, y + 5), (x + 8, y + 8), (x + 5, y + 8)], PINK)
        self.tri([(x + 14, y + 5), (x + 16, y + 8), (x + 12, y + 8)], PINK)
        self.oval(x + 8, y + 12, 6, 5, CREAM)
        self.rect(x + 10, y + 16, 1, 1, PINK)
        if mood == "sleep":
            self.rect(x + 7, y + 15, 3, 1, OUTLINE)
            self.rect(x + 13, y + 15, 3, 1, OUTLINE)
            self.rect(x + 10, y + 18, 3, 1, (70, 62, 55, 185))
        elif mood == "alert":
            self.rect(x + 7, y + 13, 3, 3, OUTLINE)
            self.rect(x + 13, y + 13, 3, 3, OUTLINE)
            self.rect(x + 10, y + 18, 4, 2, OUTLINE)
        else:
            blink = p == 5
            self.rect(x + 7, y + 13, 3, 1 if blink else 3, OUTLINE)
            self.rect(x + 13, y + 13, 3, 1 if blink else 3, OUTLINE)

    def run_body(self, x, y, stretch):
        self.oval(x, y, 24 + stretch, 13, OUTLINE)
        self.oval(x + 2, y + 2, 20 + stretch, 9, FUR)
        self.oval(x + 7, y + 4, 11 + stretch, 5, CREAM)
        self.oval(x + 18 + stretch, y + 4, 7, 7, SHADE)
        self.rect(x + 5, y + 12, 14 + stretch, 1, OUTLINE)

    def run_legs(self, x, y, stretch, p):
        front = [5, 3, 1, -3, -5, -2, 2, 4][p]
        rear = [-5, -3, 2, 5, 3, 0, -3, -5][p]
        ghost_front = [-2, 0, 3, 4, 2, 0, -1, -2][p]
        ghost_rear = [3, 1, -3, -4, -2, 0, 2, 3][p]
        self.leg(x + 5, y, x + 5 + ghost_front, y + 5, SHADE, False)
        self.leg(x + 19 + stretch, y, x + 19 + stretch + ghost_rear, y + 5, SHADE, False)
        self.leg(x + 2, y, x + 2 + front, y + 7 + (p % 2), FUR, True)
        self.leg(x + 16 + stretch, y, x + 16 + stretch + rear, y + 7 + ((p + 1) % 2), SHADE, True)

    def leg(self, hx, hy, fx, fy, fill, primary):
        kx = (hx + fx) // 2
        ky = hy + 3
        w = 3 if primary else 2
        self.line([(hx, hy), (kx, ky), (fx, fy)], OUTLINE, w)
        self.line([(hx, hy + 1), (kx, ky + 1), (fx, fy)], fill, max(1, w - 2))
        self.oval(fx - 2, fy - 1, 6 if primary else 4, 3, OUTLINE)
        self.oval(fx - 1, fy - 1, 4 if primary else 3, 2, fill)

    def run_tail(self, x, y, p):
        lift = [3, 2, -1, -3, -2, 0, 2, 3][p]
        pts = [(x, y + 8 + lift), (x + 4, y + 5 + lift), (x + 8, y + lift), (x + 8, y - 3 + lift)]
        self.line(pts, OUTLINE, 4)
        self.line(pts, FUR, 1)

    def curled_body(self, x, y, breathe):
        self.oval(x, y, 31, 16 + breathe, OUTLINE)
        self.oval(x + 3, y + 2, 26, 12 + breathe, FUR)
        self.oval(x + 10, y + 4, 14, 7 + breathe, CREAM)
        self.oval(x + 23, y + 5, 7, 7, SHADE)
        self.rect(x + 6, y + 15 + breathe, 19, 2, OUTLINE)

    def curled_tail(self, x, y):
        self.line([(x, y + 11), (x + 7, y + 8), (x + 7, y + 2)], OUTLINE, 4)
        self.line([(x, y + 11), (x + 6, y + 8), (x + 6, y + 3)], FUR, 1)

    def sitting_body(self, x, y):
        self.oval(x, y, 16, 20, OUTLINE)
        self.oval(x + 3, y + 2, 11, 16, FUR)
        self.oval(x + 6, y + 6, 7, 10, CREAM)
        self.oval(x - 2, y + 16, 8, 5, OUTLINE)
        self.oval(x + 12, y + 16, 9, 5, OUTLINE)
        self.rect(x + 1, y + 19, 5, 1, SHADE)
        self.rect(x + 15, y + 19, 5, 1, SHADE)

    def sitting_tail(self, x, y, p):
        curl = [0, 1, 0, -1][p]
        pts = [(x, y + 8 + curl), (x + 7, y + 5 + curl), (x + 10, y + curl)]
        self.line(pts, OUTLINE, 4)
        self.line(pts, FUR, 1)

    def review_mark(self, x, y, p):
        hop = [0, -1, 0, 1][p]
        self.rect(x, y + hop, 5, 16, OUTLINE)
        self.rect(x + 1, y + 1 + hop, 3, 13, SIGNAL)
        self.rect(x, y + 20 + hop, 5, 5, OUTLINE)
        self.rect(x + 1, y + 21 + hop, 3, 3, SIGNAL)

    def speed(self, p):
        alpha = 86 if p % 2 == 0 else 46
        self.rect(2, 25, 7, 1, (168, 145, 120, alpha))
        self.rect(6, 22, 5, 1, (168, 145, 120, int(alpha * 0.7)))


def frame(state, n):
    sprite = Sprite()
    getattr(sprite, state)(n)
    return sprite.img.resize((WIDTH * SCALE, HEIGHT * SCALE), Image.Resampling.NEAREST)


def gif(path, state, frames, duration):
    images = [frame(state, n) for n in frames]
    images[0].save(path, save_all=True, append_images=images[1:], duration=duration, loop=0, disposal=2)


def contact_sheet(path):
    rows = [
        ("idle / resting", "idle", [0, 3, 6, 9]),
        ("running", "running", list(range(8))),
        ("review / alert", "review", [0, 1, 2, 3]),
    ]
    cell_w = WIDTH * SCALE
    cell_h = HEIGHT * SCALE
    gap = 18
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
