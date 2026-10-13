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
      if (event is KeyDownEvent) {
        final btService = Provider.of<BluetoothHidService>(context, listen: false);
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          if (btService.isTyping) {
            btService.stopTyping();
            _isProgrammaticClear = true;
            _controller.clear();
            _previousText = "";
            return KeyEventResult.handled;
          }
          btService.sendKey(0, [0x2A]);
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (btService.isTyping) {
            btService.stopTyping();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    },
  );
  bool _isFocused = false;
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

  bool _isProgrammaticClear = false;

  void _openKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kbFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  void _handleTextChanged(String text, BluetoothHidService btService) {
    if (_isProgrammaticClear) {
      _isProgrammaticClear = false;
      return;
    }

    if (text.length < _previousText.length) {
      if (btService.isTyping) {
        btService.stopTyping();
        _isProgrammaticClear = true;
        _controller.clear();
        _previousText = "";
        return;
      }
      final diff = _previousText.length - text.length;
      _previousText = text;
      for (int i = 0; i < diff; i++) {
        btService.sendKey(0, [0x2A]);
      }
    } else if (text.length > _previousText.length) {
      final newChars = text.substring(_previousText.length);
      _previousText = text;
      btService.sendText(newChars);
    }

    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !btService.isTyping) {
        _isProgrammaticClear = true;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                "⌨ Keyboard",
                style: TextStyle(
                  color: isDark ? const Color(0xFF7E8594) : cs.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (btService.isTyping)
              GestureDetector(
                onTap: () {
                  btService.stopTyping();
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _isProgrammaticClear = true;
                    _controller.clear();
                    _previousText = "";
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, size: 13, color: Colors.white),
                      SizedBox(width: 3),
                      Text("STOP PASTE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (btService.isTyping)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE53935)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5252)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pasting text: ${btService.typingCurrent}/${btService.typingTotal} characters...",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      btService.stopTyping();
                      HapticFeedback.heavyImpact();
                      setState(() {
                        _isProgrammaticClear = true;
                        _controller.clear();
                        _previousText = "";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text("STOP", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222732) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _isFocused ? const Color(0xFF58A6FF) : Colors.transparent, width: 2.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.emoji_emotions_outlined, color: isDark ? const Color(0xFF8E95A5) : cs.primary, size: 22),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: isConn ? () => btService.sendEmoji() : null,
                tooltip: "Default Emoji",
              ),
              const SizedBox(width: 4),
              // Dedicated Paste/Stop Button
              if (btService.isTyping)
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Color(0xFFFF5252), size: 24),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    btService.stopTyping();
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isProgrammaticClear = true;
                      _controller.clear();
                      _previousText = "";
                    });
                  },
                  tooltip: "Stop Pasting Immediately",
                )
              else
                IconButton(
                  icon: Icon(Icons.content_paste_rounded, color: isDark ? const Color(0xFF8E95A5) : cs.primary, size: 20),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: isConn
                      ? () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            _handleTextChanged(data.text!, btService);
                          }
                        }
                      : null,
                  tooltip: "Paste from Phone Clipboard",
                ),
              const SizedBox(width: 6),
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
                    suffixIcon: (_controller.text.isNotEmpty || btService.isTyping)
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: isDark ? const Color(0xFF8E95A5) : cs.outline,
                            onPressed: () {
                              btService.stopTyping();
                              setState(() {
                                _isProgrammaticClear = true;
                                _controller.clear();
                                _previousText = "";
                              });
                            },
                            tooltip: "Clear / Stop",
                          )
                        : null,
                  ),
                  style: TextStyle(color: cs.onSurface, fontSize: 16, height: 1.5),
                  cursorColor: cs.primary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.backspace_outlined, color: isDark ? const Color(0xFF8E95A5) : cs.primary, size: 22),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (btService.isTyping) {
                    btService.stopTyping();
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isProgrammaticClear = true;
                      _controller.clear();
                      _previousText = "";
                    });
                  } else {
                    btService.sendKey(0, [0x2A]);
                  }
                },
                tooltip: "Backspace (Send to PC / Stop Paste)",
              ),
            ],
          ),
        ),
      ],
    );
  }
}
