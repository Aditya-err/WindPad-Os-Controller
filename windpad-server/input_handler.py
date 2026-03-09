from pynput import mouse, keyboard
from pynput.mouse import Button, Controller as MouseController
from pynput.keyboard import Key, KeyCode, Controller as KeyController

mouse_ctrl = MouseController()
kb_ctrl = KeyController()

def handle_mouse_move(dx, dy):
    cur = mouse_ctrl.position
    mouse_ctrl.position = (cur[0] + dx, cur[1] + dy)

def handle_click(button, action):
    btn = Button.left if button == "left" else Button.right
    if action == "click":
        mouse_ctrl.click(btn, 1)
    elif action == "double":
        mouse_ctrl.click(btn, 2)
    elif action == "down":
        mouse_ctrl.press(btn)
    elif action == "up":
        mouse_ctrl.release(btn)

def handle_scroll(dx, dy):
    mouse_ctrl.scroll(dx, dy)

def handle_key(modifier, keycode):
    keys_to_press = []
    if modifier & 1: keys_to_press.append(Key.ctrl)
    if modifier & 2: keys_to_press.append(Key.shift)
    if modifier & 4: keys_to_press.append(Key.alt)
    if modifier & 8: keys_to_press.append(Key.cmd)  # Win/Cmd
    
    mapped_key = HID_TO_PYNPUT.get(keycode)
    
    if mapped_key is not None:
        for k in keys_to_press:
            kb_ctrl.press(k)
        
        # pynput expects strings for characters, or Key enum for special keys
        try:
            kb_ctrl.press(mapped_key)
            kb_ctrl.release(mapped_key)
        except Exception:
            pass
            
        for k in reversed(keys_to_press):
            kb_ctrl.release(k)

def handle_text(content):
    # type text character by character
    try:
        kb_ctrl.type(content)
    except Exception:
        pass

def handle_media(action):
    # Depending on the OS, media keys on pynput might not work straight out of the box for all actions without extensions.
    # Pynput has limited media key support (e.g., Key.media_play_pause)
    if action == "play_pause":
        kb_ctrl.tap(Key.media_play_pause)
    elif action == "vol_up":
        kb_ctrl.tap(Key.media_volume_up)
    elif action == "vol_down":
        kb_ctrl.tap(Key.media_volume_down)
    elif action == "mute":
        kb_ctrl.tap(Key.media_volume_mute)
    elif action == "next":
        kb_ctrl.tap(Key.media_next)
    elif action == "prev":
        kb_ctrl.tap(Key.media_previous)

HID_TO_PYNPUT = {
    0x00: None,
    0x04: 'a', 0x05: 'b', 0x06: 'c', 0x07: 'd',
    0x08: 'e', 0x09: 'f', 0x0A: 'g', 0x0B: 'h',
    0x0C: 'i', 0x0D: 'j', 0x0E: 'k', 0x0F: 'l',
    0x10: 'm', 0x11: 'n', 0x12: 'o', 0x13: 'p',
    0x14: 'q', 0x15: 'r', 0x16: 's', 0x17: 't',
    0x18: 'u', 0x19: 'v', 0x1A: 'w', 0x1B: 'x',
    0x1C: 'y', 0x1D: 'z',
    0x1E: '1', 0x1F: '2', 0x20: '3', 0x21: '4',
    0x22: '5', 0x23: '6', 0x24: '7', 0x25: '8',
    0x26: '9', 0x27: '0',
    0x28: Key.enter,
    0x29: Key.esc,
    0x2A: Key.backspace,
    0x2B: Key.tab,
    0x2C: Key.space,
    0x2D: '-', 0x2E: '=',
    0x2F: '[', 0x30: ']',
    0x33: ';', 0x34: "'",
    0x36: ',', 0x37: '.', 0x38: '/',
    0x39: Key.caps_lock,
    0x3A: Key.f1,  0x3B: Key.f2,  0x3C: Key.f3,
    0x3D: Key.f4,  0x3E: Key.f5,  0x3F: Key.f6,
    0x40: Key.f7,  0x41: Key.f8,  0x42: Key.f9,
    0x43: Key.f10, 0x44: Key.f11, 0x45: Key.f12,
    0x46: Key.print_screen,
    0x47: Key.scroll_lock,
    0x48: Key.pause,
    0x49: Key.insert,
    0x4A: Key.home,
    0x4B: Key.page_up,
    0x4C: Key.delete,
    0x4D: Key.end,
    0x4E: Key.page_down,
    0x4F: Key.right,
    0x50: Key.left,
    0x51: Key.down,
    0x52: Key.up,
}
