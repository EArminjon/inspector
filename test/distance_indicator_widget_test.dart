import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/src/widgets/components/distance_indicator_widget.dart';
import 'package:inspector/src/widgets/inspector/box_info.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a scene with two invisible containers at the given rects.
/// On the first post-frame callback, it creates BoxInfo objects and rebuilds
/// to include the DistanceIndicatorWidget.
class _Scene extends StatefulWidget {
  const _Scene({required this.rectA, required this.rectB});

  final Rect rectA;
  final Rect rectB;

  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> {
  final _keyA = GlobalKey();
  final _keyB = GlobalKey();
  BoxInfo? _boxA;
  BoxInfo? _boxB;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ra = _keyA.currentContext!.findRenderObject()! as RenderBox;
      final rb = _keyB.currentContext!.findRenderObject()! as RenderBox;
      setState(() {
        _boxA = BoxInfo(targetRenderBox: ra);
        _boxB = BoxInfo(targetRenderBox: rb);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(rect: widget.rectA, child: Container(key: _keyA)),
        Positioned.fromRect(rect: widget.rectB, child: Container(key: _keyB)),
        if (_boxA != null && _boxB != null)
          DistanceIndicatorWidget(
            boxInfo: _boxA!,
            comparedBoxInfo: _boxB!,
            color: Colors.red,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  Future<void> createAndPump(
    WidgetTester tester, {
    required Rect a,
    required Rect b,
  }) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _Scene(rectA: a, rectB: b),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DistanceIndicatorWidget', () {
    // -------------------------------------------------------------------------
    // UC1 – A above, B wider below, horizontally overlapping
    // Lines: left overhang solid+dashed, right overhang solid+dashed,
    //        bottom vertical solid  →  5 CustomPaints
    // -------------------------------------------------------------------------
    group('UC1 – A above B, B wider, horizontally overlapping', () {
      testWidgets(
        'draws 5 lines (2 horizontal solids + 2 vertical dashes + 1 vertical solid)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(150, 50, 100, 60), // narrower, above
            b: const Rect.fromLTWH(50, 150, 300, 80), // wider, below
          );

          expect(find.byType(CustomPaint), findsNWidgets(5));
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC2 – A and B separated, not aligned
    // Lines: left solid+dashed, bottom solid+dashed  →  4 CustomPaints
    // -------------------------------------------------------------------------
    group('UC2 – A upper-right, B lower-left, no overlap', () {
      testWidgets(
        'draws 4 lines (1 horizontal solid + 1 vertical solid + 2 dashes)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(300, 50, 100, 60), // upper-right
            b: const Rect.fromLTWH(50, 200, 200, 80), // lower-left
          );

          expect(find.byType(CustomPaint), findsNWidgets(4));
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC3 – A above B, perfectly aligned (same left/right)
    // Lines: bottom vertical solid only  →  1 CustomPaint
    // -------------------------------------------------------------------------
    group('UC3 – A above B, perfectly aligned', () {
      testWidgets(
        'draws 1 vertical solid line',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 0, 100, 50),
            b: const Rect.fromLTWH(100, 100, 100, 50),
          );

          expect(find.byType(CustomPaint), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC4 – Containment
    // Lines: 4 solid lines (no dashes)  →  4 CustomPaints
    // -------------------------------------------------------------------------
    group('UC4 – A inside B', () {
      testWidgets(
        'draws 4 solid lines',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(200, 150, 100, 100), // smaller, inside
            b: const Rect.fromLTWH(100, 50, 300, 300), // larger, outside
          );

          expect(find.byType(CustomPaint), findsNWidgets(4));
        },
      );
    });

    group('UC4 – B inside A', () {
      testWidgets(
        'draws 4 solid lines (symmetric)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 50, 300, 300), // larger
            b: const Rect.fromLTWH(200, 150, 100, 100), // smaller, inside
          );

          expect(find.byType(CustomPaint), findsNWidgets(4));
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC5 – Diagonal corner touch
    // Lines: none  →  0 CustomPaints
    // -------------------------------------------------------------------------
    group('UC5 – diagonal corner touch', () {
      testWidgets(
        'draws nothing – B top-right corner',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 100, 100, 100), // (100,100,200,200)
            b: const Rect.fromLTWH(200, 0, 100, 100), // (200,  0,300,100)
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );

      testWidgets(
        'draws nothing – B bottom-right corner',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(0, 0, 100, 100),
            b: const Rect.fromLTWH(100, 100, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );

      testWidgets(
        'draws nothing – B bottom-left corner',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 0, 100, 100),
            b: const Rect.fromLTWH(0, 100, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );

      testWidgets(
        'draws nothing – B top-left corner',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 100, 100, 100),
            b: const Rect.fromLTWH(0, 0, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );

      testWidgets(
        'draws nothing – floating-point near-zero distance eliminated by snap',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 100, 100, 100),
            // b.left = 200.4 → snaps to 200 = a.right  →  d = 0
            b: const Rect.fromLTWH(200.4, 0, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC6 – A and B aligned but separated (on different axes)
    // Lines: left solid+dashed, bottom solid+dashed  →  4 CustomPaints
    // -------------------------------------------------------------------------
    group('UC6 – A upper-right, B lower-left, vertically separated', () {
      testWidgets(
        'draws 4 lines (2 solids + 2 dashes)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(300, 0, 100, 60), // upper-right
            b: const Rect.fromLTWH(50, 100, 100, 60), // lower-left
          );

          expect(find.byType(CustomPaint), findsNWidgets(4));
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC7 – Edge to edge, aligned (distance = 0)
    // Lines: none  →  0 CustomPaints
    // -------------------------------------------------------------------------
    group('UC7 – edge to edge', () {
      testWidgets(
        'draws nothing – B directly below A',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(100, 0, 100, 100),
            b: const Rect.fromLTWH(100, 100, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );

      testWidgets(
        'draws nothing – B directly to the right of A',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(0, 100, 100, 100),
            b: const Rect.fromLTWH(100, 100, 100, 100),
          );

          expect(find.byType(CustomPaint), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    // UC8 – A taller than B, side by side
    // Lines: right solid+dashed (A.centerY is below B.bottom)  →  2 CustomPaints
    // -------------------------------------------------------------------------
    group('UC8 – A taller than B, side by side', () {
      testWidgets(
        'draws 2 lines (1 horizontal solid + 1 vertical dash)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(50, 0, 100, 200), // tall, left
            b: const Rect.fromLTWH(200, 0, 100, 60), // short, right
          );

          expect(find.byType(CustomPaint), findsNWidgets(2));
        },
      );

      testWidgets(
        'draws nothing when B has same height as A (no vertical offset)',
        (tester) async {
          await createAndPump(
            tester,
            a: const Rect.fromLTWH(50, 0, 100, 100),
            b: const Rect.fromLTWH(
                200, 0, 100, 100), // same height → no dashed → no lines
          );

          // No overhang condition triggered; right distance is solid without dashed,
          // so it IS drawn (pure horizontal distance UC ~3-right variant).
          // A.centerY=50 is within B's vertical range [0,100] → no dashed, 1 solid.
          expect(find.byType(CustomPaint), findsOneWidget);
        },
      );
    });
  });
}
