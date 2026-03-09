import pystray
from PIL import Image, ImageDraw
from autostart import is_autostart_enabled, enable_autostart, disable_autostart

tray_instance = None
current_status_text = "Status: Waiting..."

def get_status_text(item):
    global current_status_text
    return current_status_text

def set_tray_status(is_connected, ip=""):
    global current_status_text, tray_instance
    if is_connected:
        current_status_text = f"Connected to {ip}"
    else:
        current_status_text = "Waiting for phone..."
    if tray_instance:
        tray_instance.update_menu()

def create_tray(on_quit, on_show_qr):
    global tray_instance
    try:
        icon_img = Image.open("windpad.ico")
    except Exception:
        icon_img = Image.new('RGB', (64, 64), color = (66, 133, 244))
        d = ImageDraw.Draw(icon_img)
        d.text((10,10), "WP", fill=(255,255,255))
        
    def toggle_autostart(icon, item):
        if is_autostart_enabled():
            disable_autostart()
        else:
            enable_autostart()
            
    menu = pystray.Menu(
        pystray.MenuItem(get_status_text, lambda: None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Show IP / QR Code", on_show_qr, default=True),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(
            "Start with system", 
            toggle_autostart, 
            checked=lambda item: is_autostart_enabled()
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Quit", on_quit)
    )
    
    tray_instance = pystray.Icon("Windpad", icon_img, "Windpad Helper", menu)
    tray_instance.HAS_DEFAULT_ACTION = True
    return tray_instance
