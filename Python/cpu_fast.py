import cv2
import numpy as np
import time

# ─────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────
IMAGE_PATH   = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\Test_images\test_image1_256.png"
THRESHOLD    = 40          # fixed threshold — matches FPGA default
NMS_RADIUS   = 8           # matches your 256×256 Python receiver
BORDER       = 4           # matches FPGA border guard
NUM_RUNS     = 100         # average over 100 runs for stable timing
DISPLAY_SIZE = 512

# ─────────────────────────────────────
# FPGA TIMING CONSTANTS (256×256)
# ─────────────────────────────────────
FPGA_PIXELS       = 256 * 256        # 65536 pixels
FPGA_PIPE_DEPTH   = 776              # 3×256 + 8 pipeline stages
FPGA_TOTAL_CLOCKS = FPGA_PIXELS + FPGA_PIPE_DEPTH   # 66312
FPGA_CLOCK_MHZ    = 100
FPGA_TIME_US      = FPGA_TOTAL_CLOCKS / FPGA_CLOCK_MHZ  # 663.12 us

# ─────────────────────────────────────
# BRESENHAM RADIUS-3 CIRCLE
# Matches hardware sliding_window.v
# ─────────────────────────────────────
CIRCLE_OFFSETS = [
    (-3,  0),   # p0
    (-3, +1),   # p1
    (-2, +2),   # p2
    (-1, +3),   # p3
    ( 0, +3),   # p4
    (+1, +3),   # p5
    (+2, +2),   # p6
    (+3, +1),   # p7
    (+3,  0),   # p8
    (+3, -1),   # p9
    (+2, -2),   # p10
    (+1, -3),   # p11
    ( 0, -3),   # p12
    (-1, -3),   # p13
    (-2, -2),   # p14
    (-3, -1),   # p15
]

# ─────────────────────────────────────
# LOAD AND PREPARE IMAGE
# ─────────────────────────────────────
image_raw = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
if image_raw is None:
    print(f"Image not found: {IMAGE_PATH}")
    exit()

# Ensure exactly 256×256
image = cv2.resize(image_raw, (256, 256), interpolation=cv2.INTER_AREA)

print("=" * 52)
print("  CPU FAST Corner Detection — 256×256 Benchmark")
print("=" * 52)
print(f"  Image shape  : {image.shape}")
print(f"  Pixel count  : {image.size}")
print(f"  Threshold    : {THRESHOLD}")
print(f"  NMS radius   : {NMS_RADIUS}")
print(f"  Timing runs  : {NUM_RUNS}")
print("=" * 52)

# ─────────────────────────────────────
# FAST DETECTION (CPU)
# Contiguous arc — matches FPGA logic
# ─────────────────────────────────────
def fast_detect_cpu(img, threshold, border):
    corners = []
    h, w    = img.shape

    for y in range(border, h - border):
        for x in range(border, w - border):
            c      = int(img[y, x])
            upper  = c + threshold
            lower  = c - threshold

            # Extract 16 circle pixels
            circle = [int(img[y + dy, x + dx])
                      for (dy, dx) in CIRCLE_OFFSETS]

            # Build bright/dark flags — duplicate for wraparound
            bright = [1 if p > upper else 0 for p in circle] * 2
            dark   = [1 if p < lower else 0 for p in circle] * 2

            # Contiguous run detection — FAST-9
            br = dr = 0
            found   = False
            for i in range(32):
                br = br + 1 if bright[i] else 0
                dr = dr + 1 if dark[i]   else 0
                if br >= 9 or dr >= 9:
                    found = True
                    break

            if found:
                corners.append((x, y))

    return corners

# ─────────────────────────────────────
# GLOBAL ADAPTIVE THRESHOLD (CPU)
# Mirrors mean_calculator.v +
# threshold_generator.v exactly
# ─────────────────────────────────────
def compute_adaptive_threshold(img):
    mean_brightness = int(img.mean())
    FACTOR          = 64
    MIN_THR         = 15
    MAX_THR         = 80
    raw_thr         = (mean_brightness * FACTOR) >> 8
    thr             = max(MIN_THR, min(MAX_THR, raw_thr))
    return mean_brightness, thr

# ─────────────────────────────────────
# NMS
# ─────────────────────────────────────
def apply_nms(corners, radius):
    if not corners:
        return []
    suppressed = set()
    result     = []
    for i in range(len(corners)):
        if i in suppressed:
            continue
        cx, cy  = corners[i]
        cluster = [(cx, cy)]
        for j in range(i + 1, len(corners)):
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
# COMPUTE ADAPTIVE THRESHOLD
# ─────────────────────────────────────
mean_val, adaptive_thr = compute_adaptive_threshold(image)
print(f"\n  Mean brightness      : {mean_val}")
print(f"  Fixed threshold      : {THRESHOLD}")
print(f"  Adaptive threshold   : {adaptive_thr}")

# ─────────────────────────────────────
# RUN 1: FIXED THRESHOLD TIMING
# ─────────────────────────────────────
print(f"\n  Running {NUM_RUNS} iterations (fixed T={THRESHOLD})...")
t0 = time.perf_counter()
for _ in range(NUM_RUNS):
    raw_fixed = fast_detect_cpu(image, THRESHOLD, BORDER)
t1 = time.perf_counter()

cpu_fixed_us  = ((t1 - t0) / NUM_RUNS) * 1_000_000
nms_fixed     = apply_nms(raw_fixed, NMS_RADIUS)
speedup_fixed = cpu_fixed_us / FPGA_TIME_US

