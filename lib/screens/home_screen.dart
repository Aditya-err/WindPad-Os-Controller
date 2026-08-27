import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_hid_service.dart';
import 'device_selection_screen.dart';
import 'settings_screen.dart';
import 'wifi_connect_screen.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

// ═══════════════════════════════════════════════════════════════
// HomeScreen wrapper with IndexedStack for instant device switch
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final String? deviceType;
  const HomeScreen({super.key, this.deviceType});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _device;
  static const _order = ['windows', 'mac', 'linux', 'tv'];

  @override
  void initState() {
    super.initState();
    _device = widget.deviceType ?? 'windows';
    if (widget.deviceType == null) _loadSaved();
  }

  void _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('savedDeviceType');
    if (s != null && mounted) setState(() => _device = s);
  }

  @override
  Widget build(BuildContext context) {
    int idx = _order.indexOf(_device);
    if (idx == -1) idx = 0;
    return IndexedStack(
      index: idx,
      children: const [
        WindowsScreen(),
        MacScreen(),
        LinuxScreen(),
        SmartTvScreen(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BASE DEVICE SCREEN — Restored exact old UI
// ═══════════════════════════════════════════════════════════════
class DeviceBaseScreen extends StatefulWidget {
  final DeviceType type;
  final List<SpecialKey> specialKeys;
  final bool isSmartTv;
  const DeviceBaseScreen({super.key, required this.type, required this.specialKeys, this.isSmartTv = false});
  @override
  State<DeviceBaseScreen> createState() => _DeviceBaseScreenState();
}

class _DeviceBaseScreenState extends State<DeviceBaseScreen> {
  final TextEditingController _kbController = TextEditingController();
  final FocusNode _kbFocus = FocusNode();
  bool _showEmojiPicker = false;
  bool _showDpiSlider = false;
  Timer? _backspaceTimer;

  // Trackpad smooth filter + DPI
  double _smoothX = 0, _smoothY = 0;
  double _dpi = 1.5;
  int _dpiInt = 1600;
  Offset? _lastPos;

  @override
  void initState() {
    super.initState();
    _loadDpi();
  }

  void _loadDpi() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dpi = p.getDouble('dpi') ?? 1.5;
        _dpiInt = p.getInt('dpiInt') ?? 1600;
      });
    }
  }

  @override
  void dispose() {
    _kbController.dispose();
    _kbFocus.dispose();
    _backspaceTimer?.cancel();
    super.dispose();
  }

  // Shortcut helpers
  void _leftClick(BluetoothHidService bt) => bt.state == BluetoothState.connected ? bt.sendMouseClick(1) : null;
  void _rightClick(BluetoothHidService bt) => bt.state == BluetoothState.connected ? bt.sendMouseClick(2) : null;
  void _scrollUp(BluetoothHidService bt) => bt.state == BluetoothState.connected ? bt.sendScroll(1) : null;
  void _scrollDown(BluetoothHidService bt) => bt.state == BluetoothState.connected ? bt.sendScroll(-1) : null;
  void _copy(BluetoothHidService bt) => _shortcut(bt, 0x06);
  void _paste(BluetoothHidService bt) => _shortcut(bt, 0x19);
  void _cut(BluetoothHidService bt) => _shortcut(bt, 0x1B);
  void _undo(BluetoothHidService bt) => _shortcut(bt, 0x1D);
  void _selectAll(BluetoothHidService bt) => _shortcut(bt, 0x04);
  void _enter(BluetoothHidService bt) => bt.state == BluetoothState.connected ? bt.sendEnter() : null;

  void _shortcut(BluetoothHidService bt, int kc) {
    if (bt.state != BluetoothState.connected) return;
    bt.sendKey(bt.deviceType == DeviceType.mac ? 0x08 : 0x01, [kc]);
  }

  void _backspace(BluetoothHidService bt) {
    if (bt.state == BluetoothState.connected) bt.sendKey(0, [0x2A]);
  }

  void _startBackspaceRepeat(BluetoothHidService bt) {
    _backspaceTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _backspace(bt));
  }
  void _stopBackspaceRepeat() => _backspaceTimer?.cancel();

  // Trackpad smooth movement
  void _onTrackpadStart(DragStartDetails d) {
    _lastPos = d.localPosition;
    _smoothX = 0; _smoothY = 0;
  }
  void _onTrackpadMove(DragUpdateDetails d, BluetoothHidService bt) {
    if (bt.state != BluetoothState.connected || _lastPos == null) return;
    double rawDx = d.localPosition.dx - _lastPos!.dx;
    double rawDy = d.localPosition.dy - _lastPos!.dy;
    _lastPos = d.localPosition;
    _smoothX = _smoothX * 0.35 + rawDx * 0.65;
    _smoothY = _smoothY * 0.35 + rawDy * 0.65;
    bt.sendMouseMove((_smoothX * _dpi).toInt(), (_smoothY * _dpi).toInt());
  }

  void _sendSpecialKey(BluetoothHidService bt, SpecialKey key) {
    if (bt.state != BluetoothState.connected) return;
    if (key.isMedia) { bt.sendMedia(key.code); } else { bt.sendKey(key.modifier, [key.code]); }
  }

  // ═══ BUILD ═══
  @override
  Widget build(BuildContext context) {
    final bt = Provider.of<BluetoothHidService>(context);
    final isConnected = bt.state == BluetoothState.connected;
    final isScanning = bt.state == BluetoothState.scanning;
    final deviceName = bt.connectedDeviceName.isNotEmpty ? bt.connectedDeviceName : 'ADITYA';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── APP BAR ──
            _buildAppBar(context, bt, isConnected, isScanning, deviceName),

            // ── INFO BANNER (only when not connected) ──
            if (!isConnected)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF0D2640)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.cyanAccent.withValues(alpha: 0.8), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isScanning ? 'Searching for devices...' : 'Ready to connect. Ensure Bluetooth is on.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // ── DPI SLIDER (toggleable) ──
            if (_showDpiSlider)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF111428), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('DPI', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _dpi, min: 0.5, max: 3.0, divisions: 10,
                          activeColor: const Color(0xFF4285F4),
                          inactiveColor: Colors.white12,
                          onChanged: (v) async {
                            setState(() {
                              _dpi = v;
                              _dpiInt = (v * 1000).round();
                            });
                            final p = await SharedPreferences.getInstance();
                            p.setDouble('dpi', v);
                            p.setInt('dpiInt', _dpiInt);
                          },
                        ),
                      ),
                    ),
                    Text('$_dpiInt', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),

            // ── TRACKPAD SECTION ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKPAD', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                      const SizedBox(height: 2),
                      Text('Touch to control cursor', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  _miniPill(Icons.touch_app, 'Move Cursor', const Color(0xFF1A4FBF)),
                  const SizedBox(width: 4),
                  _miniIconBtn(Icons.zoom_in, () => _scrollUp(bt)),
                  const SizedBox(width: 4),
                  _miniIconBtn(Icons.zoom_out, () => _scrollDown(bt)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _buildTrackpad(bt, isConnected),

            const SizedBox(height: 8),

            // ── CLICK + SCROLL BUTTONS ──
            _buildClickRow(bt),

            const SizedBox(height: 8),

            // ── QUICK KEYS (2 rows × 3) ──
            _buildQuickKeysGrid(bt),

            const SizedBox(height: 8),

            // ── SPECIAL KEYS ROW (horizontal scroll chips) ──
            _buildSpecialKeysRow(bt),

            const SizedBox(height: 8),

            // ── EMOJI PICKER ──
            if (_showEmojiPicker)
              SizedBox(
                height: 220,
                child: EmojiPicker(
                  onEmojiSelected: (_, emoji) => bt.sendText(emoji.emoji),
                  config: Config(
                    height: 220,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: const Color(0xFF0A0A0F),
                      columns: 7,
                      emojiSizeMax: 28 * (Platform.isIOS ? 1.30 : 1.0),
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(
                      backgroundColor: Color(0xFF0A0A0F),
                      indicatorColor: Color(0xFF4285F4),
                      iconColorSelected: Color(0xFF4285F4),
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(backgroundColor: Color(0xFF0A0A0F)),
                  ),
                ),
              ),

            // ── KEYBOARD SECTION ──
            const Spacer(),
            _buildKeyboardSection(bt, isConnected),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAppBar(BuildContext ctx, BluetoothHidService bt, bool isConnected, bool isScanning, String deviceName) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Device chip (left)
          GestureDetector(
            onTap: () => Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(builder: (_) => const DeviceSelectionScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.string(_getSvg(widget.type), width: 16, height: 16,
                    colorFilter: ColorFilter.mode(_getColor(widget.type), BlendMode.srcIn)),
                  const SizedBox(width: 6),
                  Text(_getLabel(widget.type),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Connection button
          GestureDetector(
            onTap: () => _showConnectSheet(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4FBF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? const Color(0xFF34D399) : (isScanning ? const Color(0xFF60A5FA) : const Color(0xFFFF6B6B)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? deviceName.toUpperCase() : (isScanning ? 'Searching...' : 'Connect'),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // DPI button
          GestureDetector(
            onTap: () => setState(() => _showDpiSlider = !_showDpiSlider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A4FBF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$_dpiInt DPI',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 6),

          // Settings gear
          GestureDetector(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Icon(Icons.settings_outlined, color: Colors.white.withValues(alpha: 0.5), size: 20),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRACKPAD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTrackpad(BluetoothHidService bt, bool isConnected) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1426),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            // Dot grid pattern
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            // Gesture area
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onTrackpadStart,
                onPanUpdate: (d) => _onTrackpadMove(d, bt),
                onPanEnd: (_) => _lastPos = null,
                onTap: () => _leftClick(bt),
                onDoubleTap: () => _leftClick(bt),
              ),
            ),
            // Center cursor icon
            Center(
              child: Opacity(
                opacity: 0.12,
                child: SizedBox(width: 28, height: 36, child: CustomPaint(painter: CursorPainter())),
              ),
            ),
            // Status text
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Center(
                child: Text(
                  isConnected ? 'Touch to control cursor' : 'Connecting via Bluetooth...',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CLICK + SCROLL ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildClickRow(BluetoothHidService bt) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // LEFT CLICK
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _leftClick(bt),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4FBF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.orange.shade300, size: 20),
                    const SizedBox(width: 6),
                    const Text('LEFT CLICK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // RIGHT CLICK
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _rightClick(bt),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6B3FA0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0),
                      child: Icon(Icons.play_arrow, color: Colors.orange.shade300, size: 20),
                    ),
                    const SizedBox(width: 6),
                    const Text('RIGHT CLICK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // SCROLL UP/DOWN
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3F52),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _scrollUp(bt),
                      behavior: HitTestBehavior.opaque,
                      child: const Center(child: Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 22)),
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _scrollDown(bt),
                      behavior: HitTestBehavior.opaque,
                      child: const Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 22)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK KEYS (2 rows × 3 = 6 buttons)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickKeysGrid(BluetoothHidService bt) {
    final keys = [
      _QK(Icons.copy_outlined, 'Copy', () => _copy(bt)),
      _QK(Icons.content_paste_outlined, 'Paste', () => _paste(bt)),
      _QK(Icons.content_cut_outlined, 'Cut', () => _cut(bt)),
      _QK(Icons.undo, 'Undo', () => _undo(bt)),
      _QK(Icons.select_all, 'All', () => _selectAll(bt)),
      _QK(Icons.keyboard_return, 'Enter', () => _enter(bt)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Row 1
          Row(
            children: keys.sublist(0, 3).map((k) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _quickKeyButton(k),
            ))).toList(),
          ),
          const SizedBox(height: 6),
          // Row 2
          Row(
            children: keys.sublist(3, 6).map((k) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _quickKeyButton(k),
            ))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _quickKeyButton(_QK k) {
    return GestureDetector(
      onTap: k.action,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(k.icon, color: Colors.white60, size: 18),
            const SizedBox(height: 2),
            Text(k.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SPECIAL KEYS ROW (horizontal scroll chips)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSpecialKeysRow(BluetoothHidService bt) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Keyboard icon chip (opens full modal)
          GestureDetector(
            onTap: () => _openKeyboardModal(context, bt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: 0.3)),
              ),
              child: const Center(child: Icon(Icons.keyboard, color: Color(0xFF4285F4), size: 16)),
            ),
          ),
          // Special key chips
          ...widget.specialKeys.take(6).map((k) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _sendSpecialKey(bt, k),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Center(
                  child: Text(k.label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          )),
          // Search chip
          GestureDetector(
            onTap: () {
              // Windows search = Win key
              if (bt.state == BluetoothState.connected) bt.sendKey(0x08, [0]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.white38, size: 14),
                    SizedBox(width: 4),
                    Text('Search', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // KEYBOARD BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildKeyboardSection(BluetoothHidService bt, bool isConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.keyboard, color: Colors.white.withValues(alpha: 0.2), size: 14),
              const SizedBox(width: 4),
              Text('Keyboard', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
            ],
          ),
        ),
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Emoji toggle
              GestureDetector(
                onTap: () => setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                  if (_showEmojiPicker) _kbFocus.unfocus(); else _kbFocus.requestFocus();
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Colors.amber.withValues(alpha: 0.7), size: 20,
                  ),
                ),
              ),
              // Text field
              Expanded(
                child: TextField(
                  focusNode: _kbFocus,
                  controller: _kbController,
                  onTap: () { if (_showEmojiPicker) setState(() => _showEmojiPicker = false); },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isConnected ? 'See on your screen' : 'Connect to type',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (t) {
                    if (t.isNotEmpty) { bt.sendText(t[t.length - 1]); _kbController.clear(); }
                  },
                ),
              ),
              // Backspace
              GestureDetector(
                onTap: () => _backspace(bt),
                onLongPressStart: (_) => _startBackspaceRepeat(bt),
                onLongPressEnd: (_) => _stopBackspaceRepeat(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.backspace_outlined, color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TABBED SPECIAL KEYS MODAL (⌨ button)
  // ═══════════════════════════════════════════════════════════════
  void _openKeyboardModal(BuildContext context, BluetoothHidService bt) {
    final funcKeys = widget.specialKeys.where((k) =>
      k.label.startsWith('F') || k.label == 'Esc' || k.label == 'PrtSc' || k.label == 'Ins').toList();
    final navKeys = widget.specialKeys.where((k) =>
      ['Home','End','PgUp','PgDn','Del','Tab','CapsLk','Super','⌘','⌥','⌃','⇧','fn','⌫',
       'Back','Menu','Settings','Guide','Info','Ch+','Ch-'].contains(k.label)).toList();
    final shortKeys = widget.specialKeys.where((k) =>
      !funcKeys.contains(k) && !navKeys.contains(k)).toList();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Text('${_getName(widget.type)} Keys',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Expanded(
              child: DefaultTabController(length: 3, child: Column(children: [
                const TabBar(
                  tabs: [Tab(text: 'Function'), Tab(text: 'Navigation'), Tab(text: 'Shortcuts')],
                  labelColor: Color(0xFF4285F4), unselectedLabelColor: Colors.white38,
                  indicatorColor: Color(0xFF4285F4), indicatorSize: TabBarIndicatorSize.label,
                ),
                Expanded(child: TabBarView(children: [
                  _keysGrid(funcKeys, bt, scrollCtrl),
                  _keysGrid(navKeys, bt, scrollCtrl),
                  _keysGrid(shortKeys, bt, scrollCtrl),
                ])),
              ])),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _keysGrid(List<SpecialKey> keys, BluetoothHidService bt, ScrollController sc) {
    if (keys.isEmpty) {
      return const Center(child: Text('No keys in this category', style: TextStyle(color: Colors.white38)));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        controller: sc,
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: keys.map((k) => GestureDetector(
          onTap: () => _sendSpecialKey(bt, k),
          child: Container(
            decoration: BoxDecoration(
              color: k.color ?? const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            alignment: Alignment.center,
            child: Text(k.label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ),
        )).toList(),
      ),
    );
  }

  // ═══ Connect Sheet ═══
  static const bool _wifiEnabled = false; // set true later when WiFi ready

  void _showConnectSheet(BuildContext context) {
    final bt = Provider.of<BluetoothHidService>(context, listen: false);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Connect Device', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Bluetooth section
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await bt.ensureServiceRunning();
              await bt.connect();
            },
            icon: const Icon(Icons.bluetooth), label: const Text('Start Bluetooth HID'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text('Pair your phone via system Bluetooth settings first.\nThen tap above to start HID mode.', 
            style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // Bonded devices list
          FutureBuilder<void>(
            future: bt.refreshBondedDevices(),
            builder: (ctx, _) {
              final devices = bt.bondedDevices;
              if (devices.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAIRED DEVICES', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...devices.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        bt.connectToDevice(d['address']!, d['name']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.bluetooth, color: Color(0xFF4285F4), size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 14))),
                          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 18),
                        ]),
                      ),
                    ),
                  )),
                ],
              );
            },
          ),
        ])),

        // WiFi section (hidden behind flag)
        if (_wifiEnabled) ...[
          const Divider(color: Colors.white12, height: 32),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const WifiConnectScreen())); },
            icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan QR Code (WiFi)'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: const Color(0xFF34A853), foregroundColor: Colors.white),
          )),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }

  // ═══ Small UI helpers ═══
  Widget _miniPill(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bg, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: bg, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _miniIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Icon(icon, color: Colors.white38, size: 14)),
      ),
    );
  }

  // ═══ Helpers ═══
  String _getSvg(DeviceType t) { switch(t) { case DeviceType.pc: return _windowsSvg; case DeviceType.mac: return _macSvg; case DeviceType.linux: return _linuxTuxSvg; case DeviceType.tv: return _tvSvg; } }
  Color _getColor(DeviceType t) { switch(t) { case DeviceType.pc: return const Color(0xFF4285F4); case DeviceType.linux: return const Color(0xFFFBBC04); case DeviceType.tv: return const Color(0xFFEA4335); case DeviceType.mac: return Colors.white; } }
  String _getName(DeviceType t) { switch(t) { case DeviceType.pc: return 'Windows'; case DeviceType.mac: return 'Mac'; case DeviceType.linux: return 'Linux'; case DeviceType.tv: return 'Smart TV'; } }
  String _getLabel(DeviceType t) { switch(t) { case DeviceType.pc: return 'PC / Desktop'; case DeviceType.mac: return 'Mac'; case DeviceType.linux: return 'Linux'; case DeviceType.tv: return 'Smart TV'; } }
}

