import 'dart:math' show max, min, sqrt;

import 'package:flutter/material.dart';

import '../inspector/box_info.dart';

/// A widget that displays distance indicators between two boxes,
/// similar to Figma's measurement tool.
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
    final boxRect = boxInfo.targetRectShifted;
    final comparedRect = comparedBoxInfo.targetRectShifted;

    // Use positional containment, not size alone: a larger widget positioned
    // beside the base widget should NOT be treated as a container.
    final bool comparedInsideBox = boxRect.left <= comparedRect.left &&
        boxRect.top <= comparedRect.top &&
        boxRect.right >= comparedRect.right &&
        boxRect.bottom >= comparedRect.bottom &&
        boxRect != comparedRect;

    final bool boxInsideCompared = comparedRect.left <= boxRect.left &&
        comparedRect.top <= boxRect.top &&
        comparedRect.right >= boxRect.right &&
        comparedRect.bottom >= boxRect.bottom &&
        boxRect != comparedRect;

    return Stack(
      children: [
        _buildLeftDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildRightDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildTopDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
        _buildBottomDistance(
            boxRect, comparedRect, comparedInsideBox, boxInsideCompared),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers: nearest-edge Y/X positions for external measurements
  // ---------------------------------------------------------------------------

  /// Y position for the solid horizontal measurement line (base perspective).
  /// Uses the nearest vertical edge of [boxRect] toward [comparedRect],
  /// or the center of the vertical overlap if they overlap.
  double _solidY(Rect boxRect, Rect comparedRect) {
    if (comparedRect.bottom <= boxRect.top) return boxRect.top;
    if (comparedRect.top >= boxRect.bottom) return boxRect.bottom;
    return (max(boxRect.top, comparedRect.top) +
            min(boxRect.bottom, comparedRect.bottom)) /
        2;
  }

  /// Y position for the dashed horizontal measurement line (compared perspective).
  /// Uses the nearest vertical edge of [comparedRect] toward [boxRect].
  double _dashedY(Rect boxRect, Rect comparedRect) {
    if (comparedRect.bottom <= boxRect.top) return comparedRect.bottom;
    if (comparedRect.top >= boxRect.bottom) return comparedRect.top;
    return _solidY(boxRect, comparedRect);
  }

  /// X position for the solid vertical measurement line (base perspective).
  /// Uses the nearest horizontal edge of [boxRect] toward [comparedRect],
  /// or the center of the horizontal overlap if they overlap.
  double _solidX(Rect boxRect, Rect comparedRect) {
    if (comparedRect.right <= boxRect.left) return boxRect.left;
    if (comparedRect.left >= boxRect.right) return boxRect.right;
    return (max(boxRect.left, comparedRect.left) +
            min(boxRect.right, comparedRect.right)) /
        2;
  }

  /// X position for the dashed vertical measurement line (compared perspective).
  /// Uses the nearest horizontal edge of [comparedRect] toward [boxRect].
  double _dashedX(Rect boxRect, Rect comparedRect) {
    if (comparedRect.right <= boxRect.left) return comparedRect.right;
    if (comparedRect.left >= boxRect.right) return comparedRect.left;
    return _solidX(boxRect, comparedRect);
  }

  // ---------------------------------------------------------------------------
  // Direction builders
  // ---------------------------------------------------------------------------

  Widget _buildLeftDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;
    Offset dashedStart;
    Offset dashedEnd;
    bool showDashed = true;

    if (comparedInsideBox) {
      showDashed = false;
      distance = comparedRect.left - boxRect.left;
      start = Offset(boxRect.left, comparedRect.center.dy);
      end = Offset(comparedRect.left, comparedRect.center.dy);
      dashedStart = Offset(comparedRect.left, boxRect.center.dy);
      dashedEnd = Offset(boxRect.left, boxRect.center.dy);
    } else if (boxInsideCompared) {
      showDashed = false;
      distance = boxRect.left - comparedRect.left;
      start = Offset(comparedRect.left, boxRect.center.dy);
      end = Offset(boxRect.left, boxRect.center.dy);
      dashedStart = Offset(boxRect.left, comparedRect.center.dy);
      dashedEnd = Offset(comparedRect.left, comparedRect.center.dy);
    } else {
      final solidY = _solidY(boxRect, comparedRect);
      final dashedLineY = _dashedY(boxRect, comparedRect);
      showDashed = solidY != dashedLineY;

      distance = boxRect.left - comparedRect.right;
      start = Offset(boxRect.left, solidY);
      end = Offset(comparedRect.right, solidY);
      dashedStart = Offset(comparedRect.right, dashedLineY);
      dashedEnd = Offset(boxRect.left, dashedLineY);

      if (distance <= 0) {
        // Fallback: compared extends past the left of base (wider or offset).
        // Show the overhang distance but without dashed lines to avoid clutter.
        distance = boxRect.left - comparedRect.left;
        if (distance <= 0) return const SizedBox.shrink();
        showDashed = false;
        end = Offset(comparedRect.left, solidY);
        dashedStart = Offset(comparedRect.left, dashedLineY);
        dashedEnd = Offset(boxRect.left, dashedLineY);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: start,
            end: end,
            distance: distance,
            color: color,
            direction: Axis.horizontal,
          ),
        ),
        if (showDashed)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashedStart,
              end: dashedEnd,
              distance: distance,
              color: color,
              direction: Axis.horizontal,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  Widget _buildRightDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;
    Offset dashedStart;
    Offset dashedEnd;
    bool showDashed = true;

    if (comparedInsideBox) {
      showDashed = false;
      distance = boxRect.right - comparedRect.right;
      start = Offset(comparedRect.right, comparedRect.center.dy);
      end = Offset(boxRect.right, comparedRect.center.dy);
      dashedStart = Offset(comparedRect.right, boxRect.center.dy);
      dashedEnd = Offset(boxRect.right, boxRect.center.dy);
    } else if (boxInsideCompared) {
      showDashed = false;
      distance = comparedRect.right - boxRect.right;
      start = Offset(boxRect.right, boxRect.center.dy);
      end = Offset(comparedRect.right, boxRect.center.dy);
      dashedStart = Offset(boxRect.right, comparedRect.center.dy);
      dashedEnd = Offset(comparedRect.right, comparedRect.center.dy);
    } else {
      final solidY = _solidY(boxRect, comparedRect);
      final dashedLineY = _dashedY(boxRect, comparedRect);
      showDashed = solidY != dashedLineY;

      distance = comparedRect.left - boxRect.right;
      start = Offset(boxRect.right, solidY);
      end = Offset(comparedRect.left, solidY);
      dashedStart = Offset(comparedRect.left, dashedLineY);
      dashedEnd = Offset(boxRect.right, dashedLineY);

      if (distance <= 0) {
        // Fallback: compared extends past the right of base (wider or offset).
        // Show the overhang distance but without dashed lines to avoid clutter.
        distance = comparedRect.right - boxRect.right;
        if (distance <= 0) return const SizedBox.shrink();
        showDashed = false;
        end = Offset(comparedRect.right, solidY);
        dashedStart = Offset(comparedRect.right, dashedLineY);
        dashedEnd = Offset(boxRect.right, dashedLineY);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: start,
            end: end,
            distance: distance,
            color: color,
            direction: Axis.horizontal,
          ),
        ),
        if (showDashed)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashedStart,
              end: dashedEnd,
              distance: distance,
              color: color,
              direction: Axis.horizontal,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  Widget _buildTopDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;
    Offset dashedStart;
    Offset dashedEnd;
    bool showDashed = true;

    if (comparedInsideBox) {
      showDashed = false;
      distance = comparedRect.top - boxRect.top;
      start = Offset(comparedRect.center.dx, boxRect.top);
      end = Offset(comparedRect.center.dx, comparedRect.top);
      dashedStart = Offset(boxRect.center.dx, comparedRect.top);
      dashedEnd = Offset(boxRect.center.dx, boxRect.top);
    } else if (boxInsideCompared) {
      showDashed = false;
      distance = boxRect.top - comparedRect.top;
      start = Offset(boxRect.center.dx, comparedRect.top);
      end = Offset(boxRect.center.dx, boxRect.top);
      dashedStart = Offset(comparedRect.center.dx, boxRect.top);
      dashedEnd = Offset(comparedRect.center.dx, comparedRect.top);
    } else {
      final solidLineX = _solidX(boxRect, comparedRect);
      final dashedLineX = _dashedX(boxRect, comparedRect);
      showDashed = solidLineX != dashedLineX;

      distance = boxRect.top - comparedRect.bottom;
      start = Offset(solidLineX, boxRect.top);
      end = Offset(solidLineX, comparedRect.bottom);
      dashedStart = Offset(dashedLineX, comparedRect.bottom);
      dashedEnd = Offset(dashedLineX, boxRect.top);

      if (distance <= 0) {
        // Fallback: compared extends past the top of base (taller or offset).
        // Show the overhang distance but without dashed lines to avoid clutter.
        distance = boxRect.top - comparedRect.top;
        if (distance <= 0) return const SizedBox.shrink();
        showDashed = false;
        end = Offset(solidLineX, comparedRect.top);
        dashedStart = Offset(dashedLineX, comparedRect.top);
        dashedEnd = Offset(dashedLineX, boxRect.top);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: start,
            end: end,
            distance: distance,
            color: color,
            direction: Axis.vertical,
          ),
        ),
        if (showDashed)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashedStart,
              end: dashedEnd,
              distance: distance,
              color: color,
              direction: Axis.vertical,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    double distance;
    Offset start;
    Offset end;
    Offset dashedStart;
    Offset dashedEnd;
    bool showDashed = true;

    if (comparedInsideBox) {
      showDashed = false;
      distance = boxRect.bottom - comparedRect.bottom;
      start = Offset(comparedRect.center.dx, comparedRect.bottom);
      end = Offset(comparedRect.center.dx, boxRect.bottom);
      dashedStart = Offset(boxRect.center.dx, comparedRect.bottom);
      dashedEnd = Offset(boxRect.center.dx, boxRect.bottom);
    } else if (boxInsideCompared) {
      showDashed = false;
      distance = comparedRect.bottom - boxRect.bottom;
      start = Offset(boxRect.center.dx, boxRect.bottom);
      end = Offset(boxRect.center.dx, comparedRect.bottom);
      dashedStart = Offset(comparedRect.center.dx, boxRect.bottom);
      dashedEnd = Offset(comparedRect.center.dx, comparedRect.bottom);
    } else {
      final solidLineX = _solidX(boxRect, comparedRect);
      final dashedLineX = _dashedX(boxRect, comparedRect);
      showDashed = solidLineX != dashedLineX;

      distance = comparedRect.top - boxRect.bottom;
      start = Offset(solidLineX, boxRect.bottom);
      end = Offset(solidLineX, comparedRect.top);
      dashedStart = Offset(dashedLineX, comparedRect.top);
      dashedEnd = Offset(dashedLineX, boxRect.bottom);

      if (distance <= 0) {
        // Fallback: compared extends past the bottom of base (taller or offset).
        // Show the overhang distance but without dashed lines to avoid clutter.
        distance = comparedRect.bottom - boxRect.bottom;
        if (distance <= 0) return const SizedBox.shrink();
        showDashed = false;
        end = Offset(solidLineX, comparedRect.bottom);
        dashedStart = Offset(dashedLineX, comparedRect.bottom);
        dashedEnd = Offset(dashedLineX, boxRect.bottom);
      }
    }

    if (distance <= 0) return const SizedBox.shrink();

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: start,
            end: end,
            distance: distance,
            color: color,
            direction: Axis.vertical,
          ),
        ),
        if (showDashed)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashedStart,
              end: dashedEnd,
              distance: distance,
              color: color,
              direction: Axis.vertical,
              isDashed: true,
            ),
          ),
      ],
    );
  }
}

