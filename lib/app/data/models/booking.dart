import 'catalog.dart';
import 'json.dart';

class AvailabilityDay {
  const AvailabilityDay({
    required this.date,
    required this.label,
    this.open = false,
    this.slotsCount = 0,
    this.firstTime,
  });

  factory AvailabilityDay.fromJson(Json j) => AvailabilityDay(
    date: asString(j['date']) ?? '',
    label: asString(j['label']) ?? '',
    open: asBool(j['open']),
    slotsCount: asInt(j['slots_count']) ?? 0,
    firstTime: asString(j['first_time']),
  );

  /// `YYYY-MM-DD` as sent by the server; also the request value.
  final String date;
  final String label;
  final bool open;
  final int slotsCount;
  final String? firstTime;

  bool get available => open && slotsCount > 0;
  DateTime? get dateValue => DateTime.tryParse(date);
}

class Slot {
  const Slot({
    required this.time,
    required this.startsAt,
    this.endsAt,
    this.staff = const [],
    this.seatsLeft,
  });

  factory Slot.fromJson(Json j) => Slot(
    time: asString(j['time']) ?? '',
    startsAt: asString(j['starts_at']) ?? '',
    endsAt: asString(j['ends_at']),
    staff: asList(j['staff'], StaffRef.fromJson),
    seatsLeft: asInt(j['seats_left']),
  );

  final String time;

  /// Opaque server value; send back unchanged when booking.
  final String startsAt;
  final String? endsAt;
  final List<StaffRef> staff;
  final int? seatsLeft;

  /// Hour in the salon's local time, read from the ISO string itself so the
  /// device timezone never shifts the grouping.
  int get hour => int.tryParse(time.split(':').first) ?? 0;
}

class SlotsResult {
  const SlotsResult({required this.slots, this.canJoinWaitlist = false});

  final List<Slot> slots;
  final bool canJoinWaitlist;
}

class CouponResult {
  const CouponResult({
    required this.valid,
    this.code,
    this.message,
    this.originalPrice,
    this.finalPrice,
    this.discount,
  });

  factory CouponResult.fromJson(Json j, {String? message}) => CouponResult(
    valid: asBool(j['valid'], true),
    code: asString(j['code']),
    message: asString(j['message']) ?? message,
    originalPrice: asDouble(j['original_price']) ?? asDouble(j['price']),
    finalPrice: asDouble(j['final_price']) ?? asDouble(j['price_after']),
    discount: asDouble(j['discount']) ?? asDouble(j['discount_amount']),
  );

  final bool valid;
  final String? code;
  final String? message;
  final double? originalPrice;
  final double? finalPrice;
  final double? discount;
}

/// Live shape (verified 2026-10-19): `{status, label, done, at (ISO|null), note}`.
/// The server sends no "current" flag; see [Booking.currentStep].
class TimelineStep {
  const TimelineStep({
    required this.label,
    this.status,
    this.at,
    this.atLabel,
    this.note,
    this.done = false,
  });

  factory TimelineStep.fromJson(Json j) => TimelineStep(
    label:
        asString(j['label']) ??
        asString(j['title']) ??
        asString(j['status']) ??
        '',
    status: asString(j['status']),
    at: asWallClock(j['at']),
    atLabel: asString(j['at_human']),
    note: asString(j['note']),
    done: asBool(j['done'] ?? j['completed']),
  );

  final String label;
  final String? status;
  final DateTime? at;
  final String? atLabel;
  final String? note;
  final bool done;
}

class AnswerDisplay {
  const AnswerDisplay({required this.label, required this.value});

  factory AnswerDisplay.fromJson(Json j) => AnswerDisplay(
    label: asString(j['label']) ?? asString(j['key']) ?? '',
    value: asString(j['display']) ?? asString(j['value']) ?? '',
  );

  final String label;
  final String value;
}

