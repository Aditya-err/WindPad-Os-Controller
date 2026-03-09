import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'platform_channel.dart';

enum BluetoothState { disconnected, scanning, pairing, connected }
enum DeviceType { tv, pc, mac, linux }

class BluetoothHidService extends ChangeNotifier with WidgetsBindingObserver {
  BluetoothState _state = BluetoothState.disconnected;
  DeviceType _deviceType = DeviceType.pc;
  String _connectedDeviceName = "";
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

  // WiFi TCP
  ServerSocket? _tcpServer;
  Socket? _tcpClient;
  String _localIp = "";
  final int _tcpPort = 8765;
  MDnsClient? _mdnsClient;

  DeviceType get deviceType => _deviceType;
  BluetoothState get state => _state;
  String get connectedDeviceName => _connectedDeviceName;
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
  String get localIp => _localIp;

  static const List<Color> trackpadColors = [
    Color(0xFFE8F1FF),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFF3E5F5),
    Color(0xFFECEFF1),
    Color(0xFFFFEBEE),
    Color(0xFF1A1A2E), // Dark Navy
    Color(0xFF212121), // Charcoal
    Color(0xFF000000), // Pure Black (AMOLED)
    Color(0xFF121212), // Deep Grey
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
    if (_deviceType == DeviceType.tv) {
      await PlatformChannel.initHid();
      await _autoConnect();
    } else {
      await _startWifiServer();
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
    _gyroSub = gyroscopeEventStream().listen((event) {
      if (_state != BluetoothState.connected || _deviceType != DeviceType.tv || _trackpadLocked || !_isAirMouse) return;
      
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
    });
  }

  void _stopGyro() {
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  Future<void> _requestPermissions() async {
    if (await Permission.bluetoothConnect.isDenied) {
      await [
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.bluetoothScan,
        Permission.bluetooth,
        Permission.location,
      ].request();
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
    _trackpadColorIndex = prefs.getInt('trackpadColor') ?? 0;
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

    if (_deviceType == DeviceType.tv) {
      _stopWifiServer();
      
      // Smart TV: Try WiFi (ADB) first, fallback to BT HID
      bool adbConnected = await _tryWifiAdbConnect();
      if (!adbConnected) {
        debugPrint("WiFi ADB failed/not found, falling back to Bluetooth HID");
        await PlatformChannel.initHid();
        await _autoConnect();
      }
      _startGyro();
    } else {
      _stopGyro();
      _isAirMouse = false;
      await PlatformChannel.disconnect(); // Disconnect BT
      await _startWifiServer();
    }
    notifyListeners();
  }

  Future<bool> _tryWifiAdbConnect() async {
    // Scaffold for ADB over WiFi (Port 5555) connection.
    // Full ADB RSA/TLS handshake requires native/external ADB client.
    // For now, quickly return false to trigger Bluetooth HID fallback reliably.
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Force fallback to BT HID as requested "Agar nahi hua -> Bluetooth HID fallback"
  }

  void toggleAirMouse() {
    if (_deviceType == DeviceType.tv) {
      _isAirMouse = !_isAirMouse;
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
  Future<void> connect() async {
    if (_state != BluetoothState.disconnected) return;
    final status = await Permission.bluetoothConnect.status;
    if (status.isDenied) {
      await _requestPermissions();
      final newStatus = await Permission.bluetoothConnect.status;
      if (newStatus.isDenied) return;
    }
    _state = BluetoothState.scanning;
    notifyListeners();
    await PlatformChannel.startAdvertising();
  }

  Future<void> connectToDevice(String mac, String name) async {
    if (_state == BluetoothState.connected) return;
    final status = await Permission.bluetoothConnect.status;
    if (status.isDenied) {
      await _requestPermissions();
      final newStatus = await Permission.bluetoothConnect.status;
      if (newStatus.isDenied) return;
    }
    _state = BluetoothState.scanning;
    notifyListeners();
    await _saveLastMac(mac);
    await PlatformChannel.connectToDevice(mac);
  }

  Future<void> disconnect() async {
    _connectingTimer?.cancel();
    await PlatformChannel.disconnect();
    _state = BluetoothState.disconnected;
    _connectedDeviceName = "";
    notifyListeners();
  }

  Future<bool> checkAndReconnect() async => await PlatformChannel.checkAndReconnect();
  Future<void> ensureServiceRunning() async => await PlatformChannel.ensureServiceRunning();

  // ── HID Reports ──
  int _activeButtons = 0;

  // --- WIFI TCP LOGIC ---
  Future<void> _startWifiServer() async {
    _state = BluetoothState.disconnected;
    _localIp = await NetworkInfo().getWifiIP() ?? "";
    notifyListeners();
    
    bool connected = await _tryAutoWifiConnect();
    if (!connected) {
      debugPrint("Auto-connect failed, waiting for user to scan QR...");
    }
  }

  Future<bool> _tryAutoWifiConnect() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('saved_wifi_ip');
    int? savedPort = prefs.getInt('saved_wifi_port');
    
    if (savedIp != null && savedPort != null) {
      if (await connectToWifiTcp(savedIp, savedPort)) return true;
    }

    try {
      final MDnsClient client = MDnsClient();
      await client.start();
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_windpad._tcp.local.'))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
             if (await connectToWifiTcp(ip.address.address, srv.port)) {
               client.stop();
               return true;
             }
          }
        }
      }
      client.stop();
    } catch(e) {
      debugPrint("mDNS discover error: $e");
    }
    return false;
  }

