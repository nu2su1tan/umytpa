import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:umytpa/features/week_counter/ui/theme/tokens.dart';

/// An animated ambient background providing colorful, softly blurred blobs
/// behind liquid glass surfaces so their refraction and lighting are visible.
///
/// Features a warm off-white base with 3 large, soft color blobs (orange,
/// lilac, and light blue at ~0.3 opacity) that drift slowly with a single
/// 20s reverse-repeating [AnimationController].
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    final bool isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));

    if (isTest) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              painter: _AuroraPainter(animation: _controller, isDark: isDark),
              size: Size.infinite,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.animation, required this.isDark})
    : super(repaint: animation);

  final Animation<double> animation;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warm base color
    final Color baseColor = isDark ? Tokens.dark.bg : Tokens.light.bg;
    canvas.drawColor(baseColor, BlendMode.src);

    final double t = animation.value;

    // 2. Three soft blurred blobs (orange, lilac, light blue ~0.3 opacity)
    // Blob 1: Orange
    final Paint orangePaint = Paint()
      ..color =
          const Color(0x33C8F53C) // lime ~0.2 opacity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 75);

    final Offset orangeCenter = Offset(
      size.width * (0.75 + 0.15 * math.cos(t * 2 * math.pi)),
      size.height * (0.20 + 0.12 * math.sin(t * 2 * math.pi)),
    );
    canvas.drawCircle(orangeCenter, size.width * 0.45, orangePaint);

    // Blob 2: Lilac
    final Paint lilacPaint = Paint()
      ..color =
          const Color(0x337C4DF0) // violet ~0.2 opacity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 85);

    final Offset lilacCenter = Offset(
      size.width * (0.20 + 0.15 * math.sin(t * 2 * math.pi)),
      size.height * (0.55 + 0.14 * math.cos(t * 2 * math.pi)),
    );
    canvas.drawCircle(lilacCenter, size.width * 0.50, lilacPaint);

    // Blob 3: Light blue
    final Paint bluePaint = Paint()
      ..color =
          const Color(0x267C4DF0) // violet ~0.15 opacity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final Offset blueCenter = Offset(
      size.width * (0.65 - 0.20 * math.cos(t * 2 * math.pi)),
      size.height * (0.80 - 0.12 * math.sin(t * 2 * math.pi)),
    );
    canvas.drawCircle(blueCenter, size.width * 0.48, bluePaint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
