import serial
import cv2
import numpy as np
import scipy.io
import os
import time

# ------------------------------------
# CONFIGURATION
# ------------------------------------
COM_PORT      = 'COM6'
BAUD_RATE     = 115200

BASE_DIR      = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC"
IMAGE_PATH    = os.path.join(BASE_DIR, "Dataset_256", "Images", "7.png")
GT_FILE       = os.path.join(BASE_DIR, "Dataset_256", "Ground Truth", "7.txt")

DISPLAY_SIZE  = 640      # CHANGED: was 1024, back to standard 640
CORNER_RADIUS = 2        # CHANGED: was 3, slightly smaller to suit 640 display
IMAGE_SIZE    = 256
NMS_RADIUS    = 8
MATCH_THRESH  = 5

# ------------------------------------
# UART CONNECTION
# ------------------------------------
ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=0.05)
ser.reset_input_buffer()

# ------------------------------------
# LOAD IMAGE
# ------------------------------------
image = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
if image is None:
    print(f"Image not found! Checked: {IMAGE_PATH}")
    ser.close()
    exit()

image     = cv2.resize(image, (IMAGE_SIZE, IMAGE_SIZE), interpolation=cv2.INTER_NEAREST)
image_bgr = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
SCALE     = DISPLAY_SIZE // IMAGE_SIZE    # CHANGED: 640//256 = 2

# ------------------------------------
# NMS + EVALUATE (combined)
# ------------------------------------
def apply_nms_and_evaluate(raw_corners, gt_file, nms_radius, match_thresh, img_size):

    corners_list = list(raw_corners)
    suppressed   = set()
    clean        = []

    for i in range(len(corners_list)):
        if i in suppressed:
            continue
        cx, cy  = corners_list[i]
        cluster = [(cx, cy)]
        for j in range(i + 1, len(corners_list)):
            if j in suppressed:
                continue
            dx = corners_list[j][0] - cx
            dy = corners_list[j][1] - cy
            if (dx*dx + dy*dy)**0.5 <= nms_radius:
                cluster.append(corners_list[j])
                suppressed.add(j)
        clean.append((
            int(round(sum(p[0] for p in cluster) / len(cluster))),
            int(round(sum(p[1] for p in cluster) / len(cluster)))
        ))

    clean = set(clean)

    corner_img = np.zeros((img_size, img_size), dtype=np.uint8)
    for (cx, cy) in clean:
        if 0 <= cy < img_size and 0 <= cx < img_size:
            corner_img[cy, cx] = 255

    ext = os.path.splitext(gt_file)[1].lower()
    if ext == '.mat':
        mat = scipy.io.loadmat(gt_file)
        key = [k for k in mat if not k.startswith('_')][0]
        gt  = mat[key]
    elif ext == '.npy':
        gt = np.load(gt_file)
    elif ext in ('.txt', '.csv'):
        gt = np.loadtxt(gt_file)
    else:
        raise ValueError(f"Unsupported GT format: {ext}")

    det_y, det_x = np.where(corner_img == 255)
    detected     = np.stack([det_x, det_y], axis=1) if len(det_x) > 0 else np.empty((0, 2))

    gt_x = gt[:, 1]
    gt_y = gt[:, 0]

    TP           = 0
    FP           = 0
    matched_gt   = np.zeros(len(gt), dtype=bool)
    distance_sum = 0.0

    for dx, dy in detected:
        distances  = np.sqrt((dx - gt_x)**2 + (dy - gt_y)**2)
        candidates = np.where((distances <= match_thresh) & (~matched_gt))[0]
        if len(candidates) > 0:
            best = candidates[np.argmin(distances[candidates])]
            TP  += 1
            matched_gt[best] = True
            distance_sum    += distances[best]
        else:
            FP += 1

    FN        = int(np.sum(~matched_gt))
    Precision = TP / (TP + FP)  if (TP + FP) > 0 else 0.0
    Recall    = TP / (TP + FN)  if (TP + FN) > 0 else 0.0
    Fscore    = (2 * Precision * Recall / (Precision + Recall)
                 if (Precision + Recall) > 0 else 0.0)
    Le        = distance_sum / TP if TP > 0 else 0.0

    print()
    print("===== NMS + FAST Evaluation =====")
    print(f"Raw Corners        = {len(raw_corners)}")
    print(f"After NMS          = {len(clean)}")
    print(f"True Positives     = {TP}")
    print(f"False Positives    = {FP}")
    print(f"False Negatives    = {FN}")
    print(f"Precision          = {Precision:.4f}")
    print(f"Recall             = {Recall:.4f}")
    print(f"F-score            = {Fscore:.4f}")
    print(f"Localization Error = {Le:.4f} pixels")

    return clean, Precision, Recall, Fscore, Le

# ------------------------------------
# PACKET READER
# ------------------------------------
def read_corner(ser):
    byte = ser.read(1)
    if len(byte) == 0:
        return None, None
    if byte[0] == 0xFF:
        xy = ser.read(2)
        if len(xy) == 2:
            return xy[0], xy[1]
    return None, None