# ─────────────────────────────────────
# RUN 2: ADAPTIVE THRESHOLD TIMING
# ─────────────────────────────────────
print(f"  Running {NUM_RUNS} iterations (adaptive T={adaptive_thr})...")
t2 = time.perf_counter()
for _ in range(NUM_RUNS):
    raw_adaptive = fast_detect_cpu(image, adaptive_thr, BORDER)
t3 = time.perf_counter()

cpu_adaptive_us  = ((t3 - t2) / NUM_RUNS) * 1_000_000
nms_adaptive     = apply_nms(raw_adaptive, NMS_RADIUS)
speedup_adaptive = cpu_adaptive_us / FPGA_TIME_US

# ─────────────────────────────────────
# PRINT RESULTS TABLE
# ─────────────────────────────────────
print()
print("=" * 52)
print("  RESULTS — 256×256 IMAGE")
print("=" * 52)
print(f"  {'Metric':<30} {'Fixed':>9}  {'Adaptive':>9}")
print("-" * 52)
print(f"  {'Raw corners detected':<30} {len(raw_fixed):>9}  {len(raw_adaptive):>9}")
print(f"  {'After NMS':<30} {len(nms_fixed):>9}  {len(nms_adaptive):>9}")
print("-" * 52)
print(f"  {'CPU processing time (us)':<30} {cpu_fixed_us:>9.1f}  {cpu_adaptive_us:>9.1f}")
print(f"  {'CPU processing time (ms)':<30} {cpu_fixed_us/1000:>9.3f}  {cpu_adaptive_us/1000:>9.3f}")
print("-" * 52)
print(f"  {'FPGA processing time (us)':<30} {FPGA_TIME_US:>9.2f}  {FPGA_TIME_US:>9.2f}")
print(f"  {'FPGA total clocks':<30} {FPGA_TOTAL_CLOCKS:>9}  {FPGA_TOTAL_CLOCKS:>9}")
print("-" * 52)
print(f"  {'Speedup over CPU':<30} {speedup_fixed:>8.1f}x  {speedup_adaptive:>8.1f}x")
print("=" * 52)

# ─────────────────────────────────────
# PRINT ALL THREE RESOLUTIONS SUMMARY
# ─────────────────────────────────────
print()
print("=" * 60)
print("  FPGA SPEEDUP ACROSS ALL RESOLUTIONS")
print("=" * 60)
resolutions = [
    ("64×64",   64*64,   200,  cpu_fixed_us * (64*64*64*64) / (256*256*256*256)),
    ("128×128", 128*128, 392,  cpu_fixed_us * (128*128*128*128) / (256*256*256*256)),
    ("256×256", 256*256, 776,  cpu_fixed_us),
]
print(f"  {'Resolution':<12} {'FPGA Time':>12} {'CPU Time':>14} {'Speedup':>10}")
print("-" * 60)
for label, px, pipe, cpu_us in resolutions:
    fpga_us = (px + pipe) / FPGA_CLOCK_MHZ
    cpu_ms  = cpu_us / 1000
    spd     = cpu_us / fpga_us
    print(f"  {label:<12} {fpga_us:>9.2f} us   {cpu_ms:>9.3f} ms   {spd:>8.1f}x")
print("=" * 60)

# ─────────────────────────────────────
# VISUALIZATION
# ─────────────────────────────────────
scale   = DISPLAY_SIZE // 256   # = 2
display = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
display = cv2.resize(display, (DISPLAY_SIZE, DISPLAY_SIZE),
                     interpolation=cv2.INTER_NEAREST)

# Draw fixed threshold corners (blue)
for (x, y) in nms_fixed:
    px = x * scale + scale // 2
    py = y * scale + scale // 2
    cv2.circle(display, (px, py), 5, (255, 100, 0), -1)
    cv2.circle(display, (px, py), 5, (255, 255, 255), 1)

# Draw adaptive threshold corners (red) on top
for (x, y) in nms_adaptive:
    px = x * scale + scale // 2
    py = y * scale + scale // 2
    cv2.circle(display, (px, py), 3, (0, 0, 255), -1)

# Info bar
cv2.rectangle(display, (0, DISPLAY_SIZE - 70),
              (DISPLAY_SIZE, DISPLAY_SIZE), (20, 20, 20), -1)
cv2.putText(display,
            f"Fixed T={THRESHOLD}: {len(nms_fixed)} corners (blue)   "
            f"Adaptive T={adaptive_thr}: {len(nms_adaptive)} corners (red)",
            (6, DISPLAY_SIZE - 48),
            cv2.FONT_HERSHEY_SIMPLEX, 0.38, (200, 200, 200), 1)
cv2.putText(display,
            f"CPU: {cpu_fixed_us:.0f} us   "
            f"FPGA: {FPGA_TIME_US:.2f} us   "
            f"Speedup: {speedup_fixed:.0f}x",
            (6, DISPLAY_SIZE - 24),
            cv2.FONT_HERSHEY_SIMPLEX, 0.42, (0, 255, 0), 1)
cv2.putText(display,
            f"Image: 256x256   Threshold: Fixed={THRESHOLD} / Adaptive={adaptive_thr}   NMS radius={NMS_RADIUS}",
            (6, DISPLAY_SIZE - 6),
            cv2.FONT_HERSHEY_SIMPLEX, 0.34, (150, 150, 150), 1)

cv2.imshow("CPU FAST 256x256 — Blue=Fixed  Red=Adaptive", display)
cv2.waitKey(0)
cv2.destroyAllWindows()