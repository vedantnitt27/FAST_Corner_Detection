import cv2
import numpy as np
import time

# ─────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────
IMAGE_PATH   = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\64\square64.png"
THRESHOLD    = 40
NMS_RADIUS   = 4
BORDER       = 4
DISPLAY_SIZE = 512

# ─────────────────────────────────────
# LOAD IMAGE
# ─────────────────────────────────────
image = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
if image is None:
    print("Image not found!")
    exit()

image = cv2.resize(image, (64, 64), interpolation=cv2.INTER_NEAREST)

# ─────────────────────────────────────
# BRESENHAM RADIUS-3 CIRCLE OFFSETS
# ─────────────────────────────────────
CIRCLE = [
    (-3, 0), (-3,+1), (-2,+2), (-1,+3),
    ( 0,+3), (+1,+3), (+2,+2), (+3,+1),
    (+3, 0), (+3,-1), (+2,-2), (+1,-3),
    ( 0,-3), (-1,-3), (-2,-2), (-3,-1)
]

# ─────────────────────────────────────
# FAST DETECTION
# ─────────────────────────────────────
def fast_detect(img, threshold, border):
    corners = []
    h, w = img.shape
    for y in range(border, h - border):
        for x in range(border, w - border):
            c      = int(img[y, x])
            upper  = c + threshold
            lower  = c - threshold
            circle = [int(img[y+dy, x+dx]) for (dy,dx) in CIRCLE]
            bright = [1 if p > upper else 0 for p in circle] * 2
            dark   = [1 if p < lower else 0 for p in circle] * 2
            br = dr = 0
            found = False
            for i in range(32):
                br = br+1 if bright[i] else 0
                dr = dr+1 if dark[i]   else 0
                if br >= 9 or dr >= 9:
                    found = True
                    break
            if found:
                corners.append((x, y))
    return corners

# ─────────────────────────────────────
# NMS
# ─────────────────────────────────────
def apply_nms(corners, radius):
    suppressed = set()
    result     = []
    for i in range(len(corners)):
        if i in suppressed:
            continue
        cx, cy  = corners[i]
        cluster = [(cx, cy)]
        for j in range(i+1, len(corners)):
            if j in suppressed:
                continue
            dx = corners[j][0] - cx
            dy = corners[j][1] - cy
            if (dx*dx + dy*dy)**0.5 <= radius:
                cluster.append(corners[j])
                suppressed.add(j)
        result.append((
            int(round(sum(p[0] for p in cluster) / len(cluster))),
            int(round(sum(p[1] for p in cluster) / len(cluster)))
        ))
    return result

# ─────────────────────────────────────
# RUN DETECTION
# ─────────────────────────────────────
t0          = time.perf_counter()
raw         = fast_detect(image, THRESHOLD, BORDER)
clean       = apply_nms(raw, NMS_RADIUS)
t1          = time.perf_counter()
cpu_time_us = (t1 - t0) * 1_000_000

# FPGA time: 4096 pixels + 200 pipeline clocks @ 100MHz
fpga_time_us = (64*64 + 200) / 100
speedup      = cpu_time_us / fpga_time_us

# ─────────────────────────────────────
# PRINT RESULTS
# ─────────────────────────────────────
print(f"Raw corners   : {len(raw)}")
print(f"After NMS     : {len(clean)}")
print(f"Positions     : {sorted(clean)}")
print(f"CPU time      : {cpu_time_us:.1f} us")
print(f"FPGA time     : {fpga_time_us:.2f} us")
print(f"Speedup       : {speedup:.1f}x")

# ─────────────────────────────────────
# VISUALIZATION
# ─────────────────────────────────────
scale   = DISPLAY_SIZE // 64
display = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
display = cv2.resize(display, (DISPLAY_SIZE, DISPLAY_SIZE),
                     interpolation=cv2.INTER_NEAREST)

for (x, y) in clean:
    px = x * scale + scale // 2
    py = y * scale + scale // 2

    cv2.circle(display, (px, py), 8, (0, 0, 255), -1)
    cv2.circle(display, (px, py), 8, (255, 255, 255), 2)
    cv2.line(display, (px-16, py), (px+16, py), (0, 255, 255), 1)
    cv2.line(display, (px, py-16), (px, py+16), (0, 255, 255), 1)

    label   = f"({x},{y})"
    lx, ly  = px + 11, py - 8
    if lx + 55 > DISPLAY_SIZE: lx = px - 60
    if ly < 12:                 ly = py + 20

    (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)
    cv2.rectangle(display, (lx-2, ly-th-2), (lx+tw+2, ly+2), (0,0,0), -1)
    cv2.putText(display, label, (lx, ly),
                cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255,255,255), 1)

# Info bar
cv2.rectangle(display, (0, DISPLAY_SIZE-36),
              (DISPLAY_SIZE, DISPLAY_SIZE), (30,30,30), -1)
cv2.putText(display,
            f"FAST+NMS  Corners:{len(clean)}  "
            f"CPU:{cpu_time_us:.0f}us  FPGA:{fpga_time_us:.1f}us  "
            f"Speedup:{speedup:.0f}x",
            (6, DISPLAY_SIZE-12),
            cv2.FONT_HERSHEY_SIMPLEX, 0.42, (0,255,0), 1)

cv2.imshow("CPU FAST + NMS Corner Detection", display)
cv2.waitKey(0)
cv2.destroyAllWindows()