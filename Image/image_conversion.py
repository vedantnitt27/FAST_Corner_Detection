import cv2
import numpy as np

# ------------------------------------
# CONFIGURATION
# ------------------------------------
INPUT_PATH  = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\Test_images\test_image5.png"
OUTPUT_PNG  = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\Test_images\test_image5_256.png"
OUTPUT_HEX  = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\Test_images\test_image5_256.hex"

# ------------------------------------
# STEP 1: LOAD IMAGE
# ------------------------------------
image_color = cv2.imread(INPUT_PATH)

if image_color is None:
    print("Image not found! Check path.")
    exit()

print(f"Original size  : {image_color.shape}")

# ------------------------------------
# STEP 2: CONVERT TO GRAYSCALE
# ------------------------------------
image_gray = cv2.cvtColor(image_color, cv2.COLOR_BGR2GRAY)
print(f"Grayscale size : {image_gray.shape}")

# ------------------------------------
# STEP 3: RESIZE TO 256×256
# ------------------------------------
image_256 = cv2.resize(image_gray, (256, 256),
                        interpolation=cv2.INTER_AREA)

print(f"Resized size   : {image_256.shape}")
print(f"Total pixels   : {image_256.size}")   # must be 65536
print(f"Pixel range    : {image_256.min()} to {image_256.max()}")

# ------------------------------------
# STEP 4: SAVE GRAYSCALE PNG
# ------------------------------------
cv2.imwrite(OUTPUT_PNG, image_256)
print(f"PNG saved      : {OUTPUT_PNG}")

# ------------------------------------
# STEP 5: GENERATE HEX FILE
# ------------------------------------
with open(OUTPUT_HEX, 'w') as f:
    for pixel in image_256.flatten():
        f.write(f"{pixel:02X}\n")

print(f"HEX saved      : {OUTPUT_HEX}")
print(f"HEX lines      : {image_256.size}")   # must be 65536

# ------------------------------------
# STEP 6: PREVIEW
# ------------------------------------
preview = cv2.resize(image_256, (512, 512),
                     interpolation=cv2.INTER_NEAREST)
cv2.imshow("Grayscale 256x256 Preview", preview)
cv2.waitKey(0)
cv2.destroyAllWindows()

print("Done!")