// ═══ Quick Key helper ═══
class _QK { final IconData icon; final String label; final VoidCallback action; _QK(this.icon, this.label, this.action); }

// ═══════════════════════════════════════════════════════════════
// DOT GRID PAINTER
// ═══════════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double y = spacing; y < size.height; y += spacing) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// DEVICE SCREENS
// ═══════════════════════════════════════════════════════════════
class WindowsScreen extends StatelessWidget {
  const WindowsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const DeviceBaseScreen(type: DeviceType.pc, specialKeys: [
      SpecialKey("⊞Win", 0x08, 0), SpecialKey("Esc", 0, 0x29), SpecialKey("Tab", 0, 0x2B),
      SpecialKey("Del", 0, 0x4C), SpecialKey("Prt Sc", 0, 0x46), SpecialKey("🔍 Search", 0x08, 0),
      // Full set in modal:
      SpecialKey("F1", 0, 0x3A), SpecialKey("F2", 0, 0x3B), SpecialKey("F3", 0, 0x3C), SpecialKey("F4", 0, 0x3D),
      SpecialKey("F5", 0, 0x3E), SpecialKey("F6", 0, 0x3F), SpecialKey("F7", 0, 0x40), SpecialKey("F8", 0, 0x41),
      SpecialKey("F9", 0, 0x42), SpecialKey("F10", 0, 0x43), SpecialKey("F11", 0, 0x44), SpecialKey("F12", 0, 0x45),
      SpecialKey("Ins", 0, 0x49), SpecialKey("Home", 0, 0x4A), SpecialKey("End", 0, 0x4D),
      SpecialKey("PgUp", 0, 0x4B), SpecialKey("PgDn", 0, 0x4E), SpecialKey("CapsLk", 0, 0x39),
      SpecialKey("Alt+F4", 0x04, 0x3D), SpecialKey("⊞+D", 0x08, 0x07), SpecialKey("⊞+E", 0x08, 0x08),
      SpecialKey("⊞+L", 0x08, 0x0F), SpecialKey("⊞+Tab", 0x08, 0x2B), SpecialKey("⊞+R", 0x08, 0x15),
      SpecialKey("Ctrl+Alt+Del", 0x05, 0x4C),
    ]);
  }
}

