import serial
import cv2
import numpy as np

# ------------------------------------
# CONFIGURATION
# ------------------------------------
COM_PORT     = 'COM6'
BAUD_RATE    = 115200
IMAGE_PATH   = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\rhombus64.png"
DISPLAY_SIZE = 640
CORNER_RADIUS = 8
NMS_RADIUS   = 5    # suppress corners within 5 pixels of each other

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

image     = cv2.resize(image, (64, 64), interpolation=cv2.INTER_NEAREST)
image_bgr = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
SCALE     = DISPLAY_SIZE // 64

# ------------------------------------
# NON-MAXIMUM SUPPRESSION
# Groups nearby corners and keeps
# the centroid of each cluster
# ------------------------------------
def apply_nms(corners, radius):
    if len(corners) == 0:
        return corners

    corners_list = list(corners)
    suppressed   = set()
    result       = []

    for i in range(len(corners_list)):
        if i in suppressed:
            continue

        cx, cy  = corners_list[i]
        cluster = [(cx, cy)]

        # Find all corners within radius
        for j in range(i+1, len(corners_list)):
            if j in suppressed:
                continue
            dx = corners_list[j][0] - cx
            dy = corners_list[j][1] - cy
            dist = (dx*dx + dy*dy) ** 0.5
            if dist <= radius:
                cluster.append(corners_list[j])
                suppressed.add(j)

        # Keep centroid of cluster
        mean_x = int(round(sum(p[0] for p in cluster) / len(cluster)))
        mean_y = int(round(sum(p[1] for p in cluster) / len(cluster)))
        result.append((mean_x, mean_y))

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
        (scale * 64, scale * 64),
        interpolation=cv2.INTER_NEAREST
    )

    for (cx, cy) in corners:
        px = cx * scale + scale // 2
        py = cy * scale + scale // 2

        # Red filled circle
        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (0, 0, 255), -1)
        # White border
        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (255, 255, 255), 2)
        # Crosshair
        cv2.line(display,
                 (px - CORNER_RADIUS*2, py),
                 (px + CORNER_RADIUS*2, py),
                 (0, 255, 255), 1)
        cv2.line(display,
                 (px, py - CORNER_RADIUS*2),
                 (px, py + CORNER_RADIUS*2),
                 (0, 255, 255), 1)

        # Coordinate label
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
                      (0,0,0), -1)
        cv2.putText(display, label,
                    (label_x, label_y),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.45, (255,255,255), 1)
    return display

# ------------------------------------
# INFO PANEL
# ------------------------------------
def draw_info(display, raw_count, nms_count):
    h, w = display.shape[:2]
    cv2.rectangle(display, (0, h-40), (w, h),
                  (30, 30, 30), -1)
    cv2.putText(display,
                f"Raw: {raw_count}  After NMS: {nms_count}",
                (10, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, (0, 255, 0), 1)
    status = "RECEIVING..." if nms_count == 0 else "COMPLETE"
    color  = (0,165,255) if nms_count == 0 else (0,255,0)
    cv2.putText(display, status,
                (w-160, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, color, 1)
    return display

# ------------------------------------
# MAIN LOOP
# ------------------------------------
raw_corners = set()

try:
    while True:
        rx_x, rx_y = read_corner(ser)

        if rx_x is not None and rx_y is not None:
            if rx_x < 64 and rx_y < 64:
                raw_corners.add((rx_x, rx_y))

        # Apply NMS to get clean corners
        clean_corners = apply_nms(raw_corners, NMS_RADIUS)

        print(f"\rRaw: {len(raw_corners):3d}  "
              f"After NMS: {len(clean_corners):3d}  "
              f"Corners: {sorted(clean_corners)}",
              end='')

        # Draw with NMS-filtered corners
        display = draw_corners(image_bgr, clean_corners, SCALE)
        display = draw_info(display, len(raw_corners),
                            len(clean_corners))

        cv2.imshow("FPGA FAST Corner Detection", display)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except serial.SerialException as e:
    print(f"\nSerial error: {e}")
except KeyboardInterrupt:
    print("\nStopped by user")
finally:
    ser.close()
    cv2.destroyAllWindows()
    print("\nClosed.")