import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspector/inspector.dart';

const _widgetKey = ValueKey('widget');

void main() {
  Widget _buildApp(Widget body) {
    return MaterialApp(
      builder: (context, child) => Inspector(child: child!),
      home: Scaffold(body: body),
    );
  }

  /// Enables the widget inspector and taps the center of the widget at [key].
  Future<void> _inspect(WidgetTester tester, Key key) async {
    await tester.tap(find.byIcon(Icons.format_shapes));
    await tester.pump();

    final box = tester.renderObject(find.byKey(key)) as RenderBox;
    final center = (box.localToGlobal(Offset.zero) & box.size).center;
    await tester.tapAt(center);
    await tester.pump();
  }

  group('Text section', () {
    testWidgets(
      'Given a Text widget, '
      'When inspected, '
      'Then the font size row is shown',
      (tester) async {
        await tester.pumpWidget(_buildApp(
          const Center(
            child: Text('Hello',
                key: _widgetKey, style: TextStyle(fontSize: 18.0)),
          ),
        ));
        await _inspect(tester, _widgetKey);

        expect(find.text('font size'), findsOneWidget);
        expect(find.text('18.0'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a Text widget, '
      'When inspected, '
      'Then the decoration section is not shown',
      (tester) async {
        await tester.pumpWidget(_buildApp(
          const Center(child: Text('Hello', key: _widgetKey)),
        ));
        await _inspect(tester, _widgetKey);

        expect(find.text('border radius (LTRB)'), findsNothing);
      },
    );

    testWidgets(
      'Given a SelectableText widget, '
      'When inspected, '
      'Then the font size row is shown',
      (tester) async {
        await tester.pumpWidget(_buildApp(
          const Center(
            child: SelectableText(
              'Selectable',
              key: _widgetKey,
              style: TextStyle(fontSize: 22.0),
            ),
          ),
        ));
        await _inspect(tester, _widgetKey);

        expect(find.text('font size'), findsOneWidget);
        expect(find.text('22.0'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a SelectableText widget, '
      'When inspected, '
      'Then the decoration section is not shown',
      (tester) async {
        await tester.pumpWidget(_buildApp(
          const Center(
            child: SelectableText('Selectable', key: _widgetKey),
          ),
        ));
        await _inspect(tester, _widgetKey);

        expect(find.text('border radius (LTRB)'), findsNothing);
      },
    );

    testWidgets(
      'Given a decorated Container, '
      'When inspected, '
      'Then the color row is shown and the font size row is not',
      (tester) async {
        await tester.pumpWidget(_buildApp(
          Center(
            child: Container(
              key: _widgetKey,
              width: 100,
              height: 100,
              decoration: const BoxDecoration(color: Colors.red),
            ),
          ),
        ));
        await _inspect(tester, _widgetKey);

        expect(find.text('color'), findsOneWidget);
        expect(find.text('font size'), findsNothing);
      },
    );
  });
}
