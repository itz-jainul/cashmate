import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/models/chat_message_model.dart';
import 'package:campus_cash/features/exchange/services/exchange_service.dart';

void main() {
  group('ChatMessageModel & Coordination Tests (Phase 24)', () {
    test('ChatMessageModel serialization and deserialization', () {
      final now = DateTime(2026, 10, 4, 12, 30);
      final model = ChatMessageModel(
        id: 'msg_101',
        senderId: 'user_a',
        senderName: 'Arun',
        text: '📍 Reached the meetup spot',
        isQuickPing: true,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['senderId'], 'user_a');
      expect(map['senderName'], 'Arun');
      expect(map['text'], '📍 Reached the meetup spot');
      expect(map['isQuickPing'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());

      final reconstructed = ChatMessageModel.fromMap(map, 'msg_101');
      expect(reconstructed.id, 'msg_101');
      expect(reconstructed.senderId, 'user_a');
      expect(reconstructed.senderName, 'Arun');
      expect(reconstructed.text, '📍 Reached the meetup spot');
      expect(reconstructed.isQuickPing, isTrue);
      expect(reconstructed.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('ExchangeService.getChatId generates deterministic symmetric chat ID', () {
      const reqA = 'req_abc';
      const reqB = 'req_xyz';

      final chat1 = ExchangeService.getChatId(reqA, reqB);
      final chat2 = ExchangeService.getChatId(reqB, reqA);

      expect(chat1, equals(chat2));
      expect(chat1, equals('req_abc_req_xyz'));
    });
  });
}
