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
                    // DPI badge
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
                          style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
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
                    // Connection banner
                    if (!isConn)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Text("Ready to connect. Ensure Bluetooth is on.", style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ).animate().fadeIn(),

                    const SizedBox(height: 12),

                    // ── Trackpad ──
                    const AspectRatio(
                      aspectRatio: 1.2,
                      child: TouchpadWidget(),
                    ),

                    const SizedBox(height: 16),

                    // ── Quick Keys + Fn Button Row ──
                    if (btService.quickKeysVisible) ...[
                      const QuickKeysWidget(),
                      const SizedBox(height: 12),
                    ],

                    // ── Function Keys Button ──
                    _buildFnButton(context, isConn, btService, cs),

                    const SizedBox(height: 12),

                    // ── Keyboard Input (at bottom) ──
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
                onPressed: btService.state == BluetoothState.scanning ? null : () => btService.connect(),
                icon: btService.state == BluetoothState.scanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bluetooth_searching),
                label: Text(btService.state == BluetoothState.scanning ? "Connecting…" : "Connect"),
              )
            : null,
      ),
    );
  }

  Widget _buildFnButton(BuildContext context, bool isConn, BluetoothHidService btService, ColorScheme cs) {
    return Material(
      color: cs.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isConn ? () => _showFunctionKeysSheet(context, btService, cs) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_command_key, size: 18, color: isConn ? cs.onSecondaryContainer : cs.outline),
              const SizedBox(width: 8),
              Text(
                "Function Keys (F1–F12)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isConn ? cs.onSecondaryContainer : cs.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFunctionKeysSheet(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FunctionKeysSheet(btService: btService),
    );
  }
}
