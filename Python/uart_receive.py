import serial
import cv2
import numpy as np

# ------------------------------------
# CONFIGURATION
# ------------------------------------
COM_PORT    = 'COM6'
BAUD_RATE   = 115200
IMAGE_PATH  = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\rhombus64.png"
DISPLAY_SIZE = 640    # enlarge to 640×640
CORNER_RADIUS = 8     # red circle radius on enlarged image

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

# Ensure exactly 64x64
image = cv2.resize(image, (64, 64), interpolation=cv2.INTER_NEAREST)
image_bgr = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)

# Scale factor for mapping 64×64 coords to display
SCALE = DISPLAY_SIZE // 64   # = 10

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
# Draws corners on enlarged image
# with crosshair markers and labels
# ------------------------------------
def draw_corners(base_img, corners, scale):
    # Enlarge base image using nearest neighbor
    display = cv2.resize(
        base_img,
        (scale * 64, scale * 64),
        interpolation=cv2.INTER_NEAREST
    )

    for (cx, cy) in corners:
        # Map 64×64 coords to display coords
        # Center of the scaled pixel
        px = cx * scale + scale // 2
        py = cy * scale + scale // 2

        # Draw filled red circle
        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (0, 0, 255), -1)

        # Draw white border around circle for visibility
        cv2.circle(display, (px, py), CORNER_RADIUS,
                   (255, 255, 255), 2)

        # Draw crosshair lines
        cv2.line(display,
                 (px - CORNER_RADIUS*2, py),
                 (px + CORNER_RADIUS*2, py),
                 (0, 255, 255), 1)
        cv2.line(display,
                 (px, py - CORNER_RADIUS*2),
                 (px, py + CORNER_RADIUS*2),
                 (0, 255, 255), 1)

        # Draw coordinate label
        label = f"({cx},{cy})"
        label_x = px + CORNER_RADIUS + 3
        label_y = py - CORNER_RADIUS

        # Keep label inside frame
        if label_x + 60 > DISPLAY_SIZE:
            label_x = px - 65
        if label_y < 15:
            label_y = py + CORNER_RADIUS + 15

        # Black background for label readability
        (tw, th), _ = cv2.getTextSize(
            label, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)
        cv2.rectangle(display,
                      (label_x - 2, label_y - th - 2),
                      (label_x + tw + 2, label_y + 2),
                      (0, 0, 0), -1)

        # White label text
        cv2.putText(display, label,
                    (label_x, label_y),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.45, (255, 255, 255), 1)

    return display

# ------------------------------------
# DRAW INFO PANEL
# Shows corner count and status
# ------------------------------------
def draw_info(display, corners):
    h, w = display.shape[:2]

    # Dark bar at bottom
    cv2.rectangle(display, (0, h-40), (w, h),
                  (30, 30, 30), -1)

    # Corner count
    cv2.putText(display,
                f"Corners detected: {len(corners)}",
                (10, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, (0, 255, 0), 1)

    # Status
    status = "RECEIVING..." if len(corners) == 0 else "COMPLETE"
    color  = (0, 165, 255)  if len(corners) == 0 else (0, 255, 0)
    cv2.putText(display, status,
                (w-160, h-15),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6, color, 1)

    return display

# ------------------------------------
# STORE DETECTED CORNERS
# ------------------------------------
corners = set()

# Show initial empty image while waiting
initial = draw_corners(image_bgr, corners, SCALE)
initial = draw_info(initial, corners)
cv2.imshow("FPGA FAST Corner Detection", initial)
cv2.waitKey(1)

print("Waiting for corners from FPGA...")

# ------------------------------------
# MAIN LOOP
# ------------------------------------
try:
    while True:
        rx_x, rx_y = read_corner(ser)

        if rx_x is not None and rx_y is not None:
            if rx_x < 64 and rx_y < 64:
                if (rx_x, rx_y) not in corners:
                    corners.add((rx_x, rx_y))
                    print(f"Corner: ({rx_x:2d}, {rx_y:2d})  "
                          f"Total: {len(corners)}")

        # Draw updated display
        display = draw_corners(image_bgr, corners, SCALE)
        display = draw_info(display, corners)

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