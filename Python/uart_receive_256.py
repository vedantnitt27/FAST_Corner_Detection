import serial
import cv2
import numpy as np

# ------------------------------------
# CONFIGURATION
# ------------------------------------
COM_PORT      = 'COM6'
BAUD_RATE     = 115200

IMAGE_PATH = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\256\six_colored_shapes256.png"

DISPLAY_SIZE  = 1024
CORNER_RADIUS = 6

IMAGE_SIZE    = 256

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

image = cv2.resize(
    image,
    (IMAGE_SIZE, IMAGE_SIZE),
    interpolation=cv2.INTER_NEAREST
)

image_bgr = cv2.cvtColor(
    image,
    cv2.COLOR_GRAY2BGR
)

SCALE = DISPLAY_SIZE // IMAGE_SIZE

# ------------------------------------
# UART PACKET READER
# Packet:
# 0xFF X Y
# ------------------------------------
def read_corner(ser):

    while True:

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
        (scale * IMAGE_SIZE,
         scale * IMAGE_SIZE),
        interpolation=cv2.INTER_NEAREST
    )

    for (cx, cy) in corners:

        px = cx * scale + scale // 2
        py = cy * scale + scale // 2

        cv2.circle(
            display,
            (px, py),
            CORNER_RADIUS,
            (0, 0, 255),
            -1
        )

        cv2.circle(
            display,
            (px, py),
            CORNER_RADIUS,
            (255, 255, 255),
            1
        )

        cv2.line(
            display,
            (px - CORNER_RADIUS*2, py),
            (px + CORNER_RADIUS*2, py),
            (0, 255, 255),
            1
        )

        cv2.line(
            display,
            (px, py - CORNER_RADIUS*2),
            (px, py + CORNER_RADIUS*2),
            (0, 255, 255),
            1
        )

    return display

# ------------------------------------
# INFO PANEL
# ------------------------------------
def draw_info(display, corner_count):

    h, w = display.shape[:2]

    cv2.rectangle(
        display,
        (0, h-40),
        (w, h),
        (30, 30, 30),
        -1
    )

    cv2.putText(
        display,
        f"Raw FAST Corners : {corner_count}",
        (10, h-15),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.6,
        (0,255,0),
        1
    )

    return display

# ------------------------------------
# STORE RAW CORNERS
# ------------------------------------
raw_corners = set()

initial = draw_corners(
    image_bgr,
    set(),
    SCALE
)

initial = draw_info(
    initial,
    0
)

cv2.imshow(
    "FPGA FAST Raw Corner Detection",
    initial
)

cv2.waitKey(1)

print("Waiting for corners from FPGA...")
print(f"Image size : {IMAGE_SIZE} x {IMAGE_SIZE}")
print(f"Scale      : {SCALE}x")

# ------------------------------------
# MAIN LOOP
# ------------------------------------
try:

    while True:

        rx_x, rx_y = read_corner(ser)

        if rx_x is not None and rx_y is not None:

            if 4 <= rx_x <= 251 and \
               4 <= rx_y <= 251:

                raw_corners.add(
                    (rx_x, rx_y)
                )

                print(
                    f"Corner: ({rx_x:3d}, {rx_y:3d})   "
                    f"Total: {len(raw_corners)}"
                )

        display = draw_corners(
            image_bgr,
            raw_corners,
            SCALE
        )

        display = draw_info(
            display,
            len(raw_corners)
        )

        cv2.imshow(
            "FPGA FAST Raw Corner Detection",
            display
        )

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