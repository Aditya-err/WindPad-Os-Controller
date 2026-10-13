import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_hid_service.dart';

void showDevicePickerSheet(BuildContext context, BluetoothHidService btService, ColorScheme cs) {
  btService.refreshBondedDevices();
  showModalBottomSheet(
    context: context,
    backgroundColor: cs.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => ChangeNotifierProvider.value(
      value: btService,
      child: Consumer<BluetoothHidService>(
        builder: (_, bt, __) => DevicePickerSheet(btService: bt),
      ),
    ),
  );
}

class DevicePickerSheet extends StatefulWidget {
  final BluetoothHidService btService;
  const DevicePickerSheet({super.key, required this.btService});

  @override
  State<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<DevicePickerSheet> {
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.btService.refreshBondedDevices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bt = widget.btService;

    final bonded = bt.bondedDevices.where((d) {
      final name = (d['name'] ?? '').toLowerCase();
      final addr = (d['address'] ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || addr.contains(q);
    }).toList();

    final discovered = bt.discoveredDevices.where((d) {
      final name = (d['name'] ?? '').toLowerCase();
      final addr = (d['address'] ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || addr.contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bluetooth_audio_rounded, color: cs.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bluetooth Devices",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Select any paired or nearby device to connect",
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Quick Action Bar: Make Discoverable & Scan Nearby
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await bt.connect();
                    },
                    icon: const Icon(Icons.cell_tower_rounded, size: 18),
                    label: const Text(
                      "Make Discoverable",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      if (bt.isDiscovering) {
                        await bt.stopDiscovery();
                      } else {
                        await bt.startDiscovery();
                      }
                    },
                    icon: bt.isDiscovering
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.radar_rounded, size: 18),
                    label: Text(
                      bt.isDiscovering ? "Scanning..." : "Scan Nearby",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Search devices by name or address...",
                hintStyle: TextStyle(fontSize: 12, color: cs.outline),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1B1E26) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Active Connection Banner (if connected)
          if (bt.state == BluetoothState.connected) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14291E) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Connected to ${bt.connectedDeviceName}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "Active HID session • Tap Disconnect to switch",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      bt.disconnect();
                    },
                    child: const Text("Disconnect", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 12),

          // Scrollable Device List
          Expanded(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // ── PAIRED DEVICES SECTION ──
                Row(
                  children: [
                    Text(
                      "PAIRED DEVICES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${bonded.length}",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (bonded.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.bluetooth_disabled_rounded, size: 40, color: cs.outline),
                          const SizedBox(height: 8),
                          Text("No paired devices found", style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text("Make this phone discoverable and pair from your TV or PC", style: TextStyle(fontSize: 11, color: cs.outline)),
                        ],
                      ),
                    ),
                  )
                else
                  ...bonded.map((d) => _buildDeviceCard(context, bt, d, isPaired: true, cs: cs, isDark: isDark)),

                // ── NEARBY DISCOVERED DEVICES SECTION ──
                if (bt.isDiscovering || discovered.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        "NEARBY DISCOVERED",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (bt.isDiscovering) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.8),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${discovered.length}",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (discovered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          "Scanning for nearby discoverable Bluetooth accessories...",
                          style: TextStyle(fontSize: 12, color: cs.outline),
                        ),
                      ),
                    )
                  else
                    ...discovered.map((d) => _buildDeviceCard(context, bt, d, isPaired: false, cs: cs, isDark: isDark)),
                ],

                // ── SMART TV PAIRING GUIDE CARD ──
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181C26) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tv_rounded, size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            "Smart TV & Projector Pairing Guide",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "1. Tap 'Make Discoverable' above.\n"
                        "2. On your Smart TV or Projector, go to: Settings ➔ Remotes & Accessories ➔ Add accessory.\n"
                        "3. Select your phone from the TV/Projector screen.\n\n"
                        "⚠️ Note: Do not initiate pairing from the phone's Android Bluetooth settings (that triggers Bluetooth tethering instead of remote control).",
                        style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    BluetoothHidService bt,
    Map<String, String> device, {
    required bool isPaired,
    required ColorScheme cs,
    required bool isDark,
  }) {
    final name = device['name'] ?? 'Unknown Device';
    final mac = device['address'] ?? '';
    final type = device['type'] ?? '';
    final isCurrent = bt.state == BluetoothState.connected && (bt.connectedDeviceName == name || bt.lastConnectedMac == mac);
    final isLast = mac == bt.lastConnectedMac;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? const Color(0xFF14291E) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF1A1D24) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF4CAF50)
              : (isLast ? cs.primary.withValues(alpha: 0.5) : (isDark ? Colors.white10 : Colors.black12)),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: isCurrent
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : (isLast ? cs.primaryContainer : cs.surfaceContainerHighest),
          child: Icon(
            _getDeviceIcon(name, type),
            color: isCurrent
                ? const Color(0xFF4CAF50)
                : (isLast ? cs.primary : cs.onSurfaceVariant),
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isCurrent || isLast ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13.5,
            color: cs.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              mac,
              style: TextStyle(fontSize: 11, color: cs.outline, fontFamily: 'monospace'),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text("CONNECTED", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ] else if (isLast) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("LAST CONNECTED", style: TextStyle(color: cs.onPrimaryContainer, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        trailing: isCurrent
            ? IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
                onPressed: () {},
              )
            : FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  bt.connectToDevice(mac, name);
                },
                child: const Text("Connect", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
        onTap: () {
          if (!isCurrent) {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            bt.connectToDevice(mac, name);
          }
        },
      ),
    );
  }

  IconData _getDeviceIcon(String name, String type) {
    final n = name.toLowerCase();
    if (type == 'projector' || n.contains('projector') || n.contains('nebula') || n.contains('xgimi') || n.contains('benq') || n.contains('epson') || n.contains('viewsonic') || n.contains('freestyle') || n.contains('dangbei') || n.contains('formovie')) {
      return Icons.videocam_rounded;
    }
    if (type == 'tv' || n.contains('tv') || n.contains('smart') || n.contains('bravia') || n.contains('fire')) {
      return Icons.tv_rounded;
    }
    if (type == 'computer' || n.contains('pc') || n.contains('laptop') || n.contains('desktop') || n.contains('windows')) {
      return Icons.laptop_windows_rounded;
    }
    if (n.contains('mac') || n.contains('apple')) {
      return Icons.laptop_mac_rounded;
    }
    if (type == 'phone' || n.contains('phone') || n.contains('galaxy') || n.contains('pixel') || n.contains('iphone')) {
      return Icons.phone_android_rounded;
    }
    if (type == 'peripheral' || n.contains('mouse') || n.contains('keyboard') || n.contains('controller')) {
      return Icons.gamepad_rounded;
    }
    return Icons.devices_rounded;
  }
}
