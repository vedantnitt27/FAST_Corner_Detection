import cv2
import numpy as np

# ─────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────
SIZE = 128

# ─────────────────────────────────────
# CREATE IMAGE
# ─────────────────────────────────────
image = np.ones((SIZE, SIZE), dtype=np.uint8) * 255

# Filled black square
cv2.rectangle(
    image,
    (32, 32),      # Top-left
    (96, 96),      # Bottom-right
    0,
    -1
)

print(f"Image shape  : {image.shape}")
print(f"Unique values: {np.unique(image)}")

# ─────────────────────────────────────
# SAVE PNG
# ─────────────────────────────────────
png_path = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\128\square128.png"
cv2.imwrite(png_path, image)

print(f"PNG saved: {png_path}")
print(f"Total pixels: {image.size}")  # 16384

# ─────────────────────────────────────
# PREVIEW
# ─────────────────────────────────────
preview = cv2.resize(image, (512,512), interpolation=cv2.INTER_NEAREST)
cv2.imshow("square128", preview)
cv2.waitKey(0)
cv2.destroyAllWindows()