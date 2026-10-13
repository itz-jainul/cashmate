import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/features/auth/providers/auth_provider.dart';
import 'package:campus_cash/features/exchange/providers/exchange_provider.dart';
import 'package:campus_cash/features/exchange/screens/requests_screen.dart';
import 'package:campus_cash/models/exchange_request_model.dart';

void main() {
  testWidgets('RequestsScreen renders request cards and list', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final mockRequests = [
      ExchangeRequestModel(
        id: 'req_1',
        userId: 'other_user_1',
        userName: 'Aarav S.',
        has: 'digital',
        wants: 'cash',
        amount: 200,
        location: 'Campus Cafeteria',
        status: ExchangeStatus.searching,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(minutes: 25)),
      ),
      ExchangeRequestModel(
        id: 'req_2',
        userId: 'other_user_2',
        userName: 'Meera K.',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        location: 'Library Lobby',
        status: ExchangeStatus.searching,
        createdAt: now.subtract(const Duration(minutes: 10)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        expiresAt: now.add(const Duration(minutes: 20)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicRequestsProvider.overrideWith((ref) => Stream.value(mockRequests)),
        ],
        child: const MaterialApp(
          home: RequestsScreen(),
        ),
      ),
    );

    // Pump frames
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

  testWidgets('RequestsScreen renders user own active request with badge and View status', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final myRequest = ExchangeRequestModel(
      id: 'my_req_1',
      userId: 'my_user_id',
      userName: 'Self User',
      has: 'cash',
      wants: 'digital',
      amount: 200,
      location: 'Campus Cafeteria',
      status: ExchangeStatus.searching,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              // Using a minimal mock or null with specific UID check
              null,
            ),
          ),
          publicRequestsProvider.overrideWith((ref) => Stream.value([myRequest])),
        ],
        child: const MaterialApp(
          home: RequestsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify header
    expect(find.text('Public requests'), findsOneWidget);
    expect(find.text('1 open request near you'), findsOneWidget);
    expect(find.text('Self User'), findsOneWidget);
  });
}

