import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_hid_service.dart';

class QuickKeysWidget extends StatelessWidget {
  const QuickKeysWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final cs = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> quickKeys = [
      {"label": "Copy", "icon": Icons.content_copy, "k": "C", "m": 0x01},
      {"label": "Paste", "icon": Icons.content_paste, "k": "V", "m": 0x01},
      {"label": "Undo", "icon": Icons.undo, "k": "Z", "m": 0x01},
      {"label": "Cut", "icon": Icons.content_cut, "k": "X", "m": 0x01},
      {"label": "All", "icon": Icons.select_all, "k": "A", "m": 0x01},
      {"label": "Enter", "icon": Icons.keyboard_return, "k": "Enter", "m": 0x00},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.8,
      ),
      itemCount: quickKeys.length,
      itemBuilder: (context, index) {
        final key = quickKeys[index];
        return _buildKey(key["label"], key["icon"], key["k"], key["m"], isConn, btService, context, cs);
      },
    );
  }

  Widget _buildKey(String label, IconData icon, String k, int modifier, bool isConn, BluetoothHidService btService, BuildContext context, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isConn ? () {
          if (k == "Enter") {
            btService.sendEnter();
          } else {
            int keycode = 0x04 + (k.codeUnitAt(0) - 'A'.codeUnitAt(0));
            btService.sendKey(modifier, [keycode]);
          }
        } : null,
        onLongPress: isConn && k == "Enter" ? () {
          btService.sendShiftEnter();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift + Enter sent'), duration: Duration(milliseconds: 500)));
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isConn ? 1.0 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: cs.onSurface),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
