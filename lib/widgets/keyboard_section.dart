import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../services/bluetooth_hid_service.dart';

class KeyboardSection extends StatefulWidget {
  const KeyboardSection({super.key});

  @override
  State<KeyboardSection> createState() => _KeyboardSectionState();
}

class _KeyboardSectionState extends State<KeyboardSection> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _kbFocus = FocusNode(
    skipTraversal: true,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        Provider.of<BluetoothHidService>(context, listen: false).sendKey(0, [0x2A]);
      }
      return KeyEventResult.ignored;
    },
  );
  bool _isFocused = false;
  TextInputType _keyboardType = TextInputType.multiline;
  String _previousText = "";
  late final KeyboardVisibilityController _kbController;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _kbController = KeyboardVisibilityController();
    _kbController.onChange.listen((visible) {
      if (!mounted) return;
      
      setState(() {
        _isFocused = visible;
      });
      
      final btService = Provider.of<BluetoothHidService>(context, listen: false);
      btService.setTrackpadLocked(visible);

      if (visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scrollable.ensureVisible(
            context,
            alignment: 1.0, 
            duration: const Duration(milliseconds: 250),
          );
        });
      }
    });
  }

  void _openKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kbFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _handleTextChanged(String text, BluetoothHidService btService) {
    if (text.length < _previousText.length) {
      final diff = _previousText.length - text.length;
      for (int i = 0; i < diff; i++) {
        btService.sendKey(0, [0x2A]);
      }
    } else if (text.length > _previousText.length) {
      final newChars = text.substring(_previousText.length);
      for (int i = 0; i < newChars.length; i++) {
        final char = newChars[i];
        if (char == '\n') {
          btService.sendEnter();
        } else {
          btService.sendText(char);
        }
      }
    }
    _previousText = text;

    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _controller.clear();
          _previousText = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _controller.dispose();
    _kbFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            "⌨️ Keyboard",
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _isFocused ? cs.primary : Colors.transparent, width: 2.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: cs.primary, size: 22),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    _kbFocus.requestFocus();
                    SystemChannels.textInput.invokeMethod('TextInput.show');
                    await Future.delayed(const Duration(milliseconds: 200));
                    SystemChannels.textInput.invokeMethod('TextInput.showEmojiPicker');
                  },
                  tooltip: "Open Emoji Panel",
                ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  restorationId: 'windpad_kb',
                  controller: _controller,
                  focusNode: _kbFocus,
                  enabled: isConn,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: true,
                  onTap: _openKeyboard,
                  onChanged: (text) => _handleTextChanged(text, btService),
                  decoration: InputDecoration(
                    hintText: isConn ? "👀 See on your screen" : "Connect to type",
                    hintStyle: TextStyle(color: _isFocused ? cs.primary.withValues(alpha: 0.7) : cs.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  style: TextStyle(color: cs.onSurface, fontSize: 16, height: 1.5),
                  cursorColor: cs.primary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.backspace_outlined, color: cs.primary, size: 22),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => btService.sendKey(0, [0x2A]),
                tooltip: "Backspace (Send to PC)",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
