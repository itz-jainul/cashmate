import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/exchange_model.dart';
import '../../../models/exchange_request_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/exchange_service.dart';

final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  return ExchangeService();
});

final activeRequestProvider = StreamProvider<ExchangeRequestModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamActiveRequest(user.uid);
});

final userHistoryProvider = StreamProvider<List<ExchangeModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamUserHistory(user.uid);
});

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final service = ref.watch(exchangeServiceProvider);
  return service.streamNotifications(user.uid);
});