  Future<bool> connectToWifiTcp(String ip, int port) async {
    try {
      _tcpClient?.close();
      _tcpClient = await Socket.connect(ip, port, timeout: const Duration(seconds: 3));
      
      _state = BluetoothState.connected;
      _connectedDeviceName = "PC Companion";
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_wifi_ip', ip);
      await prefs.setInt('saved_wifi_port', port);

      _tcpClient!.listen(
        (data) {}, 
        onDone: () {
          _tcpClient = null;
          if (_deviceType != DeviceType.tv) _state = BluetoothState.disconnected;
          notifyListeners();
        }, 
        onError: (_) {
          _tcpClient = null;
          if (_deviceType != DeviceType.tv) _state = BluetoothState.disconnected;
          notifyListeners();
        }
      );
      return true;
    } catch(e) {
      debugPrint("TCP Connect error: $e");
      return false;
    }
  }

  void _stopWifiServer() {
    _tcpClient?.close();
    _tcpClient = null;
    _tcpServer?.close();
    _tcpServer = null;
    if (_deviceType != DeviceType.tv) {
      _state = BluetoothState.disconnected;
      notifyListeners();
    }
  }

  void _sendTcp(String type, Map<String, dynamic> payload) {
    if (_deviceType == DeviceType.tv) return;
    if (_tcpClient != null) {
      payload['type'] = type;
      _tcpClient!.write('${jsonEncode(payload)}\n');
    }
  }

  Future<void> _sendMouseReport({required int buttons, required int dx, required int dy, required int scroll}) async {
    if (_deviceType == DeviceType.tv) {
      await PlatformChannel.sendMouseReport(buttons: buttons, dx: dx, dy: dy, scroll: scroll);
    } else {
      _sendTcp('mouse', {'buttons': buttons, 'dx': dx, 'dy': dy, 'scroll': scroll});
    }
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
    if (_deviceType == DeviceType.tv) {
      await PlatformChannel.sendKeyReport(modifier: modifier, keys: keys);
      await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
    } else {
      _sendTcp('key', {'modifier': modifier, 'keys': keys});
    }
  }

  Future<void> sendMedia(int hid) async {
    if (_state != BluetoothState.connected) return;
    if (_hapticFeedback) HapticFeedback.lightImpact();
    if (_deviceType == DeviceType.tv) {
      await PlatformChannel.sendMediaReport(keys: [hid & 0xFF, (hid >> 8) & 0xFF]);
      await PlatformChannel.sendMediaReport(keys: [0, 0]);
    } else {
      _sendTcp('media', {'hid': hid});
    }
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

  /// Paste clipboard text char-by-char preserving formatting
  Future<void> pasteClipboard() async {
    if (_state != BluetoothState.connected) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    final text = data.text!;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '\n') {
        if (_deviceType == DeviceType.tv) {
          await PlatformChannel.sendKeyReport(modifier: 0, keys: [0x28]);
          await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
        } else {
          _sendTcp('key', {'modifier': 0, 'keys': [0x28]});
        }
      } else if (char == '\t') {
        if (_deviceType == DeviceType.tv) {
          await PlatformChannel.sendKeyReport(modifier: 0, keys: [0x2B]);
          await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
        } else {
          _sendTcp('key', {'modifier': 0, 'keys': [0x2B]});
        }
      } else {
        final keycode = _mapCharCodeToHid(char);
        final modifier = _getModifierForChar(char);
        if (keycode != 0) {
          if (_deviceType == DeviceType.tv) {
            await PlatformChannel.sendKeyReport(modifier: modifier, keys: [keycode]);
            await PlatformChannel.sendKeyReport(modifier: 0, keys: []);
          } else {
            _sendTcp('key', {'modifier': modifier, 'keys': [keycode]});
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 8));
    }
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    final char = text[0];
    final keycode = _mapCharCodeToHid(char);
    final modifier = _getModifierForChar(char);
    if (keycode != 0) await sendKey(modifier, [keycode]);
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
    if (_state != BluetoothState.connected || _deviceType != DeviceType.tv) return;
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
    if (_state != BluetoothState.connected || _deviceType != DeviceType.tv) return;
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
        _state = BluetoothState.connected;
        if (call.arguments is Map) {
          final map = call.arguments as Map;
          _connectedDeviceName = map['name'] as String? ?? "Unknown Device";
          final isTv = map['isTv'] as bool? ?? false;
          
          // App automatically detects TV type when connected
          if (isTv && _deviceType != DeviceType.tv) {
            _deviceType = DeviceType.tv;
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('savedDeviceType', _deviceType.toString());
            });
          }
        } else {
          _connectedDeviceName = call.arguments as String? ?? "Unknown Device";
        }
        
        if (_deviceType == DeviceType.tv) _startGyro();
        else _stopGyro();

        // Try to save the MAC of connected device
        final connDevice = _bondedDevices.firstWhere(
          (d) => d['name'] == _connectedDeviceName,
          orElse: () => {},
        );
        if (connDevice.isNotEmpty && connDevice['address'] != null) {
          _saveLastMac(connDevice['address']!);
        }
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
            onConnectionTimeout?.call();
          }
        });
        notifyListeners();
        break;
      case 'onDisconnected':
        _connectingTimer?.cancel();
        _state = BluetoothState.disconnected;
        _connectedDeviceName = "";
        _stopGyro();
        notifyListeners();
        break;
    }
  }
}
