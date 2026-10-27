import 'catalog.dart';
import 'json.dart';

/// Live shape (verified 2026-10-19): `{score, level, label, completed,
/// no_shows, late_cancellations, total}`.
class Reliability {
  const Reliability({
    this.score,
    this.label,
    this.level,
    this.description,
    this.completed,
    this.noShows,
    this.lateCancellations,
    this.total,
  });

  factory Reliability.fromJson(dynamic v) {
    if (v is num) return Reliability(score: v.toInt());
    final j = asMap(v);
    return Reliability(
      score: asInt(j['score']) ?? asInt(j['value']),
      label: asString(j['label']) ?? asString(j['level']),
      level: asString(j['level']),
      description: asString(j['description']) ?? asString(j['hint']),
      completed: asInt(j['completed']),
      noShows: asInt(j['no_shows']),
      lateCancellations: asInt(j['late_cancellations']),
      total: asInt(j['total']),
    );
  }

  final int? score;
  final String? label;
  final String? level;
  final String? description;
  final int? completed;
  final int? noShows;
  final int? lateCancellations;
  final int? total;

  bool get hasStats =>
      completed != null || noShows != null || lateCancellations != null;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.reliability = const Reliability(),
  });

  factory AppUser.fromJson(Json j) {
    final source = j['user'] is Map<String, dynamic> ? asMap(j['user']) : j;
    return AppUser(
      id: asInt(source['id']) ?? 0,
      name: asString(source['name']) ?? '',
      email: asString(source['email']),
      phone: asString(source['phone']),
      avatar: asString(source['avatar']) ?? asString(source['avatar_url']),
      reliability: Reliability.fromJson(
        j['reliability'] ?? source['reliability'],
      ),
    );
  }

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final Reliability reliability;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initial =>
      name.trim().isEmpty ? 'É' : String.fromCharCode(name.trim().runes.first);
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class WaitlistOffer {
  const WaitlistOffer({
    this.time,
    this.startsAt,
    this.secondsLeft,
    this.expiresAt,
    this.staffName,
  });

  factory WaitlistOffer.fromJson(Json j) => WaitlistOffer(
    time: asString(j['time']),
    startsAt: asString(j['starts_at']),
    secondsLeft: asInt(j['seconds_left']),
    expiresAt: asDate(j['expires_at']),
    staffName: asString(asMap(j['staff'])['name']) ?? asString(j['staff_name']),
  );

  final String? time;
  final String? startsAt;
  final int? secondsLeft;
  final DateTime? expiresAt;
  final String? staffName;
}

class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.status,
    this.statusLabel,
    this.number,
    this.serviceId,
    this.serviceName,
    this.staff,
    this.date,
    this.fromTime,
    this.toTime,
    this.notes,
    this.offer,
    this.bookingId,
    this.canClaim,
  });

  factory WaitlistEntry.fromJson(Json j) {
    final service = asMap(j['service']);
    final staff = asMapOrNull(j['staff']);
    final offer = asMapOrNull(j['offer']);
    final status = j['status'];
    return WaitlistEntry(
      id: asInt(j['id']) ?? 0,
      status: status is Map
          ? (asString(status['key']) ?? '')
          : (asString(status) ?? ''),
      statusLabel: status is Map
          ? asString(status['label'])
          : asString(j['status_label']),
      number: asString(j['number']),
      serviceId: asInt(service['id']) ?? asInt(j['service_id']),
      serviceName: asString(service['name']),
      staff: staff == null ? null : StaffRef.fromJson(staff),
      date: asString(j['date']),
      fromTime: asString(j['from_time']),
      toTime: asString(j['to_time']),
      notes: asString(j['notes']),
      offer: offer == null ? null : WaitlistOffer.fromJson(offer),
      bookingId: asInt(j['booking_id']) ?? asInt(asMap(j['booking'])['id']),
      canClaim: j.containsKey('can_claim') ? asBool(j['can_claim']) : null,
    );
  }

  final int id;

  /// `waiting` | `offered` | `booked` | `expired` | `cancelled`.
  final String status;
  final String? statusLabel;
  final String? number;
  final int? serviceId;
  final String? serviceName;
  final StaffRef? staff;
  final String? date;
  final String? fromTime;
  final String? toTime;
  final String? notes;
  final WaitlistOffer? offer;
  final int? bookingId;

  /// Server decision (verified live). Null only if a response omits it.
  final bool? canClaim;

  bool get isOffered => status == 'offered';

  /// Offer that can be claimed now: the server's `can_claim` wins; without
  /// it, fall back to the status.
  bool get claimable => canClaim ?? isOffered;
  bool get isWaiting => status == 'waiting';
  bool get isActive => isWaiting || isOffered;
  String get displayNumber => number ?? 'W-$id';
}

