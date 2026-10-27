import 'package:get/get.dart';

import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';

/// Owns the auth token and the signed-in customer.
///
/// [epoch] changes on every sign-in/sign-out. Controllers that load private
/// data capture it before a request and drop the response if it changed, so a
/// slow response from an earlier session can never restore private state.
class SessionService extends GetxService {
  SessionService(this._storage);

  final TokenStorage _storage;
  late AuthRepository _auth;

  String? _token;
  final user = Rxn<AppUser>();
  final _epoch = 0.obs;
  final _signedIn = false.obs;

  String? get token => _token;
  bool get isSignedIn => _signedIn.value;
  int get epoch => _epoch.value;
  RxInt get epochStream => _epoch;
  bool isCurrent(int epoch) => _epoch.value == epoch;

  void attach(AuthRepository auth) => _auth = auth;

  /// Restores the stored token. Does not block on the network.
  Future<void> restore() async {
    final stored = await _storage.read();
    if (stored == null || stored.isEmpty) return;
    _token = stored;
    _signedIn.value = true;
    refreshUser();
  }

  Future<void> refreshUser() async {
    if (!isSignedIn) return;
    final started = epoch;
    try {
      final me = await _auth.me();
      if (isCurrent(started)) user.value = me;
    } on ApiException catch (_) {
      // 401 is handled by the client hook; other errors keep the cached user.
    }
  }

  Future<void> signIn(AuthResult result) async {
    await _storage.write(result.token);
    _token = result.token;
    user.value = result.user;
    _signedIn.value = true;
    _epoch.value++;
    refreshUser();
  }

  /// Clears every piece of private state. [remote] also revokes the token.
  Future<void> signOut({bool remote = true}) async {
    final hadToken = _token != null;
    if (remote && hadToken) {
      try {
        await _auth.logout();
      } catch (_) {
        // Local sign-out must succeed even if the server call fails.
      }
    }
    _token = null;
    user.value = null;
    _signedIn.value = false;
    _epoch.value++;
    await _storage.clear();
  }

  /// Called by the API client when an authenticated request returns 401.
  void handleUnauthorized() {
    if (_token == null) return;
    signOut(remote: false);
  }
}
