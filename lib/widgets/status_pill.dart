import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/bluetooth_hid_service.dart';

class StatusPill extends StatelessWidget {
  final BluetoothState state;
  final String deviceName;

  const StatusPill({super.key, required this.state, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color dotColor;
    Color bgColor;
    Color textColor;
    String label;
    final isScanning = state == BluetoothState.scanning || state == BluetoothState.pairing;

    switch (state) {
      case BluetoothState.connected:
        dotColor = const Color(0xFF386A20);
        bgColor = cs.primaryContainer;
        textColor = cs.primary;
        label = deviceName.isNotEmpty ? deviceName : "Connected";
        break;
      case BluetoothState.scanning:
        dotColor = cs.primary;
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        label = "Searching…";
        break;
      case BluetoothState.pairing:
        dotColor = cs.primary;
        bgColor = cs.tertiaryContainer;
        textColor = cs.onTertiaryContainer;
        label = "Pairing…";
        break;
      case BluetoothState.disconnected:
        dotColor = cs.outline;
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurfaceVariant;
        label = "Not connected";
        break;
    }

    Widget dot = Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        boxShadow: state == BluetoothState.connected ? [BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 6)] : null,
      ),
    );

    if (isScanning) {
      dot = dot.animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 1.0, end: 0.3, duration: 450.ms);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
