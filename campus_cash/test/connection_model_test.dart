import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/models/connection_model.dart';

void main() {
  group('CashMate ConnectionModel Tests', () {
    final now = DateTime.now();

    test('ConnectionModel serialization and deserialization', () {
      final conn = ConnectionModel(
        id: 'conn_123',
        userAId: 'uid_arun',
        userBId: 'uid_rahul',
        requestAId: 'req_a',
        requestBId: 'req_b',
        userAName: 'Arun',
        userBName: 'Rahul',
        userAHas: 'cash',
        userBHas: 'digital',
        amount: 100,
        location: 'Campus Cafeteria',
        status: ConnectionStatus.pending,
        userAAccepted: true,
        userBAccepted: false,
        userAConfirmed: false,
        userBConfirmed: false,
        createdAt: now,
      );

      final map = conn.toMap();
      expect(map['userAId'], 'uid_arun');
      expect(map['userBId'], 'uid_rahul');
      expect(map['amount'], 100);
      expect(map['status'], 'pending');
      expect(map['userAAccepted'], isTrue);
      expect(map['userBAccepted'], isFalse);

      final fromMap = ConnectionModel.fromMap(map, 'conn_123');
      expect(fromMap.id, 'conn_123');
      expect(fromMap.userAName, 'Arun');
      expect(fromMap.userBName, 'Rahul');
      expect(fromMap.amount, 100);
      expect(fromMap.status, ConnectionStatus.pending);
      expect(fromMap.userAAccepted, isTrue);
      expect(fromMap.userBAccepted, isFalse);
    });

    test('Relative helper methods for User A and User B', () {
      final conn = ConnectionModel(
        id: 'conn_456',
        userAId: 'uid_arun',
        userBId: 'uid_rahul',
        requestAId: 'req_a',
        requestBId: 'req_b',
        userAName: 'Arun',
        userBName: 'Rahul',
        userAHas: 'cash',
        userBHas: 'digital',
        amount: 500,
        status: ConnectionStatus.connected,
        userAAccepted: true,
        userBAccepted: true,
        userAConfirmed: true,
        userBConfirmed: false,
        createdAt: now,
      );

      // Relative to Arun (User A)
      expect(conn.isUserA('uid_arun'), isTrue);
      expect(conn.partnerId('uid_arun'), 'uid_rahul');
      expect(conn.partnerName('uid_arun'), 'Rahul');
      expect(conn.myHas('uid_arun'), 'cash');
      expect(conn.myWants('uid_arun'), 'digital');
      expect(conn.isAcceptedByMe('uid_arun'), isTrue);
      expect(conn.isAcceptedByPartner('uid_arun'), isTrue);
      expect(conn.isConfirmedByMe('uid_arun'), isTrue);
      expect(conn.isConfirmedByPartner('uid_arun'), isFalse);

      // Relative to Rahul (User B)
      expect(conn.isUserA('uid_rahul'), isFalse);
      expect(conn.partnerId('uid_rahul'), 'uid_arun');
      expect(conn.partnerName('uid_rahul'), 'Arun');
      expect(conn.myHas('uid_rahul'), 'digital');
      expect(conn.myWants('uid_rahul'), 'cash');
      expect(conn.isAcceptedByMe('uid_rahul'), isTrue);
      expect(conn.isAcceptedByPartner('uid_rahul'), isTrue);
      expect(conn.isConfirmedByMe('uid_rahul'), isFalse);
      expect(conn.isConfirmedByPartner('uid_rahul'), isTrue);
    });

    test('Status enum string parsing', () {
      expect(ConnectionStatus.fromString('pending'), ConnectionStatus.pending);
      expect(ConnectionStatus.fromString('connected'), ConnectionStatus.connected);
      expect(ConnectionStatus.fromString('completed'), ConnectionStatus.completed);
      expect(ConnectionStatus.fromString('cancelled'), ConnectionStatus.cancelled);
      expect(ConnectionStatus.fromString('unknown'), ConnectionStatus.pending);
    });
  });
}
