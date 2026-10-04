import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/exchange_model.dart';
import '../../../models/exchange_request_model.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('exchangeRequests');

  CollectionReference<Map<String, dynamic>> get _exchangesCol =>
      _firestore.collection('exchanges');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // Stream user's active request
  Stream<ExchangeRequestModel?> streamActiveRequest(String userId) {
    return _requestsCol
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['searching', 'matched', 'accepted'])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Return the most recently updated active request
      final doc = snapshot.docs.first;
      return ExchangeRequestModel.fromFirestore(doc);
    });
  }

  // Stream a specific request by ID
  Stream<ExchangeRequestModel?> streamRequest(String requestId) {
    return _requestsCol.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExchangeRequestModel.fromFirestore(doc);
    });
  }

  // Create an exchange request and proactively look for a match
  Future<ExchangeRequestModel> createRequest({
    required String userId,
    required String userName,
    required String has,
    required String wants,
    required int amount,
  }) async {
    // 1. Verify no existing active request
    final existing = await _requestsCol
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['searching', 'matched', 'accepted'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You already have an active request. Complete or cancel it first.');
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 30));

    final docRef = _requestsCol.doc();
    final request = ExchangeRequestModel(
      id: docRef.id,
      userId: userId,
      userName: userName,
      has: has,
      wants: wants,
      amount: amount,
      status: ExchangeStatus.searching,
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt,
    );

    await docRef.set(request.toMap());

    // 2. Search for matching counter-request
    await findAndBindMatch(request);

    return request;
  }

  // Matching Engine with atomic Firestore transaction
  Future<bool> findAndBindMatch(ExchangeRequestModel currentRequest) async {
    try {
      // Query candidate counter-requests
      final snapshot = await _requestsCol
          .where('has', isEqualTo: currentRequest.wants)
          .where('wants', isEqualTo: currentRequest.has)
          .where('amount', isEqualTo: currentRequest.amount)
          .where('status', isEqualTo: ExchangeStatus.searching.value)
          .get();

      final now = DateTime.now();

      DocumentSnapshot<Map<String, dynamic>>? validCandidate;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final candidateUserId = data['userId'] as String?;
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

        // Must be a different user and not expired
        if (candidateUserId != null &&
            candidateUserId != currentRequest.userId &&
            expiresAt != null &&
            expiresAt.isAfter(now)) {
          validCandidate = doc;
          break;
        }
      }

      if (validCandidate == null) {
        return false;
      }

      final candidateId = validCandidate.id;
      final candidateData = validCandidate.data()!;
      final candidateUserId = candidateData['userId'] as String;
      final candidateUserName = candidateData['userName'] as String? ?? 'Student';

      // Atomic Transaction to lock both requests
      return await _firestore.runTransaction<bool>((transaction) async {
        final freshCurrent = await transaction.get(_requestsCol.doc(currentRequest.id));
        final freshCandidate = await transaction.get(_requestsCol.doc(candidateId));

        if (!freshCurrent.exists || !freshCandidate.exists) {
          return false;
        }

        final currentStatus = freshCurrent.data()?['status'];
        final candidateStatus = freshCandidate.data()?['status'];

        if (currentStatus != ExchangeStatus.searching.value ||
            candidateStatus != ExchangeStatus.searching.value) {
          // One of them was claimed concurrently
          return false;
        }

        final updateTime = Timestamp.now();

        // Update Request A
        transaction.update(_requestsCol.doc(currentRequest.id), {
          'status': ExchangeStatus.matched.value,
          'matchedUserId': candidateUserId,
          'matchedRequestId': candidateId,
          'userAccepted': false,
          'matchedUserAccepted': false,
          'updatedAt': updateTime,
        });

        // Update Request B
        transaction.update(_requestsCol.doc(candidateId), {
          'status': ExchangeStatus.matched.value,
          'matchedUserId': currentRequest.userId,
          'matchedRequestId': currentRequest.id,
          'userAccepted': false,
          'matchedUserAccepted': false,
          'updatedAt': updateTime,
        });

        // Add Notification for candidate user
        final notifB = _notificationsCol.doc();
        transaction.set(notifB, {
          'userId': candidateUserId,
          'title': 'Match Found! 🎉',
          'message': 'You have been matched with ${currentRequest.userName} for ₹${currentRequest.amount}.',
          'type': 'match_found',
          'isRead': false,
          'createdAt': updateTime,
        });

        // Add Notification for current user
        final notifA = _notificationsCol.doc();
        transaction.set(notifA, {
          'userId': currentRequest.userId,
          'title': 'Match Found! 🎉',
          'message': 'You have been matched with $candidateUserName for ₹${currentRequest.amount}.',
          'type': 'match_found',
          'isRead': false,
          'createdAt': updateTime,
        });

        return true;
      });
    } catch (_) {
      return false;
    }
  }

  // Accept Match Handshake
  Future<void> acceptMatch({
    required String requestId,
    required String matchedRequestId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final myDoc = await transaction.get(_requestsCol.doc(requestId));
      final partnerDoc = await transaction.get(_requestsCol.doc(matchedRequestId));

      if (!myDoc.exists || !partnerDoc.exists) {
        throw Exception('Request no longer exists.');
      }

      final partnerAccepted = partnerDoc.data()?['userAccepted'] as bool? ?? false;
      final updateTime = Timestamp.now();

      if (partnerAccepted) {
        // Both have accepted -> move to accepted
        transaction.update(_requestsCol.doc(requestId), {
          'userAccepted': true,
          'matchedUserAccepted': true,
          'status': ExchangeStatus.accepted.value,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(matchedRequestId), {
          'userAccepted': true,
          'matchedUserAccepted': true,
          'status': ExchangeStatus.accepted.value,
          'updatedAt': updateTime,
        });
      } else {
        // Only this user accepted so far
        transaction.update(_requestsCol.doc(requestId), {
          'userAccepted': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(matchedRequestId), {
          'matchedUserAccepted': true,
          'updatedAt': updateTime,
        });
      }
    });
  }

  // Dual Confirmation Handshake to complete exchange
  Future<void> confirmExchange({
    required String requestId,
    required String matchedRequestId,
    required String currentUserId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final myDoc = await transaction.get(_requestsCol.doc(requestId));
      final partnerDoc = await transaction.get(_requestsCol.doc(matchedRequestId));

      if (!myDoc.exists || !partnerDoc.exists) {
        throw Exception('Exchange requests not found.');
      }

      final myData = myDoc.data()!;
      final partnerData = partnerDoc.data()!;

      final partnerConfirmed = partnerData['userConfirmed'] as bool? ?? false;
      final updateTime = Timestamp.now();

      if (partnerConfirmed) {
        // Both confirmed! Mark completed and archive to exchanges collection
        transaction.update(_requestsCol.doc(requestId), {
          'userConfirmed': true,
          'matchedUserConfirmed': true,
          'status': ExchangeStatus.completed.value,
          'updatedAt': updateTime,
        });

        transaction.update(_requestsCol.doc(matchedRequestId), {
          'userConfirmed': true,
          'matchedUserConfirmed': true,
          'status': ExchangeStatus.completed.value,
          'updatedAt': updateTime,
        });

        final exchangeDoc = _exchangesCol.doc();
        final completedExchange = ExchangeModel(
          id: exchangeDoc.id,
          requestIdA: requestId,
          requestIdB: matchedRequestId,
          userAId: currentUserId,
          userBId: partnerData['userId'] as String,
          userAName: myData['userName'] as String,
          userBName: partnerData['userName'] as String,
          amount: (myData['amount'] as num).toInt(),
          userAHas: myData['has'] as String,
          userBHas: partnerData['has'] as String,
          status: 'completed',
          userAConfirmed: true,
          userBConfirmed: true,
          createdAt: (myData['createdAt'] as Timestamp).toDate(),
          completedAt: updateTime.toDate(),
        );

        transaction.set(exchangeDoc, {
          ...completedExchange.toMap(),
          'participantIds': [currentUserId, partnerData['userId'] as String],
        });

        // Safely increment completed count on both user documents if they exist
        final userARef = _firestore.collection('users').doc(currentUserId);
        final userBRef = _firestore.collection('users').doc(partnerData['userId'] as String);

        final userASnap = await transaction.get(userARef);
        if (userASnap.exists) {
          transaction.update(userARef, {'completedExchanges': FieldValue.increment(1)});
        }
        final userBSnap = await transaction.get(userBRef);
        if (userBSnap.exists) {
          transaction.update(userBRef, {'completedExchanges': FieldValue.increment(1)});
        }
      } else {
        // Mark current user confirmed and notify partner via matchedUserConfirmed
        transaction.update(_requestsCol.doc(requestId), {
          'userConfirmed': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(matchedRequestId), {
          'matchedUserConfirmed': true,
          'updatedAt': updateTime,
        });
      }
    });
  }

  // Cancel Request
  Future<void> cancelRequest(String requestId) async {
    final doc = await _requestsCol.doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final matchedRequestId = data['matchedRequestId'] as String?;

    final batch = _firestore.batch();
    batch.update(_requestsCol.doc(requestId), {
      'status': ExchangeStatus.cancelled.value,
      'updatedAt': Timestamp.now(),
    });

    if (matchedRequestId != null) {
      // Revert partner request back to searching so they can find another peer
      batch.update(_requestsCol.doc(matchedRequestId), {
        'status': ExchangeStatus.searching.value,
        'matchedUserId': null,
        'matchedRequestId': null,
        'userAccepted': false,
        'matchedUserAccepted': false,
        'userConfirmed': false,
        'matchedUserConfirmed': false,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Stream completed/cancelled exchanges for History
  Stream<List<ExchangeModel>> streamUserHistory(String userId) {
    return _exchangesCol
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => ExchangeModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Stream notifications
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
