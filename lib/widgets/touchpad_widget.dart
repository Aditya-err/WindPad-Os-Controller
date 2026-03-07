import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_hid_service.dart';
import '../services/gesture_detector.dart';

class TouchpadWidget extends StatelessWidget {
  const TouchpadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TouchpadInternal();
  }
}

class _TouchpadInternal extends StatefulWidget {
  const _TouchpadInternal();

  @override
  State<_TouchpadInternal> createState() => _TouchpadInternalState();
}

class _TouchpadInternalState extends State<_TouchpadInternal> with SingleTickerProviderStateMixin {
  late WindpadGestureDetector _gestureHandler;
  Offset _cursorPos = const Offset(0.5, 0.5);
  final List<RippleData> _ripples = [];

  @override
  void initState() {
    super.initState();
    final btService = Provider.of<BluetoothHidService>(context, listen: false);
    _gestureHandler = WindpadGestureDetector(btService);
  }

  void _addRipple(Offset localPos, Color color) {
    setState(() {
      _ripples.add(RippleData(pos: localPos, color: color, startTime: DateTime.now()));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _ripples.removeWhere((r) => DateTime.now().difference(r.startTime).inMilliseconds > 650);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final btService = Provider.of<BluetoothHidService>(context);
    final isConn = btService.state == BluetoothState.connected;
    final activeGest = btService.activeGesture;
    final pinchPop = btService.pinchPop;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(offset: const Offset(0, 1), blurRadius: 3, color: cs.shadow.withValues(alpha: 0.1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TRACKPAD", style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(isConn ? "Touch to control cursor" : "Connect a device first", style: TextStyle(color: cs.onSurface, fontSize: 13)),
                ],
              ),
              if (activeGest != null) _buildGestureBadge(activeGest, kGestureDefinitions, cs),
            ],
          ),
          const SizedBox(height: 12),
          // Touchpad Surface
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Listener(
                  onPointerDown: (e) => _gestureHandler.handlePointerDown(e),
                  onPointerMove: (e) {
                    _gestureHandler.handlePointerMove(e);
                    if (isConn) {
                      final box = context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(e.position);
                      setState(() {
                        _cursorPos = Offset(
                          localPos.dx.clamp(0.0, box.size.width) / box.size.width,
                          localPos.dy.clamp(0.0, box.size.height) / box.size.height,
                        );
                      });
                    }
                  },
                  onPointerCancel: (e) => _gestureHandler.handlePointerCancel(e),
                  onPointerUp: (e) {
                    _gestureHandler.handlePointerUp(e);
                    if (isConn && activeGest != null && (activeGest == "singleTap" || activeGest == "twoTap")) {
                      _addRipple(_cursorPos, cs.primary.withValues(alpha: 0.18));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isConn ? btService.trackpadColor : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isConn ? cs.primaryContainer : cs.outlineVariant, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (isConn) CustomPaint(painter: DotGridPainter(color: cs.primaryContainer), size: Size.infinite),
                          ..._ripples.map((r) => Positioned(
                                left: r.pos.dx * constraints.maxWidth,
                                top: r.pos.dy * constraints.maxHeight,
                                child: RippleWidget(color: r.color),
                              )),
                          if (isConn) ...[
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 40),
                              left: _cursorPos.dx * constraints.maxWidth - 24,
                              top: _cursorPos.dy * constraints.maxHeight - 24,
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [cs.primary.withValues(alpha: 0.3), Colors.transparent], stops: const [0.0, 0.7]),
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 40),
                              left: _cursorPos.dx * constraints.maxWidth - 2,
                              top: _cursorPos.dy * constraints.maxHeight - 2,
                              child: MouseCursorWidget(color: cs.primary),
                            ),
                          ],
                          if (pinchPop != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text("🔍 $pinchPop", style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500, fontSize: 13)),
                              ),
                            ),
                          if (!isConn)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.3,
                                    child: CustomPaint(painter: CursorPainter(color: cs.outlineVariant, shadowColor: cs.outline), size: const Size(20, 24)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    btService.state == BluetoothState.scanning ? "Connecting via Bluetooth…" : "Tap Connect to get started",
                                    style: TextStyle(color: cs.outline, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Buttons
          Row(
            children: [
              _buildClickBtn("Left Click", "◀", cs.primaryContainer, cs.onPrimaryContainer, () => isConn ? btService.sendMouseClick(1) : null, isConn, cs),
              const SizedBox(width: 8),
              _buildClickBtn("Right Click", "▶", cs.tertiaryContainer, cs.onTertiaryContainer, () => isConn ? btService.sendMouseClick(2) : null, isConn, cs),
              const SizedBox(width: 8),
              _buildScrollBtn(isConn, btService, cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickBtn(String label, String icon, Color bg, Color txt, VoidCallback? onTap, bool isConn, ColorScheme cs) {
    return Expanded(
      child: SizedBox(
        height: 76,
        child: Material(
          color: isConn ? bg : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          elevation: isConn ? 3 : 0,
          shadowColor: cs.shadow.withValues(alpha: 0.5),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isConn ? cs.outlineVariant.withValues(alpha: 0.5) : Colors.transparent, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: 18, color: isConn ? txt : cs.outline)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: isConn ? txt : cs.outline)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollBtn(bool isConn, BluetoothHidService btService, ColorScheme cs) {
    return Expanded(
      child: SizedBox(
        height: 76,
        child: Material(
          color: isConn ? cs.secondaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          elevation: isConn ? 3 : 0,
          shadowColor: cs.shadow.withValues(alpha: 0.5),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isConn ? cs.outlineVariant.withValues(alpha: 0.5) : Colors.transparent, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => isConn ? btService.sendScroll(1) : null,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Center(child: Icon(Icons.arrow_drop_up, size: 30, color: isConn ? cs.onSecondaryContainer : cs.outline)),
                ),
              ),
              Container(height: 1, color: isConn ? cs.onSecondaryContainer.withValues(alpha: 0.15) : cs.outlineVariant),
              Expanded(
                child: InkWell(
                  onTap: () => isConn ? btService.sendScroll(-1) : null,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Center(child: Icon(Icons.arrow_drop_down, size: 30, color: isConn ? cs.onSecondaryContainer : cs.outline)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildGestureBadge(String? id, List<Map<String, dynamic>> gestureList, ColorScheme cs) {
    final g = gestureList.firstWhere((g) => g["id"] == id, orElse: () => {});
    if (g.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(g["icon"] as String, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(g["action"] as String, style: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class RippleData {
  final Offset pos;
  final Color color;
  final DateTime startTime;
  RippleData({required this.pos, required this.color, required this.startTime});
}

class RippleWidget extends StatefulWidget {
  final Color color;
  const RippleWidget({super.key, required this.color});

  @override
  State<RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<RippleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radius;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _radius = Tween<double>(begin: 0, end: 120).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-_radius.value / 2, -_radius.value / 2),
          child: Container(
            width: _radius.value,
            height: _radius.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: _opacity.value),
            ),
          ),
        );
      },
    );
  }
}

class MouseCursorWidget extends StatelessWidget {
  final Color color;
  const MouseCursorWidget({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: CursorPainter(color: color, shadowColor: color), size: const Size(20, 24));
  }
}

class CursorPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  CursorPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(2, 1)..lineTo(2, 20)..lineTo(6, 16)..lineTo(9, 22)..lineTo(12, 21)..lineTo(9, 15)..lineTo(16, 15)..close();
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)..style = PaintingStyle.fill);
    canvas.restore();
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DotGridPainter extends CustomPainter {
  final Color color;
  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.fill;
    const pxs = [0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85];
    const pys = [0.20, 0.40, 0.60, 0.80];
    for (var px in pxs) {
      for (var py in pys) {
        canvas.drawCircle(Offset(size.width * px, size.height * py), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final List<Map<String, dynamic>> kGestureDefinitions = [
  {"id": "singleTap", "action": "Left Click", "icon": "☝️"},
  {"id": "twoTap", "action": "Right Click", "icon": "✌️"},
  {"id": "drag", "action": "Move Cursor", "icon": "👆"},
  {"id": "twoScroll", "action": "Scroll", "icon": "🤞"},
  {"id": "pinch", "action": "Zoom In/Out", "icon": "🤏"},
  {"id": "threeSwipe", "action": "App Switch", "icon": "🖖"},
];
