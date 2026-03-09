from PIL import Image
import shutil

src = '../assets/icon/windpad-icon.png'
dest_png = 'windpad.png'
dest_ico = 'windpad.ico'
try:
    shutil.copyfile(src, dest_png)
    img = Image.open(dest_png)
    img.save(dest_ico, format='ICO', sizes=[(256, 256), (128, 128), (64, 64), (32, 32), (16, 16)])
    print("Icons successfully created.")
except Exception as e:
    print(f"Failed to create icon from {src}: {e}")
