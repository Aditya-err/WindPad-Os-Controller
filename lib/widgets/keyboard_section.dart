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
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String _previousText = " ";
  late final KeyboardVisibilityController _kbController;

  @override
  void initState() {
    super.initState();
    _controller.text = " ";
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _controller.value = const TextEditingValue(text: " ", selection: TextSelection.collapsed(offset: 1));
          _previousText = " ";
        }
      });
    });

    // Lock trackpad when keyboard is visible
    _kbController = KeyboardVisibilityController();
    _kbController.onChange.listen((visible) {
      if (!mounted) return;
      final btService = Provider.of<BluetoothHidService>(context, listen: false);
      btService.setTrackpadLocked(visible);
    });
  }

  void _handleTextChanged(String text, BluetoothHidService btService) {
    if (text.length < _previousText.length) {
      btService.sendKey(0, [0x2A]);
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
    Future.microtask(() {
      if (!mounted) return;
      _controller.value = const TextEditingValue(text: " ", selection: TextSelection.collapsed(offset: 1));
      _previousText = " ";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        border: Border(bottom: BorderSide(color: _isFocused ? cs.primary : cs.outlineVariant, width: _isFocused ? 2.0 : 1.0)),
      ),
      padding: const EdgeInsets.only(top: 8, left: 16, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).requestFocus(_focusNode);
              SystemChannels.textInput.invokeMethod('TextInput.show');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: isConn,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    enableSuggestions: false,
                    autocorrect: false,
                    showCursor: true,
                    onTap: () {
                      FocusScope.of(context).requestFocus(_focusNode);
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    },
                    onChanged: (text) => _handleTextChanged(text, btService),
                    decoration: InputDecoration(
                      hintText: isConn ? "Type anywhere..." : "Connect to type",
                      hintStyle: TextStyle(color: _isFocused ? cs.primary.withValues(alpha: 0.7) : cs.onSurfaceVariant, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      isDense: true,
                    ),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.01), fontSize: 16, height: 1.5),
                    cursorColor: cs.primary,
                  ),
                ),
                if (_isFocused)
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: cs.primary),
                    onPressed: () => btService.sendEmoji(),
                    tooltip: "Emoji",
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "👀 See on your screen",
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
