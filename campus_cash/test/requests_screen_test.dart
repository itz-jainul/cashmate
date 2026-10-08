import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/features/exchange/screens/requests_screen.dart';

void main() {
  testWidgets('RequestsScreen renders request cards and list', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RequestsScreen(),
        ),
      ),
    );

    // Pump a few frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify header
    expect(find.text('Public requests'), findsOneWidget);

    // Verify filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Wants cash'), findsWidgets);

    // Verify cards are rendered
    expect(find.text('Aarav S.'), findsOneWidget);
    expect(find.text('Meera K.'), findsOneWidget);
    expect(find.text('Offer swap'), findsWidgets);
  });
}
