import cv2
import numpy as np

# ─────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────
SIZE   = 64
RADIUS = 24        # circle radius in pixels
CENTER = (32, 32)  # center of 64×64 image

# ─────────────────────────────────────
# CREATE IMAGE
# White background, black circle
# ─────────────────────────────────────
image = np.ones((SIZE, SIZE), dtype=np.uint8) * 255

cv2.circle(image, CENTER, RADIUS, 0, -1)   # filled black circle

print(f"Image shape  : {image.shape}")
print(f"Unique values: {np.unique(image)}")

# ─────────────────────────────────────
# SAVE PNG
# ─────────────────────────────────────
png_path = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\circle64.png"
cv2.imwrite(png_path, image)
print(f"PNG saved: {png_path}")

# ─────────────────────────────────────
# SAVE HEX FILE FOR FPGA
# ─────────────────────────────────────
# hex_path = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Vivado\SummerIntern_project\SummerIntern_project.srcs\sources_1\new\circle64.hex"

# with open(hex_path, 'w') as f:
#     for pixel in image.flatten():
#         f.write(f"{pixel:02X}\n")

# print(f"HEX saved: {hex_path}")
print(f"Total pixels: {image.size}")   # must be 4096

# ─────────────────────────────────────
# PREVIEW
# ─────────────────────────────────────
preview = cv2.resize(image, (512, 512), interpolation=cv2.INTER_NEAREST)
cv2.imshow("circle64 - 64x64", preview)
cv2.waitKey(0)
cv2.destroyAllWindows()