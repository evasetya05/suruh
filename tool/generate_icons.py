#!/usr/bin/env python3
"""Renders the MSDevBuild Eats logo to every icon size the project needs.

Pure standard library: an SDF rasteriser plus a hand-rolled PNG encoder, so it
runs anywhere Python does with no imaging dependency to install.

    python3 tool/generate_icons.py

Design
------
Rounded square in the brand green gradient, a white "M" monogram drawn as four
round-capped strokes, and an orange dot beneath it. The same geometry is
reproduced vectorially by `AppLogo` in lib/core/widgets/app_logo.dart, so the
launcher icon and the in-app mark stay identical.
"""

from __future__ import annotations

import math
import os
import struct
import zlib

# --- Brand -------------------------------------------------------------------
GREEN_LIGHT = (0x00, 0xC7, 0x5A)
GREEN_DARK = (0x00, 0x8C, 0x3E)
ORANGE = (0xFF, 0x7A, 0x00)
WHITE = (0xFF, 0xFF, 0xFF)

# Geometry, in fractions of the icon's side. Mirrored in app_logo.dart.
CORNER_RADIUS = 0.2237
STROKE = 0.1120
M_LEFT, M_RIGHT = 0.2600, 0.7400
M_TOP, M_BOTTOM = 0.3050, 0.6250
M_VALLEY_Y = 0.5250
DOT_CENTRE_Y = 0.7620
DOT_RADIUS = 0.0610

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# --- Signed distance fields --------------------------------------------------
def sd_rounded_rect(px, py, half_w, half_h, radius):
    qx = abs(px) - half_w + radius
    qy = abs(py) - half_h + radius
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    inside = min(max(qx, qy), 0.0)
    return outside + inside - radius


def sd_segment(px, py, ax, ay, bx, by, radius):
    """Distance to a round-capped capsule from (ax, ay) to (bx, by)."""
    pax, pay = px - ax, py - ay
    bax, bay = bx - ax, by - ay
    denom = bax * bax + bay * bay
    h = 0.0 if denom == 0 else max(0.0, min(1.0, (pax * bax + pay * bay) / denom))
    return math.hypot(pax - bax * h, pay - bay * h) - radius


def sd_circle(px, py, cx, cy, radius):
    return math.hypot(px - cx, py - cy) - radius


def coverage(distance, texel):
    """Antialiased coverage from a signed distance, in [0, 1]."""
    return max(0.0, min(1.0, 0.5 - distance / texel))


def over(src, dst, alpha):
    """Source-over composite of one channel."""
    return src * alpha + dst * (1.0 - alpha)


# --- Rendering ---------------------------------------------------------------
def render(size, *, maskable=False, transparent_background=False):
    """Returns `size` x `size` RGBA bytes.

    maskable: full-bleed background with the mark inset, so a circular Android
    mask cannot clip it.
    """
    texel = 1.0 / size
    scale = 0.66 if maskable else 1.0
    centre = 0.5

    def s(value):
        """Scales a fractional coordinate about the icon centre."""
        return centre + (value - centre) * scale

    stroke_r = STROKE * scale / 2
    m_left, m_right = s(M_LEFT), s(M_RIGHT)
    m_top, m_bottom = s(M_TOP), s(M_BOTTOM)
    m_valley = s(M_VALLEY_Y)
    m_mid = s(0.5)
    dot_y = s(DOT_CENTRE_Y)
    dot_r = DOT_RADIUS * scale

    rows = bytearray()
    for y in range(size):
        rows.append(0)  # PNG filter byte: none
        fy = (y + 0.5) * texel
        for x in range(size):
            fx = (x + 0.5) * texel

            # Background plate.
            if transparent_background:
                bg_alpha = 0.0
                r = g = b = 0.0
            else:
                if maskable:
                    bg_alpha = 1.0
                else:
                    d = sd_rounded_rect(
                        fx - 0.5, fy - 0.5, 0.5, 0.5, CORNER_RADIUS
                    )
                    bg_alpha = coverage(d, texel)
                # Diagonal gradient, light top-left to dark bottom-right.
                t = max(0.0, min(1.0, (fx + fy) / 2.0))
                r = GREEN_LIGHT[0] + (GREEN_DARK[0] - GREEN_LIGHT[0]) * t
                g = GREEN_LIGHT[1] + (GREEN_DARK[1] - GREEN_LIGHT[1]) * t
                b = GREEN_LIGHT[2] + (GREEN_DARK[2] - GREEN_LIGHT[2]) * t

            # The "M": left stem, up-stroke, down-stroke, right stem.
            d_m = min(
                sd_segment(fx, fy, m_left, m_bottom, m_left, m_top, stroke_r),
                sd_segment(fx, fy, m_left, m_top, m_mid, m_valley, stroke_r),
                sd_segment(fx, fy, m_mid, m_valley, m_right, m_top, stroke_r),
                sd_segment(fx, fy, m_right, m_top, m_right, m_bottom, stroke_r),
            )
            a_m = coverage(d_m, texel)
            if a_m > 0:
                r = over(WHITE[0], r, a_m)
                g = over(WHITE[1], g, a_m)
                b = over(WHITE[2], b, a_m)
                bg_alpha = max(bg_alpha, a_m)

            # Accent dot.
            a_dot = coverage(sd_circle(fx, fy, m_mid, dot_y, dot_r), texel)
            if a_dot > 0:
                r = over(ORANGE[0], r, a_dot)
                g = over(ORANGE[1], g, a_dot)
                b = over(ORANGE[2], b, a_dot)
                bg_alpha = max(bg_alpha, a_dot)

            rows += bytes(
                (
                    int(r + 0.5),
                    int(g + 0.5),
                    int(b + 0.5),
                    int(bg_alpha * 255 + 0.5),
                )
            )
    return bytes(rows), size


def write_png(path, raw_rows, size):
    """Minimal RGBA8 PNG writer."""

    def chunk(tag, payload):
        body = tag + payload
        return (
            struct.pack('>I', len(payload))
            + body
            + struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF)
        )

    header = struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)
    png = (
        b'\x89PNG\r\n\x1a\n'
        + chunk(b'IHDR', header)
        + chunk(b'IDAT', zlib.compress(raw_rows, 9))
        + chunk(b'IEND', b'')
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as handle:
        handle.write(png)
    return len(png)


TARGETS = [
    # Web
    ('web/favicon.png', 64, {}),
    ('web/icons/Icon-192.png', 192, {}),
    ('web/icons/Icon-512.png', 512, {}),
    ('web/icons/Icon-maskable-192.png', 192, {'maskable': True}),
    ('web/icons/Icon-maskable-512.png', 512, {'maskable': True}),
    # Android launcher
    ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48, {}),
    ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72, {}),
    ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96, {}),
    ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144, {}),
    ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, {}),
    # iOS launcher
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 1024, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 20, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png', 40, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png', 60, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png', 29, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png', 58, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png', 87, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png', 40, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png', 80, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png', 120, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 120, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png', 180, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png', 76, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png', 152, {}),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png', 167, {}),
    # Docs
    ('assets/logo/logo-256.png', 256, {}),
    ('assets/logo/logo-512.png', 512, {}),
]


def main():
    total = 0
    for relative, size, options in TARGETS:
        raw, dimension = render(size, **options)
        written = write_png(os.path.join(ROOT, relative), raw, dimension)
        total += written
        print(f'  {relative:70s} {size:>4}px  {written / 1024:6.1f} KB')
    print(f'\n{len(TARGETS)} icons, {total / 1024:.1f} KB total')


if __name__ == '__main__':
    main()
