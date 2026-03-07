import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/bluetooth_hid_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _sectionHeader("WINDPAD SETTINGS", cs),

          // ── Theme toggle ──
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text("Theme"),
            subtitle: Text(_themeModeLabel(themeNotifier.themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest, size: 16)),
              ],
              selected: {themeNotifier.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (val) => themeNotifier.setThemeMode(val.first),
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            ),
          ),

          // ── Trackpad surface color ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Trackpad surface color", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: BluetoothHidService.trackpadColors.asMap().entries.map((e) {
                    final isSelected = btService.trackpadColorIndex == e.key;
                    return GestureDetector(
                      onTap: () => btService.setTrackpadColorIndex(e.key),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant, width: isSelected ? 3 : 1),
                        ),
                        child: isSelected ? Icon(Icons.check, size: 16, color: cs.primary) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Spreadsheet Mode ──
          SwitchListTile(
            title: const Text("Spreadsheet Mode"),
            subtitle: const Text("Enter → Tab, Shift+Enter → Down"),
            value: btService.isSpreadsheetMode,
            onChanged: (_) => btService.toggleSpreadsheetMode(),
          ),

          // ── Touch Sound ──
          SwitchListTile(
            title: const Text("Touch Sound"),
            subtitle: const Text("Soft click on each tap"),
            value: btService.touchSoundEnabled,
            onChanged: (v) => btService.setTouchSoundEnabled(v),
          ),
          if (btService.touchSoundEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.volume_down, size: 16),
                  Expanded(child: Slider(value: btService.touchSoundVolume, min: 0, max: 100, onChanged: (v) => btService.setTouchSoundVolume(v))),
                  const Icon(Icons.volume_up, size: 16),
                ],
              ),
            ),

          const Divider(height: 32),
          _sectionHeader("TRACKPAD", cs),

          // ── Pointer Speed ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Pointer speed", style: TextStyle(fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Text("${btService.dpi} DPI", style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                Slider(
                  value: btService.dpiSteps.indexOf(btService.dpi).toDouble().clamp(0, (btService.dpiSteps.length - 1).toDouble()),
                  min: 0, max: (btService.dpiSteps.length - 1).toDouble(),
                  divisions: btService.dpiSteps.length - 1,
                  label: "${btService.dpi}",
                  onChanged: (v) => btService.setDpi(btService.dpiSteps[v.toInt()]),
                ),
              ],
            ),
          ),

          SwitchListTile(title: const Text("Tap to click"), subtitle: const Text("Single tap to left click"), value: btService.tapToClick, onChanged: (v) => btService.setTapToClick(v)),
          SwitchListTile(title: const Text("Two-finger right click"), value: btService.twoFingerRightClick, onChanged: (v) => btService.setTwoFingerRightClick(v)),
          SwitchListTile(title: const Text("Three-finger swipe"), value: btService.threeFingerSwipe, onChanged: (v) => btService.setThreeFingerSwipe(v)),

          const Divider(height: 32),
          _sectionHeader("KEYBOARD", cs),
          SwitchListTile(title: const Text("Quick Keys visible"), subtitle: const Text("Action ribbon above keyboard"), value: btService.quickKeysVisible, onChanged: (v) => btService.setQuickKeysVisible(v)),
          SwitchListTile(title: const Text("Haptic feedback"), subtitle: const Text("Vibrate on key press"), value: btService.hapticFeedback, onChanged: (v) => btService.setHapticFeedback(v)),

          const Divider(height: 32),
          _sectionHeader("GBOARD SETTINGS", cs, subtitle: "Open Gboard settings directly"),
          ..._gboardItems.map((item) => ListTile(
            leading: Icon(item['icon'] as IconData, size: 20),
            title: Text(item['label'] as String),
            trailing: const Icon(Icons.open_in_new, size: 18),
            dense: true,
            onTap: () => _openGboardSettings(),
          )),

          const Divider(height: 32),
          _sectionHeader("MORE", cs),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate_outlined),
            title: const Text("Rate us"),
            onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.windpad.app'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About"),
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Feedback"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _HelpFeedbackScreen())),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  static const _gboardItems = [
    {'icon': Icons.language, 'label': 'Languages'},
    {'icon': Icons.tune, 'label': 'Preferences'},
    {'icon': Icons.palette, 'label': 'Theme'},
    {'icon': Icons.spellcheck, 'label': 'Corrections and suggestions'},
    {'icon': Icons.gesture, 'label': 'Glide typing'},
    {'icon': Icons.mic, 'label': 'Voice typing'},
    {'icon': Icons.content_paste, 'label': 'Clipboard'},
    {'icon': Icons.book_outlined, 'label': 'Dictionary'},
    {'icon': Icons.emoji_emotions_outlined, 'label': 'Emojis stickers and GIFs'},
  ];

  Widget _sectionHeader(String title, ColorScheme cs, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          if (subtitle != null) Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return "Light";
      case ThemeMode.dark: return "Dark";
      case ThemeMode.system: return "System Default";
    }
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Windpad',
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
// Privacy Policy Screen
// ═══════════════════════════════
class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
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
              "If you have questions about this policy, contact us at windpad.app@gmail.com.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════
// Help & Feedback Screen
// ═══════════════════════════════
class _HelpFeedbackScreen extends StatelessWidget {
  const _HelpFeedbackScreen();

  static const _faqs = [
    {'q': 'How do I connect my phone to a computer?', 'a': 'Tap "Connect" on the home screen, then pair from your computer\'s Bluetooth settings. Ensure your phone is visible.'},
    {'q': 'Why does Bluetooth disconnect in the background?', 'a': 'Go to Battery settings and disable battery optimization for Windpad. The app uses a foreground service to stay alive.'},
    {'q': 'What is Spreadsheet Mode?', 'a': 'When enabled, the Enter key sends Tab (to move right in Excel/Sheets), and Shift+Enter sends Down arrow.'},
    {'q': 'How do I change the cursor speed?', 'a': 'Tap the DPI badge in the top bar, or adjust the Pointer Speed slider in Settings > Trackpad.'},
    {'q': 'Does this work with macOS?', 'a': 'Yes! Windpad works with Windows, macOS, Linux, and ChromeOS via standard Bluetooth HID.'},
    {'q': 'Can I use this app without internet?', 'a': 'Absolutely. Windpad works entirely offline via Bluetooth.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Feedback')),
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
          const Text("Have a bug report, feature request, or general feedback? We'd love to hear from you.", style: TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri(scheme: 'mailto', path: 'windpad.app@gmail.com', queryParameters: {'subject': 'Windpad Feedback'});
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
