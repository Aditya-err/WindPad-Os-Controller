import threading
import sys
import time

from config import PORT
from discovery import register_service
from server import WindpadServer
from qr_window import show_widget, on_client_connect, on_client_disconnect
from tray import create_tray

zeroconf_inst = None
server_inst = None
tray_icon = None

def on_quit(icon, item):
    global zeroconf_inst, server_inst
    icon.stop()
    if server_inst:
        server_inst.stop()
    if zeroconf_inst:
        zeroconf_inst.close()
    sys.exit(0)

def on_show_qr(icon, item):
    # Run in separate thread to not block tray
    threading.Thread(target=show_widget, daemon=True).start()

def main():
    global zeroconf_inst, server_inst, tray_icon
    
    # 1. Start Server
    server_inst = WindpadServer(
        port=PORT, 
        on_connect=on_client_connect, 
        on_disconnect=on_client_disconnect
    )
    server_inst.start()
    
    # 2. Register mDNS
    zeroconf_inst = register_service(port=PORT)
    
    # 3. Create tray icon in background
    tray_icon = create_tray(on_quit=on_quit, on_show_qr=on_show_qr)
    threading.Thread(target=tray_icon.run, daemon=True).start()
    
    # 4. Show Widget on start (blocks until quit)
    show_widget()

if __name__ == "__main__":
    main()
