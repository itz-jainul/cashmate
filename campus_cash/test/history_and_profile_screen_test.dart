import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/features/auth/providers/auth_provider.dart';
import 'package:campus_cash/features/exchange/providers/exchange_provider.dart';
import 'package:campus_cash/features/history/screens/history_screen.dart';
import 'package:campus_cash/features/profile/screens/profile_screen.dart';
import 'package:campus_cash/models/exchange_model.dart';
import 'package:campus_cash/models/user_model.dart';

void main() {
  group('HistoryScreen Tests', () {
    testWidgets('renders header, segmented tabs, and empty state', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userHistoryProvider.overrideWith((ref) => Stream.value([])),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exchange history'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('renders exchange card with partner, tags, and amount', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testExchange = ExchangeModel(
        id: 'ex-1',
        userAId: 'user-a',
        userBId: 'user-b',
        userAName: 'Rahul D.',
        userBName: 'Meera K.',
        amount: 500,
        userAHas: 'cash',
        userBHas: 'digital',
        location: 'Library Lobby',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userHistoryProvider.overrideWith((ref) => Stream.value([testExchange])),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exchange history'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.textContaining('Library Lobby'), findsOneWidget);
    });
  });

  group('ProfileScreen Tests', () {
    testWidgets('renders identity card, trust stats, and financial safety notice', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testProfile = UserModel(
        userId: 'u-1',
        name: 'Arun Kumar',
        email: 'arun@campus.edu',
        completedExchanges: 8,
        rating: 4.8,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith((ref) => Stream.value(testProfile)),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My profile'), findsOneWidget);
      expect(find.text('Arun Kumar'), findsOneWidget);
      expect(find.text('Student Verified'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Trust rating'), findsOneWidget);
      expect(find.text('Exchange history'), findsOneWidget);
      expect(find.text('Financial safety notice'), findsOneWidget);
      expect(find.text('Log out of CashMate'), findsOneWidget);
    });
  });
}
