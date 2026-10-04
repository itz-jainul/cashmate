import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/connection_model.dart';
import '../../../models/exchange_model.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/exchange_service.dart';

final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  return ExchangeService();
});

// Stream all public searching requests
final publicRequestsProvider =
    StreamProvider<List<ExchangeRequestModel>>((ref) {
  final service = ref.watch(exchangeServiceProvider);
  return service.streamPublicRequests();
});

// Stream current user's active request
final activeRequestProvider = StreamProvider<ExchangeRequestModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamActiveRequest(user.uid);
});

// Stream specific request by ID
final requestByIdProvider =
    StreamProvider.family<ExchangeRequestModel?, String>((ref, requestId) {
  final service = ref.watch(exchangeServiceProvider);
  return service.streamRequest(requestId);
});

// Stream user's connections (Active & Completed)
final userConnectionsProvider = StreamProvider<List<ConnectionModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamUserConnections(user.uid);
});

// Stream specific connection by ID
final connectionByIdProvider =
    StreamProvider.family<ConnectionModel?, String>((ref, connectionId) {
  final service = ref.watch(exchangeServiceProvider);
  return service.streamConnection(connectionId);
});

// Stream user history
final userHistoryProvider = StreamProvider<List<ExchangeModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamUserHistory(user.uid);
});

// Stream notifications
final notificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamNotifications(user.uid);
});

// Stream chat messages
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, chatId) {
  final service = ref.watch(exchangeServiceProvider);
  return service.streamChatMessages(chatId);
});
