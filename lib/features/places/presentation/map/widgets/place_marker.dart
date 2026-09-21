import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../domain/place_category.dart';
import '../../common/category_visuals.dart';

/// A teardrop map pin in the category's colour with its icon inside.
///
/// The pin's tip sits at the bottom centre of [size], so place the marker
/// with `Alignment.topCenter` for the tip to land on the coordinate.
class PlaceMarker extends StatelessWidget {
  const PlaceMarker({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    required this.label,
  });

  /// Leaves headroom for the selected state's scale-up.
  static const size = Size(56, 64);
  static const _pinSize = Size(42, 52);

  final PlaceCategory category;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = palette.category(category);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${category.label}',
      child: Align(
        alignment: Alignment.bottomCenter,
        // New pins pop in when results change; existing ones keep their
        // state because markers are keyed by place id.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
          child: AnimatedScale(
            scale: selected ? 1.25 : 1,
            alignment: Alignment.bottomCenter,
            duration: const Duration(milliseconds: 280),
            curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                size: _pinSize,
                painter: _PinPainter(
                  color: color,
                  ring: palette.markerRing,
                  shadow: palette.shadow,
                  selected: selected,
                ),
                child: SizedBox.fromSize(
                  size: _pinSize,
                  child: Align(
                    alignment: const Alignment(0, -0.3),
                    child: Icon(category.icon, size: 19, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({
    required this.color,
    required this.ring,
    required this.shadow,
    required this.selected,
  });

  final Color color;
  final Color ring;
  final Color shadow;
  final bool selected;

  static const _ringWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - _ringWidth;
    final center = Offset(size.width / 2, radius + _ringWidth);
    final tip = Offset(size.width / 2, size.height - 1);
    final path = _teardrop(center, radius, tip);

    if (selected) {
      canvas.drawCircle(
        center,
        radius + 7,
        Paint()..color = color.withValues(alpha: 0.28),
      );
    }
    canvas.drawShadow(path, shadow, selected ? 6 : 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// A circle with straight tangent lines meeting at [tip].
  static Path _teardrop(Offset center, double radius, Offset tip) {
    final distance = (tip - center).distance;
    final alpha = math.acos(radius / distance);
    const down = math.pi / 2;
    final right = center + Offset.fromDirection(down - alpha, radius);
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        down - alpha,
        -(2 * math.pi - 2 * alpha),
        false,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.color != color ||
      old.ring != ring ||
      old.shadow != shadow ||
      old.selected != selected;
}
