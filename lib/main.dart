import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/bluetooth_hid_service.dart';
import 'screens/home_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'screens/device_selection_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final savedStr = prefs.getString('savedDeviceType');
  final bool hasSavedDevice = savedStr != null;
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothHidService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: WindpadApp(hasSavedDevice: hasSavedDevice, hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class WindpadApp extends StatefulWidget {
  final bool hasSavedDevice;
  final bool hasSeenOnboarding;
  const WindpadApp({super.key, required this.hasSavedDevice, required this.hasSeenOnboarding});

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
      bt.checkAndReconnect();
    } else if (state == AppLifecycleState.paused) {
      bt.ensureServiceRunning();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
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
      home: widget.hasSeenOnboarding 
          ? (widget.hasSavedDevice ? const HomeScreen() : const DeviceSelectionScreen()) 
          : const OnboardingScreen(),
    );
  }
}
