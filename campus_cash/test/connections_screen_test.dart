import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/features/exchange/providers/exchange_provider.dart';
import 'package:campus_cash/features/exchange/screens/connections_screen.dart';
import 'package:campus_cash/models/connection_model.dart';

void main() {
  testWidgets('ConnectionsScreen renders header, tabs, and empty state', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userConnectionsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ConnectionsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('My connections'), findsOneWidget);

    // Verify tabs
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Verify empty state for active tab
    expect(find.text('No active connections'), findsOneWidget);
    expect(find.text('Create request'), findsOneWidget);
  });

  testWidgets('ConnectionsScreen renders active connection card with 3-step progress and actions', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testConn = ConnectionModel(
      id: 'conn-1',
      userAId: 'user-a',
      userBId: 'user-b',
      requestAId: 'req-1',
      requestBId: 'req-2',
      userAName: 'Aarav S.',
      userBName: 'Aarav S.',
      userAHas: 'cash',
      userBHas: 'digital',
      amount: 200,
      location: 'Campus Cafeteria',
      status: ConnectionStatus.pending,
      userAAccepted: false,
      userBAccepted: false,
      userAConfirmed: false,
      userBConfirmed: false,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userConnectionsProvider.overrideWith((ref) => Stream.value([testConn])),
        ],
        child: const MaterialApp(
          home: ConnectionsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify partner name and location
    expect(find.text('Aarav S.'), findsOneWidget);
    expect(find.textContaining('Campus Cafeteria'), findsOneWidget);

    // Verify amount
    expect(find.text('₹200'), findsOneWidget);

    // Verify give/get tags
    expect(find.text('Give digital'), findsOneWidget);
    expect(find.text('Get cash'), findsOneWidget);

    // Verify 3-step progress indicator
    expect(find.text('Matched'), findsOneWidget);
    expect(find.text('Meet up'), findsOneWidget);
    expect(find.text('Exchange'), findsOneWidget);

    // Verify action buttons
    expect(find.text("I've reached the spot"), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
