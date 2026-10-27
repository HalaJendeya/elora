import 'package:elora/app/data/models/booking.dart';
import 'package:elora/app/data/models/catalog.dart';
import 'package:elora/app/data/models/place.dart';
import 'package:elora/app/features/booking/booking_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = Service(id: 38, name: 'علاج', price: 150, finalPrice: 150);
  const staff = StaffRef(id: 22, name: 'صوفيا');
  const day = AvailabilityDay(
    date: '2026-10-20',
    label: 'الثلاثاء',
    open: true,
    slotsCount: 3,
  );
  const slot = Slot(time: '09:00', startsAt: '2026-10-20T09:00:00+03:00');
  const required = IntakeField(
    key: 'hair',
    label: 'الشعر',
    type: 'select',
    required: true,
  );

  final base = const BookingDraft(service: service);

  test('step 1 needs an explicit choice; "any" is a valid choice', () {
    expect(base.stepComplete(0), isFalse);
    expect(base.withStaff(null).stepComplete(0), isTrue);
    expect(base.withStaff(null).anyStaff, isTrue);
    expect(base.withStaff(staff).anyStaff, isFalse);
  });

  test('changing specialist clears day and time; changing day clears time', () {
    final full = base.withStaff(staff).withDay(day).copyWith(slot: () => slot);
    expect(full.stepComplete(1), isTrue);
    final switched = full.withStaff(null);
    expect(switched.day, isNull);
    expect(switched.slot, isNull);
    final otherDay = full.withDay(
      const AvailabilityDay(date: '2026-10-21', label: '', open: true),
    );
    expect(otherDay.slot, isNull);
    expect(otherDay.staff, staff);
  });

  test(
    'details step requires policy acceptance and required intake answers',
    () {
      var d = base.withStaff(staff).withDay(day).copyWith(slot: () => slot);
      expect(d.stepComplete(2, fields: [required]), isFalse);
      d = d.copyWith(policyAccepted: true);
      expect(d.missingRequired([required]).single.key, 'hair');
      d = d.withAnswer('hair', 'طويل');
      expect(d.stepComplete(2, fields: [required]), isTrue);
      expect(d.stepComplete(3, fields: [required]), isTrue);
      expect(d.withAnswer('hair', '  ').answers.containsKey('hair'), isFalse);
    },
  );

  test('total uses server coupon price only', () {
    expect(base.total, 150);
    final withCoupon = base.copyWith(
      coupon: () =>
          const CouponResult(valid: true, code: 'WELCOME10', finalPrice: 135),
    );
    expect(withCoupon.total, 135);
    // A coupon that the server did not price leaves the base price.
    expect(
      base
          .copyWith(coupon: () => const CouponResult(valid: true, code: 'X'))
          .total,
      150,
    );
  });

  test('request body sends starts_at verbatim and null staff for "any"', () {
    final d = base
        .withStaff(null)
        .withDay(day)
        .copyWith(slot: () => slot, notes: '  أول زيارة ', policyAccepted: true)
        .withAnswer('occasion', 'عرس');
    final body = d.toRequest();
    expect(body['starts_at'], '2026-10-20T09:00:00+03:00');
    expect(body['staff_id'], isNull);
    expect(body['notes'], 'أول زيارة');
    expect(body['answers'], {'occasion': 'عرس'});
    expect(body['payment_method'], 'cash');
    expect(body['coupon_code'], isNull);
  });
}
