from PIL import Image

# ------------------------------------
# CONFIGURATION
# ------------------------------------

IMAGE_SIZE = 256

input_image = rf"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\256\six_colored_shapes256.png"

output_image = rf"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\256\resized_six_colored_shapes256.png"

output_hex = rf"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\256\six_colored_shapes256.hex"

# ------------------------------------
# OPEN IMAGE
# ------------------------------------

img = Image.open(input_image)

# ------------------------------------
# CONVERT TO GRAYSCALE
# ------------------------------------

img = img.convert("L")

# ------------------------------------
# RESIZE
# ------------------------------------

img = img.resize((IMAGE_SIZE, IMAGE_SIZE))

print("Image Size:", img.size)

# ------------------------------------
# SAVE IMAGE
# ------------------------------------

img.save(output_image)

# ------------------------------------
# EXTRACT PIXELS
# ------------------------------------

pixels = list(img.getdata())

# ------------------------------------
# GENERATE HEX FILE
# ------------------------------------

with open(output_hex, "w") as f:

    for pixel in pixels:

        f.write(f"{pixel:02X}\n")

print("HEX generated successfully")
print("Total pixels:", len(pixels))