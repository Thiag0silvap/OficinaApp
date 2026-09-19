import 'package:flutter/material.dart';

import '../core/constants/app_version.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/update_gate.dart';
import 'auth_wrapper.dart';

/// Splash in-app exibida entre o boot e o [AuthWrapper]. Faz fade-in do logo
/// (com glow e indicador de progresso decorativo) e mantém a tela visível
/// por um total fixo de 3000ms antes de navegar — tempo de leitura mínimo
/// mesmo quando o fade (1000ms) termina antes disso.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 1000);
  static const _totalDuration = Duration(milliseconds: 3000);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _progressController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )..forward();

    Future.delayed(_totalDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const UpdateGate(child: AuthWrapper()),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 70,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) => CustomPaint(
                      size: const Size(160, 16),
                      painter: _DashTrackPainter(_progressController.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xxl,
            child: FadeTransition(
              opacity: _opacity,
              child: Center(
                child: Text(
                  'OficinaApp · ${AppVersion.current}',
                  style: AppText.caption,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trilha decorativa de tracinhos com um "ponto" percorrendo da esquerda
/// para a direita conforme [progress] (0 a 1) — puramente ilustrativo, não
/// reflete progresso real de nenhuma operação.
class _DashTrackPainter extends CustomPainter {
  _DashTrackPainter(this.progress);

  final double progress;

  static const int _dashCount = 20;
  static const double _dashWidth = 5;
  static const double _dashHeight = 3;
  static const double _gap = 4;
  static const double _dotRadius = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final totalWidth =
        _dashCount * _dashWidth + (_dashCount - 1) * _gap;
    final startX = (size.width - totalWidth) / 2;
    final dotX = startX + progress * totalWidth;
    final centerY = size.height / 2;

    final filledPaint = Paint()..color = AppColors.primary;
    final unfilledPaint = Paint()..color = AppColors.border;

    for (var i = 0; i < _dashCount; i++) {
      final x = startX + i * (_dashWidth + _gap);
      final dashCenter = x + _dashWidth / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - _dashHeight / 2, _dashWidth, _dashHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        rect,
        dashCenter <= dotX ? filledPaint : unfilledPaint,
      );
    }

    canvas.drawCircle(Offset(dotX, centerY), _dotRadius, filledPaint);
  }

  @override
  bool shouldRepaint(covariant _DashTrackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
