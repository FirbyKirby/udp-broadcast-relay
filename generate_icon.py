#!/usr/bin/env python3
"""Generate the Unraid icon: network hub with symmetric broadcast arcs at satellite nodes."""

import math
from PIL import Image, ImageDraw

SIZE = 512
CENTER = (SIZE // 2, SIZE // 2)

BLUE = "#3B82C4"
GREEN = "#4CAF7D"
CYAN = "#00BCD4"

HUB_RADIUS = 36
SATELLITE_RADIUS = 22
LINE_WIDTH = 6
ARC_WIDTH = 8

SATELLITE_DISTANCE = 150

SATELLITE_POSITIONS = [
    (CENTER[0], CENTER[1] - SATELLITE_DISTANCE),
    (
        int(CENTER[0] - SATELLITE_DISTANCE * math.cos(math.radians(30))),
        int(CENTER[1] + SATELLITE_DISTANCE * math.sin(math.radians(30))),
    ),
    (
        int(CENTER[0] + SATELLITE_DISTANCE * math.cos(math.radians(30))),
        int(CENTER[1] + SATELLITE_DISTANCE * math.sin(math.radians(30))),
    ),
]


def draw_broadcast_arcs(draw, node_center, arcs_count=2, start_radius=32, radius_step=22,
                        arc_angle=150, line_width=ARC_WIDTH, color=CYAN):
    """Draw identical broadcast arcs around a satellite node.

    Arcs are centered on the direction from the hub to the node (pointing outward).
    Each satellite gets the exact same arc parameters for perfect symmetry.
    """
    dx = node_center[0] - CENTER[0]
    dy = node_center[1] - CENTER[1]
    outward_angle = math.degrees(math.atan2(dy, dx))

    arc_span = arc_angle
    half_span = arc_span / 2
    arc_bbox_padding = arcs_count * radius_step + start_radius + 20

    for i in range(arcs_count):
        r = start_radius + i * radius_step
        bbox = [
            node_center[0] - r,
            node_center[1] - r,
            node_center[0] + r,
            node_center[1] + r,
        ]
        start = outward_angle - half_span
        end = outward_angle + half_span
        draw.arc(bbox, start=start, end=end, fill=color, width=line_width)


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)

    for sat in SATELLITE_POSITIONS:
        draw.line([CENTER, sat], fill=BLUE, width=LINE_WIDTH)

    draw_broadcast_arcs(draw, SATELLITE_POSITIONS[0])
    draw_broadcast_arcs(draw, SATELLITE_POSITIONS[1])
    draw_broadcast_arcs(draw, SATELLITE_POSITIONS[2])

    for sat in SATELLITE_POSITIONS:
        r = SATELLITE_RADIUS
        draw.ellipse(
            [sat[0] - r, sat[1] - r, sat[0] + r, sat[1] + r],
            fill=GREEN,
        )

    r = HUB_RADIUS
    draw.ellipse(
        [CENTER[0] - r, CENTER[1] - r, CENTER[0] + r, CENTER[1] + r],
        fill=BLUE,
    )

    img.save("templates/icon.png", "PNG")
    print("Icon saved to templates/icon.png")


if __name__ == "__main__":
    main()
