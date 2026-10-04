import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus {
  pending,
  connected,
  completed,
  cancelled;

  static ConnectionStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'connected':
        return ConnectionStatus.connected;
      case 'completed':
        return ConnectionStatus.completed;
      case 'cancelled':
        return ConnectionStatus.cancelled;
      case 'pending':
      default:
        return ConnectionStatus.pending;
    }
  }

  String get value => name;
}

class ConnectionModel {
  final String id;
  final String userAId;
  final String userBId;
  final String requestAId;
  final String requestBId;
  final String userAName;
  final String userBName;
  final String userAHas; // 'cash' or 'digital'
  final String userBHas; // 'cash' or 'digital'
  final int amount;
  final String location;
  final ConnectionStatus status;
  final bool userAAccepted;
  final bool userBAccepted;
  final bool userAConfirmed;
  final bool userBConfirmed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ConnectionModel({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.requestAId,
    required this.requestBId,
    required this.userAName,
    required this.userBName,
    required this.userAHas,
    required this.userBHas,
    required this.amount,
    this.location = 'Campus Cafeteria',
    this.status = ConnectionStatus.pending,
    this.userAAccepted = false,
    this.userBAccepted = false,
    this.userAConfirmed = false,
    this.userBConfirmed = false,
    required this.createdAt,
    this.completedAt,
  });

  // Partner helper methods relative to a given user ID
  bool isUserA(String currentUserId) => currentUserId == userAId;

  String partnerId(String currentUserId) =>
      isUserA(currentUserId) ? userBId : userAId;

  String partnerName(String currentUserId) =>
      isUserA(currentUserId) ? userBName : userAName;

  String myHas(String currentUserId) =>
      isUserA(currentUserId) ? userAHas : userBHas;

  String myWants(String currentUserId) =>
      isUserA(currentUserId) ? userBHas : userAHas;

  bool isAcceptedByMe(String currentUserId) =>
      isUserA(currentUserId) ? userAAccepted : userBAccepted;

  bool isAcceptedByPartner(String currentUserId) =>
      isUserA(currentUserId) ? userBAccepted : userAAccepted;

  bool isConfirmedByMe(String currentUserId) =>
      isUserA(currentUserId) ? userAConfirmed : userBConfirmed;

  bool isConfirmedByPartner(String currentUserId) =>
      isUserA(currentUserId) ? userBConfirmed : userAConfirmed;

  factory ConnectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ConnectionModel.fromMap(data, doc.id);
  }

  factory ConnectionModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ConnectionModel(
      id: id,
      userAId: data['userAId'] as String? ?? '',
      userBId: data['userBId'] as String? ?? '',
      requestAId: data['requestAId'] as String? ?? '',
      requestBId: data['requestBId'] as String? ?? '',
      userAName: data['userAName'] as String? ?? 'Student',
      userBName: data['userBName'] as String? ?? 'Student',
      userAHas: data['userAHas'] as String? ?? 'cash',
      userBHas: data['userBHas'] as String? ?? 'digital',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      location: data['location'] as String? ?? 'Campus Cafeteria',
      status: ConnectionStatus.fromString(data['status'] as String?),
      userAAccepted: data['userAAccepted'] as bool? ?? false,
      userBAccepted: data['userBAccepted'] as bool? ?? false,
      userAConfirmed: data['userAConfirmed'] as bool? ?? false,
      userBConfirmed: data['userBConfirmed'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
      completedAt:
          data['completedAt'] != null ? parseDate(data['completedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userAId': userAId,
      'userBId': userBId,
      'requestAId': requestAId,
      'requestBId': requestBId,
      'userAName': userAName,
      'userBName': userBName,
      'userAHas': userAHas,
      'userBHas': userBHas,
      'amount': amount,
      'location': location,
      'status': status.value,
      'userAAccepted': userAAccepted,
      'userBAccepted': userBAccepted,
      'userAConfirmed': userAConfirmed,
      'userBConfirmed': userBConfirmed,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  ConnectionModel copyWith({
    String? id,
    String? userAId,
    String? userBId,
    String? requestAId,
    String? requestBId,
    String? userAName,
    String? userBName,
    String? userAHas,
    String? userBHas,
    int? amount,
    String? location,
    ConnectionStatus? status,
    bool? userAAccepted,
    bool? userBAccepted,
    bool? userAConfirmed,
    bool? userBConfirmed,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      userAId: userAId ?? this.userAId,
      userBId: userBId ?? this.userBId,
      requestAId: requestAId ?? this.requestAId,
      requestBId: requestBId ?? this.requestBId,
      userAName: userAName ?? this.userAName,
      userBName: userBName ?? this.userBName,
      userAHas: userAHas ?? this.userAHas,
      userBHas: userBHas ?? this.userBHas,
      amount: amount ?? this.amount,
      location: location ?? this.location,
      status: status ?? this.status,
      userAAccepted: userAAccepted ?? this.userAAccepted,
      userBAccepted: userBAccepted ?? this.userBAccepted,
      userAConfirmed: userAConfirmed ?? this.userAConfirmed,
      userBConfirmed: userBConfirmed ?? this.userBConfirmed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
