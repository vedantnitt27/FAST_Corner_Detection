import serial
import cv2
import numpy as np

# ------------------------------------
# CONFIGURATION
# ------------------------------------
COM_PORT      = 'COM6'
BAUD_RATE     = 115200
IMAGE_PATH    = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\128\square128.png"
DISPLAY_SIZE  = 640
CORNER_RADIUS = 8
IMAGE_SIZE    = 128          # CHANGED: 64 → 128
NMS_RADIUS    = 5

# ------------------------------------
# UART CONNECTION
# ------------------------------------
ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1.0)
ser.reset_input_buffer()

# ------------------------------------
# LOAD IMAGE
# ------------------------------------
image = cv2.imread(IMAGE_PATH, cv2.IMREAD_GRAYSCALE)
if image is None:
    print("Image not found!")
    ser.close()
    exit()

image     = cv2.resize(image, (IMAGE_SIZE, IMAGE_SIZE),
                       interpolation=cv2.INTER_NEAREST)
image_bgr = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)

SCALE = DISPLAY_SIZE // IMAGE_SIZE    # CHANGED: 640//128 = 5

# ------------------------------------
# NMS
# ------------------------------------
def apply_nms(corners, radius):
    if not corners:
        return set()
    corners_list = list(corners)
    suppressed   = set()
    result       = []
    for i in range(len(corners_list)):
        if i in suppressed:
            continue
        cx, cy  = corners_list[i]
        cluster = [(cx, cy)]
        for j in range(i+1, len(corners_list)):
            if j in suppressed:
                continue
            dx = corners_list[j][0] - cx
            dy = corners_list[j][1] - cy
            if (dx*dx + dy*dy)**0.5 <= radius:
                cluster.append(corners_list[j])
                suppressed.add(j)
        result.append((
            int(round(sum(p[0] for p in cluster) / len(cluster))),
            int(round(sum(p[1] for p in cluster) / len(cluster)))
        ))
    return set(result)

# ------------------------------------
# PACKET READER
# ------------------------------------
def read_corner(ser):
    while True:
        byte = ser.read(1)
        if len(byte) == 0:
            print("Waiting for data...")
            return None, None
        if byte[0] == 0xFF:
            xy = ser.read(2)
            if len(xy) == 2:
                return xy[0], xy[1]
            return None, None

# ------------------------------------
# DRAW FUNCTION
# ------------------------------------
def draw_corners(base_img, corners, scale):
    display = cv2.resize(
        base_img,
        (scale * IMAGE_SIZE, scale * IMAGE_SIZE),  # CHANGED
        interpolation=cv2.INTER_NEAREST
    )

    for (cx, cy) in corners:
        px = cx * scale + scale // 2
        py = cy * scale + scale // 2

        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (0, 0, 255), -1)
        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (255, 255, 255), 2)
        cv2.line(display,
                 (px - CORNER_RADIUS*2, py),
                 (px + CORNER_RADIUS*2, py),
                 (0, 255, 255), 1)
        cv2.line(display,
                 (px, py - CORNER_RADIUS*2),
                 (px, py + CORNER_RADIUS*2),
                 (0, 255, 255), 1)

        label   = f"({cx},{cy})"
        label_x = px + CORNER_RADIUS + 3
        label_y = py - CORNER_RADIUS
        if label_x + 60 > DISPLAY_SIZE:
            label_x = px - 65
        if label_y < 15:
            label_y = py + CORNER_RADIUS + 15

        (tw, th), _ = cv2.getTextSize(
            label, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)
        cv2.rectangle(display,
                      (label_x-2, label_y-th-2),
                      (label_x+tw+2, label_y+2),
                      (0, 0, 0), -1)
        cv2.putText(display, label,
                    (label_x, label_y),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.45, (255, 255, 255), 1)

    return display

# ------------------------------------
# INFO PANEL
# ------------------------------------
def draw_info(display, raw_count, nms_count):
    h, w = display.shape[:2]
    cv2.rectangle(display, (0, h-40), (w, h),
                  (30, 30, 30), -1)
    cv2.putText(display,
                f"Raw: {raw_count}   After NMS: {nms_count}",
                (10, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, (0, 255, 0), 1)
    status = "RECEIVING..." if nms_count == 0 else "COMPLETE"
    color  = (0, 165, 255)  if nms_count == 0 else (0, 255, 0)
    cv2.putText(display, status,
                (w-160, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, color, 1)
    return display

# ------------------------------------
# STORE
# ------------------------------------
raw_corners = set()

initial = draw_corners(image_bgr, set(), SCALE)
initial = draw_info(initial, 0, 0)
cv2.imshow("FPGA FAST Corner Detection", initial)
cv2.waitKey(1)

print("Waiting for corners from FPGA...")
print(f"Image size : {IMAGE_SIZE}×{IMAGE_SIZE}")
print(f"Scale      : {SCALE}x")

# ------------------------------------
# MAIN LOOP
# ------------------------------------
try:
    while True:
        rx_x, rx_y = read_corner(ser)

        if rx_x is not None and rx_y is not None:
            # CHANGED: filter < 128, border 4-123
            if 4 <= rx_x <= 123 and 4 <= rx_y <= 123:
                raw_corners.add((rx_x, rx_y))
                print(f"Corner: ({rx_x:3d}, {rx_y:3d})  "
                      f"Raw total: {len(raw_corners)}")

        # Apply NMS
        clean = apply_nms(raw_corners, NMS_RADIUS)

        # Draw with clean corners
        display = draw_corners(image_bgr, clean, SCALE)
        display = draw_info(display, len(raw_corners), len(clean))

        cv2.imshow("FPGA FAST Corner Detection", display)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except serial.SerialException as e:
    print(f"Serial error: {e}")
except KeyboardInterrupt:
    print("Stopped by user")
finally:
    ser.close()
    cv2.destroyAllWindows()
    print("Closed.")