import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

import '../inspector/box_info.dart';

/// A widget that displays distance indicators between two boxes,
/// similar to Figma's measurement tool.
///
/// * **Solid lines** start from the *center* of A's side and end at the
///   projected point on B's corresponding side (same axis level).
/// * **Dotted lines** start from an edge of component B and connect to the
///   floating endpoint of a solid line, always perpendicular to the solid line.
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
  // Direction builders
  // ---------------------------------------------------------------------------

  /// Builds a horizontal distance line on the LEFT side.
  ///
  /// Solid line runs at [boxRect.center.dy] (A's vertical centre).
  /// A perpendicular dashed line is added when A's vertical centre is outside
  /// B's vertical bounds, connecting B's nearest horizontal edge to the solid
  /// line's endpoint.
  Widget _buildLeftDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    // --- Inside cases (Use Case 4) ---
    if (comparedInsideBox) {
      // A contains B: from A.left to B.left at B.center.dy
      final distance = comparedRect.left - boxRect.left;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(boxRect.left, comparedRect.center.dy),
          end: Offset(comparedRect.left, comparedRect.center.dy),
          distance: distance,
          color: color,
          direction: Axis.horizontal,
        ),
      );
    }

    if (boxInsideCompared) {
      // B contains A: from B.left to A.left at A.center.dy
      final distance = boxRect.left - comparedRect.left;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(comparedRect.left, boxRect.center.dy),
          end: Offset(boxRect.left, boxRect.center.dy),
          distance: distance,
          color: color,
          direction: Axis.horizontal,
        ),
      );
    }

    // --- External case ---
    // Determine weather B is fully to the left, or extends past A's left edge.
    final solidY = boxRect.center.dy;
    double distance;
    Offset solidStart;
    Offset bEndpoint; // the B-side endpoint of the solid line

    if (comparedRect.right <= boxRect.left) {
      // B is fully to the left of A (gap exists)
      distance = boxRect.left - comparedRect.right;
      solidStart = Offset(boxRect.left, solidY);
      bEndpoint = Offset(comparedRect.right, solidY);
    } else if (comparedRect.left < boxRect.left) {
      // B extends past A's left edge (overhang)
      distance = boxRect.left - comparedRect.left;
      solidStart = Offset(boxRect.left, solidY);
      bEndpoint = Offset(comparedRect.left, solidY);
    } else {
      return const SizedBox.shrink();
    }

    if (distance <= 0) return const SizedBox.shrink();

    // Optional perpendicular dashed line at x = bEndpoint.dx
    final dashed = _perpendicularDashedForHorizontal(
      bEndpointX: bEndpoint.dx,
      solidY: solidY,
      comparedRect: comparedRect,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: solidStart,
            end: bEndpoint,
            distance: distance,
            color: color,
            direction: Axis.horizontal,
          ),
        ),
        if (dashed != null)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashed.start,
              end: dashed.end,
              distance: distance,
              color: color,
              direction: Axis.vertical,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  /// Builds a horizontal distance line on the RIGHT side.
  Widget _buildRightDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    // --- Inside cases ---
    if (comparedInsideBox) {
      // A contains B: from B.right to A.right at B.center.dy
      final distance = boxRect.right - comparedRect.right;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(comparedRect.right, comparedRect.center.dy),
          end: Offset(boxRect.right, comparedRect.center.dy),
          distance: distance,
          color: color,
          direction: Axis.horizontal,
        ),
      );
    }

    if (boxInsideCompared) {
      // B contains A: from A.right to B.right at A.center.dy
      final distance = comparedRect.right - boxRect.right;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(boxRect.right, boxRect.center.dy),
          end: Offset(comparedRect.right, boxRect.center.dy),
          distance: distance,
          color: color,
          direction: Axis.horizontal,
        ),
      );
    }

    // --- External case ---
    final solidY = boxRect.center.dy;
    double distance;
    Offset solidStart;
    Offset bEndpoint;

    if (comparedRect.left >= boxRect.right) {
      // B is fully to the right of A (gap exists)
      distance = comparedRect.left - boxRect.right;
      solidStart = Offset(boxRect.right, solidY);
      bEndpoint = Offset(comparedRect.left, solidY);
    } else if (comparedRect.right > boxRect.right) {
      // B extends past A's right edge (overhang)
      distance = comparedRect.right - boxRect.right;
      solidStart = Offset(boxRect.right, solidY);
      bEndpoint = Offset(comparedRect.right, solidY);
    } else {
      return const SizedBox.shrink();
    }

    if (distance <= 0) return const SizedBox.shrink();

    final dashed = _perpendicularDashedForHorizontal(
      bEndpointX: bEndpoint.dx,
      solidY: solidY,
      comparedRect: comparedRect,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: solidStart,
            end: bEndpoint,
            distance: distance,
            color: color,
            direction: Axis.horizontal,
          ),
        ),
        if (dashed != null)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashed.start,
              end: dashed.end,
              distance: distance,
              color: color,
              direction: Axis.vertical,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  /// Builds a horizontal distance line on the RIGHT side.
  /// A perpendicular dashed line is added when A's horizontal centre is outside
  /// B's horizontal bounds.
  Widget _buildTopDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    // --- Inside cases ---
    if (comparedInsideBox) {
      // A contains B: from A.top to B.top at B.center.dx
      final distance = comparedRect.top - boxRect.top;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(comparedRect.center.dx, boxRect.top),
          end: Offset(comparedRect.center.dx, comparedRect.top),
          distance: distance,
          color: color,
          direction: Axis.vertical,
        ),
      );
    }

    if (boxInsideCompared) {
      // B contains A: from B.top to A.top at A.center.dx
      final distance = boxRect.top - comparedRect.top;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(boxRect.center.dx, comparedRect.top),
          end: Offset(boxRect.center.dx, boxRect.top),
          distance: distance,
          color: color,
          direction: Axis.vertical,
        ),
      );
    }

    // --- External case ---
    final solidX = boxRect.center.dx;
    double distance;
    Offset solidStart;
    Offset bEndpoint;

    if (comparedRect.bottom <= boxRect.top) {
      // B is fully above A (gap exists)
      distance = boxRect.top - comparedRect.bottom;
      solidStart = Offset(solidX, boxRect.top);
      bEndpoint = Offset(solidX, comparedRect.bottom);
    } else if (comparedRect.top < boxRect.top) {
      // B extends past A's top edge (overhang)
      distance = boxRect.top - comparedRect.top;
      solidStart = Offset(solidX, boxRect.top);
      bEndpoint = Offset(solidX, comparedRect.top);
    } else {
      return const SizedBox.shrink();
    }

    if (distance <= 0) return const SizedBox.shrink();

    final dashed = _perpendicularDashedForVertical(
      solidX: solidX,
      bEndpointY: bEndpoint.dy,
      comparedRect: comparedRect,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: solidStart,
            end: bEndpoint,
            distance: distance,
            color: color,
            direction: Axis.vertical,
          ),
        ),
        if (dashed != null)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashed.start,
              end: dashed.end,
              distance: distance,
              color: color,
              direction: Axis.horizontal,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  /// Builds a vertical distance line on the BOTTOM side.
  Widget _buildBottomDistance(
    Rect boxRect,
    Rect comparedRect,
    bool comparedInsideBox,
    bool boxInsideCompared,
  ) {
    // --- Inside cases ---
    if (comparedInsideBox) {
      // A contains B: from B.bottom to A.bottom at B.center.dx
      final distance = boxRect.bottom - comparedRect.bottom;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(comparedRect.center.dx, comparedRect.bottom),
          end: Offset(comparedRect.center.dx, boxRect.bottom),
          distance: distance,
          color: color,
          direction: Axis.vertical,
        ),
      );
    }

    if (boxInsideCompared) {
      // B contains A: from A.bottom to B.bottom at A.center.dx
      final distance = comparedRect.bottom - boxRect.bottom;
      if (distance <= 0) return const SizedBox.shrink();
      return CustomPaint(
        painter: _DistanceLinePainter(
          start: Offset(boxRect.center.dx, boxRect.bottom),
          end: Offset(boxRect.center.dx, comparedRect.bottom),
          distance: distance,
          color: color,
          direction: Axis.vertical,
        ),
      );
    }

    // --- External case ---
    final solidX = boxRect.center.dx;
    double distance;
    Offset solidStart;
    Offset bEndpoint;

    if (comparedRect.top >= boxRect.bottom) {
      // B is fully below A (gap exists)
      distance = comparedRect.top - boxRect.bottom;
      solidStart = Offset(solidX, boxRect.bottom);
      bEndpoint = Offset(solidX, comparedRect.top);
    } else if (comparedRect.bottom > boxRect.bottom) {
      // B extends past A's bottom edge (overhang)
      distance = comparedRect.bottom - boxRect.bottom;
      solidStart = Offset(solidX, boxRect.bottom);
      bEndpoint = Offset(solidX, comparedRect.bottom);
    } else {
      return const SizedBox.shrink();
    }

    if (distance <= 0) return const SizedBox.shrink();

    final dashed = _perpendicularDashedForVertical(
      solidX: solidX,
      bEndpointY: bEndpoint.dy,
      comparedRect: comparedRect,
    );

    return Stack(
      children: [
        CustomPaint(
          painter: _DistanceLinePainter(
            start: solidStart,
            end: bEndpoint,
            distance: distance,
            color: color,
            direction: Axis.vertical,
          ),
        ),
        if (dashed != null)
          CustomPaint(
            painter: _DistanceLinePainter(
              start: dashed.start,
              end: dashed.end,
              distance: distance,
              color: color,
              direction: Axis.horizontal,
              isDashed: true,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers: perpendicular dashed lines
  // ---------------------------------------------------------------------------

  /// Returns the start/end of a perpendicular **vertical** dashed line for a
  /// horizontal solid line, or `null` if the solid endpoint already lies on B's
  /// edge (no dashed needed).
  ///
  /// The dashed line goes from B's nearest horizontal edge up/down to the
  /// solid line's floating endpoint at ([bEndpointX], [solidY]).
  _DashedSegment? _perpendicularDashedForHorizontal({
    required double bEndpointX,
    required double solidY,
    required Rect comparedRect,
  }) {
    if (solidY < comparedRect.top) {
      // A is above B: dashed from B.top down to solidY
      return _DashedSegment(
        Offset(bEndpointX, comparedRect.top),
        Offset(bEndpointX, solidY),
      );
    } else if (solidY > comparedRect.bottom) {
      // A is below B: dashed from B.bottom up to solidY
      return _DashedSegment(
        Offset(bEndpointX, comparedRect.bottom),
        Offset(bEndpointX, solidY),
      );
    }
    // solidY is within B's vertical range → endpoint is on B's edge, no dashed
    return null;
  }

  /// Returns the start/end of a perpendicular **horizontal** dashed line for
  /// a vertical solid line, or `null` if no dashed is needed.
  ///
  /// The dashed line goes from B's nearest vertical edge left/right to the
  /// solid line's floating endpoint at ([solidX], [bEndpointY]).
  _DashedSegment? _perpendicularDashedForVertical({
    required double solidX,
    required double bEndpointY,
    required Rect comparedRect,
  }) {
    if (solidX < comparedRect.left) {
      // A is to the left of B: dashed from B.left to solidX
      return _DashedSegment(
        Offset(comparedRect.left, bEndpointY),
        Offset(solidX, bEndpointY),
      );
    } else if (solidX > comparedRect.right) {
      // A is to the right of B: dashed from B.right to solidX
      return _DashedSegment(
        Offset(comparedRect.right, bEndpointY),
        Offset(solidX, bEndpointY),
      );
    }
    // solidX is within B's horizontal range → endpoint is on B's edge, no dashed
    return null;
  }
}

/// Simple pair of [Offset]s describing the start and end of a dashed segment.
class _DashedSegment {
  const _DashedSegment(this.start, this.end);

  final Offset start;
  final Offset end;
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
      distance != oldDelegate.distance ||
      color != oldDelegate.color ||
      direction != oldDelegate.direction ||
      isDashed != oldDelegate.isDashed;
}
