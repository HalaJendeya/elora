import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/account.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  static const deviceName = 'ELORA Flutter';

  AuthResult _auth(ApiResponse res) {
    final data = res.dataMap;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(
        kind: ApiErrorKind.parsing,
        message: ApiException.fallbackMessage(ApiErrorKind.parsing),
      );
    }
    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data['customer'] is Map<String, dynamic>
        ? data['customer'] as Map<String, dynamic>
        : data;
    return AuthResult(token: token, user: AppUser.fromJson(userJson));
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async => _auth(
    await _api.post(
      _api.place('auth/login'),
      body: {
        'email': email.trim(),
        'password': password,
        'device_name': deviceName,
      },
    ),
  );

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async => _auth(
    await _api.post(
      _api.place('auth/register'),
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'password_confirmation': password,
        'device_name': deviceName,
      },
    ),
  );

  Future<AppUser> me() async => AppUser.fromJson(
    (await _api.get(_api.place('auth/me'), auth: true)).dataMap,
  );

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async => AppUser.fromJson(
    (await _api.put(
      _api.place('auth/profile'),
      auth: true,
      body: {'name': name.trim(), 'phone': phone.trim()},
    )).dataMap,
  );

  Future<AppUser> uploadAvatar(
    String path, {
    required String name,
    required String phone,
  }) async => AppUser.fromJson(
    (await _api.multipart(
      _api.place('auth/profile'),
      fields: {'name': name.trim(), 'phone': phone.trim()},
      files: [UploadFile(field: 'avatar', path: path)],
    )).dataMap,
  );

  Future<void> logout() => _api.post(_api.place('auth/logout'), auth: true);
}

class WaitlistRepository {
  WaitlistRepository(this._api);

  final ApiClient _api;

  Future<WaitlistEntry> join({
    required int serviceId,
    int? staffId,
    required String date,
    String? fromTime,
    String? toTime,
    String? notes,
  }) async => WaitlistEntry.fromJson(
    (await _api.post(
      _api.place('waitlist'),
      auth: true,
      body: {
        'service_id': serviceId,
        'staff_id': staffId,
        'date': date,
        'from_time': fromTime,
        'to_time': toTime,
        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      },
    )).dataMap,
  );

  Future<List<WaitlistEntry>> list({required bool active}) async =>
      (await _api.get(
        _api.place('waitlist'),
        auth: true,
        query: {'active': active ? 1 : 0},
      )).dataList.map(WaitlistEntry.fromJson).toList();

  Future<WaitlistEntry> detail(int id) async => WaitlistEntry.fromJson(
    (await _api.get(_api.place('waitlist/$id'), auth: true)).dataMap,
  );

  /// Returns the created booking id when present.
  Future<int?> claim(int id) async {
    final data = (await _api.post(
      _api.place('waitlist/$id/claim'),
      auth: true,
    )).dataMap;
    final booking = data['booking'];
    if (booking is Map) return int.tryParse('${booking['id']}');
    return int.tryParse('${data['booking_id'] ?? data['id'] ?? ''}');
  }

  Future<void> leave(int id) =>
      _api.delete(_api.place('waitlist/$id'), auth: true);
}

class QueueRepository {
  QueueRepository(this._api);

  final ApiClient _api;

  Future<QueueBoard> board() async =>
      QueueBoard.fromJson((await _api.get(_api.place('queue'))).dataMap);

  Future<QueueTicket> take({int? serviceId}) async => QueueTicket.fromJson(
    (await _api.post(
      _api.place('queue/tickets'),
      auth: true,
      body: {'service_id': serviceId},
    )).dataMap,
  );

  Future<QueueTicket?> myTicket() async {
    final data = (await _api.get(
      _api.place('queue/my-ticket'),
      auth: true,
    )).data;
    return data is Map<String, dynamic> ? QueueTicket.fromJson(data) : null;
  }

  Future<void> cancel(int id) =>
      _api.post(_api.place('queue/tickets/$id/cancel'), auth: true);
}

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  /// Returns the page, the unread total and whether more pages exist.
  /// Accepts `data` as a list or wrapped (`{items|notifications|data: [...]}`)
  /// and the unread total from `meta` or the wrapper; otherwise counts the
  /// unread items received (a lower bound when more pages exist).
  Future<(List<AppNotification>, int)> list({int page = 1}) async {
    final (items, unread, _) = await listPage(page: page);
    return (items, unread);
  }

  Future<(List<AppNotification>, int, bool)> listPage({int page = 1}) async {
    final res = await _api.get(
      _api.place('notifications'),
      auth: true,
      query: page > 1 ? {'page': page} : null,
    );
    final wrapper = res.dataMap;
    List<Map<String, dynamic>> raw = res.dataList;
    if (raw.isEmpty) {
      for (final k in ['items', 'notifications', 'data']) {
        final v = wrapper[k];
        if (v is List) {
          raw = v.whereType<Map<String, dynamic>>().toList();
          break;
        }
      }
    }
    final items = raw.map(AppNotification.fromJson).toList();
    int? fromKeys(Map<String, dynamic> m) {
      for (final k in ['unread', 'unread_count', 'unread_total']) {
        final v = int.tryParse('${m[k] ?? ''}');
        if (v != null) return v;
      }
      return null;
    }

    final unread =
        fromKeys(res.meta) ??
        fromKeys(wrapper) ??
        items.where((n) => !n.read).length;
    final meta = PageMeta.fromJson(res.meta);
    return (items, unread, meta.hasMore);
  }

  /// Returns the unread count after the update (live: `data: {unread: 0}`).
  Future<int> readAll() async {
    final res = await _api.post(
      _api.place('notifications/read-all'),
      auth: true,
    );
    return int.tryParse('${res.dataMap['unread'] ?? ''}') ?? 0;
  }
}
