import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/bluetooth_hid_service.dart';
import '../services/gesture_detector.dart';
import 'device_picker_sheet.dart';

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
  double _wheelOffset = 0.0;
  double _scrollAccumulator = 0.0;



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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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
              Row(
                children: [
                  if (activeGest != null) ...[
                    _buildGestureBadge(activeGest, kGestureDefinitions, cs),
                    const SizedBox(width: 6),
                  ],
                  // Zoom In
                  _buildZoomBtn("🔍+", isConn, () => btService.sendKey(0x01, [0x2E]), cs),
                  const SizedBox(width: 4),
                  // Zoom Out
                  _buildZoomBtn("🔍−", isConn, () => btService.sendKey(0x01, [0x2D]), cs),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Touchpad Surface (Compact AspectRatio ~1.42 matching home page.jpg)
          AspectRatio(
            aspectRatio: 1.42,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackpadWidth = constraints.maxWidth;
                final trackpadHeight = constraints.maxHeight;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isConn ? btService.trackpadColor : (isDark ? const Color(0xFF1B1E28) : cs.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isConn
                            ? (isDark ? Colors.transparent : cs.outlineVariant)
                            : (isDark ? const Color(0xFF282C3A) : cs.outlineVariant),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Independent Gesture Pointer Area
                        Positioned.fill(
                          child: Listener(
                        onPointerDown: (e) => _gestureHandler.handlePointerDown(e),
                        onPointerMove: (e) {
                          _gestureHandler.handlePointerMove(e);
                          if (isConn && trackpadWidth > 0 && constraints.maxHeight > 0) {
                            setState(() {
                              _cursorPos = Offset(
                                e.localPosition.dx.clamp(0.0, trackpadWidth) / trackpadWidth,
                                e.localPosition.dy.clamp(0.0, constraints.maxHeight) / constraints.maxHeight,
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
                                      left: r.pos.dx * trackpadWidth,
                                      top: r.pos.dy * constraints.maxHeight,
                                      child: RippleWidget(color: r.color),
                                    )),
                                if (isConn) ...[
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 40),
                                    left: _cursorPos.dx * trackpadWidth - 24,
                                    top: _cursorPos.dy * constraints.maxHeight - 24,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [cs.primary.withValues(alpha: 0.3), Colors.transparent],
                                          stops: const [0.0, 0.7],
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 40),
                                    left: _cursorPos.dx * trackpadWidth - 2,
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
                                      child: Text(
                                        "🔍 $pinchPop",
                                        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                if (!isConn)
                                  Center(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => showDevicePickerSheet(context, btService, cs),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: cs.primaryContainer.withValues(alpha: 0.4),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.bluetooth_searching_rounded, color: cs.primary, size: 24),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                decoration: BoxDecoration(
                                                  color: cs.primary,
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: cs.primary.withValues(alpha: 0.25),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.bluetooth, size: 15, color: cs.onPrimary),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      btService.state == BluetoothState.scanning
                                                          ? "Connecting..."
                                                          : "Connect Bluetooth Device",
                                                      style: TextStyle(
                                                        color: cs.onPrimary,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Tap to view all available devices",
                                                style: TextStyle(color: cs.outline, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Slim (14px) & Compact (64px) Mechanical Mouse Wheel (Docked on Right Edge)
                    Positioned(
                      right: 8,
                      top: (trackpadHeight - 64) / 2,
                      child: _buildMechanicalMouseWheel(btService, cs, isDark, isConn),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      // 3 Buttons exactly matching user's design: Left Click, Right Click, Up/Down Scroll
      Row(
            children: [
              _buildClickBtn(
                "Left Click",
                "◀",
                isDark ? const Color(0xFF02538D) : cs.primaryContainer,
                isDark ? Colors.white : cs.onPrimaryContainer,
                () => isConn ? btService.sendMouseClick(1) : null,
                isConn,
                cs,
              ),
              const SizedBox(width: 8),
              _buildClickBtn(
                "Right Click",
                "▶",
                isDark ? const Color(0xFF45334E) : cs.tertiaryContainer,
                isDark ? Colors.white : cs.onTertiaryContainer,
                () => isConn ? btService.sendMouseClick(2) : null,
                isConn,
                cs,
              ),
              const SizedBox(width: 8),
              _buildScrollBtn(isConn, btService, cs, isDark),
            ],
          ),
        ],
      );
  }

  Widget _buildClickBtn(String label, String icon, Color bg, Color txt, VoidCallback? onTap, bool isConn, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: SizedBox(
        height: 74,
        child: Material(
          color: isConn ? bg : (isDark ? const Color(0xFF1B1E28) : cs.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Amber/Orange rounded box with arrow matching home page.jpg
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isConn ? const Color(0xFFFF8F00) : (isDark ? const Color(0xFF333846) : cs.outlineVariant),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: isConn ? Colors.white : (isDark ? const Color(0xFF7E8594) : cs.outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Realistic Physical Mechanical Mouse Scroll Wheel (Slim 14px × Compact 64px) ──
  Widget _buildMechanicalMouseWheel(BluetoothHidService btService, ColorScheme cs, bool isDark, bool isConn) {
    final wellColor = isDark ? const Color(0xFF13151D) : const Color(0xFFDCE0E8);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15);

    return Container(
      width: 14,
      height: 64,
      decoration: BoxDecoration(
        color: wellColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isConn) {
                btService.sendMouseClick(4); // Middle Click (wheel click)
                if (btService.hapticFeedback) HapticFeedback.mediumImpact();
              }
            },
            onVerticalDragUpdate: (details) {
              final delta = details.primaryDelta ?? 0.0;
              setState(() {
                _wheelOffset += delta;
              });
              if (!isConn) return;
              _scrollAccumulator += delta;
              const threshold = 10.0; // 10 pixels per scroll notch
              if (_scrollAccumulator.abs() >= threshold) {
                final notches = -(_scrollAccumulator / threshold).toInt();
                if (notches != 0) {
                  btService.sendScroll(notches);
                  if (btService.hapticFeedback) HapticFeedback.selectionClick();
                  _scrollAccumulator -= (-notches * threshold);
                }
              }
            },
            onVerticalDragEnd: (_) {
              _scrollAccumulator = 0.0;
            },
            child: CustomPaint(
              painter: _MechanicalWheelPainter(
                offset: _wheelOffset,
                isDark: isDark,
                primaryColor: cs.primary,
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildScrollBtn(bool isConn, BluetoothHidService btService, ColorScheme cs, bool isDark) {
    final btnBg = isDark ? const Color(0xFF2A3442) : cs.surfaceContainerHigh;
    final iconColor = isDark ? Colors.white : cs.onSurfaceVariant;
    return Expanded(
      child: SizedBox(
        height: 74,
        child: Material(
          color: isConn ? btnBg : (isDark ? const Color(0xFF1B1E28) : cs.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  onTap: isConn ? () => btService.sendScroll(1) : null,
                  child: Center(
                    child: Icon(Icons.arrow_drop_up, size: 28, color: isConn ? iconColor : (isDark ? const Color(0xFF7E8594) : cs.outline)),
                  ),
                ),
              ),
              Container(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.12) : cs.outlineVariant),
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  onTap: isConn ? () => btService.sendScroll(-1) : null,
                  child: Center(
                    child: Icon(Icons.arrow_drop_down, size: 28, color: isConn ? iconColor : (isDark ? const Color(0xFF7E8594) : cs.outline)),
                  ),
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

  Widget _buildZoomBtn(String label, bool isConn, VoidCallback onTap, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isConn ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 30,
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isConn ? cs.onSurface : cs.outline)),
          ),
        ),
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

class _MechanicalWheelPainter extends CustomPainter {
  final double offset;
  final bool isDark;
  final Color primaryColor;

  _MechanicalWheelPainter({
    required this.offset,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Wheel dimensions (Slim & Compact)
    const double wheelWidth = 16.0;
    final double left = (w - wheelWidth) / 2;
    final double right = left + wheelWidth;

    // 1. Wheel Base Cylinder
    final wheelRect = Rect.fromLTRB(left, 0, right, h);
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? const [
              Color(0xFF1E2026),
              Color(0xFF383B46),
              Color(0xFF282A33),
            ]
          : const [
              Color(0xFFBEC2CE),
              Color(0xFFE8EBF2),
              Color(0xFFCDD1DC),
            ],
      stops: const [0.0, 0.45, 1.0],
    );
    canvas.drawRect(wheelRect, Paint()..shader = baseGradient.createShader(wheelRect));

    // 2. Left & Right Metallic Edge Rims
    final rimPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(left + 0.5, 0), Offset(left + 0.5, h), rimPaint);
    canvas.drawLine(Offset(right - 0.5, 0), Offset(right - 0.5, h), rimPaint);

    // 3. 3D Cylindrical Rubber Traction Ridges (Tire Treads)
    const double ridgeSpacing = 10.0;
    final double startY = (offset % ridgeSpacing) - ridgeSpacing;
    final int count = (h / ridgeSpacing).ceil() + 3;

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final double y = startY + i * ridgeSpacing;
      if (y < -3 || y > h + 3) continue;

      // Cylindrical perspective foreshortening factor (-1 at top, 0 at center, +1 at bottom)
      final double normalized = ((y - h / 2) / (h / 2)).clamp(-1.0, 1.0);
      final double perspective = 1.0 - (normalized * normalized * 0.6);

      // Highlight line (upper ridge edge)
      highlightPaint.color = isDark
          ? Colors.white.withValues(alpha: 0.28 * perspective)
          : Colors.white.withValues(alpha: 0.85 * perspective);
      canvas.drawLine(Offset(left + 2, y), Offset(right - 2, y), highlightPaint);

      // Deep Shadow line (lower groove)
      groovePaint.color = isDark
          ? Colors.black.withValues(alpha: 0.75 * perspective)
          : Colors.black.withValues(alpha: 0.40 * perspective);
      canvas.drawLine(Offset(left + 2, y + 1.6), Offset(right - 2, y + 1.6), groovePaint);
    }

    // 4. Center Specular Axis Glow
    final centerGlowRect = Rect.fromLTRB(left + wheelWidth * 0.35, 0, left + wheelWidth * 0.55, h);
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(centerGlowRect);
    canvas.drawRect(centerGlowRect, glowPaint);

    // 5. Top & Bottom Cylindrical Curve Shadow Vignette (Rolling into the mouse cavity)
    final topShadowRect = Rect.fromLTRB(left, 0, right, 18);
    final topShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.95 : 0.70),
          Colors.black.withValues(alpha: isDark ? 0.40 : 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(topShadowRect);
    canvas.drawRect(topShadowRect, topShadowPaint);

    final bottomShadowRect = Rect.fromLTRB(left, h - 18, right, h);
    final bottomShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withValues(alpha: isDark ? 0.95 : 0.70),
          Colors.black.withValues(alpha: isDark ? 0.40 : 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bottomShadowRect);
    canvas.drawRect(bottomShadowRect, bottomShadowPaint);
  }

  @override
  bool shouldRepaint(covariant _MechanicalWheelPainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.isDark != isDark;
}
