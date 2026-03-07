import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            border: Border(bottom: BorderSide(color: _isFocused ? cs.primary : cs.outlineVariant, width: _isFocused ? 2.0 : 1.0)),
          ),
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 4),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: isConn,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (text) => _handleTextChanged(text, btService),
            decoration: InputDecoration(
              labelText: isConn ? "Type anywhere..." : "Connect to type",
              labelStyle: TextStyle(color: _isFocused ? cs.primary : cs.onSurfaceVariant, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            style: TextStyle(color: cs.onSurface, fontSize: 16, height: 1.5),
            cursorColor: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            "Opens your default phone keyboard (Gboard, Samsung, etc.)",
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
