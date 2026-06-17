from PIL import Image

# ------------------------------------
# INPUT IMAGE
# ------------------------------------

input_image = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\128\square128.png"

# ------------------------------------
# OPEN IMAGE
# ------------------------------------

img = Image.open(input_image)

# ------------------------------------
# CONVERT TO GRAYSCALE
# ------------------------------------

img = img.convert("L")

# ------------------------------------
# RESIZE TO 128x128
# ------------------------------------

img = img.resize((128, 128))

print("New Image Size:", img.size)

# ------------------------------------
# SAVE RESIZED IMAGE
# ------------------------------------

img.save(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\128\resized_square128.png"
)

# ------------------------------------
# EXTRACT PIXELS
# ------------------------------------

pixels = list(img.getdata())

# ------------------------------------
# GENERATE HEX FILE
# ------------------------------------

with open(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\128\square128.hex",
    "w"
) as f:

    for pixel in pixels:
        f.write(f"{pixel:02X}\n")

print("HEX file generated successfully!")
print("Total pixels written:", len(pixels))