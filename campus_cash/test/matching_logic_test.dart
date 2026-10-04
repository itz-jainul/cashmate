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
      reqB.status == ExchangeStatus.searching &&
      !reqA.isExpired &&
      !reqB.isExpired;
}

void main() {
  group('CashMate Exact Matching Logic Tests (Section 5 & 33)', () {
    final now = DateTime.now();
    final expires = now.add(const Duration(minutes: 30));
    final expired = now.subtract(const Duration(minutes: 5));

    test('Exact match: A Cash->Digital ₹100 and B Digital->Cash ₹100 => MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
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
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isTrue);
    });

    test('Different amount: A ₹100 and B ₹80 => NO MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
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
        amount: 80,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Same direction: A Cash->Digital and B Cash->Digital => NO MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
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
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Same user: User matching own request => NO MATCH', () {
      final userAReq1 = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
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
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq1, reqB: userAReq2), isFalse);
    });

    test('Already matched request cannot match => NO MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
        status: ExchangeStatus.matched,
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
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Cancelled request cannot match => NO MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
        status: ExchangeStatus.cancelled,
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
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });

    test('Expired request cannot match => NO MATCH', () {
      final userAReq = ExchangeRequestModel(
        id: 'req_1',
        userId: 'user_a',
        userName: 'Arun',
        has: 'cash',
        wants: 'digital',
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now.subtract(const Duration(minutes: 40)),
        updatedAt: now.subtract(const Duration(minutes: 40)),
        expiresAt: expired,
      );

      final userBReq = ExchangeRequestModel(
        id: 'req_2',
        userId: 'user_b',
        userName: 'Rahul',
        has: 'digital',
        wants: 'cash',
        amount: 100,
        status: ExchangeStatus.searching,
        createdAt: now,
        updatedAt: now,
        expiresAt: expires,
      );

      expect(isCompatibleMatch(reqA: userAReq, reqB: userBReq), isFalse);
    });
  });
}
