import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final int completedExchanges;
  final double rating;
  final bool isActive;
  final DateTime createdAt;
  final Map<String, bool> notificationPreferences;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.completedExchanges = 0,
    this.rating = 5.0,
    this.isActive = true,
    required this.createdAt,
    this.notificationPreferences = const {
      'matchAlerts': true,
      'chatAlerts': true,
      'statusAlerts': true,
      'soundAlerts': true,
    },
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, bool> parsePreferences(dynamic val) {
      if (val is Map) {
        return {
          'matchAlerts': val['matchAlerts'] == true || val['matchAlerts'] == null,
          'chatAlerts': val['chatAlerts'] == true || val['chatAlerts'] == null,
          'statusAlerts': val['statusAlerts'] == true || val['statusAlerts'] == null,
          'soundAlerts': val['soundAlerts'] == true || val['soundAlerts'] == null,
        };
      }
      return const {
        'matchAlerts': true,
        'chatAlerts': true,
        'statusAlerts': true,
        'soundAlerts': true,
      };
    }

    return UserModel(
      userId: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      completedExchanges: (data['completedExchanges'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      isActive: data['isActive'] ?? true,
      createdAt: parseDate(data['createdAt']),
      notificationPreferences: parsePreferences(data['notificationPreferences']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'completedExchanges': completedExchanges,
      'rating': rating,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'notificationPreferences': notificationPreferences,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    int? completedExchanges,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    Map<String, bool>? notificationPreferences,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      completedExchanges: completedExchanges ?? this.completedExchanges,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }
}
