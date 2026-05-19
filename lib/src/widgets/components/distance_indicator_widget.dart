import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

import '../inspector/box_info.dart';

class DistanceIndicatorWidget extends StatelessWidget {
  const DistanceIndicatorWidget({
    required this.boxInfo,
    required this.comparedBoxInfo,
    required this.color,
    Key? key,
  }) : super(key: key);

  final BoxInfo boxInfo;
  final BoxInfo comparedBoxInfo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = boxInfo.targetRectShifted;
    final b = comparedBoxInfo.targetRectShifted;

    final aContainsB = a.left <= b.left &&
        a.top <= b.top &&
        a.right >= b.right &&
        a.bottom >= b.bottom &&
        a != b;

    final bContainsA = b.left <= a.left &&
        b.top <= a.top &&
        b.right >= a.right &&
        b.bottom >= a.bottom &&
        a != b;

    return Stack(
      children: [
        _buildLeft(a, b, aContainsB, bContainsA),
        _buildRight(a, b, aContainsB, bContainsA),
        _buildTop(a, b, aContainsB, bContainsA),
        _buildBottom(a, b, aContainsB, bContainsA),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Direction builders
  // ---------------------------------------------------------------------------

  Widget _buildLeft(Rect a, Rect b, bool aContainsB, bool bContainsA) {
    // UC4 – A contains B
    if (aContainsB) {
      final d = b.left - a.left;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(a.left, b.center.dy), Offset(b.left, b.center.dy), d,
          Axis.horizontal);
    }

    // UC4 – B contains A
    if (bContainsA) {
      final d = a.left - b.left;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(b.left, a.center.dy), Offset(a.left, a.center.dy), d,
          Axis.horizontal);
    }

    final solidY = a.center.dy;
    late final double d;
    late final Offset solidStart, solidEnd;
    bool isOverhang = false;

    if (b.right <= a.left) {
      // B fully to the left (UC2, UC6)
      d = a.left - b.right;
      solidStart = Offset(a.left, solidY);
      solidEnd = Offset(b.right, solidY);
    } else if (b.left < a.left) {
      // B overhangs A's left (UC1)
      isOverhang = true;
      d = a.left - b.left;
      solidStart = Offset(a.left, solidY);
      solidEnd = Offset(b.left, solidY);
    } else {
      return const SizedBox.shrink();
    }

    if (d <= 0) return const SizedBox.shrink();

    final dashed =
        _verticalDashed(atX: solidEnd.dx, solidY: solidY, a: a, b: b);
    if (isOverhang && dashed == null) return const SizedBox.shrink();

    return _solidWithDashed(solidStart, solidEnd, d, Axis.horizontal, dashed);
  }

  Widget _buildRight(Rect a, Rect b, bool aContainsB, bool bContainsA) {
    // UC4 – A contains B
    if (aContainsB) {
      final d = a.right - b.right;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(b.right, b.center.dy), Offset(a.right, b.center.dy),
          d, Axis.horizontal);
    }

