import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../week_counter/ui/theme/tokens.dart';

/// A short burst of confetti. Call [ConfettiBurstState.fire] to play it.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => ConfettiBurstState();
}

class ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  final math.Random _random = math.Random();
  List<_Piece> _pieces = const <_Piece>[];

  void fire() {
    _pieces = List<_Piece>.generate(46, (int _) => _Piece.random(_random));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          if (!_controller.isAnimating) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _controller.value),
          );
        },
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
  });

  factory _Piece.random(math.Random r) => _Piece(
    angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
    speed: 220 + r.nextDouble() * 360,
    spin: (r.nextDouble() - 0.5) * 14,
    size: 5 + r.nextDouble() * 6,
    color: _palette[r.nextInt(_palette.length)],
  );

  static const List<Color> _palette = <Color>[
    Tokens.lime,
    Tokens.violet,
    Color(0xFFFFD166),
    Color(0xFF4CC9F0),
    Color(0xFFFF6B9D),
  ];

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * 0.28);
    const double gravity = 620;
    final double seconds = t * 1.6;
    for (final _Piece p in pieces) {
      final double x = origin.dx + math.cos(p.angle) * p.speed * seconds;
      final double y =
          origin.dy +
          math.sin(p.angle) * p.speed * seconds +
          0.5 * gravity * seconds * seconds;
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t * t).clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * seconds)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
