from PIL import Image
import os

# Load the original logo from windpad-server
img = Image.open('windpad-server/windpad.png').convert('RGBA')

# Resize to 1024x1024 master
master = img.resize((1024, 1024), Image.LANCZOS)
master.save('windpad-icon-1024.png')

# For Flutter APK — save to assets/icon/
os.makedirs('assets/icon', exist_ok=True)
master.save('assets/icon/windpad-icon.png')

# User's step 2 asks for "assets/icon/windpad-icon-foreground.png" which hasn't been written in their script.
# Let's save a copy there too to prevent build failures.
master.save('assets/icon/windpad-icon-foreground.png')

# For Helper app Windows .ico (multiple sizes)
sizes = [(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)]
ico_images = [img.resize(s, Image.LANCZOS) for s in sizes]
ico_images[0].save('windpad.ico', format='ICO',
    sizes=sizes, append_images=ico_images[1:])
print("windpad.ico created")

# For Helper app Linux/Mac PNG
img.resize((512, 512), Image.LANCZOS).save('windpad.png')
img.resize((512, 512), Image.LANCZOS).save('assets/windpad.png')
print("windpad.png created")
