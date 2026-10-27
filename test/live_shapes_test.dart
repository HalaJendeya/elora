import 'dart:convert';
import 'dart:io';

import 'package:elora/app/core/utils/formatters.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/data/models/booking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Shapes captured from the live protected endpoints on 2026-10-19 with the
/// test account; every personal value is replaced by a fake one.
final _fx =
    jsonDecode(File('test/fixtures/private_sanitized.json').readAsStringSync())
        as Map<String, dynamic>;

List<Booking> _list(String key) => (_fx[key]['data'] as List)
    .cast<Map<String, dynamic>>()
    .map(Booking.fromJson)
    .toList();

void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  writeShapes();

  test('auth/me: user and reliability stats', () {
    final u = AppUser.fromJson(_fx['me']['data']);
    expect(u.name, 'عميلة تجريبية');
    expect(u.email, 'test@example.com');
    final r = u.reliability;
    expect(r.score, isNotNull);
    expect(r.label, isNotNull);
    expect(r.level, isNotNull);
    expect(r.hasStats, isTrue);
    expect(r.completed, isNotNull);
    expect(r.noShows, isNotNull);
    expect(r.lateCancellations, isNotNull);
  });

  test('upcoming booking: prices, flags, answers, encodable QR', () {
    final b = _list('upcoming').single;
    expect(b.status, 'confirmed');
    expect(b.statusLabel, isNotNull);
    expect(b.serviceName, isNotNull);
    expect(b.staff?.name, isNotNull);
    expect(b.finalPrice, isNotNull); // from `total`
    expect(b.canCancel, isTrue);
    expect(b.answers, hasLength(2));
    expect(b.answers.first.label, isNotEmpty);
    expect(b.qrPayload, 'TEST:CODE:000001');
    expect(b.startsAt, isNotNull);
  });

  test('timeline: ISO times become dates and the current step is derived', () {
    final b = _list('upcoming').single;
    expect(b.timeline, hasLength(4));
    expect(b.timeline.first.done, isTrue);
    expect(b.timeline.first.at, isNotNull);
    // Rendered as a readable date, never the raw ISO string.
    expect(Fmt.dateTime(b.timeline.first.at), isNot(contains('T')));
    expect(b.timeline[1].at, isNull);
    expect(b.currentStep, 1);
  });

  test('cancelled past bookings carry a reason and no actions', () {
    final cancelled = _list('past').where((b) => b.status == 'cancelled');
    expect(cancelled, isNotEmpty);
    for (final b in cancelled) {
      expect(b.cancelReason, 'سبب تجريبي');
      expect(b.canCancel || b.canReschedule || b.canReview, isFalse);
      expect(b.currentStep, -1);
    }
  });

  test('notifications meta exposes the unread total', () {
    final meta = _fx['notifications']['meta'] as Map<String, dynamic>;
    expect(meta.containsKey('unread'), isTrue);
  });
}

void writeShapes() {
  test('waitlist join / after-leave entries', () {
    final joined = WaitlistEntry.fromJson(_fx['waitlist_join']);
    expect(joined.status, 'waiting');
    expect(joined.isActive, isTrue);
    expect(joined.canClaim, isFalse);
    expect(joined.claimable, isFalse);
    expect(joined.fromTime, matches(RegExp(r'^\d\d:\d\d$')));
    final left = WaitlistEntry.fromJson(_fx['waitlist_after_leave']);
    expect(left.status, 'cancelled');
    expect(left.isActive, isFalse);
  });

  test('the server can_claim overrides the offered status', () {
    final base = Map<String, dynamic>.from(_fx['waitlist_join'])
      ..['status'] = 'offered';
    expect(
      WaitlistEntry.fromJson({...base, 'can_claim': false}).claimable,
      isFalse,
    );
    expect(
      WaitlistEntry.fromJson({...base, 'can_claim': true}).claimable,
      isTrue,
    );
    expect(WaitlistEntry.fromJson(base..remove('can_claim')).claimable, isTrue);
  });

  test('profile PUT response has no reliability block', () {
    final u = AppUser.fromJson(_fx['profile_put']['data']);
    expect(u.name, isNotEmpty);
    expect(u.reliability.score, isNull);
  });

  test('invalid coupon is a 422 with COUPON_INVALID and a message', () {
    final c = _fx['coupon_invalid'] as Map<String, dynamic>;
    expect(c['error']['code'], 'COUPON_INVALID');
    expect(c['message'], isNotEmpty);
  });

  test('read-all returns the remaining unread count', () {
    expect(_fx['read_all']['data']['unread'], 0);
  });
}
