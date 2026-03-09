import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_hid_service.dart';
import '../widgets/status_pill.dart';
import '../widgets/touchpad_widget.dart';
import '../widgets/quick_keys_widget.dart';
import '../widgets/keyboard_section.dart';
import '../widgets/function_keys_sheet.dart';
import '../widgets/device_controls_widget.dart';
import '../widgets/device_picker_sheet.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/platform_channel.dart';
import 'device_selection_screen.dart';
import 'wifi_connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPromptedBattery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BluetoothHidService>(context, listen: false).onConnectionTimeout = () {
        if (!mounted) return;
        _showDevicePicker(context, Provider.of<BluetoothHidService>(context, listen: false), Theme.of(context).colorScheme);
      };
    });
  }

  Future<void> _checkAndPromptBatteryOptimization(ColorScheme cs) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('battery_optimization_requested') == true) return;
    await prefs.setBool('battery_optimization_requested', true);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text("Background Connection", style: TextStyle(color: cs.onSurface)),
          content: Text("Keep Windpad connected in background?", style: TextStyle(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); },
              child: Text("No", style: TextStyle(color: cs.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              onPressed: () {
                Navigator.pop(ctx);
                PlatformChannel.requestBatteryOptimization();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final cs = Theme.of(context).colorScheme;

    if (isConn && !_hasPromptedBattery) {
      _hasPromptedBattery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptBatteryOptimization(cs);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          const MethodChannel('com.windpad/hid').invokeMethod('moveToBackground');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ═══ TOP BAR ═══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Device Selection Chip
                    InkWell(
                      onTap: () {
                        // Keep current device type mostly empty but push the selection screen to change it.
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            SvgPicture.string(
                              _getSvgForDevice(btService.deviceType),
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                btService.deviceType == DeviceType.pc ? const Color(0xFF0078D6) : Colors.white, 
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(_deviceName(btService.deviceType), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Air/Touch Toggle (Only for Smart TV)
                    if (btService.deviceType == DeviceType.tv) ...[
                      InkWell(
                        onTap: () => btService.toggleAirMouse(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: btService.isAirMouse ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Text(btService.isAirMouse ? "🌀" : "✋"),
                              const SizedBox(width: 4),
                              Text(
                                btService.isAirMouse ? "AIR" : "TOUCH", 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: btService.isAirMouse ? cs.onPrimary : cs.onSurfaceVariant)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    StatusPill(state: btService.state, deviceName: btService.connectedDeviceName),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => btService.cycleDpi(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text("${btService.dpi} DPI", style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),

              // ═══ SCROLLABLE CONTENT ═══
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                    if (!isConn)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              btService.deviceType == DeviceType.tv
                                  ? "Ready to connect. Ensure Bluetooth is on."
                                  : "Ready to connect. Open Windpad Companion App on PC to scan.",
                              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ).animate().fadeIn(),

                    const SizedBox(height: 12),

                    // Trackpad
                    const AspectRatio(aspectRatio: 0.95, child: TouchpadWidget()),

                    // Trackpad lock indicator
                    if (btService.trackpadLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Center(child: Text("🔒 Trackpad locked (keyboard open)", style: TextStyle(fontSize: 11, color: cs.outline))),
                      ),

                    const SizedBox(height: 12),

                    // Quick Keys
                    if (btService.quickKeysVisible) ...[
                      const QuickKeysWidget(),
                      const SizedBox(height: 8),
                    ],

                    // Special Device Aware UI
                    DeviceControlsWidget(
                      isConn: isConn,
                      btService: btService,
                      cs: cs,
                    ),

                    const SizedBox(height: 12),

                    // Keyboard Input
                    const KeyboardSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: !isConn
            ? FloatingActionButton.extended(
                onPressed: btService.deviceType == DeviceType.tv
                    ? (btService.state == BluetoothState.scanning
                        ? () {
                            btService.disconnect();
                            _showDevicePicker(context, btService, cs);
                          }
                        : () => _showDevicePicker(context, btService, cs))
                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiConnectScreen())),
                icon: btService.deviceType == DeviceType.tv
                    ? (btService.state == BluetoothState.scanning
                        ? const Icon(Icons.close)
                        : const Icon(Icons.bluetooth_searching))
                    : const Icon(Icons.qr_code_scanner),
                label: Text(btService.deviceType == DeviceType.tv
                    ? (btService.state == BluetoothState.scanning ? "Cancel" : "Connect")
                    : "Show QR Code"),
              )
            : null,
      ),
    );
  }
  


  void _showFunctionKeysSheet(BuildContext context, BluetoothHidService btService) {
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FunctionKeysSheet(btService: btService),
      );
    }
  }

  void _showDevicePicker(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
    btService.refreshBondedDevices();
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: btService,
        child: Consumer<BluetoothHidService>(
          builder: (_, bt, __) => DevicePickerSheet(btService: bt),
        ),
      ),
    );
  }

  String _getSvgForDevice(DeviceType type) {
    switch (type) {
      case DeviceType.tv: return _tvSvg;
      case DeviceType.mac: return _macSvg;
      case DeviceType.linux: return _linuxSvg;
      case DeviceType.pc: default: return _windowsSvg;
    }
  }

  String _deviceName(DeviceType type) {
    switch (type) {
      case DeviceType.tv: return "Smart TV";
      case DeviceType.mac: return "Mac";
      case DeviceType.linux: return "Linux";
      case DeviceType.pc: default: return "PC / Desktop";
    }
  }
}

const String _tvSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 3H3C1.89 3 1 3.89 1 5v12c0 1.1.89 2 2 2h5v2h8v-2h5c1.1 0 2-.9 2-2V5c0-1.11-.9-2-2-2zm0 14H3V5h18v12z" />
</svg>
''';

const String _windowsSvg = '''
<svg viewBox="0 0 122.46 122.88" xmlns="http://www.w3.org/2000/svg">
  <path d="M0,17.58 l51.8,-7.4 v48.8 h-51.8 v-41.4 z M58.9,8.2 l63.5,-8.2 v58.7 h-63.5 v-50.5 z M0,63.1 l51.8,0.1 v48.8 l-51.8,-7.4 v-41.5 z M58.9,63.1 h63.5 v59.8 l-63.5,-8.2 v-51.6 z" />
</svg>
''';

const String _macSvg = '''
<svg viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">
  <path d="M433.2 249.4c-0.6-58.4 47.7-86.8 49.9-88.2 -27.2-39.7-69.5-44.9-84.5-45.6 -35.9-3.6-70.1 21.2-88.3 21.2 -18.2 0-46.7-20.8-77-20.2 -39.9 0.6-76.7 23.2-97.1 58.7 -41.3 71.5-10.6 177.3 29.8 235.4 19.8 28.5 43.3 60.1 73.8 58.9 29.8-1.2 41.1-19.3 77.2-19.3 35.8 0 46.4 19.3 77.5 18.7 31.7-0.6 52.4-29.6 71.9-58 22.5-32.9 31.8-64.8 32.2-66.4 -0.7-0.3-61.9-23.7-65.4-95.2" />
  <path d="M371.4 100.8c16.3-19.8 27.3-47.3 24.3-74.8 -23.7 1-52.2 15.8-69.1 35.5 -13.5 15.6-26.8 43.7-23.2 70.6 26.5 2.1 51.7-11.5 68-31.3" />
</svg>
''';

const String _linuxSvg = '''
<svg viewBox="0 0 93.56 122.88" xmlns="http://www.w3.org/2000/svg">
  <path d="M60.2,7C60.2,7,44.9-5,29.9,2.8C20,7.9,13.7,19.9,11.8,31C8.8,49.2,14.6,67.6,18.8,85.2 C19.6,88.7,20.2,92.5,23.1,94.9c5.3,4.4,14.1,4.7,20.5,6c9.8,2,20.1,2.8,30.1,2.5c6.5-0.2,14.6-2.1,19.2-7C97.1,91.8,93.4,85.3,92.6,82 C88.3,64.4,94,44.9,90.4,27.1C87.4,11.4,72.6-3.8,60.2,7z M48.2,19.8C54,19.8,59,24,60.1,29.7c1.1,5.6-1.8,11.7-6.8,14.4 c-4.9,2.7-11.4,1.4-15-2.8c-3.6-4.2-3.8-10.9-0.5-15.3C40.6,22,44.5,19.8,48.2,19.8z M27.8,23.3c3.5,0,6.6,2.5,7.3,5.9c0.7,3.4-1.1,7.1-4.1,8.7c-3,1.6-6.9,0.8-9.1-1.7C19.7,33.7,19.6,29.7,21.6,27C23.1,24.8,25.4,23.3,27.8,23.3z" />
</svg>
''';
