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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final cs = Theme.of(context).colorScheme;

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
                    Text("Windpad", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (!isConn)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text("Ready to connect. Ensure Bluetooth is on.", style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500))),
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

                    // Special Keys Bar: ⊞ Windows button opens full sheet
                    _buildSpecialKeysBar(context, isConn, btService, cs),

                    const SizedBox(height: 12),

                    // Keyboard Input
                    const KeyboardSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: !isConn
            ? FloatingActionButton.extended(
                onPressed: btService.state == BluetoothState.scanning
                    ? null
                    : () => _showDevicePicker(context, btService, cs),
                icon: btService.state == BluetoothState.scanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bluetooth_searching),
                label: Text(btService.state == BluetoothState.scanning ? "Connecting…" : "Connect"),
              )
            : null,
      ),
    );
  }
  
  Widget _buildSpecialKeysBar(BuildContext context, bool isConn, BluetoothHidService btService, ColorScheme cs) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Long-press any key to open full sheet; small hint button
            Material(
              color: cs.secondaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: isConn ? () => _showFunctionKeysSheet(context, btService) : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Icon(Icons.keyboard_outlined, size: 16, color: isConn ? cs.onSecondaryContainer : cs.outline),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildMiniKey("⊞ Win", () => btService.sendKey(0x08, [0x00]), isConn, cs),
            const SizedBox(width: 6),
            _buildMiniKey("Esc", () => btService.sendKey(0, [0x29]), isConn, cs),
            const SizedBox(width: 6),
            _buildMiniKey("Tab", () => btService.sendKey(0, [0x2B]), isConn, cs),
            const SizedBox(width: 6),
            _buildMiniKey("Del", () => btService.sendKey(0, [0x4C]), isConn, cs),
            const SizedBox(width: 6),
            _buildMiniKey("Prt Sc", () => btService.sendKey(0, [0x46]), isConn, cs),
            const SizedBox(width: 6),
            _buildMiniKey("🔍 Search", () => btService.sendKey(0x08, [0x16]), isConn, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKey(String label, VoidCallback onAct, bool isConn, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isConn ? onAct : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isConn ? cs.onSurface : cs.outline)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: btService,
        child: Consumer<BluetoothHidService>(
          builder: (_, bt, __) => DevicePickerSheet(btService: bt),
        ),
      ),
    );
  }
}
