import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/bluetooth_hid_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothHidService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const WindpadApp(),
    ),
  );
}

class WindpadApp extends StatefulWidget {
  const WindpadApp({super.key});

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
      themeMode: themeNotifier.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
