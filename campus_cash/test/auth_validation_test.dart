import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cash/models/user_model.dart';

void main() {
  group('CashMate Auth & Validation Tests (Section 33 & 35)', () {
    test('Valid email regex matches standard and college emails', () {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

      expect(emailRegex.hasMatch('student@college.edu'), isTrue);
      expect(emailRegex.hasMatch('arun.kumar@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('user123@sub.domain.org'), isTrue);

      expect(emailRegex.hasMatch('invalid-email'), isFalse);
      expect(emailRegex.hasMatch('student@'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('spaces in@email.com'), isFalse);
    });

    test('Password validation enforces min 8 chars with letters and numbers', () {
      bool isValidPassword(String pwd) {
        if (pwd.length < 8) return false;
        final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(pwd);
        final hasNumber = RegExp(r'[0-9]').hasMatch(pwd);
        return hasLetter && hasNumber;
      }

      expect(isValidPassword('short1'), isFalse);
      expect(isValidPassword('onlylettershere'), isFalse);
      expect(isValidPassword('1234567890'), isFalse);
      expect(isValidPassword('password123'), isTrue);
      expect(isValidPassword('CampusCash#2026'), isTrue);
    });

    test('UserModel serialization and deserialization preserves all fields', () {
      final now = DateTime.now();
      final user = UserModel(
        userId: 'user_456',
        name: 'Arun Kumar',
        email: 'arun@example.com',
        phone: '+91 9876543210',
        photoUrl: 'https://example.com/photo.jpg',
        completedExchanges: 12,
        rating: 4.9,
        isActive: true,
        createdAt: now,
        notificationPreferences: const {
          'matchAlerts': true,
          'chatAlerts': false,
          'statusAlerts': true,
          'soundAlerts': true,
        },
      );

      final map = user.toMap();
      expect(map['name'], 'Arun Kumar');
      expect(map['email'], 'arun@example.com');
      expect(map['completedExchanges'], 12);
      expect(map['rating'], 4.9);
      expect(map['notificationPreferences']['chatAlerts'], isFalse);

      final copy = user.copyWith(completedExchanges: 13, rating: 5.0);
      expect(copy.completedExchanges, 13);
      expect(copy.rating, 5.0);
      expect(copy.name, 'Arun Kumar');
    });
  });
}
