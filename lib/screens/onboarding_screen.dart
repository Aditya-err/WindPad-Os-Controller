import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_selection_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui' as ui;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DeviceSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 800), curve: Curves.easeInOutExpo);
    } else {
      _onIntroEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? const Color(0xFF080808) : const Color(0xFFF8F9FF);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0F);
    final accent = isDark ? const Color(0xFF4285F4) : const Color(0xFF0061A4);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: Stack(
        children: [
          // Background Gradient Mesh (Looping Colors)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MeshPainter(
                    color1: isDark ? const Color(0xFF080808) : const Color(0xFFF0F2FF),
                    color2: isDark ? const Color(0xFF0D0D1F) : const Color(0xFFE6EFFF),
                    progress: _animController.value,
                  ),
                );
              },
            ),
          ),

          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            children: [
              _PageOne(isDark: isDark, textPrimary: textPrimary, accent: accent),
              _PageTwo(isDark: isDark, textPrimary: textPrimary, accent: accent),
              _PageThree(isDark: isDark, textPrimary: textPrimary, accent: accent),
              _PageFour(isDark: isDark, textPrimary: textPrimary, accent: accent),
            ],
          ),

          // Bottom Navigation
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _currentPage == 3
                    ? GestureDetector(
                        onTap: _onIntroEnd,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Let's Go →",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _onIntroEnd,
                            style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white38 : Colors.black38),
                            child: const Text("Skip", style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          // Pagination Line
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.black12,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: 400.ms,
                                    height: 2,
                                    width: (MediaQuery.of(context).size.width - 200) * ((_currentPage + 1) / 4),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 6)],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _nextPage,
                            icon: Icon(Icons.arrow_forward_ios, color: textPrimary, size: 20),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double progress;

  _MeshPainter({required this.color1, required this.color2, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.8, size.height),
        [color1, color2, color1],
        [0.0, 0.5 + 0.2 * ui.lerpDouble(-1, 1, progress)!, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) => oldDelegate.progress != progress;
}

class _PageOne extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color accent;
  const _PageOne({required this.isDark, required this.textPrimary, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _CursorPainter(color: accent),
              ).animate().custom(duration: 1500.ms, builder: (context, val, child) {
                  return CustomPaint(
                    painter: _CursorPainter(color: accent, drawingProgress: val),
                  );
              }),
            ),
          ),
          const SizedBox(height: 100),
          ...[
            "Your",
            "phone.",
            "Now",
            "a trackpad."
          ].asMap().entries.map((e) => Text(
                e.value,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1.5,
                  color: textPrimary,
                ),
              ).animate(delay: (e.key * 100).ms).fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0)),
          const SizedBox(height: 24),
          Text(
            "Wireless. Instant. No BS.",
            style: TextStyle(fontSize: 18, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w600),
          ).animate(delay: 800.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  final Color color;
  final double drawingProgress;
  _CursorPainter({required this.color, this.drawingProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Simple trackpad representation (rounded rect)
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 20, size.width, size.height - 40), const Radius.circular(20)));
    // Cursor arrow
    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.58, size.height * 0.62);
    path.lineTo(size.width * 0.65, size.height * 0.75);
    path.lineTo(size.width * 0.6, size.height * 0.78);
    path.lineTo(size.width * 0.53, size.height * 0.65);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.close();

    ui.PathMetrics metrics = path.computeMetrics();
    for (ui.PathMetric metric in metrics) {
      canvas.drawPath(metric.extractPath(0, metric.length * drawingProgress), paint);
    }
  }

  @override
  bool shouldRepaint(_CursorPainter oldDelegate) => oldDelegate.drawingProgress != drawingProgress;
}

class _PageTwo extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color accent;
  const _PageTwo({required this.isDark, required this.textPrimary, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep(0, "01", "Open Windpad"),
          const SizedBox(height: 32),
          _buildStep(1, "02", "Scan QR on PC"),
          const SizedBox(height: 32),
          _buildStep(2, "03", "Done. Control everything."),
          const SizedBox(height: 80),
          Text(
            "3 steps.\nThat's it.",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1, color: textPrimary, height: 1.1),
          ).animate(delay: 600.ms).fadeIn().slideX(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildStep(int idx, String num, String text) {
    return Row(
      children: [
        Text(num, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: accent))
            .animate(delay: (idx * 200).ms).fadeIn().slideX(begin: -0.5),
        const SizedBox(width: 24),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary))
              .animate(delay: (idx * 200).ms).fadeIn().slideX(begin: 0.5),
        ),
      ],
    );
  }
}

class _PageThree extends StatefulWidget {
  final bool isDark;
  final Color textPrimary;
  final Color accent;
  const _PageThree({required this.isDark, required this.textPrimary, required this.accent});
  @override
  State<_PageThree> createState() => _PageThreeState();
}

class _PageThreeState extends State<_PageThree> {
  int _selectedIdx = 0;
  final List<String> _chips = ["Remote", "Keyboard", "Gestures", "Media", "TV", "Shortcuts"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 140.0, left: 40, right: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Everything.\nOne App.", 
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1, color: widget.textPrimary, height: 1.1),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _chips.asMap().entries.map((e) {
              final isSel = _selectedIdx == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedIdx = e.key),
                child: AnimatedContainer(
                  duration: 300.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? widget.accent : (widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSel ? [BoxShadow(color: widget.accent.withValues(alpha: 0.3), blurRadius: 12)] : [],
                  ),
                  child: Text(e.value, style: TextStyle(color: isSel ? Colors.white : widget.textPrimary, fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 1.0, end: 0, delay: (e.key * 50).ms, curve: Curves.elasticOut);
            }).toList(),
          ),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: 300.ms,
            child: Text(
              "Control your cursor, media, and typing with premium precision.",
              key: ValueKey(_selectedIdx),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: widget.textPrimary.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageFour extends StatefulWidget {
  final bool isDark;
  final Color textPrimary;
  final Color accent;
  const _PageFour({required this.isDark, required this.textPrimary, required this.accent});
  @override
  State<_PageFour> createState() => _PageFourState();
}

class _PageFourState extends State<_PageFour> with SingleTickerProviderStateMixin {
  late AnimationController _lineController;
  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.smartphone, color: widget.accent, size: 48),
              Expanded(
                child: SizedBox(
                   height: 40,
                   child: CustomPaint(
                     painter: _DashedLinePainter(color: widget.accent, progress: _lineController.value),
                   ),
                ),
              ),
              Icon(Icons.desktop_windows_rounded, color: widget.textPrimary, size: 64),
            ],
          ),
          const SizedBox(height: 100),
          Text(
            "Same WiFi.\nInstant connect.",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1, color: widget.textPrimary, height: 1.1),
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 24),
          Text(
            "Phone and PC on same network? You're good to go.",
            style: TextStyle(fontSize: 18, color: widget.isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  _DashedLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    const dashWidth = 10.0;
    const dashSpace = 10.0;
    double startX = size.width * progress;

    canvas.drawLine(
      Offset(startX % size.width, size.height / 2),
      Offset((startX + dashWidth) % size.width, size.height / 2),
      dashPaint
    );
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => true;
}
