import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windpad/services/bluetooth_hid_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> hidCalls = [];

  setUp(() {
    hidCalls.clear();
    SharedPreferences.setMockInitialValues({});

    // Mock com.windpad/hid channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.windpad/hid'), (MethodCall call) async {
      hidCalls.add(call);
      switch (call.method) {
        case 'initHid':
          return true;
        case 'getBondedDevices':
          return [
            {'name': 'Test PC', 'address': '11:22:33:44:55:66'},
            {'name': 'Test Mac', 'address': 'AA:BB:CC:DD:EE:FF'},
          ];
        case 'connectToDevice':
          return true;
        case 'disconnect':
          return null;
        case 'sendMouse':
        case 'sendKey':
        case 'sendMedia':
        case 'startAdvert':
        case 'ensureServiceRunning':
          return null;
        case 'checkAndReconnect':
          return true;
        default:
          return null;
      }
    });

    // Mock permission_handler channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'),
            (MethodCall call) async {
      if (call.method == 'checkPermissionStatus') {
        return 1; // PermissionStatus.granted
      }
      if (call.method == 'requestPermissions') {
        final list = (call.arguments as List?) ?? [];
        return {for (var p in list) p: 1}; // 1 = granted
      }
      return 1;
    });

    // Mock sensors_plus channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
            (MethodCall call) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.windpad/hid'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/sensors/method'), null);
  });

  group('Bluetooth HID Transport Bug Fix Verification', () {
    test('Initialization invokes initHid on PlatformChannel for all profiles', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      final initHidCalls = hidCalls.where((c) => c.method == 'initHid').toList();
      expect(initHidCalls, isNotEmpty,
          reason: 'initHid must be invoked unconditionally regardless of default device type');
      service.dispose();
    });

    test('Mouse reports route to PlatformChannel on Windows PC profile', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await service.setDeviceType(DeviceType.pc);

      // Simulate connection
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Windows PC', 'isTv': false}),
        ),
        (data) {},
      );

      expect(service.state, BluetoothState.connected);
      expect(service.isBluetoothConnected, isTrue);

      hidCalls.clear();
      await service.sendMouseMove(15, -20);

      final mouseCalls = hidCalls.where((c) => c.method == 'sendMouse').toList();
      expect(mouseCalls, isNotEmpty,
          reason: 'Mouse movement must be routed to PlatformChannel for PC profile');
      expect(mouseCalls.first.arguments['x'], 15);
      expect(mouseCalls.first.arguments['y'], -20);
      expect(mouseCalls.first.arguments['b'], 0);

      service.dispose();
    });

    test('Keyboard reports route to PlatformChannel on Mac profile', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await service.setDeviceType(DeviceType.mac);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'MacBook Pro', 'isTv': false}),
        ),
        (data) {},
      );

      expect(service.deviceType, DeviceType.mac);
      expect(service.state, BluetoothState.connected);

      hidCalls.clear();
      // Send key 'a' (0x04) with no modifier
      await service.sendKey(0, [0x04]);

      final keyCalls = hidCalls.where((c) => c.method == 'sendKey').toList();
      expect(keyCalls.length, 2,
          reason: 'sendKey must dispatch press followed by release report (modifier: 0, keys: [])');
      expect(keyCalls[0].arguments['mod'], 0);
      expect(keyCalls[0].arguments['keys'], [0x04]);
      expect(keyCalls[1].arguments['mod'], 0);
      expect(keyCalls[1].arguments['keys'], isEmpty);

      service.dispose();
    });

    test('Media reports route to PlatformChannel on Linux profile', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await service.setDeviceType(DeviceType.linux);

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Linux Desktop', 'isTv': false}),
        ),
        (data) {},
      );

      expect(service.deviceType, DeviceType.linux);
      expect(service.state, BluetoothState.connected);

      hidCalls.clear();
      // Media key: Volume Up (HID 0x00E9)
      await service.sendMedia(0x00E9);

      final mediaCalls = hidCalls.where((c) => c.method == 'sendMedia').toList();
      expect(mediaCalls.length, 2,
          reason: 'sendMedia must dispatch press followed by release report to PlatformChannel');
      expect(mediaCalls[0].arguments['keys'], [0xE9, 0x00]);
      expect(mediaCalls[1].arguments['keys'], [0x00, 0x00]);

      service.dispose();
    });

    test('Switching device profile does NOT disconnect Bluetooth HID', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Living Room TV', 'isTv': true}),
        ),
        (data) {},
      );

      expect(service.state, BluetoothState.connected);

      hidCalls.clear();
      // Switch from TV to PC
      await service.setDeviceType(DeviceType.pc);

      final disconnectCalls = hidCalls.where((c) => c.method == 'disconnect').toList();
      expect(disconnectCalls, isEmpty,
          reason: 'setDeviceType must NOT call PlatformChannel.disconnect()');
      expect(service.state, BluetoothState.connected);
      expect(service.isBluetoothConnected, isTrue);

      service.dispose();
    });
  });

  group('Keyboard shortcuts & Profile features', () {
    test('Emoji shortcut adapts to useWindowsEmoji preference', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Windows PC', 'isTv': false}),
        ),
        (data) {},
      );

      // Windows emoji: Win+. (mod: 0x08, key: 0x37)
      service.setUseWindowsEmoji(true);
      hidCalls.clear();
      await service.sendEmoji();

      var keyCalls = hidCalls.where((c) => c.method == 'sendKey').toList();
      expect(keyCalls.first.arguments['mod'], 0x08);
      expect(keyCalls.first.arguments['keys'], [0x37]);

      // macOS emoji: Ctrl+Cmd+Space (mod: 0x09, key: 0x2C)
      service.setUseWindowsEmoji(false);
      hidCalls.clear();
      await service.sendEmoji();

      keyCalls = hidCalls.where((c) => c.method == 'sendKey').toList();
      expect(keyCalls.first.arguments['mod'], 0x01 | 0x08);
      expect(keyCalls.first.arguments['keys'], [0x2C]);

      service.dispose();
    });

    test('Spreadsheet mode switches Enter to Tab', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Office Laptop', 'isTv': false}),
        ),
        (data) {},
      );

      // Standard mode: Enter (0x28)
      expect(service.isSpreadsheetMode, isFalse);
      hidCalls.clear();
      await service.sendEnter();
      var keyCalls = hidCalls.where((c) => c.method == 'sendKey').toList();
      expect(keyCalls.first.arguments['keys'], [0x28]);

      // Spreadsheet mode: Tab (0x2B)
      service.toggleSpreadsheetMode();
      expect(service.isSpreadsheetMode, isTrue);
      hidCalls.clear();
      await service.sendEnter();
      keyCalls = hidCalls.where((c) => c.method == 'sendKey').toList();
      expect(keyCalls.first.arguments['keys'], [0x2B]);

      service.dispose();
    });

    test('Trackpad lock prevents mouse movement and scroll', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Target Host', 'isTv': false}),
        ),
        (data) {},
      );

      service.setTrackpadLocked(true);
      hidCalls.clear();
      await service.sendMouseMove(50, 50);
      await service.sendScroll(5);

      final mouseCalls = hidCalls.where((c) => c.method == 'sendMouse').toList();
      expect(mouseCalls, isEmpty,
          reason: 'When trackpad is locked, no mouse reports should be sent');

      service.dispose();
    });
  });

  group('Failure & Disconnect Handling', () {
    test('Sending reports when disconnected safely no-ops without exception', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.state, BluetoothState.disconnected);

      hidCalls.clear();
      await service.sendMouseMove(10, 10);
      await service.sendMouseClick(1);
      await service.sendKey(0, [0x04]);
      await service.sendMedia(0x00E9);
      await service.sendScroll(2);

      expect(hidCalls.where((c) => c.method == 'sendMouse'), isEmpty);
      expect(hidCalls.where((c) => c.method == 'sendKey'), isEmpty);
      expect(hidCalls.where((c) => c.method == 'sendMedia'), isEmpty);

      service.dispose();
    });

    test('PlatformChannel disconnect cleanly updates state to disconnected', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Target Host', 'isTv': false}),
        ),
        (data) {},
      );

      expect(service.state, BluetoothState.connected);

      await service.disconnect();

      expect(service.state, BluetoothState.disconnected);
      expect(service.isBluetoothConnected, isFalse);
      expect(service.connectedDeviceName, isEmpty);

      service.dispose();
    });

    test('Permission denial sets actionable error message and halts connection', () async {
      // Mock permission denied
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'),
              (MethodCall call) async {
        if (call.method == 'checkPermissionStatus') return 0;
        if (call.method == 'requestPermissions') {
          final list = (call.arguments as List?) ?? [];
          return {for (var p in list) p: 0}; // 0 = denied
        }
        return 0;
      });

      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.state, BluetoothState.disconnected);
      expect(service.errorMessage, isNull);

      await service.connect();

      expect(service.state, BluetoothState.disconnected);
      expect(service.errorMessage, contains('Bluetooth permissions are required'));

      service.dispose();
    });

    test('Input reports exclusively target native PlatformChannel without network fallback', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Target Host', 'isTv': false}),
        ),
        (data) {},
      );

      hidCalls.clear();
      await service.sendMouseMove(10, 20);
      await service.sendKey(0, [0x04]);
      await service.sendMedia(0x00E9);

      // Verify PlatformChannel received all calls
      expect(hidCalls.any((c) => c.method == 'sendMouse'), isTrue);
      expect(hidCalls.any((c) => c.method == 'sendKey'), isTrue);
      expect(hidCalls.any((c) => c.method == 'sendMedia'), isTrue);

      service.dispose();
    });

    test('sendText streaming aborts immediately when stopTyping is called', () async {
      final service = BluetoothHidService();
      await Future.delayed(const Duration(milliseconds: 50));

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.windpad/hid',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onConnected', {'name': 'Target Host', 'isTv': false}),
        ),
        (data) {},
      );

      hidCalls.clear();
      // Start a long paragraph sendText
      final longText = 'A' * 100;
      final sendFuture = service.sendText(longText);

      // Verify typing state started
      expect(service.isTyping, isTrue);

      // Stop typing midway
      await Future.delayed(const Duration(milliseconds: 25));
      service.stopTyping();
      await sendFuture;

      expect(service.isTyping, isFalse);
      expect(service.typingCurrent, 0);
      expect(service.typingTotal, 0);

      // Verify that release report was sent
      final emptyKeyCalls = hidCalls.where((c) => c.method == 'sendKey' && c.arguments['keys'] is List && (c.arguments['keys'] as List).isEmpty).toList();
      expect(emptyKeyCalls, isNotEmpty, reason: 'Key release report must be sent when aborting typing');

      service.dispose();
    });
  });
}
