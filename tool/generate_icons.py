from PIL import Image
import os

source_path = r"c:\Users\akela\Downloads\EventEase\assets\icons\app_logo.jpg"
res_dir = r"c:\Users\akela\Downloads\EventEase\android\app\src\main\res"

sizes = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}

img = Image.open(source_path).convert("RGBA")

for folder, size in sizes.items():
    target_dir = os.path.join(res_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    resized_img = img.resize(size, Image.Resampling.LANCZOS)
    target_file = os.path.join(target_dir, "ic_launcher.png")
    resized_img.save(target_file, "PNG")
    print(f"Generated {target_file} ({size[0]}x{size[1]})")

print("App launcher icons successfully generated!")
