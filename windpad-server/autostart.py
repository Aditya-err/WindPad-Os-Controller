import sys
import platform
import os

def enable_autostart():
    system = platform.system().lower()
    if system == "windows":
        _enable_autostart_windows()
    elif system == "darwin":
        _enable_autostart_mac()
    elif system == "linux":
        _enable_autostart_linux()

def disable_autostart():
    system = platform.system().lower()
    if system == "windows":
        _disable_autostart_windows()
    elif system == "darwin":
        _disable_autostart_mac()
    elif system == "linux":
        _disable_autostart_linux()

def is_autostart_enabled():
    system = platform.system().lower()
    if system == "windows":
        return _is_autostart_windows()
    elif system == "darwin":
        return _is_autostart_mac()
    elif system == "linux":
        return _is_autostart_linux()
    return False

def _get_exe_path():
    if getattr(sys, 'frozen', False):
        return sys.executable
    return os.path.abspath(sys.argv[0])

# --- Windows ---
def _enable_autostart_windows():
    import winreg
    exe_path = _get_exe_path()
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        winreg.SetValueEx(key, "WindpadHelper", 0, winreg.REG_SZ, f'"{exe_path}"')
        winreg.CloseKey(key)
    except Exception as e:
        print("Failed to enable autostart (Windows):", e)

def _disable_autostart_windows():
    import winreg
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        winreg.DeleteValue(key, "WindpadHelper")
        winreg.CloseKey(key)
    except:
        pass

def _is_autostart_windows():
    import winreg
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_READ
        )
        winreg.QueryValueEx(key, "WindpadHelper")
        winreg.CloseKey(key)
        return True
    except:
        return False

# --- Mac ---
def _enable_autostart_mac():
    import plistlib
    plist_path = os.path.expanduser("~/Library/LaunchAgents/com.windpad.helper.plist")
    plist_data = {
        "Label": "com.windpad.helper",
        "ProgramArguments": [_get_exe_path()],
        "RunAtLoad": True,
        "KeepAlive": False,
        "LSUIElement": True,
    }
    os.makedirs(os.path.dirname(plist_path), exist_ok=True)
    with open(plist_path, "wb") as f:
        plistlib.dump(plist_data, f)
    os.system(f"launchctl load {plist_path}")

def _disable_autostart_mac():
    plist_path = os.path.expanduser("~/Library/LaunchAgents/com.windpad.helper.plist")
    os.system(f"launchctl unload {plist_path}")
    if os.path.exists(plist_path):
        os.remove(plist_path)

def _is_autostart_mac():
    plist_path = os.path.expanduser("~/Library/LaunchAgents/com.windpad.helper.plist")
    return os.path.exists(plist_path)

# --- Linux ---
def _enable_autostart_linux():
    autostart_dir = os.path.expanduser("~/.config/autostart")
    os.makedirs(autostart_dir, exist_ok=True)
    desktop_content = f"""[Desktop Entry]
Name=Windpad Helper
Exec={_get_exe_path()}
Type=Application
X-GNOME-Autostart-enabled=true
Hidden=false
"""
    with open(f"{autostart_dir}/windpad.desktop", "w") as f:
        f.write(desktop_content)

def _disable_autostart_linux():
    path = os.path.expanduser("~/.config/autostart/windpad.desktop")
    if os.path.exists(path):
        os.remove(path)

def _is_autostart_linux():
    path = os.path.expanduser("~/.config/autostart/windpad.desktop")
    return os.path.exists(path)
