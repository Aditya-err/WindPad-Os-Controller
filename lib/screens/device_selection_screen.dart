import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bluetooth_hid_service.dart';
import 'home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeviceSelectionScreen extends StatelessWidget {
  const DeviceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                "What are you\nconnecting to?",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ).animate().slideY(begin: -0.2, curve: Curves.easeOutCubic, duration: 600.ms).fadeIn(),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRow(
                      context,
                      title: "Smart TV",
                      svgContent: _tvSvg,
                      iconColor: const Color(0xFFEA4335),
                      desc: "Air mouse & TV remote",
                      type: DeviceType.tv,
                      delay: 100,
                    ),
                    _buildRow(
                      context,
                      title: "Windows",
                      svgContent: _windowsSvg,
                      iconColor: const Color(0xFF4285F4),
                      desc: "Full PC control",
                      type: DeviceType.pc,
                      delay: 200,
                    ),
                    _buildRow(
                      context,
                      title: "Mac",
                      svgContent: _macSvg,
                      iconColor: Colors.white,
                      desc: "Mac shortcuts & gestures",
                      type: DeviceType.mac,
                      delay: 300,
                    ),
                    _buildRow(
                      context,
                      title: "Linux",
                      svgContent: _linuxSvg,
                      iconColor: const Color(0xFFFBBC04),
                      desc: "Linux commands & shortcuts",
                      type: DeviceType.linux,
                      delay: 400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "You can change this anytime",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {
    required String title,
    required String svgContent,
    required Color iconColor,
    required String desc,
    required DeviceType type,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final btService = Provider.of<BluetoothHidService>(context, listen: false);
            await btService.setDeviceType(type);
            
            // FIX 14: Save to prefs FIRST
            final prefs = await SharedPreferences.getInstance();
            final deviceKey = type == DeviceType.pc ? 'windows' : type.name;
            await prefs.setString('savedDeviceType', deviceKey);

            if (type != DeviceType.tv) {
              final String prefKey = 'helper_installed_${type.name}';
              final bool isInstalled = prefs.getBool(prefKey) ?? false;
              
              if (!isInstalled && context.mounted) {
                _showSetupSheet(context, type, prefKey);
                return;
              }
            }

            if (context.mounted) {
              // FIX 14: Pass deviceType directly — no async read at HomeScreen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen(deviceType: deviceKey)),
              );
            }
          },
          highlightColor: const Color(0xFF4285F4).withValues(alpha: 0.1),
          splashColor: const Color(0xFF4285F4).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              children: [
                SvgPicture.string(
                  svgContent,
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ).animate(delay: delay.ms).slideX(begin: 0.1, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(),
    );
  }

  void _showSetupSheet(BuildContext context, DeviceType type, String prefKey) {
    String downloadUrl = '';
    String buttonText = '';
    String instructions = '';

    if (type == DeviceType.pc) {
      downloadUrl = 'https://github.com/Aditya-err/WindPad/releases/latest/download/WindpadHelper_Setup.exe';
      buttonText = '⬇ Download for Windows (.exe)';
      instructions = '1. Download the .exe file\n2. Run WindpadHelper_Setup.exe\n3. Click Install — done!\n4. A small icon appears in your taskbar tray';
    } else if (type == DeviceType.mac) {
      downloadUrl = 'https://github.com/Aditya-err/WindPad/releases/latest/download/WindpadHelper.dmg';
      buttonText = '⬇ Download for Mac (.dmg)';
      instructions = '1. Download the .dmg file\n2. Open it and drag to Applications\n3. Run WindpadHelper from Applications\n4. Allow it in Security & Privacy if asked';
    } else if (type == DeviceType.linux) {
      downloadUrl = 'https://github.com/Aditya-err/WindPad/releases/latest/download/windpad-helper_amd64.deb';
      buttonText = '⬇ Download for Linux (.deb)';
      instructions = '1. Download the .deb file\n2. Run: sudo dpkg -i windpad-helper.deb\n3. Or double-click to install with Software Center';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '💻 Setup Windpad Helper on your PC',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Download and run this small file\non your PC — only once.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
                },
                child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 24),
              Text(
                instructions,
                style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(prefKey, true);
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  if (context.mounted) {
                    final selectedDevice = type.name;
                    final deviceKey = type == DeviceType.pc ? 'windows' : selectedDevice;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => HomeScreen(deviceType: deviceKey)),
                    );
                  }
                },
                child: const Text('Already installed? Skip →', style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

const String _tvSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 3H3C1.89 3 1 3.89 1 5v12c0 1.1.89 2 2 2h5v2h8v-2h5c1.1 0 2-.9 2-2V5c0-1.11-.9-2-2-2zm0 14H3V5h18v12z" />
</svg>
''';

const String _windowsSvg = '''
<svg viewBox="0 0 122.46 122.88" xmlns="http://www.w3.org/2000/svg">
  <path d="M0,17.58 l51.8,-7.4 v48.8 h-51.8 v-41.4 z M58.9,8.2 l63.5,-8.2 v58.7 h-63.5 v-50.5 z M0,63.1 l51.8,0.1 v48.8 l-51.8,-7.4 v-41.5 z M58.9,63.1 h63.5 v59.8 l-63.5,-8.2 v-51.6 z" />
</svg>
''';

const String _macSvg = '''
<svg viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">
  <path d="M433.2 249.4c-0.6-58.4 47.7-86.8 49.9-88.2 -27.2-39.7-69.5-44.9-84.5-45.6 -35.9-3.6-70.1 21.2-88.3 21.2 -18.2 0-46.7-20.8-77-20.2 -39.9 0.6-76.7 23.2-97.1 58.7 -41.3 71.5-10.6 177.3 29.8 235.4 19.8 28.5 43.3 60.1 73.8 58.9 29.8-1.2 41.1-19.3 77.2-19.3 35.8 0 46.4 19.3 77.5 18.7 31.7-0.6 52.4-29.6 71.9-58 22.5-32.9 31.8-64.8 32.2-66.4 -0.7-0.3-61.9-23.7-65.4-95.2" />
  <path d="M371.4 100.8c16.3-19.8 27.3-47.3 24.3-74.8 -23.7 1-52.2 15.8-69.1 35.5 -13.5 15.6-26.8 43.7-23.2 70.6 26.5 2.1 51.7-11.5 68-31.3" />
</svg>
''';

const String _linuxSvg = '''
<svg viewBox="0 0 100 120" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="50" cy="78" rx="28" ry="34" fill="#1a1a1a"/>
  <ellipse cx="50" cy="84" rx="17" ry="24" fill="#f0f0f0"/>
  <circle cx="50" cy="36" r="24" fill="#1a1a1a"/>
  <ellipse cx="50" cy="38" rx="14" ry="12" fill="#f5c842"/>
  <circle cx="43" cy="30" r="5" fill="white"/>
  <circle cx="57" cy="30" r="5" fill="white"/>
  <circle cx="44" cy="30" r="2.5" fill="#1a1a1a"/>
  <circle cx="58" cy="30" r="2.5" fill="#1a1a1a"/>
  <circle cx="45" cy="29" r="1" fill="white"/>
  <circle cx="59" cy="29" r="1" fill="white"/>
  <ellipse cx="50" cy="41" rx="6" ry="4" fill="#f5a623"/>
  <ellipse cx="20" cy="76" rx="10" ry="22" fill="#1a1a1a" transform="rotate(-15 20 76)"/>
  <ellipse cx="80" cy="76" rx="10" ry="22" fill="#1a1a1a" transform="rotate(15 80 76)"/>
  <ellipse cx="37" cy="113" rx="10" ry="5" fill="#f5a623"/>
  <ellipse cx="63" cy="113" rx="10" ry="5" fill="#f5a623"/>
</svg>
''';
