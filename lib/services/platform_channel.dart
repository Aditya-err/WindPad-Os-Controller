import 'package:flutter/services.dart';

class PlatformChannel {
  static const MethodChannel _ch = MethodChannel('com.windpad/hid');

  static Future<void> sendMouseReport({required int buttons, required int dx, required int dy, required int scroll}) async {
    try {
      await _ch.invokeMethod('sendMouse', {'b': buttons, 'x': dx, 'y': dy, 's': scroll});
    } on PlatformException catch (_) {}
  }

  static Future<void> sendKeyReport({required int modifier, required List<int> keys}) async {
    try {
      await _ch.invokeMethod('sendKey', {'mod': modifier, 'keys': keys});
    } on PlatformException catch (_) {}
  }

  static Future<void> sendMediaReport({required List<int> keys}) async {
    try {
      await _ch.invokeMethod('sendMedia', {'keys': keys});
    } on PlatformException catch (_) {}
  }

  static Future<void> startAdvertising() async {
    try { await _ch.invokeMethod('startAdvert'); } on PlatformException catch (_) {}
  }

  static Future<void> disconnect() async {
    try { await _ch.invokeMethod('disconnect'); } on PlatformException catch (_) {}
  }

  static Future<bool> checkAndReconnect() async {
    try {
      return await _ch.invokeMethod<bool>('checkAndReconnect') ?? false;
    } on PlatformException catch (_) { return false; }
  }

  static Future<void> ensureServiceRunning() async {
    try { await _ch.invokeMethod('ensureServiceRunning'); } on PlatformException catch (_) {}
  }

  static Future<void> initHid() async {
    try { await _ch.invokeMethod('initHid'); } on PlatformException catch (_) {}
  }

  /// Get list of bonded Bluetooth devices [{name, address}]
  static Future<List<Map<String, String>>> getBondedDevices() async {
    try {
      final result = await _ch.invokeMethod('getBondedDevices');
      if (result is List) {
        return result.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } on PlatformException catch (_) {}
    return [];
  }

  /// Connect to a specific device by MAC address
  static Future<void> connectToDevice(String macAddress) async {
    try {
      await _ch.invokeMethod('connectToDevice', {'mac': macAddress});
    } on PlatformException catch (_) {}
  }

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    _ch.setMethodCallHandler(handler);
  }
}