# ------------------------------------
# DRAW CORNERS
# ------------------------------------
def draw_corners(base_img, corners, scale):
    display = cv2.resize(
        base_img,
        (scale * IMAGE_SIZE, scale * IMAGE_SIZE),
        interpolation=cv2.INTER_NEAREST
    )
    for (cx, cy) in corners:
        px = cx * scale + scale // 2
        py = cy * scale + scale // 2

        cv2.circle(display, (px, py), CORNER_RADIUS, (0, 0, 255), -1)
        cv2.circle(display, (px, py), CORNER_RADIUS, (255, 255, 255), 1)
        cv2.line(display, (px - CORNER_RADIUS*2, py), (px + CORNER_RADIUS*2, py), (0, 255, 255), 1)
        cv2.line(display, (px, py - CORNER_RADIUS*2), (px, py + CORNER_RADIUS*2), (0, 255, 255), 1)

        label   = f"({cx},{cy})"
        label_x = px + CORNER_RADIUS + 3
        label_y = py - CORNER_RADIUS
        if label_x + 60 > DISPLAY_SIZE:
            label_x = px - 65
        if label_y < 15:
            label_y = py + CORNER_RADIUS + 15

        (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.4, 1)
        cv2.rectangle(display, (label_x-2, label_y-th-2), (label_x+tw+2, label_y+2), (0,0,0), -1)
        cv2.putText(display, label, (label_x, label_y),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255, 255, 255), 1)
    return display

# ------------------------------------
# INFO PANEL
# ------------------------------------
def draw_info(display, raw_count, nms_count, done=False):
    h, w = display.shape[:2]
    cv2.rectangle(display, (0, h-40), (w, h), (30, 30, 30), -1)
    cv2.putText(display,
                f"Raw: {raw_count}   After NMS: {nms_count}",
                (10, h-15), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 1)
    status = "DONE — Press Q to quit" if done else "RECEIVING..."
    color  = (0, 255, 0) if done else (0, 165, 255)
    cv2.putText(display, status, (w-220, h-15),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 1)
    return display

# ------------------------------------
# SETUP
# ------------------------------------
cv2.namedWindow("FPGA FAST Corner Detection", cv2.WINDOW_NORMAL)

raw_corners   = set()
clean         = set()
prev_raw_len  = -1
evaluated     = False
first_corner  = None
loop_complete = False

initial = draw_corners(image_bgr, set(), SCALE)
initial = draw_info(initial, 0, 0)
cv2.imshow("FPGA FAST Corner Detection", initial)
cv2.waitKey(1)

print("Waiting for corners from FPGA...")
print(f"Image  : {IMAGE_PATH}")
print(f"GT file: {GT_FILE}")
print(f"Image size : {IMAGE_SIZE}×{IMAGE_SIZE}  |  Scale: {SCALE}x")
print("Auto-evaluates when FPGA completes one full loop. Press Q to evaluate manually.")

# ------------------------------------
# MAIN LOOP
# ------------------------------------
try:
    while True:
        rx_x, rx_y = read_corner(ser)
        new_data   = False

        if rx_x is not None and rx_y is not None:
            if 4 <= rx_x <= 251 and 4 <= rx_y <= 251:

                if first_corner is None:
                    first_corner = (rx_x, rx_y)
                    raw_corners.add((rx_x, rx_y))
                    new_data = True
                    print(f"First corner: ({rx_x}, {rx_y}) — watching for loop completion...")

                elif (rx_x, rx_y) == first_corner and len(raw_corners) > 1:
                    loop_complete = True

                else:
                    raw_corners.add((rx_x, rx_y))
                    new_data = True

        if loop_complete and not evaluated:
            print("\nFirst corner received again — one full loop completed!")
            if os.path.exists(GT_FILE):
                clean, P, R, F, Le = apply_nms_and_evaluate(
                    raw_corners, GT_FILE, NMS_RADIUS, MATCH_THRESH, IMAGE_SIZE
                )
            else:
                print(f"GT file not found: {GT_FILE} — skipping evaluation.")
            evaluated = True
            display = draw_corners(image_bgr, clean, SCALE)
            display = draw_info(display, len(raw_corners), len(clean), done=True)
            cv2.imshow("FPGA FAST Corner Detection", display)

        if new_data or prev_raw_len != len(raw_corners):
            corners_list = list(raw_corners)
            suppressed   = set()
            preview      = []
            for i in range(len(corners_list)):
                if i in suppressed:
                    continue
                cx, cy  = corners_list[i]
                cluster = [(cx, cy)]
                for j in range(i + 1, len(corners_list)):
                    if j in suppressed:
                        continue
                    dx = corners_list[j][0] - cx
                    dy = corners_list[j][1] - cy
                    if (dx*dx + dy*dy)**0.5 <= NMS_RADIUS:
                        cluster.append(corners_list[j])
                        suppressed.add(j)
                preview.append((
                    int(round(sum(p[0] for p in cluster) / len(cluster))),
                    int(round(sum(p[1] for p in cluster) / len(cluster)))
                ))

            display      = draw_corners(image_bgr, set(preview), SCALE)
            display      = draw_info(display, len(raw_corners), len(preview))
            cv2.imshow("FPGA FAST Corner Detection", display)
            prev_raw_len = len(raw_corners)

        key = cv2.waitKey(1) & 0xFF

        if key == ord('q'):
            if not evaluated:
                if os.path.exists(GT_FILE):
                    clean, P, R, F, Le = apply_nms_and_evaluate(
                        raw_corners, GT_FILE, NMS_RADIUS, MATCH_THRESH, IMAGE_SIZE
                    )
                else:
                    print(f"GT file not found: {GT_FILE} — skipping evaluation.")
            break

except serial.SerialException as e:
    print(f"Serial error: {e}")
except KeyboardInterrupt:
    print("Stopped by user.")
finally:
    ser.close()
    cv2.destroyAllWindows()
    print("Closed.")