class MacScreen extends StatelessWidget {
  const MacScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const DeviceBaseScreen(type: DeviceType.mac, specialKeys: [
      SpecialKey("⌘", 0x08, 0), SpecialKey("⌥", 0x04, 0), SpecialKey("⌃", 0x01, 0),
      SpecialKey("⇧", 0x02, 0), SpecialKey("Del", 0, 0x4C), SpecialKey("⌘+Space", 0x08, 0x2C),
      // Full set in modal:
      SpecialKey("Esc", 0, 0x29), SpecialKey("F1", 0, 0x3A), SpecialKey("F2", 0, 0x3B), SpecialKey("F3", 0, 0x3C),
      SpecialKey("F4", 0, 0x3D), SpecialKey("F5", 0, 0x3E), SpecialKey("F6", 0, 0x3F), SpecialKey("F7", 0, 0x40),
      SpecialKey("F8", 0, 0x41), SpecialKey("F9", 0, 0x42), SpecialKey("F10", 0, 0x43), SpecialKey("F11", 0, 0x44),
      SpecialKey("F12", 0, 0x45), SpecialKey("PrtSc", 0, 0x46), SpecialKey("fn", 0, 0x00), SpecialKey("⌫", 0, 0x2A),
      SpecialKey("⌘+Tab", 0x08, 0x2B), SpecialKey("⌃+↑", 0x01, 0x52), SpecialKey("⌘+Q", 0x08, 0x14),
      SpecialKey("⌘+W", 0x08, 0x1A), SpecialKey("⌘+⇧+3", 0x0A, 0x20), SpecialKey("⌘+⇧+4", 0x0A, 0x21),
      SpecialKey("⌘+H", 0x08, 0x0B), SpecialKey("⌘+M", 0x08, 0x10), SpecialKey("⌘+,", 0x08, 0x36),
    ]);
  }
}