class _DistanceLinePainter extends CustomPainter {
  _DistanceLinePainter({
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

  static const double labelPadding = 4.0;
  static const double _dashLength = 5.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    if (isDashed) {
      _drawDashedLine(canvas, paint);
    } else {
      canvas.drawLine(start, end, paint);
      _drawLabel(canvas);
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lineLength = sqrt(dx * dx + dy * dy);
    if (lineLength == 0) return;

    final unitDx = dx / lineLength;
    final unitDy = dy / lineLength;

    double traveled = 0;
    bool drawing = true;

    while (traveled < lineLength) {
      final segmentLength = drawing ? _dashLength : _dashGap;
      final next = (traveled + segmentLength).clamp(0.0, lineLength);

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitDx * traveled, start.dy + unitDy * traveled),
          Offset(start.dx + unitDx * next, start.dy + unitDy * next),
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
    );

    textPainter.layout();

    final labelWidth = textPainter.width + labelPadding * 2;
    final labelHeight = textPainter.height + labelPadding * 2;
    const double labelOffset = 6.0;

    final Offset lineCenter = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final Offset labelCenter;
    if (direction == Axis.horizontal) {
      labelCenter = Offset(
        lineCenter.dx,
        lineCenter.dy - labelHeight / 2 - labelOffset,
      );
    } else {
      labelCenter = Offset(
        lineCenter.dx + labelWidth / 2 + labelOffset,
        lineCenter.dy,
      );
    }

    final Rect labelRect = Rect.fromCenter(
      center: labelCenter,
      width: labelWidth,
      height: labelHeight,
    );

    final labelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
      labelPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        labelRect.left + labelPadding,
        labelRect.top + labelPadding,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DistanceLinePainter oldDelegate) =>
      start != oldDelegate.start ||
      end != oldDelegate.end ||
      distance != (oldDelegate).distance ||
      color != oldDelegate.color ||
      direction != oldDelegate.direction ||
      isDashed != oldDelegate.isDashed;
}
