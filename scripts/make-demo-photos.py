#!/usr/bin/env python3
"""Generates the 3 placeholder demo photos (original art, no third-party images).
Replace entry/src/main/resources/base/media/demo_photo_{1,2,3}.jpg with real photos any time."""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), '..', 'entry/src/main/resources/base/media')
W, H = 600, 600

def gradient(top, bottom):
    img = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img

def heart(d, cx, cy, s, fill):
    pts = []
    for i in range(200):
        t = i / 200 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * s, cy - y * s))
    d.polygon(pts, fill=fill)

# 1: sunset with a heart
img = gradient((255, 154, 139), (255, 106, 136)); d = ImageDraw.Draw(img)
d.ellipse([200, 330, 400, 530], fill=(255, 221, 148)); d.rectangle([0, 430, W, H], fill=(120, 60, 110))
heart(d, 300, 220, 7, (255, 255, 255))
img.save(os.path.join(OUT, 'demo_photo_1.jpg'), quality=88)

# 2: night sky with moon and stars
img = gradient((20, 24, 82), (88, 60, 140)); d = ImageDraw.Draw(img)
d.ellipse([360, 80, 500, 220], fill=(250, 240, 200)); d.ellipse([400, 60, 540, 200], fill=(32, 34, 92))
import random; random.seed(7)
for _ in range(70):
    x, y, r = random.randint(0, W), random.randint(0, 420), random.choice([1, 1, 2, 3])
    d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 240))
d.polygon([(0, H), (0, 470), (180, 400), (330, 480), (470, 420), (W, 470), (W, H)], fill=(14, 16, 50))
img.save(os.path.join(OUT, 'demo_photo_2.jpg'), quality=88)

# 3: sea and sun
img = gradient((130, 210, 255), (255, 240, 200)); d = ImageDraw.Draw(img)
d.ellipse([90, 90, 230, 230], fill=(255, 210, 90)); d.rectangle([0, 380, W, H], fill=(40, 140, 190))
for i in range(6):
    y = 410 + i * 30
    d.arc([40 + i * 20, y - 10, 160 + i * 20, y + 10], 200, 340, fill=(220, 245, 255), width=3)
    d.arc([330 - i * 15, y - 10, 450 - i * 15, y + 10], 200, 340, fill=(220, 245, 255), width=3)
heart(d, 430, 250, 3.5, (255, 120, 150))
img.save(os.path.join(OUT, 'demo_photo_3.jpg'), quality=88)
print('ok')
