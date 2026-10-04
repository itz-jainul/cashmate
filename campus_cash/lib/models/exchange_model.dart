import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeModel {
  final String id;
  final String? requestIdA;
  final String? requestIdB;
  final String userAId;
  final String userBId;
  final String userAName;
  final String userBName;
  final int amount;
  final String userAHas;
  final String userBHas;
  final String status; // 'completed' | 'cancelled'
  final bool userAConfirmed;
  final bool userBConfirmed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ExchangeModel({
    required this.id,
    this.requestIdA,
    this.requestIdB,
    required this.userAId,
    required this.userBId,
    required this.userAName,
    required this.userBName,
    required this.amount,
    required this.userAHas,
    required this.userBHas,
    required this.status,
    this.userAConfirmed = false,
    this.userBConfirmed = false,
    required this.createdAt,
    this.completedAt,
  });

  factory ExchangeModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ExchangeModel.fromMap(data, doc.id);
  }

  factory ExchangeModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ExchangeModel(
      id: id,
      requestIdA: data['requestIdA'],
      requestIdB: data['requestIdB'],
      userAId: data['userAId'] ?? '',
      userBId: data['userBId'] ?? '',
      userAName: data['userAName'] ?? '',
      userBName: data['userBName'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      userAHas: data['userAHas'] ?? 'cash',
      userBHas: data['userBHas'] ?? 'digital',
      status: data['status'] ?? 'completed',
      userAConfirmed: data['userAConfirmed'] ?? false,
      userBConfirmed: data['userBConfirmed'] ?? false,
      createdAt: parseDate(data['createdAt']),
      completedAt: data['completedAt'] != null ? parseDate(data['completedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestIdA': requestIdA,
      'requestIdB': requestIdB,
      'userAId': userAId,
      'userBId': userBId,
      'userAName': userAName,
      'userBName': userBName,
      'amount': amount,
      'userAHas': userAHas,
      'userBHas': userBHas,
      'status': status,
      'userAConfirmed': userAConfirmed,
      'userBConfirmed': userBConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
