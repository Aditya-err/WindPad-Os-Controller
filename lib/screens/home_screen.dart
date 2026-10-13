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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildDeviceIcon(btService.deviceType, cs),
                            const SizedBox(width: 8),
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
                    const SizedBox(width: 8),

                    // Air/Touch Toggle (Only for Smart TV)
                    if (btService.deviceType == DeviceType.tv) ...[
                      InkWell(
                        onTap: () => btService.toggleAirMouse(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: btService.isAirMouse ? cs.primary : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(btService.isAirMouse ? "🌀" : "✋"),
                              const SizedBox(width: 4),
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
                    ],

                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showDevicePicker(context, btService, cs),
                      child: StatusPill(state: btService.state, deviceName: btService.connectedDeviceName),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => btService.cycleDpi(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${btService.dpi} DPI",
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              // ═══ ACTIVE PASTE / TYPING BANNER WITH INSTANT ABORT ═══
              if (btService.isTyping)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Pasting Paragraph...",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              "${btService.typingCurrent} of ${btService.typingTotal} characters sent",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD32F2F),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          btService.stopTyping();
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⏹ Paste stopped immediately"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.stop, size: 16, color: Color(0xFFD32F2F)),
                        label: const Text("STOP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                        InkWell(
                          onTap: () => _showDevicePicker(context, btService, cs),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: cs.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (btService.deviceType == DeviceType.tv || btService.deviceType == DeviceType.mac)
                                        ? "TV/Mac: Tap here → 'Pair New Device' to make phone discoverable."
                                        : "Ready to connect. Tap here or status pill to select device.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
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

  void _showDevicePicker(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
    btService.refreshBondedDevices();
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: btService,
        child: Consumer<BluetoothHidService>(
          builder: (_, bt, __) => DevicePickerSheet(btService: bt),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(DeviceType type, ColorScheme cs) {
    switch (type) {
      case DeviceType.tv:
        return Image.asset('assets/devices/smart-tv.png', width: 18, height: 18, fit: BoxFit.contain);
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
      case DeviceType.mac:
        return "Mac";
      case DeviceType.linux:
        return "Linux";
      case DeviceType.pc:
        return "PC / Desktop";
    }
  }
}
