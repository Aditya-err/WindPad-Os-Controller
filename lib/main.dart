import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'theme/app_theme.dart';
import 'services/bluetooth_hid_service.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/device_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedDevice = prefs.getString('savedDeviceType');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothHidService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: WindpadApp(
        initialScreen: savedDevice != null
            ? HomeScreen(deviceType: savedDevice)
            : const DeviceSelectionScreen(),
      ),
    ),
  );
}

class WindpadApp extends StatefulWidget {
  final Widget initialScreen;
  const WindpadApp({super.key, required this.initialScreen});

  @override
  State<WindpadApp> createState() => _WindpadAppState();
}

class _WindpadAppState extends State<WindpadApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChanged);
  }

  void _onStateChanged(AppLifecycleState state) {
    if (!mounted) return;
    final bt = Provider.of<BluetoothHidService>(context, listen: false);
    if (state == AppLifecycleState.resumed) {
      if (bt.state == BluetoothState.connected) {
        WakelockPlus.enable();
      }
      bt.checkAndReconnect();
    } else if (state == AppLifecycleState.paused) {
      bt.ensureServiceRunning();
    } else if (state == AppLifecycleState.detached) {
      WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Windpad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: widget.initialScreen,
    );
  }
}
