import 'package:flutter/material.dart';
import '../services/bluetooth_hid_service.dart';

class DeviceControlsWidget extends StatelessWidget {
  final bool isConn;
  final BluetoothHidService btService;
  final ColorScheme cs;

  const DeviceControlsWidget({
    super.key, 
    required this.isConn, 
    required this.btService, 
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    switch (btService.deviceType) {
      case DeviceType.tv:
        return _buildTvControls(context);
      case DeviceType.mac:
        return _buildMacControls(context);
      case DeviceType.linux:
        return _buildLinuxControls(context);
      case DeviceType.pc:
      default:
        return _buildWindowsControls(context);
    }
  }

  // --- MAC CONTROLS ---
  Widget _buildMacControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("Shortcuts"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("⌘+Space", () {
              btService.sendKey(0x08, [0x2C]); // Cmd (0x08) + Space (0x2C)
            }),
            _buildMiniKey("⌘+Tab", () {
              btService.sendKey(0x08, [0x2B]); // Cmd + Tab
            }),
            _buildMiniKey("⌘+Q", () {
              btService.sendKey(0x08, [0x14]); // Cmd + Q
            }),
            _buildMiniKey("⌘+W", () {
              btService.sendKey(0x08, [0x1A]); // Cmd + W
            }),
            _buildMiniKey("⌃+↑", () {
              btService.sendKey(0x01, [0x52]); // Ctrl + Up
            }),
            _buildMiniKey("⌘+⇧+3", () {
              btService.sendKey(0x08 | 0x02, [0x20]); // Cmd + Shift + 3
            }),
            _buildMiniKey("⌘+⇧+4", () {
              btService.sendKey(0x08 | 0x02, [0x21]); // Cmd + Shift + 4
            }),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionHeader("Special Keys"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("⌘ Cmd", () => btService.sendKey(0x08, [0x00])),
            _buildMiniKey("⌥ Opt", () => btService.sendKey(0x04, [0x00])),
            _buildMiniKey("⌃ Ctrl", () => btService.sendKey(0x01, [0x00])),
            _buildMiniKey("fn", () => btService.sendKey(0, [0])), // fn is often tricky, mock action
            _buildMiniKey("Del", () => btService.sendKey(0, [0x2A])), // Backspace
            _buildMiniKey("Fwd Del", () => btService.sendKey(0, [0x4C])), // Delete Forward
          ],
        ),
      ],
    );
  }

  // --- LINUX CONTROLS ---
  Widget _buildLinuxControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("Shortcuts"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("Ctrl+Alt+T", () {
              btService.sendKey(0x01 | 0x04, [0x17]); // Ctrl + Alt + T
            }),
            _buildMiniKey("Super+D", () {
              btService.sendKey(0x08, [0x07]); // Super + D
            }),
            _buildMiniKey("Alt+F4", () {
              btService.sendKey(0x04, [0x3D]); // Alt + F4
            }),
            _buildMiniKey("Ctrl+Alt+L", () {
              btService.sendKey(0x01 | 0x04, [0x0F]); // Ctrl + Alt + L
            }),
            _buildMiniKey("Workspc Up", () {
              btService.sendKey(0x08, [0x4B]); // Super + PageUp
            }),
            _buildMiniKey("Workspc Dn", () {
              btService.sendKey(0x08, [0x4E]); // Super + PageDown
            }),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionHeader("Special Keys"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("Super", () => btService.sendKey(0x08, [0x00])),
            _buildMiniKey("Ctrl", () => btService.sendKey(0x01, [0x00])),
            _buildMiniKey("Alt", () => btService.sendKey(0x04, [0x00])),
            _buildMiniKey("Shift", () => btService.sendKey(0x02, [0x00])),
            _buildMiniKey("Tab", () => btService.sendKey(0, [0x2B])),
            _buildMiniKey("Esc", () => btService.sendKey(0, [0x29])),
            _buildMiniKey("Del", () => btService.sendKey(0, [0x4C])),
          ],
        ),
      ],
    );
  }

  // --- WINDOWS CONTROLS ---
  Widget _buildWindowsControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("Shortcuts"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("Win+D", () {
              btService.sendKey(0x08, [0x07]); // Win + D
            }),
            _buildMiniKey("Win+E", () {
              btService.sendKey(0x08, [0x08]); // Win + E
            }),
            _buildMiniKey("Win+L", () {
              btService.sendKey(0x08, [0x0F]); // Win + L
            }),
            _buildMiniKey("Win+Tab", () {
              btService.sendKey(0x08, [0x2B]); // Win + Tab
            }),
            _buildMiniKey("Alt+F4", () {
              btService.sendKey(0x04, [0x3D]); // Alt + F4
            }),
            _buildMiniKey("Task Mgr", () {
              btService.sendKey(0x01 | 0x02, [0x29]); // Ctrl + Shift + Esc
            }),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionHeader("Special Keys"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("⊞ Win", () => btService.sendKey(0x08, [0x00])),
            _buildMiniKey("Ctrl", () => btService.sendKey(0x01, [0x00])),
            _buildMiniKey("Alt", () => btService.sendKey(0x04, [0x00])),
            _buildMiniKey("Shift", () => btService.sendKey(0x02, [0x00])),
            _buildMiniKey("Tab", () => btService.sendKey(0, [0x2B])),
            _buildMiniKey("Esc", () => btService.sendKey(0, [0x29])),
            _buildMiniKey("Del", () => btService.sendKey(0, [0x4C])),
            _buildMiniKey("PrtSc", () => btService.sendKey(0, [0x46])),
          ],
        ),
      ],
    );
  }

  // --- SMART TV CONTROLS ---
  Widget _buildTvControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // D-pad & Basic TV Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDpad(context),
            _buildTvBasicButtons(),
          ],
        ),
        const SizedBox(height: 16),
        
        // Media Controls
        _buildSectionHeader("Media Controls"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildIconBtn(Icons.play_arrow, () => btService.sendMedia(0x00B0)),
            _buildIconBtn(Icons.pause, () => btService.sendMedia(0x00B1)),
            _buildIconBtn(Icons.stop, () => btService.sendMedia(0x00B7)),
            _buildIconBtn(Icons.skip_previous, () => btService.sendMedia(0x00B6)),
            _buildIconBtn(Icons.fast_rewind, () => btService.sendMedia(0x00B4)),
            _buildIconBtn(Icons.fast_forward, () => btService.sendMedia(0x00B3)),
            _buildIconBtn(Icons.skip_next, () => btService.sendMedia(0x00B5)),
          ],
        ),
        const SizedBox(height: 16),

        // Volume Controls
        _buildSectionHeader("Volume"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildIconBtn(Icons.volume_down, () => btService.sendMedia(0x00EA)),
            _buildIconBtn(Icons.volume_mute, () => btService.sendMedia(0x00E2)),
            _buildIconBtn(Icons.volume_up, () => btService.sendMedia(0x00E9)),
          ],
        ),
        const SizedBox(height: 16),

        // Streaming
        _buildSectionHeader("Streaming Apps"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMiniKey("YouTube", () => btService.sendMedia(0x0001)),
            _buildMiniKey("Netflix", () => btService.sendMedia(0x0002)),
            _buildMiniKey("Prime", () => btService.sendMedia(0x0003)),
            _buildMiniKey("Disney+", () => btService.sendMedia(0x0004)),
            _buildMiniKey("Spotify", () => btService.sendMedia(0x0005)),
          ],
        ),
      ],
    );
  }

  Widget _buildDpad(BuildContext context) {
    return Column(
      children: [
        _buildIconBtn(Icons.keyboard_arrow_up, () => btService.sendKey(0, [0x52])), // Up
        Row(
          children: [
            _buildIconBtn(Icons.keyboard_arrow_left, () => btService.sendKey(0, [0x50])), // Left
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildMiniKey("OK", () => btService.sendKey(0, [0x28])), // Enter
            ),
            _buildIconBtn(Icons.keyboard_arrow_right, () => btService.sendKey(0, [0x4F])), // Right
          ],
        ),
        _buildIconBtn(Icons.keyboard_arrow_down, () => btService.sendKey(0, [0x51])), // Down
      ],
    );
  }

  Widget _buildTvBasicButtons() {
    return Column(
      children: [
        _buildMiniKey("🏠 Home", () => btService.sendMedia(0x0223)),
        const SizedBox(height: 12),
        _buildMiniKey("🔙 Back", () => btService.sendMedia(0x0224)),
        const SizedBox(height: 12),
        _buildMiniKey("⚙️ Menu", () => btService.sendMedia(0x0040)),
      ],
    );
  }

  // --- HELPERS ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMiniKey(String label, VoidCallback onAct) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isConn ? onAct : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isConn ? cs.onSurface : cs.outline)),
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onAct) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isConn ? onAct : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: isConn ? cs.onSurface : cs.outline),
        ),
      ),
    );
  }
}
