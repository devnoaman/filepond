import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'basic usage: form opens on the basic page, send enabled when empty',
    (tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();

      expect(find.text('Attach files'), findsOneWidget);
      final send = find.widgetWithText(FilledButton, 'Send ticket');
      expect(send, findsOneWidget);
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
    },
  );

  testWidgets(
    'lab: mixed scenario blocks submit until the failure is retried',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());
      await tester.tap(find.text('Upload Lab'));
      await tester.pumpAndSettle();
      expect(find.text('Submit form'), findsOneWidget);

      // "Mixed" (default): request 1 succeeds, request 2 fails with a 500.
      await tester.tap(find.text('Add sample PDF'));
      await settle(tester);
      await tester.tap(find.text('Add sample PDF'));
      await settle(tester);

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.text('Disk full'), findsWidgets);
      expect(find.text('Submit blocked — files not uploaded'), findsOneWidget);

      // Switch the server to success and retry.
      await tester.tap(find.text('200 OK'));
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(find.text('Upload failed'), findsNothing);
      expect(find.text('Submit form'), findsOneWidget);
      expect(find.textContaining('isSettled: true'), findsOneWidget);
    },
  );
}
