from PIL import Image

def remove_white_bg(img_path):
    try:
        img = Image.open(img_path)
        img = img.convert("RGBA")

        datas = img.getdata()
        newData = []

        for item in datas:
            # Check if pixel is white or very close to white
            if item[0] > 230 and item[1] > 230 and item[2] > 230:
                # Replace with transparent pixel
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)

        img.putdata(newData)
        img.save(img_path, "PNG")
        print(f"Successfully processed {img_path}")
    except Exception as e:
        print(f"Error processing {img_path}: {e}")

remove_white_bg('assets/icon/windpad-icon.png')
