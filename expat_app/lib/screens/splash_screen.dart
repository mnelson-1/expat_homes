import 'package:flutter/material.dart';

/// Splash screen with multi-phase color sweep on "expat":
/// 1. Green fill L→R, hold 1s
/// 2. White clear L→R, hold 1s
/// 3. Green fill R→L, hold 1s
/// 4. Cinematic diagonal close (two panels from top corners to bottom-center), then [onComplete]
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _word = 'expat';
  static const double _sweepDuration = 1.2;
  static const double _holdDuration = 1.0;
  static const double _curtainDuration = 1.2;

  static const double _phase1Start = 0;
  static const double _phase1SweepEnd = _phase1Start + _sweepDuration;
  static const double _phase1HoldEnd = _phase1SweepEnd + _holdDuration;

  static const double _phase2Start = _phase1HoldEnd;
  static const double _phase2SweepEnd = _phase2Start + _sweepDuration;
  static const double _phase2HoldEnd = _phase2SweepEnd + _holdDuration;

  static const double _phase3Start = _phase2HoldEnd;
  static const double _phase3SweepEnd = _phase3Start + _sweepDuration;
  static const double _phase3HoldEnd = _phase3SweepEnd + _holdDuration;

  static const double _phase4Start = _phase3HoldEnd;
  static const double _phase4DiagonalEnd = _phase4Start + _curtainDuration;
  static const double _phase4HoldEnd = _phase4DiagonalEnd + _holdDuration;

  static const double _totalDuration = _phase4HoldEnd;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: (_totalDuration * 1000).round()),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              widget.onComplete?.call();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _t => _controller.value * _totalDuration;

  /// Phase 1–4 and progress 0..1 within the active sweep/hold.
  /// Phase 4 uses a more dramatic curve for the diagonal close.
  (int phase, double progress) _phaseProgress() {
    const curve = Curves.easeInOut;
    final t = _t;
    if (t < _phase1SweepEnd) return (1, curve.transform(t / _sweepDuration));
    if (t < _phase1HoldEnd) return (1, 1.0);
    if (t < _phase2SweepEnd)
      return (2, curve.transform((t - _phase2Start) / _sweepDuration));
    if (t < _phase2HoldEnd) return (2, 1.0);
    if (t < _phase3SweepEnd)
      return (3, curve.transform((t - _phase3Start) / _sweepDuration));
    if (t < _phase3HoldEnd) return (3, 1.0);
    if (t < _phase4DiagonalEnd) {
      final linear = (t - _phase4Start) / _curtainDuration;
      return (4, Curves.easeInOutCubic.transform(linear));
    }
    return (4, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2E35),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final (phase, progress) = _phaseProgress();

            final baseStyle = Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            );

            final baseText = Text(_word, style: baseStyle);
            final greenText = Text(
              _word,
              style: baseStyle?.copyWith(color: const Color(0xFF8ED966)),
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                baseText,
                ClipPath(
                  clipper: _SweepPathClipper(phase: phase, progress: progress),
                  child: greenText,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Clips the green layer: rect for phases 1–3, diagonal-close path for phase 4.
class _SweepPathClipper extends CustomClipper<Path> {
  _SweepPathClipper({required this.phase, required this.progress});

  final int phase;
  final double progress;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    switch (phase) {
      case 1:
        return Path()..addRect(Rect.fromLTWH(0, 0, w * progress, h));
      case 2:
        return Path()
          ..addRect(Rect.fromLTWH(w * progress, 0, w * (1 - progress), h));
      case 3:
        return Path()
          ..addRect(Rect.fromLTWH(w * (1 - progress), 0, w * progress, h));
      case 4:
        return _diagonalClosePath(w, h, progress);
      default:
        return Path()..addRect(Rect.fromLTWH(0, 0, w, h));
    }
  }

  /// Phase 4: two panels from top-left and top-right move diagonally
  /// toward bottom-center (cinematic close).
  Path _diagonalClosePath(double w, double h, double p) {
    final path = Path();
    if (p >= 1.0) {
      path.addRect(Rect.zero);
      return path;
    }
    final cx = w * 0.5;
    final leftX = cx * p;
    final leftY = h * p;
    final rightX = w - cx * p;
    final rightY = h * p;
    path.moveTo(0, h);
    path.lineTo(cx, h);
    path.lineTo(w, h);
    path.lineTo(rightX, rightY);
    path.lineTo(leftX, leftY);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_SweepPathClipper oldClipper) =>
      phase != oldClipper.phase || progress != oldClipper.progress;
}