class LinuxScreen extends StatelessWidget {
  const LinuxScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const DeviceBaseScreen(type: DeviceType.linux, specialKeys: [
      SpecialKey("Super", 0x08, 0), SpecialKey("Esc", 0, 0x29), SpecialKey("Tab", 0, 0x2B),
      SpecialKey("Del", 0, 0x4C), SpecialKey("PrtSc", 0, 0x46), SpecialKey("Ctrl+T", 0x01, 0x17),
      // Full set in modal:
      SpecialKey("F1", 0, 0x3A), SpecialKey("F2", 0, 0x3B), SpecialKey("F3", 0, 0x3C), SpecialKey("F4", 0, 0x3D),
      SpecialKey("F5", 0, 0x3E), SpecialKey("F6", 0, 0x3F), SpecialKey("F7", 0, 0x40), SpecialKey("F8", 0, 0x41),
      SpecialKey("F9", 0, 0x42), SpecialKey("F10", 0, 0x43), SpecialKey("F11", 0, 0x44), SpecialKey("F12", 0, 0x45),
      SpecialKey("Ins", 0, 0x49), SpecialKey("Home", 0, 0x4A), SpecialKey("End", 0, 0x4D),
      SpecialKey("PgUp", 0, 0x4B), SpecialKey("PgDn", 0, 0x4E), SpecialKey("CapsLk", 0, 0x39),
      SpecialKey("Sup+D", 0x08, 0x07), SpecialKey("Alt+F4", 0x04, 0x3D), SpecialKey("Ctrl+Alt+L", 0x05, 0x0F),
      SpecialKey("Ct+Al+←", 0x05, 0x50), SpecialKey("Ct+Al+→", 0x05, 0x4F), SpecialKey("Sup+Tab", 0x08, 0x2B),
    ]);
  }
}