class Booking {
  const Booking({
    required this.id,
    this.number,
    this.code,
    this.qr,
    this.status = '',
    this.statusLabel,
    this.serviceId,
    this.serviceName,
    this.serviceImage,
    this.staff,
    this.startsAt,
    this.endsAt,
    this.startsAtRaw,
    this.durationMinutes,
    this.price,
    this.finalPrice,
    this.discount,
    this.couponCode,
    this.paymentMethod,
    this.notes,
    this.canCancel = false,
    this.canReschedule = false,
    this.canReview = false,
    this.cancelIsLate = false,
    this.timeline = const [],
    this.hasReview = false,
    this.answers = const [],
    this.cancelReason,
    this.cancelledLate = false,
    this.dayLabel,
  });

  factory Booking.fromJson(Json j) {
    final service = asMap(j['service']);
    final staffJson = asMapOrNull(j['staff']);
    final status = j['status'];
    return Booking(
      id: asInt(j['id']) ?? 0,
      number: asString(j['number']),
      code: asString(j['code']),
      qr: asString(j['qr']),
      status: status is Map
          ? (asString(status['key']) ?? '')
          : (asString(status) ?? ''),
      statusLabel: status is Map
          ? asString(status['label'])
          : asString(j['status_label']),
      serviceId: asInt(service['id']) ?? asInt(j['service_id']),
      serviceName: asString(service['name']) ?? asString(j['service_name']),
      serviceImage: asString(service['thumb']) ?? asString(service['image']),
      staff: staffJson == null ? null : StaffRef.fromJson(staffJson),
      startsAt: asWallClock(j['starts_at']),
      endsAt: asWallClock(j['ends_at']),
      startsAtRaw: asString(j['starts_at']),
      durationMinutes:
          asInt(j['duration_minutes']) ?? asInt(service['duration_minutes']),
      price: asDouble(j['price']),
      finalPrice:
          asDouble(j['final_price']) ??
          asDouble(j['total']) ??
          asDouble(j['price']),
      discount: asDouble(j['discount']),
      couponCode: asString(j['coupon_code']),
      paymentMethod: asString(j['payment_method']),
      notes: asString(j['notes']),
      canCancel: asBool(j['can_cancel']),
      canReschedule: asBool(j['can_reschedule']),
      canReview: asBool(j['can_review']),
      cancelIsLate: asBool(j['cancel_is_late']),
      timeline: asList(j['timeline'], TimelineStep.fromJson),
      hasReview: j['review'] != null,
      answers: asList(
        j['answers_display'],
        AnswerDisplay.fromJson,
      ).where((a) => a.value.isNotEmpty).toList(),
      cancelReason: asString(j['cancel_reason']),
      cancelledLate: asBool(j['cancelled_late']),
      dayLabel: asString(j['day_label']),
    );
  }

  final int id;
  final String? number;
  final String? code;
  final String? qr;
  final String status;
  final String? statusLabel;
  final int? serviceId;
  final String? serviceName;
  final String? serviceImage;
  final StaffRef? staff;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? startsAtRaw;
  final int? durationMinutes;
  final double? price;
  final double? finalPrice;
  final double? discount;
  final String? couponCode;
  final String? paymentMethod;
  final String? notes;
  final bool canCancel;
  final bool canReschedule;
  final bool canReview;
  final bool cancelIsLate;
  final List<TimelineStep> timeline;
  final bool hasReview;
  final List<AnswerDisplay> answers;
  final String? cancelReason;
  final bool cancelledLate;

  /// Server weekday name for the appointment date.
  final String? dayLabel;

  /// Index of the step the visit is at: the first not-done step after the
  /// done ones, or -1 when everything is done.
  int get currentStep {
    final i = timeline.indexWhere((s) => !s.done);
    return i;
  }

  String get displayNumber => number ?? '#$id';

  /// Value encoded in the check-in QR: the server `qr` payload, else the code.
  String? get qrPayload => qr ?? code ?? number;
}
