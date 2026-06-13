from PIL import Image

# ------------------------------------
# INPUT IMAGE
# ------------------------------------

input_image = r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\chessboard64.png"

# ------------------------------------
# OPEN IMAGE
# ------------------------------------

img = Image.open(input_image)

# ------------------------------------
# CONVERT TO GRAYSCALE
# ------------------------------------

img = img.convert("L")

# ------------------------------------
# RESIZE TO 64x64
# ------------------------------------

img = img.resize((64, 64))

print("New Image Size:", img.size)

# ------------------------------------
# SAVE RESIZED IMAGE
# ------------------------------------

img.save(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\resized_chessboard64.png"
)

# ------------------------------------
# EXTRACT PIXELS
# ------------------------------------

pixels = list(img.getdata())

# ------------------------------------
# GENERATE HEX FILE
# ------------------------------------

with open(
    r"D:\Vedant\NIT\Electronics\Summer_Intern_CSoC\Image\chessboard64.hex",
    "w"
) as f:

    for pixel in pixels:

        f.write(f"{pixel:02X}\n")

print("HEX file generated successfully!")
print("Total pixels written:", len(pixels))