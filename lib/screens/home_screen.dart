import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_hid_service.dart';
import '../widgets/touchpad_widget.dart';
import '../widgets/quick_keys_widget.dart';
import '../widgets/keyboard_section.dart';
import '../widgets/function_keys_sheet.dart';
import '../widgets/device_picker_sheet.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/platform_channel.dart';
import 'device_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? deviceType;
  const HomeScreen({super.key, this.deviceType});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPromptedBattery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final btService = Provider.of<BluetoothHidService>(context, listen: false);
      if (widget.deviceType != null) {
        switch (widget.deviceType) {
          case 'tv':
            btService.setDeviceType(DeviceType.tv);
            break;
          case 'projector':
            btService.setDeviceType(DeviceType.projector);
            break;
          case 'mac':
            btService.setDeviceType(DeviceType.mac);
            break;
          case 'linux':
            btService.setDeviceType(DeviceType.linux);
            break;
          case 'windows':
          case 'pc':
          default:
            btService.setDeviceType(DeviceType.pc);
            break;
        }
      }
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
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          const MethodChannel('com.windpad/hid').invokeMethod('moveToBackground');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ═══ TOP BAR ═══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      // Device Selection Chip
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const DeviceSelectionScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildDeviceIcon(btService.deviceType, cs),
                              const SizedBox(width: 6),
                              Text(
                                _deviceName(btService.deviceType),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Air/Touch Toggle (Smart TV & Projector)
                      if (btService.deviceType == DeviceType.tv || btService.deviceType == DeviceType.projector) ...[
                        InkWell(
                          onTap: () => btService.toggleAirMouse(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: btService.isAirMouse ? cs.primary : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(btService.isAirMouse ? "🌀" : "✋"),
                                const SizedBox(width: 3),
                                Text(
                                  btService.isAirMouse ? "AIR" : "TOUCH",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: btService.isAirMouse ? cs.onPrimary : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // ═══ CONNECT BUTTON (Tap to choose/scroll all Bluetooth devices) ═══
                      _buildConnectButton(context, btService, cs),

                      const SizedBox(width: 6),

                      // ═══ DPI SELECTOR ═══
                      GestureDetector(
                        onTap: () => btService.cycleDpi(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${btService.dpi} DPI",
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // ═══ SETTINGS ═══
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant, size: 21),
                        tooltip: "Settings",
                        padding: const EdgeInsets.all(5),
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),




              // ═══ SCROLLABLE CONTENT ═══
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (!isConn)
                        InkWell(
                          onTap: () => showDevicePickerSheet(context, btService, cs),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.bluetooth_searching, size: 18, color: cs.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select Bluetooth Device",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (btService.deviceType == DeviceType.tv || btService.deviceType == DeviceType.mac)
                                            ? "Tap here to view devices or pair new TV/Mac"
                                            : "Choose a paired device or scan for live nearby devices",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "CHOOSE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(),

                      const SizedBox(height: 12),

                      // Trackpad (Original compact surface)
                      const TouchpadWidget(),

                      // Trackpad lock indicator
                      if (btService.trackpadLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Center(
                            child: Text(
                              "🔒 Trackpad locked (keyboard open)",
                              style: TextStyle(fontSize: 11, color: cs.outline),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Quick Keys Grid (Copy, Paste, Cut, Undo, All, Enter)
                      if (btService.quickKeysVisible) ...[
                        const QuickKeysWidget(),
                        const SizedBox(height: 8),
                      ],

                      // Special Keys Bar (Fn, Win, Esc, Tab, Del, Prt Sc, Search)
                      _buildSpecialKeysBar(context, isConn, btService, cs),

                      const SizedBox(height: 12),

                      // Keyboard Input in the MIDDLE position
                      const KeyboardSection(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKeysBar(BuildContext context, bool isConn, BluetoothHidService btService, ColorScheme cs) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          // 1. Function Keys Sheet
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: Icons.keyboard_outlined,
              label: null,
              onTap: isConn ? () => _showFunctionKeysSheet(context, btService) : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 2. Win / Cmd / Super
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: null,
              label: btService.deviceType == DeviceType.mac
                  ? "⌘ Cmd"
                  : (btService.deviceType == DeviceType.linux ? "Super" : "⊞ Win"),
              onTap: isConn ? () => btService.sendKey(0x08, [0x00]) : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 3. Esc
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: null,
              label: "Esc",
              onTap: isConn ? () {
                if (btService.isTyping) btService.stopTyping();
                btService.sendKey(0, [0x29]);
              } : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 4. Tab
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: null,
              label: "Tab",
              onTap: isConn ? () => btService.sendKey(0, [0x2B]) : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 5. Del
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: null,
              label: "Del",
              onTap: isConn ? () {
                if (btService.isTyping) btService.stopTyping();
                btService.sendKey(0, [0x4C]);
              } : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 6. Prt Sc
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: null,
              label: "Prt Sc",
              onTap: isConn ? () => btService.sendKey(0, [0x46]) : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
          const SizedBox(width: 4),
          // 7. Search
          Expanded(
            child: _buildSpecialKeyBtn(
              icon: Icons.search_rounded,
              label: null,
              onTap: isConn
                  ? () => btService.deviceType == DeviceType.mac
                      ? btService.sendKey(0x08, [0x2C])
                      : btService.sendKey(0x08, [0x16])
                  : null,
              isConn: isConn,
              cs: cs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialKeyBtn({
    IconData? icon,
    String? label,
    VoidCallback? onTap,
    required bool isConn,
    required ColorScheme cs,
  }) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 40,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 18, color: isConn ? cs.onSurface : cs.outline)
                : Text(
                    label ?? "",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isConn ? cs.onSurface : cs.outline,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showFunctionKeysSheet(BuildContext context, BluetoothHidService btService) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: FunctionKeysSheet(btService: btService),
        ),
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
    final isConn = btService.state == BluetoothState.connected;
    final isScanning = btService.state == BluetoothState.scanning;

    if (isConn) {
      return Material(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => showDevicePickerSheet(context, btService, cs),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Text(
                    btService.connectedDeviceName.isEmpty ? "Connected" : btService.connectedDeviceName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF4CAF50)),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: isScanning ? cs.primaryContainer : cs.primary,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        onTap: () => showDevicePickerSheet(context, btService, cs),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isScanning)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimaryContainer),
                )
              else
                Icon(Icons.bluetooth, size: 15, color: cs.onPrimary),
              const SizedBox(width: 5),
              Text(
                isScanning ? "Connecting..." : "Connect",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isScanning ? cs.onPrimaryContainer : cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(DeviceType type, ColorScheme cs) {
    switch (type) {
      case DeviceType.tv:
        return Image.asset('assets/devices/smart-tv.png', width: 18, height: 18, fit: BoxFit.contain);
      case DeviceType.projector:
        return SvgPicture.asset('assets/devices/projector.svg', width: 18, height: 18);
      case DeviceType.mac:
        return SvgPicture.asset('assets/devices/apple.svg', width: 18, height: 18, colorFilter: ColorFilter.mode(cs.onSurfaceVariant, BlendMode.srcIn));
      case DeviceType.linux:
        return SvgPicture.asset('assets/devices/linux.svg', width: 18, height: 18);
      case DeviceType.pc:
        return SvgPicture.asset('assets/devices/windows_11.svg', width: 18, height: 18);
    }
  }

  String _deviceName(DeviceType type) {
    switch (type) {
      case DeviceType.tv:
        return "Smart TV";
      case DeviceType.projector:
        return "Projector";
      case DeviceType.mac:
        return "Mac";
      case DeviceType.linux:
        return "Linux";
      case DeviceType.pc:
        return "PC / Desktop";
    }
  }
}
