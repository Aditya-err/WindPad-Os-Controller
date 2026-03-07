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
      {"label": "Copy", "icon": Icons.content_copy, "action": "copy"},
      {"label": "Paste", "icon": Icons.content_paste, "action": "paste"},
      {"label": "Cut", "icon": Icons.content_cut, "action": "cut"},
      {"label": "Undo", "icon": Icons.undo, "action": "undo"},
      {"label": "All", "icon": Icons.select_all, "action": "selectAll"},
      {"label": "Enter", "icon": Icons.keyboard_return, "action": "enter"},
      {"label": "Emoji", "icon": Icons.emoji_emotions_outlined, "action": "emoji"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 2.2,
      ),
      itemCount: quickKeys.length,
      itemBuilder: (context, index) {
        final key = quickKeys[index];
        return _buildKey(key["label"], key["icon"], key["action"], isConn, btService, context, cs);
      },
    );
  }

  Widget _buildKey(String label, IconData icon, String action, bool isConn, BluetoothHidService btService, BuildContext context, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isConn ? () => _handleAction(action, btService) : null,
        onLongPress: isConn && action == "enter" ? () {
          btService.sendShiftEnter();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift+Enter sent'), duration: Duration(milliseconds: 500)));
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isConn ? 1.0 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: cs.onSurface),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(String action, BluetoothHidService btService) {
    switch (action) {
      case "copy":
        btService.sendKey(0x01, [0x06]); // Ctrl+C
        break;
      case "paste":
        btService.pasteClipboard(); // Paste from clipboard char-by-char
        break;
      case "cut":
        btService.sendKey(0x01, [0x1B]); // Ctrl+X
        break;
      case "undo":
        btService.sendKey(0x01, [0x1D]); // Ctrl+Z
        break;
      case "selectAll":
        btService.sendKey(0x01, [0x04]); // Ctrl+A
        break;
      case "enter":
        btService.sendEnter();
        break;
      case "emoji":
        btService.sendEmoji();
        break;
    }
  }
}
