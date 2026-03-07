# Windpad 🖱️⌨️

**Turn your Android phone into a Bluetooth HID Trackpad & Keyboard for any device.**

Windpad connects via Bluetooth HID — no apps needed on the receiving end. Works with Windows, macOS, Linux, Smart TVs, Android TV, and more.

---

## ✨ Features

- **Trackpad** — smooth cursor movement with low-pass filtering & pointer acceleration
- **Multi-gesture** — 1-finger move, 2-finger scroll, pinch-to-zoom, 3-finger swipe
- **Keyboard** — type directly, sends HID keycodes character by character
- **Quick Keys** — Copy, Paste, Cut, Undo, Select All, Enter, Emoji
- **Special Keys** — F1–F12, Nav (Home/End/PgUp/PgDn/arrows), Media, sticky modifiers
- **Clipboard Paste** — sends clipboard text char-by-char preserving formatting
- **Auto-connect** — remembers last device, auto-reconnects on launch
- **Dark / Light / System theme** — app-wide Material 3 theming
- **Trackpad lock** — locks trackpad while system keyboard is open
- **Settings** — DPI, trackpad color, spreadsheet mode, emoji OS toggle (Win/Mac)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android SDK (minSdk 28)
- A Bluetooth-capable Android phone

### Build & Run

```bash
flutter pub get
flutter build apk --release --split-per-abi --shrink
```

APKs will be in `build/app/outputs/flutter-apk/`.

---

## 📦 Tech Stack

- **Flutter** + **Dart**
- **Kotlin** — native Bluetooth HID via Android BluetoothHidDevice API
- **Provider** — state management
- **SharedPreferences** — settings persistence
- **flutter_keyboard_visibility** — keyboard open/close detection
- **flutter_rating_bar** — in-app rating screen

---

## 📄 License

Developed by **Aditya** 🎓 — Made in India 🇮🇳