class SmartTvScreen extends StatelessWidget {
  const SmartTvScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DeviceBaseScreen(type: DeviceType.tv, isSmartTv: true, specialKeys: [
      const SpecialKey("Back", 0, 0x0224, isMedia: true), const SpecialKey("Home", 0, 0x0223, isMedia: true),
      const SpecialKey("Menu", 0, 0x0040, isMedia: true), SpecialKey("Vol+", 0, 0x00E9, isMedia: true, color: const Color(0xFF2A1A1A)),
      SpecialKey("Vol-", 0, 0x00EA, isMedia: true, color: const Color(0xFF2A1A1A)), SpecialKey("Mute", 0, 0x00E2, isMedia: true, color: const Color(0xFF2A1A1A)),
      // Full set in modal:
      const SpecialKey("Settings", 0, 0x42, isMedia: true), const SpecialKey("Guide", 0, 0x43, isMedia: true),
      SpecialKey("⏮", 0, 0x00B6, isMedia: true, color: const Color(0xFF1A2A4E)),
      SpecialKey("⏵/⏸", 0, 0x00CD, isMedia: true, color: const Color(0xFF1A2A4E)),
      SpecialKey("⏭", 0, 0x00B5, isMedia: true, color: const Color(0xFF1A2A4E)),
      SpecialKey("⏹", 0, 0x00B7, isMedia: true, color: const Color(0xFF1A2A4E)),
      const SpecialKey("Ch+", 0, 0x44, isMedia: true), const SpecialKey("Ch-", 0, 0x45, isMedia: true),
      const SpecialKey("Info", 0, 0x46, isMedia: true),
      const SpecialKey("YouTube", 0, 0x3A, color: Color(0xFF4A1A1A)),
      const SpecialKey("Netflix", 0, 0x3B, color: Color(0xFF4A1A1A)),
      const SpecialKey("Prime", 0, 0x3C, color: Color(0xFF1A1A4A)),
      const SpecialKey("Hotstar", 0, 0x3D, color: Color(0xFF1A4A4A)),
      const SpecialKey("Disney+", 0, 0x3E, color: Color(0xFF1A1A4A)),
    ]);
  }
}

