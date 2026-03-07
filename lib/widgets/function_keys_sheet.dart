import 'package:flutter/material.dart';
import '../services/bluetooth_hid_service.dart';

class FunctionKeysSheet extends StatefulWidget {
  final BluetoothHidService btService;
  const FunctionKeysSheet({super.key, required this.btService});

  @override
  State<FunctionKeysSheet> createState() => _FunctionKeysSheetState();
}

class _FunctionKeysSheetState extends State<FunctionKeysSheet> {
  int _stickyModifier = 0; // Accumulated sticky modifier

  static const List<Map<String, dynamic>> _fnKeys = [
    {'label': 'F1', 'hid': 0x3A}, {'label': 'F2', 'hid': 0x3B},
    {'label': 'F3', 'hid': 0x3C}, {'label': 'F4', 'hid': 0x3D},
    {'label': 'F5', 'hid': 0x3E}, {'label': 'F6', 'hid': 0x3F},
    {'label': 'F7', 'hid': 0x40}, {'label': 'F8', 'hid': 0x41},
    {'label': 'F9', 'hid': 0x42}, {'label': 'F10', 'hid': 0x43},
    {'label': 'F11', 'hid': 0x44}, {'label': 'F12', 'hid': 0x45},
  ];

  static const List<Map<String, dynamic>> _navKeys = [
    {'label': 'Esc', 'hid': 0x29}, {'label': 'Tab', 'hid': 0x2B},
    {'label': 'Ins', 'hid': 0x49}, {'label': 'Del', 'hid': 0x4C},
    {'label': 'Home', 'hid': 0x4A}, {'label': 'End', 'hid': 0x4D},
    {'label': 'PgUp', 'hid': 0x4B}, {'label': 'PgDn', 'hid': 0x4E},
    {'label': '←', 'hid': 0x50}, {'label': '→', 'hid': 0x4F},
    {'label': '↑', 'hid': 0x52}, {'label': '↓', 'hid': 0x51},
    {'label': 'PrtSc', 'hid': 0x46},
  ];

  static const List<Map<String, dynamic>> _mediaKeys = [
    {'label': 'Vol+', 'hid': 0x00E9}, {'label': 'Vol-', 'hid': 0x00EA},
    {'label': 'Mute', 'hid': 0x00E2}, {'label': '⏯', 'hid': 0x00CD},
    {'label': '⏭', 'hid': 0x00B5}, {'label': '⏮', 'hid': 0x00B6},
  ];

  static const List<Map<String, dynamic>> _modifierKeys = [
    {'label': 'Ctrl', 'mod': 0x01}, {'label': 'Shift', 'mod': 0x02},
    {'label': 'Alt', 'mod': 0x04}, {'label': 'Win', 'mod': 0x08},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Sticky Modifiers
            Text("Modifiers (sticky)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: _modifierKeys.map((k) => _buildModifierBtn(k, cs)).toList()),
            if (_stickyModifier > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Active: ${_modifierLabel()}", style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 16),

            Text("Function Keys", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            _buildGrid(_fnKeys, cs),

            const SizedBox(height: 16),
            Text("Navigation & System", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            _buildGrid(_navKeys, cs),

            const SizedBox(height: 16),
            Text("Media & Audio", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            _buildGrid(_mediaKeys, cs, isMedia: true),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> keys, ColorScheme cs, {bool isMedia = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 2.2,
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) => _buildKeyButton(keys[i]['label'], keys[i]['hid'], cs, isMedia: isMedia),
    );
  }

  Widget _buildKeyButton(String label, int hid, ColorScheme cs, {bool isMedia = false}) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (isMedia) {
            widget.btService.sendMedia(hid);
          } else {
            widget.btService.sendKey(_stickyModifier, [hid]);
            if (_stickyModifier > 0) setState(() => _stickyModifier = 0);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface))),
      ),
    );
  }

  Widget _buildModifierBtn(Map<String, dynamic> k, ColorScheme cs) {
    final int mod = k['mod'];
    final bool isActive = (_stickyModifier & mod) != 0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: isActive ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() {
              if (isActive) {
                _stickyModifier &= ~mod;
              } else {
                _stickyModifier |= mod;
              }
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(child: Text(k['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? cs.onPrimary : cs.onSurface))),
            ),
          ),
        ),
      ),
    );
  }

  String _modifierLabel() {
    final parts = <String>[];
    if ((_stickyModifier & 0x01) != 0) parts.add('Ctrl');
    if ((_stickyModifier & 0x02) != 0) parts.add('Shift');
    if ((_stickyModifier & 0x04) != 0) parts.add('Alt');
    if ((_stickyModifier & 0x08) != 0) parts.add('Win');
    return parts.join(' + ');
  }
}
