import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/models/exchange_request_model.dart';

bool isCompatibleMatch({
  required ExchangeRequestModel reqA,
  required ExchangeRequestModel reqB,
}) {
  return reqA.has == reqB.wants &&
      reqA.wants == reqB.has &&
      reqA.amount == reqB.amount &&
      reqA.userId != reqB.userId &&
      reqA.status == ExchangeStatus.searching &&
      reqB.status == ExchangeStatus.searching;
}

void main() {
  group('CampusCash Matching Logic Tests (Phase 10 & 24)', () {
    final now = DateTime.now();
    final expires = now.add(const Duration(minutes: 30));

    test('Compatible requests match (Cash -> Digital vs Digital -> Cash for ₹500)', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      final userBReq = ExchangeRequestModel(
        id: 'req_2',
        userId: 'user_b',
        userName: 'Rahul',
        has: 'digital',
        wants: 'cash',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isTrue);
    });

    test('Mismatched amounts do not match (₹500 vs ₹300)', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      final userBReq = ExchangeRequestModel(
        id: 'req_2',
        userId: 'user_b',
        userName: 'Rahul',
        has: 'digital',
        wants: 'cash',
        amount: 300,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Same requirements do not match (Cash -> Digital vs Cash -> Digital)', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      final userBReq = ExchangeRequestModel(
        id: 'req_2',
        userId: 'user_b',
        userName: 'Rahul',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Self request cannot match own request', () {
      final userAReq1 = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      final userAReq2 = ExchangeRequestModel(
        id: 'req_2',
        userId: 'user_a',
        userName: 'Arun',
        has: 'digital',
        wants: 'cash',
        amount: 500,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq1, reqB: userAReq2), isFalse);
    });
  });
}