// ═══ Data classes ═══
class SpecialKey {
  final String label; final int modifier; final int code; final bool isMedia; final Color? color;
  const SpecialKey(this.label, this.modifier, this.code, {this.isMedia = false, this.color});
}

// ═══ CursorPainter ═══
class CursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.78)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.45, h)
      ..lineTo(w * 0.62, h * 0.94)
      ..lineTo(w * 0.47, h * 0.55)
      ..lineTo(w, h * 0.55)
      ..close();

    // Red
    canvas.drawPath(
      Path()..moveTo(0, 0)..lineTo(0, h * 0.4)..lineTo(w * 0.38, h * 0.2)..close(),
      Paint()..color = const Color(0xFFE53935)..style = PaintingStyle.fill,
    );
    // Yellow
    canvas.drawPath(
      Path()..moveTo(0, 0)..lineTo(w, h * 0.55)..lineTo(w * 0.38, h * 0.2)..close(),
      Paint()..color = const Color(0xFFFDD835)..style = PaintingStyle.fill,
    );
    // Green
    canvas.drawPath(
      Path()..moveTo(0, h * 0.4)..lineTo(0, h * 0.78)..lineTo(w * 0.3, h * 0.6)..lineTo(w * 0.45, h)
        ..lineTo(w * 0.62, h * 0.94)..lineTo(w * 0.47, h * 0.55)..lineTo(w, h * 0.55)..lineTo(w * 0.38, h * 0.2)..close(),
      Paint()..color = const Color(0xFF43A047)..style = PaintingStyle.fill,
    );
    // Outline
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    // Glow
    canvas.drawPath(path, Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══ SVGs ═══
const String _tvSvg = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M21 3H3C1.89 3 1 3.89 1 5v12c0 1.1.89 2 2 2h5v2h8v-2h5c1.1 0 2-.9 2-2V5c0-1.11-.9-2-2-2zm0 14H3V5h18v12z"/></svg>';
const String _windowsSvg = '<svg viewBox="0 0 88 88" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="4" width="38" height="38" fill="#0078D6"/><rect x="46" y="4" width="38" height="38" fill="#0078D6"/><rect x="4" y="46" width="38" height="38" fill="#0078D6"/><rect x="46" y="46" width="38" height="38" fill="#0078D6"/></svg>';
const String _macSvg = '<svg viewBox="0 0 56 68" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="M44 18C46.5 14.5 48 10 47 6C43 6.5 38.5 9 36 12.5C33.5 16 32 20.5 33 24.5C37.5 24.5 41.5 21.5 44 18Z"/><path d="M47 26C41 26 36 30 33 30C30 30 25.5 26.5 20 26.5C13 26.5 6 32 6 43C6 58 15.5 68 21 68C24 68 27 65.5 31 65.5C35 65.5 37.5 68 41 68C47 68 56 58.5 56 44C48 41 47 33 47 26Z"/></svg>';
const String _linuxTuxSvg = '<svg viewBox="0 0 100 120" xmlns="http://www.w3.org/2000/svg"><ellipse cx="50" cy="78" rx="28" ry="34" fill="#1a1a1a"/><ellipse cx="50" cy="84" rx="17" ry="24" fill="#f0f0f0"/><circle cx="50" cy="36" r="24" fill="#1a1a1a"/><ellipse cx="50" cy="38" rx="14" ry="12" fill="#f5c842"/><circle cx="43" cy="30" r="5" fill="white"/><circle cx="57" cy="30" r="5" fill="white"/><circle cx="44" cy="30" r="2.5" fill="#1a1a1a"/><circle cx="58" cy="30" r="2.5" fill="#1a1a1a"/><circle cx="45" cy="29" r="1" fill="white"/><circle cx="59" cy="29" r="1" fill="white"/><ellipse cx="50" cy="41" rx="6" ry="4" fill="#f5a623"/><ellipse cx="20" cy="76" rx="10" ry="22" fill="#1a1a1a" transform="rotate(-15 20 76)"/><ellipse cx="80" cy="76" rx="10" ry="22" fill="#1a1a1a" transform="rotate(15 80 76)"/><ellipse cx="37" cy="113" rx="10" ry="5" fill="#f5a623"/><ellipse cx="63" cy="113" rx="10" ry="5" fill="#f5a623"/></svg>';
