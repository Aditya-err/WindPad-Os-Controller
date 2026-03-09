import qrcode
import socket
import tkinter as tk
from PIL import Image, ImageTk
import sys
import platform
import os
import pyperclip

from autostart import is_autostart_enabled, enable_autostart, disable_autostart
from tray import set_tray_status

# Global reference to widget window
widget_instance = None

class FloatingWidget(tk.Tk):
    def __init__(self, port=8765):
        super().__init__()
        self.port = port
        self.ip = self._get_local_ip()
        
        self.overrideredirect(True)        # no title bar
        self.attributes('-topmost', True)  # always on top
        if sys.platform != 'darwin':
            self.attributes('-alpha', 0.96)    # slight transparency
        
        self.configure(bg="#0A0A0F")
        self.is_connected = False
        self.connected_device = ""
        
        # Draw UI
        self._build_ui()
        self._position_widget(waiting=True)
        
    def _get_local_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"

    def _position_widget(self, waiting=True):
        screen_w = self.winfo_screenwidth()
        screen_h = self.winfo_screenheight()
        width = 320
        height = 420 if waiting else 80
        
        # Position bottom-right corner
        x = screen_w - width - 20
        y = screen_h - height - 60 # 60px above bottom to clear taskbar
        self.geometry(f"{width}x{height}+{x}+{y}")

    def _build_ui(self):
        for widget in self.winfo_children():
            widget.destroy()
            
        top_frame = tk.Frame(self, bg="#111116", height=30)
        top_frame.pack(fill=tk.X, side=tk.TOP)
        top_frame.pack_propagate(False)

        title_text = "🔵 Windpad Connected" if self.is_connected else "🔵 Windpad Helper"
        title_color = "#00e676" if self.is_connected else "#4285F4"
        
        title = tk.Label(top_frame, text=title_text, fg=title_color, bg="#111116", font=("Arial", 10, "bold"))
        title.pack(side=tk.LEFT, padx=10)

        close_btn = tk.Button(top_frame, text="✕", fg="#aaa", bg="#111116", bd=0, activebackground="#ff4444", activeforeground="white", command=lambda: os._exit(0))
        close_btn.pack(side=tk.RIGHT, padx=5)

        min_btn = tk.Button(top_frame, text="—", fg="#aaa", bg="#111116", bd=0, activebackground="#333", activeforeground="white", command=self.withdraw)
        min_btn.pack(side=tk.RIGHT)
        
        self.content_frame = tk.Frame(self, bg="#0A0A0F")
        self.content_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        if self.is_connected:
            self._position_widget(waiting=False)
            status = tk.Label(self.content_frame, text=f"Phone IP: {self.connected_device}", fg="white", bg="#0A0A0F", font=("Arial", 11, "bold"))
            status.pack(pady=10)
        else:
            self._position_widget(waiting=True)
            status = tk.Label(self.content_frame, text="Status: Waiting for phone...", fg="#aaa", bg="#0A0A0F", font=("Arial", 10))
            status.pack(pady=5)
            
            # QR Code
            qr_data = f"windpad://connect?ip={self.ip}&port={self.port}"
            qr = qrcode.make(qr_data)
            qr_img = qr.resize((192, 192), Image.NEAREST)
            self.img = ImageTk.PhotoImage(qr_img)
            
            lbl_img = tk.Label(self.content_frame, image=self.img, bg="white")
            lbl_img.pack(pady=10)
            
            ip_lbl = tk.Label(self.content_frame, text=f"{self.ip} : {self.port}", fg="#4285F4", bg="#0A0A0F", font=("Courier", 12, "bold"))
            ip_lbl.pack()
            
            self.copy_btn = tk.Button(self.content_frame, text="Copy IP", bg="#1A1A24", fg="white", bd=0, padx=10, pady=2, command=self._copy_ip)
            self.copy_btn.pack(pady=5)
            
            tk.Label(self.content_frame, text="─── OR ───", fg="#444", bg="#0A0A0F", font=("Arial", 9)).pack(pady=5)
            
            bt_btn = tk.Button(self.content_frame, text="Connect via Bluetooth", bg="#4285F4", fg="white", bd=0, padx=15, pady=4, font=("Arial", 10, "bold"), command=self._open_bt_settings)
            bt_btn.pack(pady=5)
            
            self.autostart_var = tk.IntVar(value=1 if is_autostart_enabled() else 0)
            astart_cb = tk.Checkbutton(self.content_frame, text="Start with system", variable=self.autostart_var, 
                                       bg="#0A0A0F", fg="#aaa", selectcolor="#0A0A0F", 
                                       activebackground="#0A0A0F", activeforeground="white",
                                       command=self._toggle_autostart)
            astart_cb.pack(pady=2)

    def _toggle_autostart(self):
        if self.autostart_var.get() == 1:
            enable_autostart()
        else:
            disable_autostart()

    def _copy_ip(self):
        pyperclip.copy(f"{self.ip}:{self.port}")
        self.copy_btn.config(text="✓ Copied!")
        self.after(2000, lambda: self.copy_btn.config(text="Copy IP"))

    def _open_bt_settings(self):
        system = platform.system().lower()
        if system == "windows":
            os.system("start ms-settings:bluetooth")
        elif system == "darwin":
            os.system("open /System/Library/PreferencePanes/Bluetooth.prefPane")
        elif system == "linux":
            os.system("blueman-manager")
        
        if hasattr(self, 'bt_instruct_lbl'):
            self.bt_instruct_lbl.pack_forget()
        self.bt_instruct_lbl = tk.Label(self.content_frame, text="On your phone open Windpad → Select Bluetooth", fg="#666", bg="#0A0A0F", font=("Arial", 9, "italic"))
        self.bt_instruct_lbl.pack(pady=2)

    def set_connected(self, device_name):
        self.is_connected = True
        self.connected_device = device_name
        self.deiconify() 
        self._build_ui()
        set_tray_status(True, device_name)

    def set_disconnected(self):
        self.is_connected = False
        self.connected_device = ""
        self.deiconify() 
        self._build_ui()
        set_tray_status(False)

def show_widget():
    global widget_instance
    if widget_instance is None:
        widget_instance = FloatingWidget()
        widget_instance.mainloop()
    else:
        widget_instance.deiconify()
        widget_instance.lift()

def on_client_connect(ip_address):
    global widget_instance
    if widget_instance:
        widget_instance.after(0, widget_instance.set_connected, ip_address)

def on_client_disconnect():
    global widget_instance
    if widget_instance:
        widget_instance.after(0, widget_instance.set_disconnected)
