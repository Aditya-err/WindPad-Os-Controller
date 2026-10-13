import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_theme.dart';
import '../services/bluetooth_hid_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerColor = isDark ? const Color(0xFF58A6FF) : cs.primary;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : cs.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── WINDPAD SETTINGS ──
          _buildSectionHeader("WINDPAD SETTINGS", headerColor),

          // Disconnect connected device
          ListTile(
            leading: const Icon(Icons.link_off, color: Color(0xFFFF6F00)),
            title: const Text("Disconnect connected device", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text(
              btService.state == BluetoothState.connected
                  ? (btService.connectedDeviceName.isNotEmpty
                      ? "Connected to ${btService.connectedDeviceName} • Tap to disconnect"
                      : "Active connection • Tap to disconnect")
                  : "Clear active Bluetooth connection",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            onTap: () => _confirmDisconnect(context, btService),
          ),

          // Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text("Theme", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text(_themeModeLabel(themeNotifier.themeMode), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: CupertinoSlidingSegmentedControl<ThemeMode>(
              groupValue: themeNotifier.themeMode,
              backgroundColor: isDark ? const Color(0xFF1E212A) : cs.surfaceContainerHighest,
              thumbColor: isDark ? const Color(0xFF333846) : Colors.white,
              children: {
                ThemeMode.light: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(Icons.light_mode_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                ),
                ThemeMode.dark: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(Icons.dark_mode_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                ),
                ThemeMode.system: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(Icons.settings_brightness_outlined, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                ),
              },
              onValueChanged: (val) {
                if (val != null) themeNotifier.setThemeMode(val);
              },
            ),
          ),

          // Trackpad surface color
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Trackpad surface color", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: BluetoothHidService.trackpadColors.asMap().entries.map((e) {
                      final isSelected = btService.trackpadColorIndex == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => btService.setTrackpadColorIndex(e.key),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2196F3) : (isDark ? Colors.white24 : Colors.black26),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: const Color(0xFF2196F3).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Color(0xFF2196F3))
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Spreadsheet Mode
          ListTile(
            title: const Text("Spreadsheet Mode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text("Enter → Tab, Shift+Enter → Down", style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: _buildCompactSwitch(
              value: btService.isSpreadsheetMode,
              onChanged: (_) => btService.toggleSpreadsheetMode(),
              isDark: isDark,
            ),
          ),

          // Emoji shortcut OS
          ListTile(
            leading: const Icon(Icons.sentiment_satisfied_alt_outlined),
            title: const Text("Emoji shortcut OS", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text(
              btService.useWindowsEmoji ? "Windows (Win + .)" : "macOS (Ctrl + Cmd + Space)",
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: CupertinoSlidingSegmentedControl<bool>(
              groupValue: btService.useWindowsEmoji,
              backgroundColor: isDark ? const Color(0xFF1E212A) : cs.surfaceContainerHighest,
              thumbColor: isDark ? const Color(0xFF333846) : Colors.white,
              children: {
                true: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text("Win", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                ),
                false: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text("Mac", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                ),
              },
              onValueChanged: (val) {
                if (val != null) btService.setUseWindowsEmoji(val);
              },
            ),
          ),

          Divider(height: 24, thickness: 1, color: dividerColor),

          // ── TRACKPAD ──
          _buildSectionHeader("TRACKPAD", headerColor),

          // Pointer speed
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Pointer speed", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF093E66),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${btService.dpi} DPI",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8AB4F8)),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    activeTrackColor: const Color(0xFF8AB4F8),
                    inactiveTrackColor: isDark ? const Color(0xFF2E323D) : const Color(0xFFD6DAE3),
                    thumbColor: const Color(0xFF8AB4F8),
                    overlayColor: const Color(0xFF8AB4F8).withValues(alpha: 0.15),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: btService.dpiSteps.indexOf(btService.dpi).clamp(0, btService.dpiSteps.length - 1).toDouble(),
                    min: 0,
                    max: (btService.dpiSteps.length - 1).toDouble(),
                    divisions: btService.dpiSteps.length - 1,
                    onChanged: (val) {
                      btService.setDpi(btService.dpiSteps[val.round()]);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tap to click
          ListTile(
            title: const Text("Tap to click", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text("Single tap to left click", style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: _buildCompactSwitch(
              value: btService.tapToClick,
              onChanged: (v) => btService.setTapToClick(v),
              isDark: isDark,
            ),
          ),

          // Two-finger right click
          ListTile(
            title: const Text("Two-finger right click", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            trailing: _buildCompactSwitch(
              value: btService.twoFingerRightClick,
              onChanged: (v) => btService.setTwoFingerRightClick(v),
              isDark: isDark,
            ),
          ),

          // Three-finger swipe
          ListTile(
            title: const Text("Three-finger swipe", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            trailing: _buildCompactSwitch(
              value: btService.threeFingerSwipe,
              onChanged: (v) => btService.setThreeFingerSwipe(v),
              isDark: isDark,
            ),
          ),

          Divider(height: 24, thickness: 1, color: dividerColor),

          // ── KEYBOARD ──
          _buildSectionHeader("KEYBOARD", headerColor),

          // Quick Keys visible
          ListTile(
            title: const Text("Quick Keys visible", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text("Action ribbon above keyboard", style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: _buildCompactSwitch(
              value: btService.quickKeysVisible,
              onChanged: (v) => btService.setQuickKeysVisible(v),
              isDark: isDark,
            ),
          ),

          // Haptic feedback
          ListTile(
            title: const Text("Haptic feedback", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text("Vibrate on key press", style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: _buildCompactSwitch(
              value: btService.hapticFeedback,
              onChanged: (v) => btService.setHapticFeedback(v),
              isDark: isDark,
            ),
          ),

          Divider(height: 24, thickness: 1, color: dividerColor),

          // ── GBOARD SETTINGS ──
          _buildSectionHeader("GBOARD SETTINGS", headerColor, subtitle: "Open Gboard settings directly"),

          ..._gboardItems.map((item) => ListTile(
                leading: Icon(item['icon'] as IconData, size: 22, color: cs.onSurfaceVariant),
                title: Text(item['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Icon(Icons.open_in_new, size: 18, color: cs.onSurfaceVariant),
                onTap: _openGboardSettings,
              )),

          Divider(height: 24, thickness: 1, color: dividerColor),

          // ── MORE ──
          _buildSectionHeader("MORE", headerColor),

          ListTile(
            leading: const Icon(Icons.shield_outlined, size: 22),
            title: const Text("Privacy Policy", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen())),
          ),

          ListTile(
            leading: const Icon(Icons.star_outline_rounded, size: 22),
            title: const Text("Rate us", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _RateAppScreen())),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, size: 22),
            title: const Text("About", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            onTap: () => _showAbout(context),
          ),

          ListTile(
            leading: const Icon(Icons.help_outline, size: 22),
            title: const Text("Help & Feedback", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _HelpFeedbackScreen())),
          ),

          const SizedBox(height: 32),

          // Footer
          const Center(
            child: Column(
              children: [
                Text("🇮🇳 Made in India", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text("Developed by Aditya 🎓", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static const _gboardItems = [
    {'icon': Icons.language, 'label': 'Languages'},
    {'icon': Icons.tune, 'label': 'Preferences'},
    {'icon': Icons.palette_outlined, 'label': 'Theme'},
    {'icon': Icons.spellcheck, 'label': 'Corrections and suggestions'},
    {'icon': Icons.gesture, 'label': 'Glide typing'},
    {'icon': Icons.mic_none, 'label': 'Voice typing'},
    {'icon': Icons.content_paste, 'label': 'Clipboard'},
    {'icon': Icons.menu_book_outlined, 'label': 'Dictionary'},
    {'icon': Icons.sentiment_satisfied_outlined, 'label': 'Emojis stickers and GIFs'},
  ];

  Widget _buildCompactSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Transform.scale(
      scale: 0.68,
      child: Switch(
        value: value,
        activeThumbColor: const Color(0xFF0F2C4C),
        activeTrackColor: const Color(0xFF8AB4F8),
        inactiveThumbColor: const Color(0xFF8E929E),
        inactiveTrackColor: isDark ? const Color(0xFF2E323D) : const Color(0xFFD6DAE3),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      case ThemeMode.system:
        return "System Default";
    }
  }

  void _confirmDisconnect(BuildContext context, BluetoothHidService btService) {
    if (btService.state != BluetoothState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No device is currently connected")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Disconnect Device?"),
        content: Text(
          "Are you sure you want to disconnect from ${btService.connectedDeviceName.isNotEmpty ? btService.connectedDeviceName : 'the connected device'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              btService.disconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Disconnected")),
              );
            },
            child: const Text("Disconnect", style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openGboardSettings() {
    const AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: 'com.google.android.inputmethod.latin',
      componentName: 'com.google.android.inputmethod.latin.settings.SettingsActivity',
    ).launch().catchError((_) {
      const AndroidIntent(action: 'android.settings.INPUT_METHOD_SETTINGS').launch();
    });
  }

  void _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'WindPad',
      applicationVersion: 'v${info.version} (${info.buildNumber})',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset('assets/icon/windpad-icon.png', width: 64, height: 64),
      ),
      children: [
        const Text('Turn your phone into a Bluetooth HID trackpad & keyboard for any computer.'),
        const SizedBox(height: 8),
        Text('Package: ${info.packageName}', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════
// Rate App Screen
// ═══════════════════════════════
class _RateAppScreen extends StatefulWidget {
  const _RateAppScreen();

  @override
  State<_RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<_RateAppScreen> {
  double _rating = 0;
  final _feedbackController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Windpad')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _submitted ? _buildThankYou(cs) : _buildForm(cs),
      ),
    );
  }

  Widget _buildForm(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_rounded, size: 64, color: Color(0xFFFFCC00)),
        const SizedBox(height: 16),
        Text("How's your experience?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text("Your feedback helps us improve", style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 48,
          unratedColor: cs.outlineVariant,
          itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Color(0xFFFFCC00)),
          onRatingUpdate: (rating) => setState(() => _rating = rating),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Tell us what you think...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _rating > 0 ? _submitRating : null,
          icon: const Icon(Icons.send),
          label: const Text("Submit"),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
      ],
    );
  }

  Widget _buildThankYou(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite, size: 64, color: Color(0xFFFF2D55)),
        const SizedBox(height: 16),
        Text("Thank you! 🎉", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        Text("We appreciate your feedback", style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Go Back"),
        ),
      ],
    );
  }

  void _submitRating() async {
    setState(() => _submitted = true);
    final body = "Rating: ${_rating.toInt()}/5\n\nFeedback: ${_feedbackController.text}";
    final uri = Uri(
      scheme: 'mailto',
      path: 'gadityaprasadachary@gmail.com',
      queryParameters: {'subject': 'Windpad Rating', 'body': body},
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ═══════════════════════════════
// Privacy Policy Screen
// ═══════════════════════════════
class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: _PrivacyAppBar(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Privacy Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text("Last updated: March 2026\n", style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              "Windpad respects your privacy. This app:\n\n"
              "• Does NOT collect personal data\n"
              "• Does NOT transmit data to external servers\n"
              "• Uses Bluetooth ONLY for HID device communication with your paired computer\n"
              "• Stores settings locally on your device using SharedPreferences\n"
              "• Does NOT use analytics, tracking, or advertising SDKs\n\n"
              "Bluetooth permissions are required solely to establish a Bluetooth HID connection between your phone and your computer. "
              "Location permission (Android ≤ 11) is required by Android to discover Bluetooth devices and is not used for actual location tracking.\n\n"
              "If you have questions about this policy, contact us at gadityaprasadachary@gmail.com.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyAppBar extends StatelessWidget {
  const _PrivacyAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Privacy Policy'));
  }
}

// ═══════════════════════════════
// Help & FAQ Screen
// ═══════════════════════════════
class _HelpFeedbackScreen extends StatelessWidget {
  const _HelpFeedbackScreen();

  static const _faqs = [
    {'q': 'How do I connect my phone to a computer?', 'a': 'Tap "Connect" on the home screen, select your paired device from the list, and it will connect automatically.'},
    {'q': 'Why does Bluetooth stay connected in the background?', 'a': 'Windpad uses a persistent Android foreground service so you can switch apps without losing your mouse and keyboard connection.'},
    {'q': 'How do I disconnect?', 'a': 'Tap "Disconnect connected device" in Settings, or turn off Bluetooth on your phone.'},
    {'q': 'What is Spreadsheet Mode?', 'a': 'When enabled, the Enter key sends Tab (to move right in Excel/Sheets), and Shift+Enter sends Down arrow.'},
    {'q': 'How do I change cursor speed?', 'a': 'Adjust the Pointer Speed slider in Settings > Trackpad.'},
    {'q': 'Does this work with macOS, Smart TVs & Projectors?', 'a': 'Yes! Windpad works seamlessly with Windows, macOS, Linux, Smart TVs, and Smart Projectors via standard Bluetooth HID with dedicated remote controls and air mouse pointer.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          ..._faqs.map((faq) => ExpansionTile(
            title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w500)),
            children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(faq['a']!, style: const TextStyle(height: 1.5)))],
          )),
          const Divider(height: 32),
          Text("Send Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          const Text("Have a bug report or feature request? We'd love to hear from you.", style: TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri(scheme: 'mailto', path: 'gadityaprasadachary@gmail.com', queryParameters: {'subject': 'Windpad Feedback'});
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text("Send Email"),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
