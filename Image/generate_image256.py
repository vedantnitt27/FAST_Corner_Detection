import cv2
import numpy as np

# ------------------------------------
# CREATE WHITE IMAGE
# ------------------------------------

SIZE = 256

image = np.ones(
    (SIZE, SIZE, 3),
    dtype=np.uint8
) * 255

# ------------------------------------
# 1. LARGE RED SQUARE
# ------------------------------------

cv2.rectangle(
    image,
    (10, 10),
    (80, 80),
    (0, 0, 255),
    -1
)

# ------------------------------------
# 2. LARGE GREEN TRIANGLE
# ------------------------------------

triangle = np.array([
    [128, 10],
    [88, 90],
    [168, 90]
], np.int32)

cv2.fillPoly(
    image,
    [triangle],
    (0, 255, 0)
)

# ------------------------------------
# 3. LARGE BLUE RHOMBUS
# ------------------------------------

rhombus = np.array([
    [220, 10],
    [250, 50],
    [220, 90],
    [190, 50]
], np.int32)

cv2.fillPoly(
    image,
    [rhombus],
    (255, 0, 0)
)

# ------------------------------------
# 4. LARGE YELLOW PENTAGON
# ------------------------------------

pentagon = np.array([
    [45, 115],
    [85, 145],
    [70, 195],
    [20, 195],
    [5, 145]
], np.int32)

cv2.fillPoly(
    image,
    [pentagon],
    (0, 255, 255)
)

# ------------------------------------
# 5. LARGE MAGENTA HEXAGON
# ------------------------------------

hexagon = np.array([
    [110, 110],
    [160, 110],
    [185, 155],
    [160, 200],
    [110, 200],
    [85, 155]
], np.int32)

cv2.fillPoly(
    image,
    [hexagon],
    (255, 0, 255)
)

# ------------------------------------
# 6. LARGE CYAN STAR
# ------------------------------------

star = np.array([
    [220,105],
    [230,135],
    [255,135],
    [235,155],
    [245,190],
    [220,170],
    [195,190],
    [205,155],
    [185,135],
    [210,135]
], np.int32)

cv2.fillPoly(
    image,
    [star],
    (255,255,0)
)

# ------------------------------------
# SAVE IMAGE
# ------------------------------------

cv2.imwrite(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\256\six_colored_shapes256.png",
    image
)

# ------------------------------------
# DISPLAY IMAGE
# ------------------------------------

preview = cv2.resize(
    image,
    (512, 512),
    interpolation=cv2.INTER_NEAREST
)

cv2.imshow(
    "Large Colored Shapes 256x256",
    preview
)

cv2.waitKey(0)
cv2.destroyAllWindows()