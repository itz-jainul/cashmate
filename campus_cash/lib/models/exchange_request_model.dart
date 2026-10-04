import 'package:cloud_firestore/cloud_firestore.dart';

enum ExchangeStatus {
  searching,
  matched,
  accepted,
  completed,
  cancelled,
  expired;

  static ExchangeStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'matched':
        return ExchangeStatus.matched;
      case 'accepted':
        return ExchangeStatus.accepted;
      case 'completed':
        return ExchangeStatus.completed;
      case 'cancelled':
        return ExchangeStatus.cancelled;
      case 'expired':
        return ExchangeStatus.expired;
      case 'searching':
      default:
        return ExchangeStatus.searching;
    }
  }

  String get value => name;
}

class ExchangeRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String has; // 'cash' or 'digital'
  final String wants; // 'cash' or 'digital'
  final int amount;
  final ExchangeStatus status;
  final String? matchedUserId;
  final String? matchedRequestId;
  final bool userAccepted;
  final bool matchedUserAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  const ExchangeRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.has,
    required this.wants,
    required this.amount,
    this.status = ExchangeStatus.searching,
    this.matchedUserId,
    this.matchedRequestId,
    this.userAccepted = false,
    this.matchedUserAccepted = false,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory ExchangeRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ExchangeRequestModel.fromMap(data, doc.id);
  }

  factory ExchangeRequestModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExchangeRequestModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      has: data['has'] ?? 'cash',
      wants: data['wants'] ?? 'digital',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      status: ExchangeStatus.fromString(data['status']),
      matchedUserId: data['matchedUserId'],
      matchedRequestId: data['matchedRequestId'],
      userAccepted: data['userAccepted'] ?? false,
      matchedUserAccepted: data['matchedUserAccepted'] ?? false,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      expiresAt: parseDate(data['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'has': has,
      'wants': wants,
      'amount': amount,
      'status': status.value,
      'matchedUserId': matchedUserId,
      'matchedRequestId': matchedRequestId,
      'userAccepted': userAccepted,
      'matchedUserAccepted': matchedUserAccepted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  ExchangeRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? has,
    String? wants,
    int? amount,
    ExchangeStatus? status,
    String? matchedUserId,
    String? matchedRequestId,
    bool? userAccepted,
    bool? matchedUserAccepted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return ExchangeRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      has: has ?? this.has,
      wants: wants ?? this.wants,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      matchedRequestId: matchedRequestId ?? this.matchedRequestId,
      userAccepted: userAccepted ?? this.userAccepted,
      matchedUserAccepted: matchedUserAccepted ?? this.matchedUserAccepted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
