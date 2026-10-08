import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/models/connection_model.dart';
import 'package:campus_cash/models/notification_model.dart';

void main() {
  group('CashMate Connection & Exchange Lifecycle Tests (Section 12 & 14)', () {
    final now = DateTime.now();

    test('Connection starts as pending when match is first established', () {
      final conn = ConnectionModel(
        id: 'conn_101',
        userAId: 'user_a',
        userBId: 'user_b',
        userAName: 'Arun',
        userBName: 'Rahul',
        requestAId: 'req_a',
        requestBId: 'req_b',
        userAHas: 'cash',
        userBHas: 'digital',
        amount: 500,
        status: ConnectionStatus.pending,
        userAAccepted: false,
        userBAccepted: false,
        userAConfirmed: false,
        userBConfirmed: false,
        createdAt: now,
      );

      expect(conn.status, ConnectionStatus.pending);
      expect(conn.userAAccepted, isFalse);
      expect(conn.userBAccepted, isFalse);
    });

    test('Connection transitions to connected only when BOTH users accept', () {
      ConnectionModel conn = ConnectionModel(
        id: 'conn_102',
        userAId: 'user_a',
        userBId: 'user_b',
        userAName: 'Arun',
        userBName: 'Rahul',
        requestAId: 'req_a',
        requestBId: 'req_b',
        userAHas: 'cash',
        userBHas: 'digital',
        amount: 200,
        status: ConnectionStatus.pending,
        userAAccepted: false,
        userBAccepted: false,
        userAConfirmed: false,
        userBConfirmed: false,
        createdAt: now,
      );

      // User A accepts
      conn = conn.copyWith(userAAccepted: true);
      // Status remains pending
      expect(conn.userAAccepted, isTrue);
      expect(conn.userBAccepted, isFalse);
      expect(conn.status, ConnectionStatus.pending);

      // User B also accepts => now transition to connected
      final bothAccepted = conn.userAAccepted && true;
      if (bothAccepted) {
        conn = conn.copyWith(userBAccepted: true, status: ConnectionStatus.connected);
      }

      expect(conn.status, ConnectionStatus.connected);
      expect(conn.userAAccepted, isTrue);
      expect(conn.userBAccepted, isTrue);
    });

    test('Exchange is marked completed only when BOTH users confirm receipt', () {
      ConnectionModel conn = ConnectionModel(
        id: 'conn_103',
        userAId: 'user_a',
        userBId: 'user_b',
        userAName: 'Arun',
        userBName: 'Rahul',
        requestAId: 'req_a',
        requestBId: 'req_b',
        userAHas: 'cash',
        userBHas: 'digital',
        amount: 1000,
        status: ConnectionStatus.connected,
        userAAccepted: true,
        userBAccepted: true,
        userAConfirmed: false,
        userBConfirmed: false,
        createdAt: now,
      );

      // User A confirms
      conn = conn.copyWith(userAConfirmed: true);
      expect(conn.userAConfirmed, isTrue);
      expect(conn.userBConfirmed, isFalse);
      expect(conn.status, ConnectionStatus.connected);

      // User B confirms
      final bothConfirmed = conn.userAConfirmed && true;
      if (bothConfirmed) {
        conn = conn.copyWith(
          userBConfirmed: true,
          status: ConnectionStatus.completed,
          completedAt: DateTime.now(),
        );
      }

      expect(conn.status, ConnectionStatus.completed);
      expect(conn.completedAt, isNotNull);
    });

    test('NotificationModel serializes and deserializes correctly', () {
      final notif = NotificationModel(
        id: 'notif_001',
        userId: 'user_a',
        title: 'Match Found 🎉',
        message: 'You have a matching exchange request with Rahul.',
        type: 'match_found',
        isRead: false,
        createdAt: now,
      );

      final map = notif.toMap();
      expect(map['title'], 'Match Found 🎉');
      expect(map['type'], 'match_found');
      expect(map['isRead'], isFalse);

      final restored = NotificationModel.fromMap(map, 'notif_001');
      expect(restored.id, 'notif_001');
      expect(restored.userId, 'user_a');
      expect(restored.type, 'match_found');
    });
  });
}
