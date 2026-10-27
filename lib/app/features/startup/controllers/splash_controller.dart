import 'dart:async';

import 'package:get/get.dart';

import '../../../core/session/place_service.dart';
import '../../../core/session/session_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._session, this._place);

  final SessionService _session;
  final PlaceService _place;
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    final minimum = Completer<void>();
    _timer = Timer(const Duration(milliseconds: 1600), minimum.complete);
    await _session.restore();
    // Warm the public salon config; failures are retried by screens later.
    unawaited(_place.load().then((_) {}, onError: (_) {}));
    await minimum.future;
    if (isClosed) return;
    Get.offAllNamed(_session.isSignedIn ? Routes.main : Routes.onboarding);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
