import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/connection_model.dart';
import '../../../models/exchange_model.dart';
import '../../../models/exchange_request_model.dart';

class ExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('exchangeRequests');

  CollectionReference<Map<String, dynamic>> get _connectionsCol =>
      _firestore.collection('connections');

  CollectionReference<Map<String, dynamic>> get _exchangesCol =>
      _firestore.collection('exchanges');

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // Helper to compute deterministic connection/chat ID between two requests
  static String getConnectionId(String reqA, String reqB) {
    return reqA.compareTo(reqB) < 0 ? '${reqA}_$reqB' : '${reqB}_$reqA';
  }

  // Alias for backwards compatibility
  static String getChatId(String idA, String idB) => getConnectionId(idA, idB);

  // 1. Stream all active public searching requests (for the Requests screen)
  // Queries by status without requiring composite indexes, sorted in memory
  Stream<List<ExchangeRequestModel>> streamPublicRequests() {
    return _requestsCol
        .where('status', isEqualTo: ExchangeStatus.searching.value)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ExchangeRequestModel.fromFirestore(doc))
          .where((req) => !req.isExpired)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 2. Stream user's active request
  Stream<ExchangeRequestModel?> streamActiveRequest(String userId) {
    return _requestsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final activeList = snapshot.docs
          .map((doc) => ExchangeRequestModel.fromFirestore(doc))
          .where((req) =>
              req.status == ExchangeStatus.searching ||
              req.status == ExchangeStatus.matched ||
              req.status == ExchangeStatus.accepted)
          .toList();
      if (activeList.isEmpty) return null;
      activeList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return activeList.first;
    });
  }

  // 3. Stream a specific request by ID
  Stream<ExchangeRequestModel?> streamRequest(String requestId) {
    return _requestsCol.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExchangeRequestModel.fromFirestore(doc);
    });
  }

  // 4. Stream user's connections (Active & Completed, with backward-compatibility)
  Stream<List<ConnectionModel>> streamUserConnections(String userId) {
    late StreamController<List<ConnectionModel>> controller;
    StreamSubscription? subA;
    StreamSubscription? subB;
    StreamSubscription? subReq;
    StreamSubscription? subReqB;
    StreamSubscription? subExA;
    StreamSubscription? subExB;

    Map<String, ConnectionModel> userAConnections = {};
    Map<String, ConnectionModel> userBConnections = {};
    Map<String, ConnectionModel> requestConnections = {};
    Map<String, ConnectionModel> requestBConnections = {};
    Map<String, ConnectionModel> historyConnections = {};

    void emitMerged() {
      // Direct connections have highest priority, then requests, then history
      final allMap = <String, ConnectionModel>{
        ...historyConnections,
        ...requestConnections,
        ...requestBConnections,
        ...userAConnections,
        ...userBConnections,
      };
      final all = allMap.values.toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) {
        controller.add(all);
      }
    }

    controller = StreamController<List<ConnectionModel>>(
      onListen: () {
        // Direct connections where user is User A
        subA = _connectionsCol
            .where('userAId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            userAConnections = {
              for (var doc in snap.docs)
                doc.id: ConnectionModel.fromFirestore(doc)
            };
            emitMerged();
          },
          onError: (_) => emitMerged(),
        );

        // Direct connections where user is User B
        subB = _connectionsCol
            .where('userBId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            userBConnections = {
              for (var doc in snap.docs)
                doc.id: ConnectionModel.fromFirestore(doc)
            };
            emitMerged();
          },
          onError: (_) => emitMerged(),
        );

        // Backward compatibility: user's own matched/accepted requests
        subReq = _requestsCol
            .where('userId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            final Map<String, ConnectionModel> map = {};
            for (final doc in snap.docs) {
              final req = ExchangeRequestModel.fromFirestore(doc);
              if (req.status == ExchangeStatus.matched ||
                  req.status == ExchangeStatus.accepted ||
                  req.status == ExchangeStatus.completed) {
                if (req.matchedUserId != null && req.matchedRequestId != null) {
                  final connId = req.connectionId ??
                      getConnectionId(req.id, req.matchedRequestId!);
                  final status = req.status == ExchangeStatus.completed
                      ? ConnectionStatus.completed
                      : (req.status == ExchangeStatus.accepted
                          ? ConnectionStatus.connected
                          : ConnectionStatus.pending);

                  map[connId] = ConnectionModel(
                    id: connId,
                    userAId: req.userId,
                    userBId: req.matchedUserId!,
                    requestAId: req.id,
                    requestBId: req.matchedRequestId!,
                    userAName: req.userName,
                    userBName: 'Exchange Partner',
                    userAHas: req.has,
                    userBHas: req.wants,
                    amount: req.amount,
                    location: req.location,
                    status: status,
                    userAAccepted: req.userAccepted,
                    userBAccepted: req.matchedUserAccepted,
                    userAConfirmed: req.userConfirmed,
                    userBConfirmed: req.matchedUserConfirmed,
                    createdAt: req.createdAt,
                  );
                }
              }
            }
            requestConnections = map;
            emitMerged();
          },
          onError: (_) => emitMerged(),
        );

        // Backward compatibility: requests where user was matched by peer
        subReqB = _requestsCol
            .where('matchedUserId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            final Map<String, ConnectionModel> map = {};
            for (final doc in snap.docs) {
              final req = ExchangeRequestModel.fromFirestore(doc);
              if (req.status == ExchangeStatus.matched ||
                  req.status == ExchangeStatus.accepted ||
                  req.status == ExchangeStatus.completed) {
                final connId = req.connectionId ??
                    getConnectionId(req.id, req.matchedRequestId ?? doc.id);
                final status = req.status == ExchangeStatus.completed
                    ? ConnectionStatus.completed
                    : (req.status == ExchangeStatus.accepted
                        ? ConnectionStatus.connected
                        : ConnectionStatus.pending);

                map[connId] = ConnectionModel(
                  id: connId,
                  userAId: req.userId,
                  userBId: userId,
                  requestAId: req.id,
                  requestBId: req.matchedRequestId ?? '',
                  userAName: req.userName,
                  userBName: 'Exchange Partner',
                  userAHas: req.has,
                  userBHas: req.wants,
                  amount: req.amount,
                  location: req.location,
                  status: status,
                  userAAccepted: req.userAccepted,
                  userBAccepted: req.matchedUserAccepted,
                  userAConfirmed: req.userConfirmed,
                  userBConfirmed: req.matchedUserConfirmed,
                  createdAt: req.createdAt,
                );
              }
            }
            requestBConnections = map;
            emitMerged();
          },
          onError: (_) => emitMerged(),
        );

        // Backward compatibility: completed history
        subExA = _exchangesCol
            .where('userAId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            for (final doc in snap.docs) {
              final ex = ExchangeModel.fromFirestore(doc);
              historyConnections[ex.id] = ConnectionModel(
                id: ex.id,
                userAId: ex.userAId,
                userBId: ex.userBId,
                requestAId: ex.requestIdA ?? '',
                requestBId: ex.requestIdB ?? '',
                userAName: ex.userAName,
                userBName: ex.userBName,
                userAHas: ex.userAHas,
                userBHas: ex.userBHas,
                amount: ex.amount,
                location: ex.location ?? 'Campus Cafeteria',
                status: ConnectionStatus.completed,
                userAAccepted: true,
                userBAccepted: true,
                userAConfirmed: true,
                userBConfirmed: true,
                createdAt: ex.createdAt,
                completedAt: ex.completedAt,
              );
            }
            emitMerged();
          },
          onError: (_) {},
        );

        subExB = _exchangesCol
            .where('userBId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            for (final doc in snap.docs) {
              final ex = ExchangeModel.fromFirestore(doc);
              historyConnections[ex.id] = ConnectionModel(
                id: ex.id,
                userAId: ex.userAId,
                userBId: ex.userBId,
                requestAId: ex.requestIdA ?? '',
                requestBId: ex.requestIdB ?? '',
                userAName: ex.userAName,
                userBName: ex.userBName,
                userAHas: ex.userAHas,
                userBHas: ex.userBHas,
                amount: ex.amount,
                location: ex.location ?? 'Campus Cafeteria',
                status: ConnectionStatus.completed,
                userAAccepted: true,
                userBAccepted: true,
                userAConfirmed: true,
                userBConfirmed: true,
                createdAt: ex.createdAt,
                completedAt: ex.completedAt,
              );
            }
            emitMerged();
          },
          onError: (_) {},
        );
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
        subReq?.cancel();
        subReqB?.cancel();
        subExA?.cancel();
        subExB?.cancel();
      },
    );

    return controller.stream;
  }

  // 5. Stream single connection by ID (with fallback lookup)
  Stream<ConnectionModel?> streamConnection(String connectionId) {
    late StreamController<ConnectionModel?> controller;
    StreamSubscription? connSub;
    StreamSubscription? reqSub;

    controller = StreamController<ConnectionModel?>(
      onListen: () {
        connSub = _connectionsCol.doc(connectionId).snapshots().listen(
          (doc) {
            if (doc.exists) {
              if (!controller.isClosed) {
                controller.add(ConnectionModel.fromFirestore(doc));
              }
            } else {
              // Fallback to checking request by ID pair (reqA_reqB)
              final parts = connectionId.split('_');
              if (parts.isNotEmpty) {
                reqSub = _requestsCol.doc(parts[0]).snapshots().listen((rDoc) {
                  if (rDoc.exists) {
                    final req = ExchangeRequestModel.fromFirestore(rDoc);
                    final status = req.status == ExchangeStatus.completed
                        ? ConnectionStatus.completed
                        : (req.status == ExchangeStatus.accepted
                            ? ConnectionStatus.connected
                            : ConnectionStatus.pending);

                    final fallback = ConnectionModel(
                      id: connectionId,
                      userAId: req.userId,
                      userBId: req.matchedUserId ?? '',
                      requestAId: req.id,
                      requestBId: req.matchedRequestId ??
                          (parts.length > 1 ? parts[1] : ''),
                      userAName: req.userName,
                      userBName: 'Exchange Partner',
                      userAHas: req.has,
                      userBHas: req.wants,
                      amount: req.amount,
                      location: req.location,
                      status: status,
                      userAAccepted: req.userAccepted,
                      userBAccepted: req.matchedUserAccepted,
                      userAConfirmed: req.userConfirmed,
                      userBConfirmed: req.matchedUserConfirmed,
                      createdAt: req.createdAt,
                    );
                    if (!controller.isClosed) controller.add(fallback);
                  } else {
                    if (!controller.isClosed) controller.add(null);
                  }
                });
              } else {
                if (!controller.isClosed) controller.add(null);
              }
            }
          },
          onError: (e) {
            if (!controller.isClosed) controller.add(null);
          },
        );
      },
      onCancel: () {
        connSub?.cancel();
        reqSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 6. Create an exchange request and proactively look for an exact match
  Future<ExchangeRequestModel> createRequest({
    required String userId,
    required String userName,
    required String has,
    required String wants,
    required int amount,
    String location = 'Campus Cafeteria',
  }) async {
    if (has == wants) {
      throw Exception('What you have and what you want cannot be identical.');
    }

    // Verify only one active searching/matched request per user
    final existingDocs = await _requestsCol
        .where('userId', isEqualTo: userId)
        .get();

    final hasActive = existingDocs.docs.any((d) {
      final s = d.data()['status']?.toString().toLowerCase();
      return s == 'searching' || s == 'matched' || s == 'accepted';
    });

    if (hasActive) {
      throw Exception(
          'You already have an active request. Please cancel your current request before creating another.');
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
      location: location,
      status: ExchangeStatus.searching,
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt,
    );

    await docRef.set(request.toMap());

    // Automatically check for exact compatible match
    await findAndBindMatch(request);

    return request;
  }

  // 7. Automatic Exact Matching Engine with atomic Firestore transaction
  Future<bool> findAndBindMatch(ExchangeRequestModel currentRequest) async {
    try {
      // Query candidate counter-requests:
      // Exact opposite has/wants, exact same amount, searching status
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
      final connectionId = getConnectionId(currentRequest.id, candidateId);

      // Atomic Transaction to match both requests and create Connection
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
          'connectionId': connectionId,
          'userAccepted': false,
          'matchedUserAccepted': false,
          'updatedAt': updateTime,
        });

        // Update Request B
        transaction.update(_requestsCol.doc(candidateId), {
          'status': ExchangeStatus.matched.value,
          'matchedUserId': currentRequest.userId,
          'matchedRequestId': currentRequest.id,
          'connectionId': connectionId,
          'userAccepted': false,
          'matchedUserAccepted': false,
          'updatedAt': updateTime,
        });

        // Create Connection Document
        final connDoc = _connectionsCol.doc(connectionId);
        final newConnection = ConnectionModel(
          id: connectionId,
          userAId: currentRequest.userId,
          userBId: candidateUserId,
          requestAId: currentRequest.id,
          requestBId: candidateId,
          userAName: currentRequest.userName,
          userBName: candidateUserName,
          userAHas: currentRequest.has,
          userBHas: candidateData['has'] as String? ?? currentRequest.wants,
          amount: currentRequest.amount,
          location: currentRequest.location,
          status: ConnectionStatus.pending,
          userAAccepted: false,
          userBAccepted: false,
          userAConfirmed: false,
          userBConfirmed: false,
          createdAt: updateTime.toDate(),
        );

        transaction.set(connDoc, newConnection.toMap());

        // Add Notification for candidate user
        final notifB = _notificationsCol.doc();
        transaction.set(notifB, {
          'userId': candidateUserId,
          'title': 'Match Found! 🎉',
          'message':
              'You have been matched with ${currentRequest.userName} for ₹${currentRequest.amount}.',
          'type': 'match_found',
          'connectionId': connectionId,
          'isRead': false,
          'createdAt': updateTime,
        });

        // Add Notification for current user
        final notifA = _notificationsCol.doc();
        transaction.set(notifA, {
          'userId': currentRequest.userId,
          'title': 'Match Found! 🎉',
          'message':
              'You have been matched with $candidateUserName for ₹${currentRequest.amount}.',
          'type': 'match_found',
          'connectionId': connectionId,
          'isRead': false,
          'createdAt': updateTime,
        });

        return true;
      });
    } catch (_) {
      return false;
    }
  }

  // 8. Manual Connect Operation (from Public Requests screen)
  Future<ConnectionModel> connectToRequest({
    required String currentUserId,
    required String currentUserName,
    required String targetRequestId,
  }) async {
    return await _firestore.runTransaction<ConnectionModel>((transaction) async {
      // 1. Re-read target request
      final targetDoc = await transaction.get(_requestsCol.doc(targetRequestId));
      if (!targetDoc.exists) {
        throw Exception('Target request no longer exists.');
      }

      final targetData = targetDoc.data()!;
      final targetStatus = targetData['status'] as String?;
      final targetUserId = targetData['userId'] as String?;
      final targetUserName = targetData['userName'] as String? ?? 'Student';
      final targetHas = targetData['has'] as String;
      final targetWants = targetData['wants'] as String;
      final targetAmount = (targetData['amount'] as num).toInt();
      final targetExpiresAt = (targetData['expiresAt'] as Timestamp?)?.toDate();

      if (targetStatus != ExchangeStatus.searching.value) {
        throw Exception('This request is no longer available.');
      }

      if (targetUserId == currentUserId) {
        throw Exception('Cannot connect to your own request.');
      }

      if (targetExpiresAt != null && targetExpiresAt.isBefore(DateTime.now())) {
        throw Exception('This exchange request has expired.');
      }

      // 2. Check current user's existing requests
      final userExistingSnap = await _requestsCol
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Check if user is already in an ongoing active handshake/match
      final hasOngoingMatch = userExistingSnap.docs.any((d) {
        final s = d.data()['status']?.toString().toLowerCase();
        return s == ExchangeStatus.matched.value ||
            s == ExchangeStatus.accepted.value;
      });

      if (hasOngoingMatch) {
        throw Exception(
            'You already have an active exchange in progress. Please complete or cancel it first.');
      }

      final userSearchingDocs = userExistingSnap.docs.where((d) {
        final s = d.data()['status']?.toString().toLowerCase();
        return s == ExchangeStatus.searching.value;
      }).toList();

      String myRequestId;
      String myLocation = targetData['location'] as String? ?? 'Campus Cafeteria';
      final now = DateTime.now();
      final updateTime = Timestamp.now();

      if (userSearchingDocs.isNotEmpty) {
        final myDoc = userSearchingDocs.first;
        final myData = myDoc.data();

        myRequestId = myDoc.id;
        myLocation = myData['location'] as String? ?? myLocation;

        // Cancel any extra searching requests if they exist
        for (int i = 1; i < userSearchingDocs.length; i++) {
          transaction.update(userSearchingDocs[i].reference, {
            'status': ExchangeStatus.cancelled.value,
            'updatedAt': updateTime,
          });
        }
      } else {
        final newReqRef = _requestsCol.doc();
        myRequestId = newReqRef.id;
      }

      final connectionId = getConnectionId(myRequestId, targetRequestId);

      if (userSearchingDocs.isNotEmpty) {
        // Update existing search request to match this connection's terms
        transaction.update(_requestsCol.doc(myRequestId), {
          'has': targetWants,
          'wants': targetHas,
          'amount': targetAmount,
          'status': ExchangeStatus.matched.value,
          'matchedUserId': targetUserId,
          'matchedRequestId': targetRequestId,
          'connectionId': connectionId,
          'userAccepted': false,
          'matchedUserAccepted': false,
          'updatedAt': updateTime,
        });
      } else {
        // Create brand new matching request for current user
        final newReq = ExchangeRequestModel(
          id: myRequestId,
          userId: currentUserId,
          userName: currentUserName,
          has: targetWants,
          wants: targetHas,
          amount: targetAmount,
          location: myLocation,
          status: ExchangeStatus.matched,
          matchedUserId: targetUserId,
          matchedRequestId: targetRequestId,
          connectionId: connectionId,
          createdAt: now,
          updatedAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
        );

        transaction.set(_requestsCol.doc(myRequestId), newReq.toMap());
      }

      // Update target request to matched
      transaction.update(_requestsCol.doc(targetRequestId), {
        'status': ExchangeStatus.matched.value,
        'matchedUserId': currentUserId,
        'matchedRequestId': myRequestId,
        'connectionId': connectionId,
        'userAccepted': false,
        'matchedUserAccepted': false,
        'updatedAt': updateTime,
      });

      // Create Connection Document
      final connection = ConnectionModel(
        id: connectionId,
        userAId: currentUserId,
        userBId: targetUserId!,
        requestAId: myRequestId,
        requestBId: targetRequestId,
        userAName: currentUserName,
        userBName: targetUserName,
        userAHas: targetWants,
        userBHas: targetHas,
        amount: targetAmount,
        location: myLocation,
        status: ConnectionStatus.pending,
        userAAccepted: false,
        userBAccepted: false,
        userAConfirmed: false,
        userBConfirmed: false,
        createdAt: updateTime.toDate(),
      );

      transaction.set(_connectionsCol.doc(connectionId), connection.toMap());

      // Notify target user
      final notifTarget = _notificationsCol.doc();
      transaction.set(notifTarget, {
        'userId': targetUserId,
        'title': 'Match Found! 🎉',
        'message':
            '$currentUserName connected with your ₹$targetAmount request.',
        'type': 'match_found',
        'connectionId': connectionId,
        'isRead': false,
        'createdAt': updateTime,
      });

      // Notify current user
      final notifCurrent = _notificationsCol.doc();
      transaction.set(notifCurrent, {
        'userId': currentUserId,
        'title': 'Connected! 🎉',
        'message':
            'You connected with $targetUserName for ₹$targetAmount.',
        'type': 'match_found',
        'connectionId': connectionId,
        'isRead': false,
        'createdAt': updateTime,
      });

      return connection;
    });
  }

  // 9. Accept Connection Handshake (both users must accept)
  Future<void> acceptConnection({
    required String connectionId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final connDoc = await transaction.get(_connectionsCol.doc(connectionId));
      if (!connDoc.exists) {
        throw Exception('Connection not found.');
      }

      final conn = ConnectionModel.fromFirestore(connDoc);
      final isUserA = conn.userAId == userId;
      final partnerId = isUserA ? conn.userBId : conn.userAId;
      final partnerAccepted = isUserA ? conn.userBAccepted : conn.userAAccepted;

      final updateTime = Timestamp.now();

      if (partnerAccepted) {
        // Both accepted! Transition connection to connected
        transaction.update(_connectionsCol.doc(connectionId), {
          if (isUserA) 'userAAccepted': true else 'userBAccepted': true,
          'status': ConnectionStatus.connected.value,
        });

        // Update requests to accepted
        transaction.update(_requestsCol.doc(conn.requestAId), {
          'status': ExchangeStatus.accepted.value,
          'userAccepted': true,
          'matchedUserAccepted': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(conn.requestBId), {
          'status': ExchangeStatus.accepted.value,
          'userAccepted': true,
          'matchedUserAccepted': true,
          'updatedAt': updateTime,
        });

        // Send notification: Connection Accepted
        final notif = _notificationsCol.doc();
        transaction.set(notif, {
          'userId': partnerId,
          'title': 'Connection Accepted',
          'message': 'You can now complete your exchange.',
          'type': 'connection_accepted',
          'connectionId': connectionId,
          'isRead': false,
          'createdAt': updateTime,
        });
      } else {
        // Only this user accepted so far
        transaction.update(_connectionsCol.doc(connectionId), {
          if (isUserA) 'userAAccepted': true else 'userBAccepted': true,
        });

        // Update request accepted flag
        final myReqId = isUserA ? conn.requestAId : conn.requestBId;
        final partnerReqId = isUserA ? conn.requestBId : conn.requestAId;

        transaction.update(_requestsCol.doc(myReqId), {
          'userAccepted': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(partnerReqId), {
          'matchedUserAccepted': true,
          'updatedAt': updateTime,
        });
      }
    });
  }

  // 10. Dual Confirmation Handshake to complete exchange
  Future<void> confirmConnection({
    required String connectionId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      // 1. All Reads First
      final connDoc = await transaction.get(_connectionsCol.doc(connectionId));
      if (!connDoc.exists) {
        throw Exception('Connection not found.');
      }

      final conn = ConnectionModel.fromFirestore(connDoc);
      final isUserA = conn.userAId == userId;
      final partnerConfirmed = isUserA ? conn.userBConfirmed : conn.userAConfirmed;

      final userARef = _firestore.collection('users').doc(conn.userAId);
      final userBRef = _firestore.collection('users').doc(conn.userBId);

      final userASnap = await transaction.get(userARef);
      final userBSnap = await transaction.get(userBRef);

      final updateTime = Timestamp.now();

      // 2. All Writes After
      if (partnerConfirmed) {
        // Both confirmed! Mark completed
        transaction.update(_connectionsCol.doc(connectionId), {
          if (isUserA) 'userAConfirmed': true else 'userBConfirmed': true,
          'status': ConnectionStatus.completed.value,
          'completedAt': updateTime,
        });

        // Update both requests
        transaction.update(_requestsCol.doc(conn.requestAId), {
          'status': ExchangeStatus.completed.value,
          'userConfirmed': true,
          'matchedUserConfirmed': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(conn.requestBId), {
          'status': ExchangeStatus.completed.value,
          'userConfirmed': true,
          'matchedUserConfirmed': true,
          'updatedAt': updateTime,
        });

        // Archive into exchanges collection for historical consistency
        final exchangeDoc = _exchangesCol.doc(connectionId);
        final completedExchange = ExchangeModel(
          id: connectionId,
          requestIdA: conn.requestAId,
          requestIdB: conn.requestBId,
          userAId: conn.userAId,
          userBId: conn.userBId,
          userAName: conn.userAName,
          userBName: conn.userBName,
          amount: conn.amount,
          userAHas: conn.userAHas,
          userBHas: conn.userBHas,
          location: conn.location,
          status: 'completed',
          userAConfirmed: true,
          userBConfirmed: true,
          createdAt: conn.createdAt,
          completedAt: updateTime.toDate(),
        );

        transaction.set(exchangeDoc, {
          ...completedExchange.toMap(),
          'participantIds': [conn.userAId, conn.userBId],
        });

        if (userASnap.exists) {
          transaction.update(userARef, {'completedExchanges': FieldValue.increment(1)});
        }
        if (userBSnap.exists) {
          transaction.update(userBRef, {'completedExchanges': FieldValue.increment(1)});
        }

        // Notify both users: Exchange Completed
        final notifA = _notificationsCol.doc();
        transaction.set(notifA, {
          'userId': conn.userAId,
          'title': 'Exchange Completed',
          'message': 'Your ₹${conn.amount} exchange is complete.',
          'type': 'exchange_completed',
          'connectionId': connectionId,
          'isRead': false,
          'createdAt': updateTime,
        });

        final notifB = _notificationsCol.doc();
        transaction.set(notifB, {
          'userId': conn.userBId,
          'title': 'Exchange Completed',
          'message': 'Your ₹${conn.amount} exchange is complete.',
          'type': 'exchange_completed',
          'connectionId': connectionId,
          'isRead': false,
          'createdAt': updateTime,
        });
      } else {
        // Mark current user confirmed
        transaction.update(_connectionsCol.doc(connectionId), {
          if (isUserA) 'userAConfirmed': true else 'userBConfirmed': true,
        });

        final myReqId = isUserA ? conn.requestAId : conn.requestBId;
        final partnerReqId = isUserA ? conn.requestBId : conn.requestAId;

        transaction.update(_requestsCol.doc(myReqId), {
          'userConfirmed': true,
          'updatedAt': updateTime,
        });
        transaction.update(_requestsCol.doc(partnerReqId), {
          'matchedUserConfirmed': true,
          'updatedAt': updateTime,
        });
      }
    });
  }

  // 11. Cancel Connection
  Future<void> cancelConnection({
    required String connectionId,
    required String userId,
  }) async {
    final connDoc = await _connectionsCol.doc(connectionId).get();
    if (!connDoc.exists) return;

    final conn = ConnectionModel.fromFirestore(connDoc);
    final batch = _firestore.batch();
    final updateTime = Timestamp.now();

    batch.update(_connectionsCol.doc(connectionId), {
      'status': ConnectionStatus.cancelled.value,
    });

    batch.update(_requestsCol.doc(conn.requestAId), {
      'status': ExchangeStatus.cancelled.value,
      'updatedAt': updateTime,
    });

    batch.update(_requestsCol.doc(conn.requestBId), {
      'status': ExchangeStatus.cancelled.value,
      'updatedAt': updateTime,
    });

    await batch.commit();
  }

  // 12. Cancel Request
  Future<void> cancelRequest(String requestId) async {
    final doc = await _requestsCol.doc(requestId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final matchedRequestId = data['matchedRequestId'] as String?;
    final connectionId = data['connectionId'] as String?;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    batch.update(_requestsCol.doc(requestId), {
      'status': ExchangeStatus.cancelled.value,
      'updatedAt': now,
    });

    if (connectionId != null) {
      batch.update(_connectionsCol.doc(connectionId), {
        'status': ConnectionStatus.cancelled.value,
      });
    }

    if (matchedRequestId != null) {
      // Revert partner request back to searching so they can find another match
      batch.update(_requestsCol.doc(matchedRequestId), {
        'status': ExchangeStatus.searching.value,
        'matchedUserId': null,
        'matchedRequestId': null,
        'connectionId': null,
        'userAccepted': false,
        'matchedUserAccepted': false,
        'userConfirmed': false,
        'matchedUserConfirmed': false,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  // 13. Update agreed meetup location
  Future<void> updateMeetupLocation({
    required String requestId,
    String? matchedRequestId,
    required String newLocation,
    String? connectionId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_requestsCol.doc(requestId), {
      'location': newLocation,
      'updatedAt': Timestamp.now(),
    });
    if (matchedRequestId != null) {
      batch.update(_requestsCol.doc(matchedRequestId), {
        'location': newLocation,
        'updatedAt': Timestamp.now(),
      });
    }
    if (connectionId != null) {
      batch.update(_connectionsCol.doc(connectionId), {
        'location': newLocation,
      });
    }
    await batch.commit();
  }

  // 14. Stream completed/cancelled exchanges for History
  Stream<List<ExchangeModel>> streamUserHistory(String userId) {
    late StreamController<List<ExchangeModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subA;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subB;

    Map<String, ExchangeModel> userAExchanges = {};
    Map<String, ExchangeModel> userBExchanges = {};

    void emitMerged() {
      final all = {...userAExchanges, ...userBExchanges}.values.toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) {
        controller.add(all);
      }
    }

    controller = StreamController<List<ExchangeModel>>(
      onListen: () {
        subA = _exchangesCol
            .where('userAId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            userAExchanges = {
              for (var doc in snap.docs) doc.id: ExchangeModel.fromFirestore(doc)
            };
            emitMerged();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );

        subB = _exchangesCol
            .where('userBId', isEqualTo: userId)
            .snapshots()
            .listen(
          (snap) {
            userBExchanges = {
              for (var doc in snap.docs) doc.id: ExchangeModel.fromFirestore(doc)
            };
            emitMerged();
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );
      },
      onCancel: () {
        subA?.cancel();
        subB?.cancel();
      },
    );

    return controller.stream;
  }

  // 15. Stream notifications
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Mark single notification as read
  Future<void> markNotificationAsRead(String notifId) async {
    try {
      await _notificationsCol.doc(notifId).update({'isRead': true});
    } catch (_) {}
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final unreadSnap = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (final doc in unreadSnap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  // 16. Chat Subcollection
  CollectionReference<Map<String, dynamic>> _chatMessagesCol(String chatId) =>
      _firestore.collection('exchangeChats').doc(chatId).collection('messages');

  // Stream messages for a specific meetup coordination chat
  Stream<List<ChatMessageModel>> streamChatMessages(String chatId) {
    return _chatMessagesCol(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // Send a coordination message or quick status ping
  Future<void> sendChatMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    bool isQuickPing = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final docRef = _chatMessagesCol(chatId).doc();
    final msg = ChatMessageModel(
      id: docRef.id,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
      isQuickPing: isQuickPing,
      createdAt: now,
    );

    await docRef.set(msg.toMap());
  }

  // Backwards compatibility for match acceptance
  Future<void> acceptMatch({
    required String requestId,
    required String matchedRequestId,
  }) async {
    final connectionId = getConnectionId(requestId, matchedRequestId);
    final reqDoc = await _requestsCol.doc(requestId).get();
    if (!reqDoc.exists) return;
    final userId = reqDoc.data()!['userId'] as String;
    await acceptConnection(connectionId: connectionId, userId: userId);
  }

  // Backwards compatibility for match confirmation
  Future<void> confirmExchange({
    required String requestId,
    required String matchedRequestId,
    required String currentUserId,
  }) async {
    final connectionId = getConnectionId(requestId, matchedRequestId);
    await confirmConnection(connectionId: connectionId, userId: currentUserId);
  }
}
