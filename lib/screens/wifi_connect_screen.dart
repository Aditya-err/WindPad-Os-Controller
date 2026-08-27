import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_hid_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WifiConnectScreen extends StatefulWidget {
  const WifiConnectScreen({super.key});

  @override
  State<WifiConnectScreen> createState() => _WifiConnectScreenState();
}

class _WifiConnectScreenState extends State<WifiConnectScreen> {
  bool _isScanning = false;
  MDnsClient? _mdnsClient;
  RawDatagramSocket? _udpSocket;
  final List<Map<String, dynamic>> _discoveredDevices = [];
  
  @override
  void initState() {
    super.initState();
    _startMdnsDiscovery();
  }
  
  @override
  void dispose() {
    _mdnsClient?.stop();
    _udpSocket?.close();
    super.dispose();
  }

  Future<void> _startUdpDiscovery() async {
    _udpSocket?.close();
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8766);
      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _udpSocket!.receive();
          if (dg != null) {
            String msg = utf8.decode(dg.data);
            if (msg.startsWith("WINDPAD:")) {
              final parts = msg.split(':');
              if (parts.length >= 5) {
                final ipAddr = parts[1];
                final port = int.tryParse(parts[2]) ?? 8765;
                final name = parts[3];
                final osType = parts[4];
                if (mounted) {
                  setState(() {
                    if (!_discoveredDevices.any((d) => d['ip'] == ipAddr)) {
                      _discoveredDevices.add({
                        'name': name,
                        'ip': ipAddr,
                        'port': port,
                        'os': osType,
                      });
                    }
                  });
                }
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint("UDP discover error: \$e");
    }
  }

  Future<void> _startMdnsDiscovery() async {
    _startUdpDiscovery();
    setState(() {
      _discoveredDevices.clear();
    });
    _mdnsClient?.stop();
    _mdnsClient = MDnsClient();
    await _mdnsClient!.start();

    try {
      await for (final PtrResourceRecord ptr in _mdnsClient!.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_windpad._tcp.local.'))) {
        await for (final SrvResourceRecord srv in _mdnsClient!.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {

          String osType = 'windows';
          await for (final TxtResourceRecord txt in _mdnsClient!.lookup<TxtResourceRecord>(
              ResourceRecordQuery.text(ptr.domainName))) {
             if (txt.text.toLowerCase().contains("os=darwin") || txt.text.toLowerCase().contains("os=mac")) {
                osType = 'mac';
             } else if (txt.text.toLowerCase().contains("os=linux")) {
                osType = 'linux';
             }
          }

          await for (final IPAddressResourceRecord ip in _mdnsClient!.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
             
             final String ipAddr = ip.address.address;
             final int port = srv.port;
             final String name = ptr.domainName.split('.').first;
             
             if (mounted) {
               setState(() {
                 // Prevent duplicates
                 if (!_discoveredDevices.any((d) => d['ip'] == ipAddr)) {
                   _discoveredDevices.add({
                     'name': name,
                     'ip': ipAddr,
                     'port': port,
                     'os': osType,
                   });
                 }
               });
             }
          }
        }
      }
    } catch (e) {
      debugPrint("mDNS discover error: \$e");
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final String? code = capture.barcodes.first.rawValue;
    if (code == null) return;
    
    // Support formats:
    // 1. windpad://192.168.x.x:8765
    // 2. windpad://connect?ip=X.X.X.X&port=8765
    if (code.startsWith("windpad://")) {
      String ip = "";
      int port = 8765;

      if (code.contains("?ip=")) {
        final uri = Uri.parse(code);
        ip = uri.queryParameters['ip'] ?? "";
        port = int.tryParse(uri.queryParameters['port'] ?? "8765") ?? 8765;
      } else {
        final raw = code.replaceAll("windpad://", "");
        if (raw.contains(":")) {
          final parts = raw.split(":");
          ip = parts[0];
          port = int.tryParse(parts[1]) ?? 8765;
        } else {
          ip = raw;
        }
      }
      
      if (ip.isNotEmpty) {
        final btService = Provider.of<BluetoothHidService>(context, listen: false);
        btService.connectToWifiTcp(ip, port);
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final cs = Theme.of(context).colorScheme;
    final ip = btService.localIp;

    if (btService.state == BluetoothState.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Connect to PC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isScanning) ...[
                const Text(
                  "Scan QR Code on your PC",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: MobileScanner(
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => setState(() => _isScanning = false),
                  child: const Text("Cancel Scan", style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
              ] else ...[
                const Text(
                  "Your Local IP:",
                  style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w600),
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    ip.isNotEmpty ? ip : "Loading...",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ).animate().slideY(begin: 0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
                
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms)
                     .fade(begin: 0.5, end: 1.0, duration: 800.ms),
                    const SizedBox(width: 12),
                    const Text(
                      "Waiting for connection...",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 12),
                const Text(
                  "Companion app will auto-detect on same WiFi",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 64),
                
                // DISCOVERED DEVICES
                if (_discoveredDevices.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Nearby Devices",
                        style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _startMdnsDiscovery(),
                        icon: const Icon(Icons.refresh, color: Color(0xFF4285F4), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._discoveredDevices.map((device) {
                    final os = device['os'];
                    String assetName = 'assets/windows_icon.svg';
                    String osName = 'Windows';
                    if (os == 'mac') {
                       assetName = 'assets/mac_icon.svg';
                       osName = 'Mac';
                    } else if (os == 'linux') {
                       assetName = 'assets/linux_icon.svg';
                       osName = 'Linux';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          final btService = Provider.of<BluetoothHidService>(context, listen: false);
                          btService.connectToWifiTcp(device['ip'], device['port']);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                assetName,
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Color(0xFF4285F4), BlendMode.srcIn),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "${device['name']} ($osName) — Tap to connect",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF4285F4), size: 20),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                const Text(
                  "OR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white24),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isScanning = true),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text("Scan QR Code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ).animate(delay: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic).fadeIn(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
