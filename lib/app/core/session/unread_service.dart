import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/repositories/account_repository.dart';
import '../network/api_exception.dart';
import 'session_service.dart';

/// Unread-notification count for badges. Refreshed on sign-in, when the app
/// returns to the foreground, and after the notifications screen changes it.
/// Private: reset on every session change.
class UnreadService extends GetxService with WidgetsBindingObserver {
  UnreadService(this._repo, this._session);

  final NotificationRepository _repo;
  final SessionService _session;
  final count = 0.obs;
  Worker? _worker;
  bool _inFlight = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _worker = ever<int>(_session.epochStream, (_) {
      count.value = 0;
      reload();
    });
  }

  Future<void> reload() async {
    if (!_session.isSignedIn || _inFlight) return;
    _inFlight = true;
    final epoch = _session.epoch;
    try {
      final (_, unread) = await _repo.list();
      if (_session.isCurrent(epoch)) count.value = unread;
    } on ApiException {
      // Badge is best effort; the screen itself reports errors.
    } finally {
      _inFlight = false;
    }
  }

  void set(int value) => count.value = value;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  @override
  void onClose() {
    _worker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
