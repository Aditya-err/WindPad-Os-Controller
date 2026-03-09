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
                      iconColor: Colors.white,
                      desc: "Air mouse & TV remote",
                      type: DeviceType.tv,
                      delay: 100,
                    ),
                    _buildRow(
                      context,
                      title: "Windows",
                      svgContent: _windowsSvg,
                      iconColor: const Color(0xFF0078D6),
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
                      iconColor: Colors.white,
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
            
            if (type != DeviceType.tv) {
              final prefs = await SharedPreferences.getInstance();
              final String prefKey = 'helper_installed_\${type.name}';
              final bool isInstalled = prefs.getBool(prefKey) ?? false;
              
              if (!isInstalled && context.mounted) {
                // Show setup bottom sheet
                _showSetupSheet(context, type, prefKey);
                return;
              }
            }

            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
<svg viewBox="0 0 93.56 122.88" xmlns="http://www.w3.org/2000/svg">
  <path d="M60.2,7C60.2,7,44.9-5,29.9,2.8C20,7.9,13.7,19.9,11.8,31C8.8,49.2,14.6,67.6,18.8,85.2 C19.6,88.7,20.2,92.5,23.1,94.9c5.3,4.4,14.1,4.7,20.5,6c9.8,2,20.1,2.8,30.1,2.5c6.5-0.2,14.6-2.1,19.2-7C97.1,91.8,93.4,85.3,92.6,82 C88.3,64.4,94,44.9,90.4,27.1C87.4,11.4,72.6-3.8,60.2,7z M48.2,19.8C54,19.8,59,24,60.1,29.7c1.1,5.6-1.8,11.7-6.8,14.4 c-4.9,2.7-11.4,1.4-15-2.8c-3.6-4.2-3.8-10.9-0.5-15.3C40.6,22,44.5,19.8,48.2,19.8z M27.8,23.3c3.5,0,6.6,2.5,7.3,5.9c0.7,3.4-1.1,7.1-4.1,8.7c-3,1.6-6.9,0.8-9.1-1.7C19.7,33.7,19.6,29.7,21.6,27C23.1,24.8,25.4,23.3,27.8,23.3z" />
</svg>
''';
