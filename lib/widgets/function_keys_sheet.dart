import 'package:flutter/material.dart';
import '../services/bluetooth_hid_service.dart';

class FunctionKeysSheet extends StatelessWidget {
  final BluetoothHidService btService;
  const FunctionKeysSheet({super.key, required this.btService});

  // HID keycodes for F1–F12: 0x3A–0x45
  static const List<Map<String, dynamic>> _fnKeys = [
    {'label': 'F1', 'hid': 0x3A},
    {'label': 'F2', 'hid': 0x3B},
    {'label': 'F3', 'hid': 0x3C},
    {'label': 'F4', 'hid': 0x3D},
    {'label': 'F5', 'hid': 0x3E},
    {'label': 'F6', 'hid': 0x3F},
    {'label': 'F7', 'hid': 0x40},
    {'label': 'F8', 'hid': 0x41},
    {'label': 'F9', 'hid': 0x42},
    {'label': 'F10', 'hid': 0x43},
    {'label': 'F11', 'hid': 0x44},
    {'label': 'F12', 'hid': 0x45},
  ];

  // Special modifier combos
  static const List<Map<String, dynamic>> _modifierKeys = [
    {'label': 'Esc', 'hid': 0x29, 'mod': 0},
    {'label': 'Tab', 'hid': 0x2B, 'mod': 0},
    {'label': 'Del', 'hid': 0x4C, 'mod': 0},
    {'label': 'Home', 'hid': 0x4A, 'mod': 0},
    {'label': 'End', 'hid': 0x4D, 'mod': 0},
    {'label': 'PgUp', 'hid': 0x4B, 'mod': 0},
    {'label': 'PgDn', 'hid': 0x4E, 'mod': 0},
    {'label': 'Ins', 'hid': 0x49, 'mod': 0},
    {'label': '←', 'hid': 0x50, 'mod': 0},
    {'label': '→', 'hid': 0x4F, 'mod': 0},
    {'label': '↑', 'hid': 0x52, 'mod': 0},
    {'label': '↓', 'hid': 0x51, 'mod': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Text("Function Keys", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 12),

          // F1–F12 grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0,
            ),
            itemCount: _fnKeys.length,
            itemBuilder: (_, i) => _buildKeyButton(_fnKeys[i]['label'], _fnKeys[i]['hid'], 0, cs),
          ),

          const SizedBox(height: 16),
          Text("Navigation & Special Keys", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),

          // Modifier keys grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.0,
            ),
            itemCount: _modifierKeys.length,
            itemBuilder: (_, i) => _buildKeyButton(_modifierKeys[i]['label'], _modifierKeys[i]['hid'], _modifierKeys[i]['mod'], cs),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label, int hid, int mod, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: () => btService.sendKey(mod, [hid]),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
