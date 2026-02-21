import 'package:flutter/material.dart';

/// Splash screen with staggered pop-in animation for "expat".
/// - Background: dark teal #212C2F
/// - Each letter: scale 0.5 → 1.1 → 1.0, opacity 0 → 1, 0.4s duration, 0.1s stagger
/// Call [onComplete] when the animation finishes (parent handles navigation).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _word = 'expat';
  static const int _letterCount = 5;
  static const double _staggerSeconds = 0.1;
  static const double _letterDurationSeconds = 0.4;
  static const double _totalDurationSeconds =
      (_letterCount - 1) * _staggerSeconds + _letterDurationSeconds;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_totalDurationSeconds * 1000).round(),
      ),
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

  double get _globalTime =>
      _controller.value * _totalDurationSeconds;

  double _localProgress(int index) {
    final start = index * _staggerSeconds;
    final t = (_globalTime - start) / _letterDurationSeconds;
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return t;
  }

  static double _scaleForProgress(double t) {
    if (t <= 0) return 0.5;
    if (t >= 1) return 1.0;
    if (t < 0.6) {
      return 0.5 + (1.1 - 0.5) * (t / 0.6);
    }
    return 1.1 + (1.0 - 1.1) * ((t - 0.6) / 0.4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212C2F),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_letterCount, (i) {
                final progress = _localProgress(i);
                final scale = _scaleForProgress(progress);
                final opacity = progress.clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: Text(
                      _word[i],
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: progress >= 1.0
                            ? Colors.white
                            : const Color(0xFF8ED966),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
