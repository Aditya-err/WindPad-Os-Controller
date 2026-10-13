import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'platform_channel.dart';

enum BluetoothState { disconnected, scanning, pairing, connected }
enum DeviceType { tv, pc, mac, linux, projector }
enum NotificationType { info, success, warning, error }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final String? actionLabel;
  final VoidCallback? onAction;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    DateTime? timestamp,
    this.actionLabel,
    this.onAction,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BluetoothHidService extends ChangeNotifier with WidgetsBindingObserver {
  BluetoothState _state = BluetoothState.disconnected;
  DeviceType _deviceType = DeviceType.pc;
  String _connectedDeviceName = "";
  String? _errorMessage;
  int _dpi = 1200;
  final List<int> _dpiSteps = [400, 800, 1200, 1600, 2400];
  String? _activeGesture;
  String? _pinchPop;

  bool _isSpreadsheetMode = false;
  bool _touchSoundEnabled = true;
  double _touchSoundVolume = 50.0;
  bool _tapToClick = true;
  bool _twoFingerRightClick = true;
  bool _threeFingerSwipe = true;
  bool _quickKeysVisible = true;
  bool _hapticFeedback = true;
  int _trackpadColorIndex = 0;
  bool _trackpadLocked = false;
  bool _useWindowsEmoji = true; // true=Windows, false=macOS
  bool _isAirMouse = false;

  // Bonded devices
  List<Map<String, String>> _bondedDevices = [];
  String? _lastConnectedMac;
  Timer? _connectingTimer;

  VoidCallback? onConnectionTimeout;

  // Connection tracking
  bool _isBluetoothConnected = false;

  DeviceType get deviceType => _deviceType;
  bool get isTvOrProjector => _deviceType == DeviceType.tv || _deviceType == DeviceType.projector;
  BluetoothState get state => _state;
  bool get isBluetoothConnected => _isBluetoothConnected;
  String get connectedDeviceName => _connectedDeviceName;
  String? get errorMessage => _errorMessage;
  int get dpi => _dpi;
  List<int> get dpiSteps => _dpiSteps;
  String? get activeGesture => _activeGesture;
  String? get pinchPop => _pinchPop;
  bool get isSpreadsheetMode => _isSpreadsheetMode;
  bool get touchSoundEnabled => _touchSoundEnabled;
  double get touchSoundVolume => _touchSoundVolume;
  bool get tapToClick => _tapToClick;
  bool get twoFingerRightClick => _twoFingerRightClick;
  bool get threeFingerSwipe => _threeFingerSwipe;
  bool get quickKeysVisible => _quickKeysVisible;
  bool get hapticFeedback => _hapticFeedback;
  int get trackpadColorIndex => _trackpadColorIndex;
  bool get trackpadLocked => _trackpadLocked;
  bool get useWindowsEmoji => _useWindowsEmoji;
  bool get isAirMouse => _isAirMouse;
  double get movementScale => _dpi / 800.0;
  List<Map<String, String>> get bondedDevices => _bondedDevices;
  String? get lastConnectedMac => _lastConnectedMac;
  bool _isTyping = false;
  bool get isTyping => _isTyping;
  int _typingCurrent = 0;
  int _typingTotal = 0;
  int get typingCurrent => _typingCurrent;
  int get typingTotal => _typingTotal;

  void stopTyping() {
    _isTyping = false;
    _typingCurrent = 0;
    _typingTotal = 0;
    try {
      PlatformChannel.sendKeyReport(modifier: 0, keys: []);
    } catch (_) {}
    showNotification(
      "Paste Stopped",
      "Text streaming was cancelled immediately",
      type: NotificationType.warning,
    );
    notifyListeners();
  }

  // ── Discovery State & Actions ──
  final List<Map<String, String>> _discoveredDevices = [];
  List<Map<String, String>> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  bool _isDiscovering = false;
  bool get isDiscovering => _isDiscovering;

  Future<void> startDiscovery() async {
    final granted = await _requestPermissions();
    if (!granted) return;
    _discoveredDevices.clear();
    _isDiscovering = true;
    notifyListeners();
    showNotification(
      "Scanning Nearby Devices",
      "Searching for active Bluetooth devices nearby...",
      type: NotificationType.info,
    );
    final ok = await PlatformChannel.startDiscovery();
    if (!ok) {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    await PlatformChannel.cancelDiscovery();
    notifyListeners();
  }

  // ── Notification System (System Notifications Outside App) ──
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  AppNotification? get activeNotification => null;
  int get unreadNotificationCount => 0;

  void showNotification(
    String title,
    String message, {
    NotificationType type = NotificationType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Show real Android system notification outside the app
    PlatformChannel.showSystemNotification(title: title, message: message);
  }

  void dismissActiveNotification() {}
  void clearAllNotifications() {}
  void markNotificationsAsRead() {}

  static const List<Color> trackpadColors = [
    Color(0xFFF0F4F8), // 0: White
    Color(0xFFE8F5E9), // 1: Mint
    Color(0xFFFFF8E1), // 2: Cream
    Color(0xFFF3E5F5), // 3: Lavender
    Color(0xFFE0F2F1), // 4: Ice Blue
    Color(0xFFFFEBEE), // 5: Peach Pink (Default in assets/Dark theme/home page.jpg)
    Color(0xFF1E2235), // 6: Navy
    Color(0xFF2C2F3C), // 7: Charcoal
  ];

  Color get trackpadColor => trackpadColors[_trackpadColorIndex.clamp(0, trackpadColors.length - 1)];

  BluetoothHidService() {
    _initService();
  }

  Future<void> _initService() async {
    WidgetsBinding.instance.addObserver(this);
    await _loadSettings();
    PlatformChannel.setMethodCallHandler(_handleMethodCall);
    await _requestPermissions();
    // Initialize Bluetooth HID universally across all device profiles
    await PlatformChannel.initHid();
    await _autoConnect();
    if (isTvOrProjector) {
      _startGyro();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_state == BluetoothState.disconnected) {
        checkAndReconnect();
      }
    }
  }

  @override
  void dispose() {
    _stopGyro();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _smoothX = 0;
  double _smoothY = 0;

  void _startGyro() {
    _gyroSub?.cancel();
    try {
      _gyroSub = gyroscopeEventStream().listen((event) {
        if (_state != BluetoothState.connected || !isTvOrProjector || _trackpadLocked || !_isAirMouse) return;
        
        double yaw = -event.z;
        double pitch = -event.x;
        
        if (yaw.abs() < 0.02) yaw = 0;
        if (pitch.abs() < 0.02) pitch = 0;

        _smoothX = _smoothX * 0.4 + yaw * 0.6;
        _smoothY = _smoothY * 0.4 + pitch * 0.6;

        if (_smoothX.abs() > 0.01 || _smoothY.abs() > 0.01) {
          final mult = movementScale * 35.0;
          int dx = (_smoothX * mult).round();
          int dy = (_smoothY * mult).round();
          if (dx != 0 || dy != 0) {
            sendMouseMove(dx, dy);
          }
        }
      }, onError: (e) {
        debugPrint("Gyroscope stream error: $e");
      });
    } catch (e) {
      debugPrint("Failed to initialize gyroscope: $e");
    }
  }

  void _stopGyro() {
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  Future<bool> _requestPermissions() async {
    try {
      final status = await Permission.bluetoothConnect.status;
      if (status.isGranted) return true;
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.bluetoothScan,
        Permission.bluetooth,
        Permission.location,
        Permission.notification,
      ].request();
      final connectStatus = statuses[Permission.bluetoothConnect] ?? await Permission.bluetoothConnect.status;
      return connectStatus.isGranted;
    } catch (e) {
      debugPrint("Bluetooth permission request error: $e");
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dpi = prefs.getInt('dpi') ?? 1200;
    _isSpreadsheetMode = prefs.getBool('spreadsheetMode') ?? false;
    _touchSoundEnabled = prefs.getBool('touchSound') ?? true;
    _touchSoundVolume = prefs.getDouble('touchSoundVol') ?? 50.0;
    _tapToClick = prefs.getBool('tapToClick') ?? true;
    _twoFingerRightClick = prefs.getBool('twoFingerRight') ?? true;
    _threeFingerSwipe = prefs.getBool('threeFingerSwipe') ?? true;
    _quickKeysVisible = prefs.getBool('quickKeys') ?? true;
    _hapticFeedback = prefs.getBool('haptic') ?? true;
    _trackpadColorIndex = prefs.getInt('trackpadColor') ?? 5;
    _useWindowsEmoji = prefs.getBool('useWindowsEmoji') ?? true;
    _lastConnectedMac = prefs.getString('lastMac');
    final dtStr = prefs.getString('savedDeviceType');
    if (dtStr != null) {
      _deviceType = DeviceType.values.firstWhere((e) => e.toString() == dtStr, orElse: () => DeviceType.pc);
      if (_deviceType == DeviceType.tv) _startGyro();
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dpi', _dpi);
    await prefs.setBool('spreadsheetMode', _isSpreadsheetMode);
    await prefs.setBool('touchSound', _touchSoundEnabled);
    await prefs.setDouble('touchSoundVol', _touchSoundVolume);
    await prefs.setBool('tapToClick', _tapToClick);
    await prefs.setBool('twoFingerRight', _twoFingerRightClick);
    await prefs.setBool('threeFingerSwipe', _threeFingerSwipe);
    await prefs.setBool('quickKeys', _quickKeysVisible);
    await prefs.setBool('haptic', _hapticFeedback);
    await prefs.setInt('trackpadColor', _trackpadColorIndex);
    await prefs.setBool('useWindowsEmoji', _useWindowsEmoji);
  }

  Future<void> _saveLastMac(String mac) async {
    _lastConnectedMac = mac;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastMac', mac);
  }

  // ── Auto-connect ──
  Future<void> _autoConnect() async {
    await refreshBondedDevices();
    if (_lastConnectedMac != null && _lastConnectedMac!.isNotEmpty && _state == BluetoothState.disconnected) {
      _state = BluetoothState.scanning;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1500)); // Wait for HID service registration
      await PlatformChannel.connectToDevice(_lastConnectedMac!);
    }
  }

  Future<void> refreshBondedDevices() async {
    _bondedDevices = await PlatformChannel.getBondedDevices();
    notifyListeners();
  }

  // ── Setters ──
  Future<void> setDeviceType(DeviceType val) async {
    if (_deviceType == val) return;
    _deviceType = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedDeviceType', val.toString());

    if (isTvOrProjector) {
      _startGyro();
      if (_state == BluetoothState.disconnected) {
        await PlatformChannel.startAdvertising();
      }
    } else {
      _stopGyro();
      _isAirMouse = false;
    }
    notifyListeners();
  }

  void toggleAirMouse() {
    if (isTvOrProjector) {
      _isAirMouse = !_isAirMouse;
      if (_isAirMouse) {
        _startGyro();
      } else {
        _stopGyro();
      }
      notifyListeners();
    }
  }

  void setAirMouseEnabled(bool enabled) {
    if (isTvOrProjector && _isAirMouse != enabled) {
      _isAirMouse = enabled;
      if (_isAirMouse) {
        _startGyro();
      } else {
        _stopGyro();
      }
      notifyListeners();
    }
  }

  void toggleSpreadsheetMode() { _isSpreadsheetMode = !_isSpreadsheetMode; _saveSettings(); notifyListeners(); }
  void setTouchSoundEnabled(bool v) { _touchSoundEnabled = v; _saveSettings(); notifyListeners(); }
  void setTouchSoundVolume(double v) { _touchSoundVolume = v; _saveSettings(); notifyListeners(); }
  void setTapToClick(bool v) { _tapToClick = v; _saveSettings(); notifyListeners(); }
  void setTwoFingerRightClick(bool v) { _twoFingerRightClick = v; _saveSettings(); notifyListeners(); }
  void setThreeFingerSwipe(bool v) { _threeFingerSwipe = v; _saveSettings(); notifyListeners(); }
  void setQuickKeysVisible(bool v) { _quickKeysVisible = v; _saveSettings(); notifyListeners(); }
  void setHapticFeedback(bool v) { _hapticFeedback = v; _saveSettings(); notifyListeners(); }
  void setUseWindowsEmoji(bool v) { _useWindowsEmoji = v; _saveSettings(); notifyListeners(); }

  void setTrackpadLocked(bool v) { _trackpadLocked = v; notifyListeners(); }

  void setTrackpadColorIndex(int idx) {
    _trackpadColorIndex = idx.clamp(0, trackpadColors.length - 1);
    _saveSettings();
    notifyListeners();
  }

  void setDpi(int value) {
    if (_dpiSteps.contains(value)) { _dpi = value; _saveSettings(); notifyListeners(); }
  }

  void cycleDpi() {
    final idx = _dpiSteps.indexOf(_dpi);
    _dpi = _dpiSteps[(idx + 1) % _dpiSteps.length];
    _saveSettings();
    notifyListeners();
  }

  void setActiveGesture(String? gestureId) {
    if (_activeGesture == gestureId) return;
    _activeGesture = gestureId;
    notifyListeners();
  }

  void setPinchPop(String? text) {
    if (_pinchPop == text) return;
    _pinchPop = text;
    notifyListeners();
    if (text != null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (_pinchPop == text) { _pinchPop = null; notifyListeners(); }
      });
    }
  }

  // ── Connection ──
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> connect() async {
    if (_state != BluetoothState.disconnected) return;
    final granted = await _requestPermissions();
    if (!granted) {
      _errorMessage = "Bluetooth permissions are required to connect.";
      showNotification("Permission Required", _errorMessage!, type: NotificationType.error);
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _state = BluetoothState.scanning;
    showNotification(
      "Device Discoverable",
      "Broadcasting BLE HID & Bluetooth. Select this phone on your TV or PC.",
      type: NotificationType.info,
    );
    notifyListeners();
    await PlatformChannel.startAdvertising();
  }

  Future<void> connectToDevice(String mac, String name) async {
    if (_state == BluetoothState.connected) return;
    final granted = await _requestPermissions();
    if (!granted) {
      _errorMessage = "Bluetooth permissions are required to connect.";
      showNotification("Permission Required", _errorMessage!, type: NotificationType.error);
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _state = BluetoothState.scanning;
    _connectedDeviceName = name;
    showNotification(
      "Connecting",
      "Connecting to $name...",
      type: NotificationType.info,
    );
    notifyListeners();
    await _saveLastMac(mac);
    await PlatformChannel.connectToDevice(mac);
  }

  Future<void> disconnect() async {
    _connectingTimer?.cancel();
    final prevName = _connectedDeviceName;
    await PlatformChannel.disconnect();
    _isBluetoothConnected = false;
    _state = BluetoothState.disconnected;
    _connectedDeviceName = "";
    _stopGyro();
    showNotification(
      "Disconnected",
      prevName.isNotEmpty ? "Disconnected from $prevName" : "Bluetooth connection closed",
      type: NotificationType.warning,
      actionLabel: "Reconnect",
      onAction: () => connect(),
    );
    notifyListeners();
  }

  Future<bool> checkAndReconnect() async => await PlatformChannel.checkAndReconnect();
  Future<void> ensureServiceRunning() async => await PlatformChannel.ensureServiceRunning();

  // ── HID Reports ──
  int _activeButtons = 0;

  Future<void> _sendMouseReport({required int buttons, required int dx, required int dy, required int scroll}) async {
    await PlatformChannel.sendMouseReport(buttons: buttons, dx: dx, dy: dy, scroll: scroll);
  }

  Future<void> sendMouseMove(int dx, int dy) async {
    if (_state != BluetoothState.connected || _trackpadLocked) return;
    await _sendMouseReport(buttons: _activeButtons, dx: dx, dy: dy, scroll: 0);
  }

  Future<void> sendMouseClick(int buttonMask) async {
    if (_state != BluetoothState.connected) return;
    await _sendMouseReport(buttons: _activeButtons | buttonMask, dx: 0, dy: 0, scroll: 0);
    await Future.delayed(const Duration(milliseconds: 10));
    await _sendMouseReport(buttons: _activeButtons, dx: 0, dy: 0, scroll: 0);
  }

  Future<void> sendMouseButtonDown(int buttonMask) async {
    if (_state != BluetoothState.connected) return;
    _activeButtons |= buttonMask;
    await _sendMouseReport(buttons: _activeButtons, dx: 0, dy: 0, scroll: 0);
  }

  Future<void> sendMouseButtonUp() async {
    if (_state != BluetoothState.connected) return;
    _activeButtons = 0;
    await _sendMouseReport(buttons: _activeButtons, dx: 0, dy: 0, scroll: 0);
  }

  Future<void> sendScroll(int scroll) async {
    if (_state != BluetoothState.connected || _trackpadLocked) return;
    await _sendMouseReport(buttons: 0, dx: 0, dy: 0, scroll: scroll);
  }

  Future<void> sendKey(int modifier, List<int> keys) async {
    if (_state != BluetoothState.connected) return;
    if (_hapticFeedback) HapticFeedback.lightImpact();
    await PlatformChannel.sendKeyReport(modifier: modifier, keys: keys);
    await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
  }

  Future<void> sendMedia(int hid) async {
    if (_state != BluetoothState.connected) return;
    if (_hapticFeedback) HapticFeedback.lightImpact();
    await PlatformChannel.sendMediaReport(keys: [hid & 0xFF, (hid >> 8) & 0xFF]);
    await PlatformChannel.sendMediaReport(keys: [0, 0]);
  }

  Future<void> sendEnter() async {
    if (_isSpreadsheetMode) {
      await sendKey(0, [0x2B]); // Tab
    } else {
      await sendKey(0, [0x28]); // Enter
    }
  }

  Future<void> sendShiftEnter() async {
    if (_isSpreadsheetMode) {
      await sendKey(0, [0x28]); // Enter (down in spreadsheet)
    } else {
      await sendKey(0x02, [0x28]); // Shift+Enter
    }
  }

  Future<void> sendEmoji() async {
    if (_useWindowsEmoji) {
      // Windows: Win+. (GUI key 0xE3 + period 0x37)
      await sendKey(0x08, [0x37]);
    } else {
      // macOS: Ctrl+Cmd+Space (0x01|0x08 + Space 0x2C)
      await sendKey(0x01 | 0x08, [0x2C]);
    }
  }

  /// Paste clipboard text char-by-char preserving formatting with instant abort support
  Future<void> pasteClipboard() async {
    if (_state != BluetoothState.connected) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    await sendText(data.text!);
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty || _state != BluetoothState.connected) return;

    // Only activate isTyping progress state for long pasted blocks (> 5 chars),
    // so normal keyboard typing never flickers or blips red error banners!
    final isLongPaste = text.length > 5;
    if (isLongPaste) {
      _isTyping = true;
      _typingTotal = text.length;
      _typingCurrent = 0;
      notifyListeners();
    }

    try {
      for (int i = 0; i < text.length; i++) {
        if (isLongPaste && (!_isTyping || _state != BluetoothState.connected)) {
          await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
          break;
        }
        if (isLongPaste) {
          _typingCurrent = i + 1;
          if (i % 5 == 0 || i == text.length - 1) notifyListeners();
        }

        final char = text[i];
        if (char == '\n') {
          await PlatformChannel.sendKeyReport(modifier: 0, keys: [0x28]);
          await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
        } else if (char == '\t') {
          await PlatformChannel.sendKeyReport(modifier: 0, keys: [0x2B]);
          await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
        } else {
          final keycode = _mapCharCodeToHid(char);
          final modifier = _getModifierForChar(char);
          if (keycode != 0) {
            await PlatformChannel.sendKeyReport(modifier: modifier, keys: [keycode]);
            await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
          }
        }
        await Future.delayed(const Duration(milliseconds: 8));
      }
    } finally {
      if (isLongPaste) {
        _isTyping = false;
        _typingCurrent = 0;
        _typingTotal = 0;
        notifyListeners();
      }
      try {
        await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
      } catch (_) {}
    }
  }

  Future<void> zoomIn() async {
    if (_state != BluetoothState.connected) return;
    if (_deviceType == DeviceType.mac) {
      await sendKey(0x08, [0x2E]); // Cmd + =
    } else {
      await sendKey(0x01, [0x2E]); // Ctrl + =
    }
  }

  Future<void> zoomOut() async {
    if (_state != BluetoothState.connected) return;
    if (_deviceType == DeviceType.mac) {
      await sendKey(0x08, [0x2D]); // Cmd + -
    } else {
      await sendKey(0x01, [0x2D]); // Ctrl + -
    }
  }

  int _mapCharCodeToHid(String char) {
    const Map<String, int> m = {
      'a':0x04,'b':0x05,'c':0x06,'d':0x07,'e':0x08,'f':0x09,'g':0x0A,'h':0x0B,'i':0x0C,'j':0x0D,'k':0x0E,'l':0x0F,'m':0x10,'n':0x11,'o':0x12,'p':0x13,'q':0x14,'r':0x15,'s':0x16,'t':0x17,'u':0x18,'v':0x19,'w':0x1A,'x':0x1B,'y':0x1C,'z':0x1D,
      'A':0x04,'B':0x05,'C':0x06,'D':0x07,'E':0x08,'F':0x09,'G':0x0A,'H':0x0B,'I':0x0C,'J':0x0D,'K':0x0E,'L':0x0F,'M':0x10,'N':0x11,'O':0x12,'P':0x13,'Q':0x14,'R':0x15,'S':0x16,'T':0x17,'U':0x18,'V':0x19,'W':0x1A,'X':0x1B,'Y':0x1C,'Z':0x1D,
      '1':0x1E,'2':0x1F,'3':0x20,'4':0x21,'5':0x22,'6':0x23,'7':0x24,'8':0x25,'9':0x26,'0':0x27,
      '!':0x1E,'@':0x1F,'#':0x20,'\$':0x21,'%':0x22,'^':0x23,'&':0x24,'*':0x25,'(':0x26,')':0x27,
      '\n':0x28,'\r':0x28,'\t':0x2B,' ':0x2C,
      '-':0x2D,'_':0x2D,'=':0x2E,'+':0x2E,
      '[':0x2F,'{':0x2F,']':0x30,'}':0x30,
      '\\':0x31,'|':0x31,';':0x33,':':0x33,
      '\'':0x34,'"':0x34,'`':0x35,'~':0x35,
      ',':0x36,'<':0x36,'.':0x37,'>':0x37,
      '/':0x38,'?':0x38,
    };
    return m[char] ?? 0;
  }

  int _getModifierForChar(String char) {
    const s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#\$%^&*()_+{}|:"<>?~';
    return s.contains(char) ? 0x02 : 0;
  }

  Timer? _volDownTimer;
  bool _volDownIsRight = false;

  void _handleVolumeKeyDown(int keyCode) {
    if (_state != BluetoothState.connected || !isTvOrProjector) return;
    if (keyCode == 24) { // Volume Up
      sendMouseButtonDown(1);
    } else if (keyCode == 25) { // Volume Down
      _volDownIsRight = false;
      _volDownTimer = Timer(const Duration(milliseconds: 500), () {
        _volDownIsRight = true;
        sendMouseButtonDown(2);
      });
    }
  }

  void _handleVolumeKeyUp(int keyCode) {
    if (_state != BluetoothState.connected || !isTvOrProjector) return;
    if (keyCode == 24) {
      sendMouseButtonUp();
    } else if (keyCode == 25) {
      if (_volDownTimer != null && _volDownTimer!.isActive) {
        _volDownTimer!.cancel();
        sendMouseButtonDown(1);
        Future.delayed(const Duration(milliseconds: 50), sendMouseButtonUp);
      } else if (_volDownIsRight) {
        sendMouseButtonUp();
      }
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onVolumeKeyDown':
        _handleVolumeKeyDown(call.arguments['keyCode'] as int);
        break;
      case 'onVolumeKeyUp':
        _handleVolumeKeyUp(call.arguments['keyCode'] as int);
        break;
      case 'onConnected':
        _connectingTimer?.cancel();
        _isBluetoothConnected = true;
        _state = BluetoothState.connected;
        _errorMessage = null;
        if (call.arguments is Map) {
          final map = call.arguments as Map;
          _connectedDeviceName = map['name'] as String? ?? "Unknown Device";
          final isTv = map['isTv'] as bool? ?? false;
          final isProjector = map['isProjector'] as bool? ?? false;
          
          if (isProjector && _deviceType != DeviceType.projector) {
            _deviceType = DeviceType.projector;
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('savedDeviceType', _deviceType.toString());
            });
          } else if (isTv && _deviceType != DeviceType.tv) {
            _deviceType = DeviceType.tv;
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('savedDeviceType', _deviceType.toString());
            });
          }
        } else {
          _connectedDeviceName = call.arguments as String? ?? "Unknown Device";
        }
        
        if (isTvOrProjector) {
          _startGyro();
        } else {
          _stopGyro();
        }

        // Try to save the MAC of connected device
        final connDevice = _bondedDevices.firstWhere(
          (d) => d['name'] == _connectedDeviceName,
          orElse: () => {},
        );
        if (connDevice.isNotEmpty && connDevice['address'] != null) {
          _saveLastMac(connDevice['address']!);
        }

        final modeLabel = _deviceType == DeviceType.projector
            ? "Projector"
            : (_deviceType == DeviceType.tv ? "Smart TV" : "PC/Mac");
        showNotification(
          "Connected",
          "Connected to $_connectedDeviceName ($modeLabel Mode)",
          type: NotificationType.success,
        );
        notifyListeners();
        break;
      case 'onConnecting':
        _state = BluetoothState.scanning;
        if (call.arguments is Map) {
            _connectedDeviceName = (call.arguments as Map)['name'] as String? ?? "Unknown Device";
        } else {
            _connectedDeviceName = call.arguments as String? ?? "Unknown Device";
        }
        _connectingTimer?.cancel();
        _connectingTimer = Timer(const Duration(seconds: 8), () {
          if (_state == BluetoothState.scanning || _state == BluetoothState.pairing) {
            disconnect();
            _errorMessage = "Connection timed out. Ensure target device Bluetooth is discoverable.";
            showNotification("Connection Timeout", _errorMessage!, type: NotificationType.error);
            onConnectionTimeout?.call();
          }
        });
        showNotification(
          "Connecting",
          "Connecting to $_connectedDeviceName...",
          type: NotificationType.info,
        );
        notifyListeners();
        break;
      case 'onDisconnected':
        _connectingTimer?.cancel();
        final prevName = _connectedDeviceName;
        _isBluetoothConnected = false;
        _state = BluetoothState.disconnected;
        _connectedDeviceName = "";
        _stopGyro();
        showNotification(
          "Disconnected",
          prevName.isNotEmpty ? "Disconnected from $prevName" : "Bluetooth connection closed",
          type: NotificationType.warning,
          actionLabel: "Reconnect",
          onAction: () => connect(),
        );
        notifyListeners();
        break;
      case 'onDeviceDiscovered':
        if (call.arguments is Map) {
          final d = Map<String, String>.from(call.arguments as Map);
          final addr = d['address'] ?? '';
          if (addr.isNotEmpty && !_discoveredDevices.any((x) => x['address'] == addr)) {
            _discoveredDevices.add(d);
            notifyListeners();
          }
        }
        break;
      case 'onDiscoveryFinished':
        _isDiscovering = false;
        notifyListeners();
        break;
    }
  }
}
