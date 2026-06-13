import numpy as np
import cv2

# ------------------------------------
# CREATE 64x64 WHITE IMAGE
# ------------------------------------

img = np.ones((64,64), dtype=np.uint8) * 255

# ------------------------------------
# DRAW CHESSBOARD
# ------------------------------------

square_size = 8

for row in range(8):

    for col in range(8):

        # Alternate black and white squares

        if (row + col) % 2 == 0:

            cv2.rectangle(
                img,
                (col*square_size, row*square_size),
                ((col+1)*square_size - 1,
                 (row+1)*square_size - 1),
                0,      # Black
                -1      # Filled
            )

# ------------------------------------
# SAVE IMAGE
# ------------------------------------

cv2.imwrite(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\chessboard64.png",
    img
)

# ------------------------------------
# DISPLAY IMAGE
# ------------------------------------

enlarged = cv2.resize(
    img,
    (512,512),
    interpolation=cv2.INTER_NEAREST
)

cv2.imshow("64x64 Chessboard", enlarged)

cv2.waitKey(0)

cv2.destroyAllWindows()