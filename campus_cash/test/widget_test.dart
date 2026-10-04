import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/core/widgets/custom_button.dart';
import 'package:campus_cash/core/widgets/custom_text_field.dart';
import 'package:campus_cash/core/widgets/status_badge.dart';
import 'package:campus_cash/models/exchange_request_model.dart';

void main() {
  group('CampusCash UI Widget Tests (Phase 24)', () {
    testWidgets('CustomButton renders text and responds to taps', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Find Match',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Find Match'), findsOneWidget);
      await tester.tap(find.text('Find Match'));
      expect(tapped, isTrue);
    });

    testWidgets('CustomButton shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Find Match',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StatusBadge displays correct label and icon for Searching', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: ExchangeStatus.searching),
          ),
        ),
      );

      expect(find.text('Searching'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('CustomTextField renders label and hintText', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Full Name',
              hintText: 'Enter your name',
            ),
          ),
        ),
      );

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);
    });
  });
}