class QueueTicket {
  const QueueTicket({
    required this.id,
    required this.label,
    this.status,
    this.ahead,
    this.estimatedWaitMinutes,
    this.canCancel = true,
  });

  factory QueueTicket.fromJson(Json j) => QueueTicket(
    id: asInt(j['id']) ?? 0,
    label: asString(j['label']) ?? asString(j['number']) ?? '',
    status: asString(j['status']),
    ahead: asInt(j['ahead']),
    estimatedWaitMinutes: asInt(j['estimated_wait_minutes']),
    canCancel: asBool(j['can_cancel'], true),
  );

  final int id;
  final String label;
  final String? status;
  final int? ahead;
  final int? estimatedWaitMinutes;
  final bool canCancel;

  bool get isCalled => status == 'called' || status == 'serving';
}

class QueueBoard {
  const QueueBoard({
    this.enabled = false,
    this.open = false,
    this.accepting = false,
    this.nowServing = const [],
    this.waitingCount = 0,
    this.next = const [],
    this.servedToday = 0,
    this.estimatedWaitMinutes,
    this.updatedAt,
  });

  factory QueueBoard.fromJson(Json j) {
    List<String> labels(dynamic v) => v is List
        ? v
              .map(
                (e) => e is Map
                    ? asString(e['label']) ?? asString(e['number'])
                    : asString(e),
              )
              .whereType<String>()
              .toList()
        : const [];
    return QueueBoard(
      enabled: asBool(j['enabled']),
      open: asBool(j['open']),
      accepting: asBool(j['accepting']),
      nowServing: labels(j['now_serving']),
      waitingCount: asInt(j['waiting_count']) ?? 0,
      next: labels(j['next']),
      servedToday: asInt(j['served_today']) ?? 0,
      estimatedWaitMinutes: asInt(j['estimated_wait_minutes']),
      updatedAt: asDate(j['updated_at']),
    );
  }

  final bool enabled;
  final bool open;
  final bool accepting;
  final List<String> nowServing;
  final int waitingCount;
  final List<String> next;
  final int servedToday;
  final int? estimatedWaitMinutes;
  final DateTime? updatedAt;

  bool get isClosed => !enabled || !open;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.url,
    this.type,
    this.read = false,
    this.createdAt,
    this.createdLabel,
  });

  /// The live shape is unverified (no example in the collection), so common
  /// variants are accepted: flat fields or a nested `data` payload (Laravel
  /// database notifications), and several read-state conventions.
  factory AppNotification.fromJson(Json j) {
    final data = asMap(j['data']);
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = asString(j[k]) ?? asString(data[k]);
        if (v != null) return v;
      }
      return null;
    }

    return AppNotification(
      id: asString(j['id']) ?? '',
      title: pick(['title', 'subject', 'heading']) ?? '',
      body: pick(['body', 'message', 'text', 'description']),
      url: pick(['url', 'link', 'action_url', 'route']),
      type: pick(['type', 'kind', 'event']),
      read: _readState(j),
      createdAt: asDate(j['created_at']),
      createdLabel:
          asString(j['created_human']) ??
          asString(j['time_ago']) ??
          asString(j['created_at_human']),
    );
  }

  static bool _readState(Json j) {
    for (final k in ['read_at', 'seen_at']) {
      if (j.containsKey(k)) return j[k] != null;
    }
    for (final k in ['is_read', 'read', 'seen', 'is_seen']) {
      if (j.containsKey(k)) return asBool(j[k]);
    }
    if (j.containsKey('unread')) return !asBool(j['unread']);
    return false;
  }

  final String id;
  final String title;
  final String? body;
  final String? url;
  final String? type;
  final bool read;
  final DateTime? createdAt;
  final String? createdLabel;
}
