import '../../data/models/booking.dart';
import '../../data/models/catalog.dart';
import '../../data/models/place.dart';

/// Everything selected across the four booking steps. Immutable; the flow
/// controller replaces it on every change so steps can never drift apart.
class BookingDraft {
  const BookingDraft({
    this.service,
    this.staff,
    this.staffChosen = false,
    this.day,
    this.slot,
    this.notes = '',
    this.answers = const {},
    this.coupon,
    this.paymentMethod = 'cash',
    this.policyAccepted = false,
  });

  final Service? service;

  /// Null with [staffChosen] = "any available specialist".
  final StaffRef? staff;
  final bool staffChosen;
  final AvailabilityDay? day;
  final Slot? slot;
  final String notes;
  final Map<String, dynamic> answers;

  /// Server-validated coupon; only a valid result is ever stored.
  final CouponResult? coupon;
  final String paymentMethod;
  final bool policyAccepted;

  bool get anyStaff => staffChosen && staff == null;

  BookingDraft copyWith({
    Service? service,
    StaffRef? Function()? staff,
    bool? staffChosen,
    AvailabilityDay? Function()? day,
    Slot? Function()? slot,
    String? notes,
    Map<String, dynamic>? answers,
    CouponResult? Function()? coupon,
    String? paymentMethod,
    bool? policyAccepted,
  }) => BookingDraft(
    service: service ?? this.service,
    staff: staff != null ? staff() : this.staff,
    staffChosen: staffChosen ?? this.staffChosen,
    day: day != null ? day() : this.day,
    slot: slot != null ? slot() : this.slot,
    notes: notes ?? this.notes,
    answers: answers ?? this.answers,
    coupon: coupon != null ? coupon() : this.coupon,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    policyAccepted: policyAccepted ?? this.policyAccepted,
  );

  /// Changing the specialist invalidates the chosen day and time.
  BookingDraft withStaff(StaffRef? value) => copyWith(
    staff: () => value,
    staffChosen: true,
    day: () => null,
    slot: () => null,
  );

  /// Changing the day invalidates the chosen time.
  BookingDraft withDay(AvailabilityDay value) =>
      copyWith(day: () => value, slot: () => null);

  BookingDraft withAnswer(String key, dynamic value) {
    final next = Map<String, dynamic>.from(answers);
    if (value == null || (value is String && value.trim().isEmpty)) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(answers: next);
  }

  /// Price before discount, as returned by the server.
  double get basePrice => service?.finalPrice ?? 0;

  /// Price after a server-validated coupon, otherwise the base price.
  double get total => coupon?.finalPrice ?? basePrice;

  /// The specialist that will actually serve: the chosen one, or the first
  /// one the server listed for the chosen slot.
  String? get staffLabel =>
      staff?.name ?? (anyStaff ? 'أي أخصائية متاحة' : null);

  List<IntakeField> missingRequired(List<IntakeField> fields) =>
      fields.where((f) => f.required && !answers.containsKey(f.key)).toList();

  bool stepComplete(int step, {List<IntakeField> fields = const []}) {
    switch (step) {
      case 0:
        return service != null && staffChosen;
      case 1:
        return day != null && slot != null;
      case 2:
        return missingRequired(fields).isEmpty && policyAccepted;
      default:
        return stepComplete(0) &&
            stepComplete(1) &&
            stepComplete(2, fields: fields);
    }
  }

  /// Body for `POST /bookings`. `starts_at` is sent back exactly as received.
  Map<String, dynamic> toRequest() => {
    'service_id': service?.id,
    'staff_id': staff?.id,
    'starts_at': slot?.startsAt,
    'notes': notes.trim().isEmpty ? null : notes.trim(),
    'answers': answers,
    'coupon_code': coupon?.code,
    'payment_method': paymentMethod,
  };
}
