import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_hid_service.dart';
import 'home_screen.dart';

class DeviceSelectionScreen extends StatelessWidget {
  const DeviceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Exact color palette extracted from website/assets/Dark theme/select device.jpg
    // and website/assets/light theme/Select device.jpg
    final backgroundColor = isDark ? const Color(0xFF111215) : const Color(0xFFF4F5F9);
    final cardBgColor = isDark ? const Color(0xFF282A31) : const Color(0xFFE0E3EA);
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1E24);
    final subtitleColor = isDark ? const Color(0xFF8E929E) : const Color(0xFF606470);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Title: "Select Device"
              Text(
                "Select Device",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle: "What do you want to control?"
              Text(
                "What do you want to control?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 40),

              // 2x2 Grid exactly matching website/assets/Dark theme/select device.jpg
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  physics: const BouncingScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.74,
                  children: [
                    // 1. Smart TV
                    _buildDeviceCard(
                      context: context,
                      btService: btService,
                      title: "Smart TV",
                      subtitle: "With Air Mouse & TV Remote",
                      assetPath: "assets/devices/smart-tv.png",
                      isPng: true,
                      type: DeviceType.tv,
                      cardBg: cardBgColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),

                    // 2. PC / Desktop
                    _buildDeviceCard(
                      context: context,
                      btService: btService,
                      title: "PC / Desktop",
                      subtitle: "Standard trackpad & keyboard",
                      assetPath: "assets/devices/windows_11.svg",
                      isPng: false,
                      type: DeviceType.pc,
                      cardBg: cardBgColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),

                    // 3. Mac
                    _buildDeviceCard(
                      context: context,
                      btService: btService,
                      title: "Mac",
                      subtitle: "Standard trackpad & keyboard",
                      assetPath: "assets/devices/apple.svg",
                      isPng: false,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : const Color(0xFF1C1E24),
                        BlendMode.srcIn,
                      ),
                      type: DeviceType.mac,
                      cardBg: cardBgColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),

                    // 4. Linux
                    _buildDeviceCard(
                      context: context,
                      btService: btService,
                      title: "Linux",
                      subtitle: "Standard trackpad & keyboard",
                      assetPath: "assets/devices/linux.svg",
                      isPng: false,
                      type: DeviceType.linux,
                      cardBg: cardBgColor,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required BuildContext context,
    required BluetoothHidService btService,
    required String title,
    required String subtitle,
    required String assetPath,
    required bool isPng,
    ColorFilter? colorFilter,
    required DeviceType type,
    required Color cardBg,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await btService.setDeviceType(type);

          final prefs = await SharedPreferences.getInstance();
          final deviceKey = type == DeviceType.pc ? 'windows' : type.name;
          await prefs.setString('savedDeviceType', deviceKey);

          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(deviceType: deviceKey),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Illustration matching user requested asset
                if (isPng)
                  Image.asset(
                    assetPath,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  )
                else
                  SvgPicture.asset(
                    assetPath,
                    width: 70,
                    height: 70,
                    colorFilter: colorFilter,
                  ),

                const Spacer(flex: 2),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
