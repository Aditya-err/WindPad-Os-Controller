import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_hid_service.dart';

void showDevicePickerSheet(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
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

class DevicePickerSheet extends StatelessWidget {
  final BluetoothHidService btService;
  const DevicePickerSheet({super.key, required this.btService});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final devices = btService.bondedDevices;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text("Select your device", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text("Tap a paired device to connect", style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.bluetooth_disabled, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text("No paired devices found", style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("Pair a device in Bluetooth settings first", style: TextStyle(color: cs.outline, fontSize: 12)),
                ],
              ),
            )
          else
            ...devices.map((d) {
              final name = d['name'] ?? 'Unknown';
              final mac = d['address'] ?? '';
              final isLast = mac == btService.lastConnectedMac;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLast ? cs.primaryContainer : cs.surfaceContainerHighest,
                  child: Icon(_deviceIcon(name), color: isLast ? cs.primary : cs.onSurfaceVariant, size: 20),
                ),
                title: Text(name, style: TextStyle(fontWeight: isLast ? FontWeight.w600 : FontWeight.w500)),
                subtitle: isLast ? Text("Last connected", style: TextStyle(color: cs.primary, fontSize: 12)) : null,
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: cs.outline),
                onTap: () {
                  Navigator.pop(context);
                  btService.connectToDevice(mac, name);
                },
              );
            }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await btService.refreshBondedDevices();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refresh"),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Important Pairing Step"),
                      content: const Text(
                        "To connect to Smart TVs, iPads, Macs, or Desktop PCs:\n\n"
                        "1. Stay on this app (Windpad must be running).\n"
                        "2. Go to your TV/Tablet/Desktop's Bluetooth Settings.\n"
                        "3. Find your phone in their list and pair from there.\n\n"
                        "If a PIN dialog appears on your PC/TV, type 0000 and press Enter. After the first successful pairing, it will never ask again.",
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                        FilledButton(
                          onPressed: () async {
                            Navigator.pop(c);
                            await btService.connect();
                          },
                          child: const Text("Make Phone Discoverable"),
                        )
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.bluetooth_searching, size: 18),
                label: const Text("Pair New Device"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('tv') || n.contains('smart')) return Icons.tv;
    if (n.contains('laptop') || n.contains('macbook') || n.contains('pc') || n.contains('desktop')) return Icons.laptop;
    if (n.contains('tablet') || n.contains('ipad')) return Icons.tablet;
    if (n.contains('phone') || n.contains('pixel') || n.contains('samsung') || n.contains('iphone')) return Icons.phone_android;
    return Icons.devices;
  }
}