    // UC4 – B contains A
    if (bContainsA) {
      final d = b.right - a.right;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(a.right, a.center.dy), Offset(b.right, a.center.dy),
          d, Axis.horizontal);
    }

    final solidY = a.center.dy;
    late final double d;
    late final Offset solidStart, solidEnd;
    bool isOverhang = false;

    if (b.left >= a.right) {
      // B fully to the right
      d = b.left - a.right;
      solidStart = Offset(a.right, solidY);
      solidEnd = Offset(b.left, solidY);
    } else if (b.right > a.right) {
      // B overhangs A's right (UC1)
      isOverhang = true;
      d = b.right - a.right;
      solidStart = Offset(a.right, solidY);
      solidEnd = Offset(b.right, solidY);
    } else {
      return const SizedBox.shrink();
    }

    if (d <= 0) return const SizedBox.shrink();

    final dashed =
        _verticalDashed(atX: solidEnd.dx, solidY: solidY, a: a, b: b);
    if (isOverhang && dashed == null) return const SizedBox.shrink();

    return _solidWithDashed(solidStart, solidEnd, d, Axis.horizontal, dashed);
  }

  Widget _buildTop(Rect a, Rect b, bool aContainsB, bool bContainsA) {
    // UC4 – A contains B
    if (aContainsB) {
      final d = b.top - a.top;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(b.center.dx, a.top), Offset(b.center.dx, b.top), d,
          Axis.vertical);
    }

    // UC4 – B contains A
    if (bContainsA) {
      final d = a.top - b.top;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(a.center.dx, b.top), Offset(a.center.dx, a.top), d,
          Axis.vertical);
    }

    final solidX = a.center.dx;
    late final double d;
    late final Offset solidStart, solidEnd;
    bool isOverhang = false;

    if (b.bottom <= a.top) {
      // B fully above A
      d = a.top - b.bottom;
      solidStart = Offset(solidX, a.top);
      solidEnd = Offset(solidX, b.bottom);
    } else if (b.top < a.top) {
      // B overhangs A's top
      isOverhang = true;
      d = a.top - b.top;
      solidStart = Offset(solidX, a.top);
      solidEnd = Offset(solidX, b.top);
    } else {
      return const SizedBox.shrink();
    }

    if (d <= 0) return const SizedBox.shrink();

    final dashed =
        _horizontalDashed(atY: solidEnd.dy, solidX: solidX, a: a, b: b);
    if (isOverhang && dashed == null) return const SizedBox.shrink();

    return _solidWithDashed(solidStart, solidEnd, d, Axis.vertical, dashed);
  }

  Widget _buildBottom(Rect a, Rect b, bool aContainsB, bool bContainsA) {
    // UC4 – A contains B
    if (aContainsB) {
      final d = a.bottom - b.bottom;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(b.center.dx, b.bottom),
          Offset(b.center.dx, a.bottom), d, Axis.vertical);
    }

    // UC4 – B contains A
    if (bContainsA) {
      final d = b.bottom - a.bottom;
      if (d <= 0) return const SizedBox.shrink();
      return _solid(Offset(a.center.dx, a.bottom),
          Offset(a.center.dx, b.bottom), d, Axis.vertical);
    }

    final solidX = a.center.dx;
    late final double d;
    late final Offset solidStart, solidEnd;
    bool isOverhang = false;

    if (b.top >= a.bottom) {
      // B fully below A (UC1, UC2, UC3, UC6)
      d = b.top - a.bottom;
      solidStart = Offset(solidX, a.bottom);
      solidEnd = Offset(solidX, b.top);
    } else if (b.bottom > a.bottom) {
      // B overhangs A's bottom
      isOverhang = true;
      d = b.bottom - a.bottom;
      solidStart = Offset(solidX, a.bottom);
      solidEnd = Offset(solidX, b.bottom);
    } else {
      return const SizedBox.shrink();
    }

    if (d <= 0) return const SizedBox.shrink();

    final dashed =
        _horizontalDashed(atY: solidEnd.dy, solidX: solidX, a: a, b: b);
    if (isOverhang && dashed == null) return const SizedBox.shrink();

    return _solidWithDashed(solidStart, solidEnd, d, Axis.vertical, dashed);
  }

  // ---------------------------------------------------------------------------
  // Perpendicular dashed helpers
  // ---------------------------------------------------------------------------

  /// Vertical dashed for a horizontal solid at [atX], from B's edge to [solidY].
  /// Only produced when there is a true vertical gap between A and B (not just touching).
  _Segment? _verticalDashed({
    required double atX,
    required double solidY,
    required Rect a,
    required Rect b,
  }) {
    if (solidY < b.top && b.top > a.bottom) {
      return _Segment(Offset(atX, b.top), Offset(atX, solidY));
    }
    if (solidY > b.bottom && b.bottom < a.top) {
      return _Segment(Offset(atX, b.bottom), Offset(atX, solidY));
    }
    return null;
  }

  /// Horizontal dashed for a vertical solid at [atY], from B's edge to [solidX].
  /// Only produced when there is a true horizontal gap between A and B (not just touching).
  _Segment? _horizontalDashed({
    required double atY,
    required double solidX,
    required Rect a,
    required Rect b,
  }) {
    if (solidX < b.left && b.left > a.right) {
      return _Segment(Offset(b.left, atY), Offset(solidX, atY));
    }
    if (solidX > b.right && b.right < a.left) {
      return _Segment(Offset(b.right, atY), Offset(solidX, atY));
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Widget factories
  // ---------------------------------------------------------------------------

  Widget _solid(Offset start, Offset end, double distance, Axis direction) {
    return CustomPaint(
      painter: _LinePainter(
        start: start,
        end: end,
        distance: distance,
        color: color,
        direction: direction,
      ),
    );
  }

  Widget _solidWithDashed(
    Offset solidStart,
    Offset solidEnd,
    double distance,
    Axis solidDirection,
    _Segment? dashed,
  ) {
    if (dashed == null) {
      return _solid(solidStart, solidEnd, distance, solidDirection);
    }
    return Stack(
      children: [
        _solid(solidStart, solidEnd, distance, solidDirection),
        CustomPaint(
          painter: _LinePainter(
            start: dashed.start,
            end: dashed.end,
            distance: distance,
            color: color,
            direction: solidDirection == Axis.horizontal
                ? Axis.vertical
                : Axis.horizontal,
            isDashed: true,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class _Segment {
  const _Segment(this.start, this.end);

  final Offset start;
  final Offset end;
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.start,
    required this.end,
    required this.distance,
    required this.color,
    required this.direction,
    this.isDashed = false,
  });

  final Offset start;
  final Offset end;
  final double distance;
  final Color color;
  final Axis direction;
  final bool isDashed;

  static const double _dashLength = 5.0;
  static const double _dashGap = 4.0;
  static const double _labelPadding = 4.0;
  static const double _labelOffset = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (isDashed) {
      _drawDashed(canvas, paint);
    } else {
      canvas.drawLine(start, end, paint);
      _drawLabel(canvas);
    }
  }

  void _drawDashed(Canvas canvas, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final ux = dx / length;
    final uy = dy / length;
    double traveled = 0;
    bool drawing = true;

    while (traveled < length) {
      final next =
          (traveled + (drawing ? _dashLength : _dashGap)).clamp(0.0, length);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * traveled, start.dy + uy * traveled),
          Offset(start.dx + ux * next, start.dy + uy * next),
          paint,
        );
      }
      traveled = next;
      drawing = !drawing;
    }
  }

  void _drawLabel(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: distance.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final lw = textPainter.width + _labelPadding * 2;
    final lh = textPainter.height + _labelPadding * 2;
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    final labelCenter = direction == Axis.horizontal
        ? Offset(center.dx, center.dy - lh / 2 - _labelOffset)
        : Offset(center.dx + lw / 2 + _labelOffset, center.dy);

    final rect = Rect.fromCenter(center: labelCenter, width: lw, height: lh);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    textPainter.paint(
        canvas, Offset(rect.left + _labelPadding, rect.top + _labelPadding));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      start != old.start ||
      end != old.end ||
      distance != old.distance ||
      color != old.color ||
      direction != old.direction ||
      isDashed != old.isDashed;
}
