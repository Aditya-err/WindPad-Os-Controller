import qrcode
import socket
import tkinter as tk
from PIL import Image, ImageTk
import sys
import platform
import os
import time
import threading
import pyperclip

from autostart import is_autostart_enabled, enable_autostart, disable_autostart
from tray import set_tray_status

# Global reference
widget_instance = None

class FloatingWidget(tk.Tk):
    def __init__(self, port=8765):
        super().__init__()
        self.port = port
        self.ip = self._get_local_ip()
        
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        if sys.platform != 'darwin':
            self.attributes('-alpha', 0.96)
        
        self.configure(bg="#0A0A0F")
        self.is_connected = False
        self.connected_device = ""
        self.connect_time = None
        self.bytes_sent = 0
        self.bytes_recv = 0
        self.last_ping_ms = 0
        self._session_timer_id = None
        self._ping_timer_id = None
        
        # For window dragging
        self._drag_x = 0
        self._drag_y = 0
        
        self._build_ui()
        self._position_widget(waiting=True)
        
    def _get_local_ip(self):
        """FIX 13A: Better IP detection using UDP trick"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.settimeout(2)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            # Fallback: iterate interfaces
            try:
                hostname = socket.gethostname()
                ips = socket.getaddrinfo(hostname, None, socket.AF_INET)
                for info in ips:
                    ip = info[4][0]
                    if ip.startswith("192.168.") or ip.startswith("10.") or ip.startswith("172."):
                        return ip
            except Exception:
                pass
            return "127.0.0.1"

    def _position_widget(self, waiting=True):
        screen_w = self.winfo_screenwidth()
        screen_h = self.winfo_screenheight()
        width = 340
        height = 480 if waiting else 200
        x = screen_w - width - 20
        y = screen_h - height - 60
        self.geometry(f"{width}x{height}+{x}+{y}")

    def _start_drag(self, event):
        self._drag_x = event.x
        self._drag_y = event.y

    def _on_drag(self, event):
        x = self.winfo_x() + (event.x - self._drag_x)
        y = self.winfo_y() + (event.y - self._drag_y)
        self.geometry(f"+{x}+{y}")

    def _build_ui(self):
        for widget in self.winfo_children():
            widget.destroy()
        
        # Cancel old timers
        if self._session_timer_id:
            self.after_cancel(self._session_timer_id)
        if self._ping_timer_id:
            self.after_cancel(self._ping_timer_id)
            
        # ── TOP BAR ──
        top_frame = tk.Frame(self, bg="#111116", height=32)
        top_frame.pack(fill=tk.X, side=tk.TOP)
        top_frame.pack_propagate(False)
        top_frame.bind("<Button-1>", self._start_drag)
        top_frame.bind("<B1-Motion>", self._on_drag)

        # Status dot
        dot_color = "#00e676" if self.is_connected else "#4285F4"
        dot = tk.Label(top_frame, text="●", fg=dot_color, bg="#111116", font=("Arial", 12))
        dot.pack(side=tk.LEFT, padx=(8, 2))

        title_text = "Windpad Connected" if self.is_connected else "Windpad Helper"
        title_color = "#00e676" if self.is_connected else "#ccc"
        title = tk.Label(top_frame, text=title_text, fg=title_color, bg="#111116", font=("Arial", 10, "bold"))
        title.pack(side=tk.LEFT, padx=4)

        # Window controls
        close_btn = tk.Button(top_frame, text="✕", fg="#aaa", bg="#111116", bd=0,
                              activebackground="#ff4444", activeforeground="white",
                              font=("Arial", 9), command=lambda: os._exit(0))
        close_btn.pack(side=tk.RIGHT, padx=5)

        # FIX 13F: Minimize to tray properly
        min_btn = tk.Button(top_frame, text="—", fg="#aaa", bg="#111116", bd=0,
                            activebackground="#333", activeforeground="white",
                            font=("Arial", 9), command=self._minimize_to_tray)
        min_btn.pack(side=tk.RIGHT)
        
        # ── CONTENT ──
        self.content_frame = tk.Frame(self, bg="#0A0A0F")
        self.content_frame.pack(fill=tk.BOTH, expand=True, padx=12, pady=5)
        
        if self.is_connected:
            self._build_connected_ui()
        else:
            self._build_waiting_ui()

    def _minimize_to_tray(self):
        """FIX 13F: Proper minimize"""
        self.wm_state('iconic')

    def _build_connected_ui(self):
        """FIX 13E: Better connected state"""
        self._position_widget(waiting=False)
        
        # Connected device info
        device_frame = tk.Frame(self.content_frame, bg="#111820", highlightbackground="#00e676",
                                highlightthickness=1, padx=12, pady=8)
        device_frame.pack(fill=tk.X, pady=5)

        tk.Label(device_frame, text="📱 Connected Device", fg="#00e676", bg="#111820",
                 font=("Arial", 9, "bold")).pack(anchor="w")
        tk.Label(device_frame, text=f"IP: {self.connected_device}", fg="white", bg="#111820",
                 font=("Courier", 11, "bold")).pack(anchor="w")

        # Stats row
        stats_frame = tk.Frame(self.content_frame, bg="#0A0A0F")
        stats_frame.pack(fill=tk.X, pady=5)

        # Ping
        self.ping_label = tk.Label(stats_frame, text=f"Ping: {self.last_ping_ms}ms", fg="#4285F4",
                                   bg="#0A0A0F", font=("Courier", 10))
        self.ping_label.pack(side=tk.LEFT, padx=5)

        # Session timer
        self.timer_label = tk.Label(stats_frame, text="⏱ 0:00", fg="#aaa", bg="#0A0A0F",
                                    font=("Courier", 10))
        self.timer_label.pack(side=tk.RIGHT, padx=5)
        self._update_session_timer()

    def _update_session_timer(self):
        """FIX 13E: Session duration timer"""
        if self.connect_time and self.is_connected:
            elapsed = int(time.time() - self.connect_time)
            mins = elapsed // 60
            secs = elapsed % 60
            self.timer_label.config(text=f"⏱ {mins}:{secs:02d}")
            self._session_timer_id = self.after(1000, self._update_session_timer)

    def _build_waiting_ui(self):
        self._position_widget(waiting=True)
        
        # Status
        status = tk.Label(self.content_frame, text="Waiting for phone...", fg="#888",
                          bg="#0A0A0F", font=("Arial", 10))
        status.pack(pady=4)
        
        # QR Code
        qr_data = f"windpad://connect?ip={self.ip}&port={self.port}"
        qr = qrcode.make(qr_data)
        qr_img = qr.resize((180, 180), Image.NEAREST)
        self.img = ImageTk.PhotoImage(qr_img)
        
        qr_frame = tk.Frame(self.content_frame, bg="white", padx=4, pady=4)
        qr_frame.pack(pady=6)
        lbl_img = tk.Label(qr_frame, image=self.img, bg="white")
        lbl_img.pack()
        
        # IP display
        ip_lbl = tk.Label(self.content_frame, text=f"{self.ip} : {self.port}", fg="#4285F4",
                          bg="#0A0A0F", font=("Courier", 13, "bold"))
        ip_lbl.pack(pady=2)
        
        # Button row
        btn_frame = tk.Frame(self.content_frame, bg="#0A0A0F")
        btn_frame.pack(fill=tk.X, pady=4)

        # FIX 13C: Copy IP button
        self.copy_btn = tk.Button(btn_frame, text="📋 Copy IP", bg="#1A1A24", fg="white", bd=0,
                                  padx=10, pady=4, font=("Arial", 9, "bold"), command=self._copy_ip)
        self.copy_btn.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=2)

        # FIX 13C: Test Port button
        self.test_btn = tk.Button(btn_frame, text="🔌 Test Port", bg="#1A1A24", fg="white", bd=0,
                                  padx=10, pady=4, font=("Arial", 9, "bold"), command=self._test_port)
        self.test_btn.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=2)

        # FIX 13C: Network Info
        net_btn = tk.Button(btn_frame, text="ℹ️ Network", bg="#1A1A24", fg="white", bd=0,
                            padx=10, pady=4, font=("Arial", 9, "bold"), command=self._show_network_info)
        net_btn.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=2)

        tk.Label(self.content_frame, text="─── OR ───", fg="#333", bg="#0A0A0F",
                 font=("Arial", 8)).pack(pady=3)
        
        bt_btn = tk.Button(self.content_frame, text="Connect via Bluetooth", bg="#4285F4", fg="white",
                           bd=0, padx=15, pady=5, font=("Arial", 10, "bold"),
                           command=self._open_bt_settings)
        bt_btn.pack(pady=3)
        
        # Autostart
        self.autostart_var = tk.IntVar(value=1 if is_autostart_enabled() else 0)
        astart_cb = tk.Checkbutton(self.content_frame, text="Start with system",
                                   variable=self.autostart_var, bg="#0A0A0F", fg="#666",
                                   selectcolor="#0A0A0F", activebackground="#0A0A0F",
                                   activeforeground="white", font=("Arial", 9),
                                   command=self._toggle_autostart)
        astart_cb.pack(pady=2)

    def _toggle_autostart(self):
        if self.autostart_var.get() == 1:
            enable_autostart()
        else:
            disable_autostart()

    def _copy_ip(self):
        """FIX 13C: Copy with green flash"""
        pyperclip.copy(f"{self.ip}:{self.port}")
        self.copy_btn.config(text="✓ Copied!", bg="#1B5E20", fg="#00e676")
        self.after(2000, lambda: self.copy_btn.config(text="📋 Copy IP", bg="#1A1A24", fg="white"))

    def _test_port(self):
        """FIX 13C: Test if port is open"""
        def _check():
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.settimeout(2)
                result = s.connect_ex((self.ip, self.port))
                s.close()
                if result == 0:
                    self.after(0, lambda: self.test_btn.config(text="✓ Port Open", bg="#1B5E20", fg="#00e676"))
                else:
                    self.after(0, lambda: self.test_btn.config(text="✗ Closed", bg="#4A1A1A", fg="#ff5252"))
            except Exception:
                self.after(0, lambda: self.test_btn.config(text="✗ Error", bg="#4A1A1A", fg="#ff5252"))
            self.after(3000, lambda: self.test_btn.config(text="🔌 Test Port", bg="#1A1A24", fg="white"))
        threading.Thread(target=_check, daemon=True).start()

    def _show_network_info(self):
        """FIX 13C: Show network details"""
        info_win = tk.Toplevel(self)
        info_win.title("Network Info")
        info_win.geometry("280x180")
        info_win.configure(bg="#0A0A0F")
        info_win.attributes('-topmost', True)
        
        try:
            hostname = socket.gethostname()
            ssid = "N/A"
            if sys.platform == "win32":
                import subprocess
                result = subprocess.run(["netsh", "wlan", "show", "interfaces"], capture_output=True, text=True)
                for line in result.stdout.split("\n"):
                    if "SSID" in line and "BSSID" not in line:
                        ssid = line.split(":")[1].strip()
                        break
        except Exception:
            hostname = "Unknown"
            ssid = "N/A"
        
        info = [
            ("Hostname", hostname),
            ("Local IP", self.ip),
            ("Port", str(self.port)),
            ("WiFi SSID", ssid),
            ("Status", "Connected" if self.is_connected else "Waiting"),
        ]
        
        for label, value in info:
            row = tk.Frame(info_win, bg="#0A0A0F")
            row.pack(fill=tk.X, padx=12, pady=2)
            tk.Label(row, text=f"{label}:", fg="#888", bg="#0A0A0F", font=("Arial", 10), anchor="w", width=12).pack(side=tk.LEFT)
            tk.Label(row, text=value, fg="white", bg="#0A0A0F", font=("Courier", 10, "bold"), anchor="w").pack(side=tk.LEFT)

    def _open_bt_settings(self):
        system = platform.system().lower()
        if system == "windows":
            os.system("start ms-settings:bluetooth")
        elif system == "darwin":
            os.system("open /System/Library/PreferencePanes/Bluetooth.prefPane")
        elif system == "linux":
            os.system("blueman-manager")

    def set_connected(self, device_name):
        self.is_connected = True
        self.connected_device = device_name
        self.connect_time = time.time()
        self.deiconify()
        self.wm_state('normal')
        self._build_ui()
        set_tray_status(True, device_name)

    def set_disconnected(self):
        self.is_connected = False
        self.connected_device = ""
        self.connect_time = None
        self.deiconify()
        self.wm_state('normal')
        self._build_ui()
        set_tray_status(False)

    def update_ping(self, ms):
        self.last_ping_ms = ms
        if hasattr(self, 'ping_label') and self.is_connected:
            try:
                color = "#00e676" if ms < 50 else ("#FBBC04" if ms < 150 else "#ff5252")
                self.ping_label.config(text=f"Ping: {ms}ms", fg=color)
            except Exception:
                pass

def show_widget():
    global widget_instance
    if widget_instance is None:
        widget_instance = FloatingWidget()
        widget_instance.mainloop()
    else:
        widget_instance.deiconify()
        widget_instance.wm_state('normal')
        widget_instance.lift()

def on_client_connect(ip_address):
    global widget_instance
    if widget_instance:
        widget_instance.after(0, widget_instance.set_connected, ip_address)

def on_client_disconnect():
    global widget_instance
    if widget_instance:
        widget_instance.after(0, widget_instance.set_disconnected)

def on_ping_update(ms):
    global widget_instance
    if widget_instance:
        widget_instance.after(0, widget_instance.update_ping, ms)
