import 'dart:convert';
import 'dart:io';

import 'package:elora/app/core/network/api_response.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/data/models/booking.dart';
import 'package:elora/app/data/models/catalog.dart';
import 'package:elora/app/data/models/json.dart';
import 'package:elora/app/data/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures are real public responses captured from the live API on
/// 2026-10-18 (see docs/API_INVENTORY.md).
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('place: hours, booking rules, intake fields, labels', () {
    final p = Place.fromJson(fixture('place')['data']);
    expect(p.name, 'ÉLORA');
    expect(p.openingHours, hasLength(7));
    expect(p.openingHours.firstWhere((d) => d.day == 'mon').open, isFalse);
    expect(p.booking.cancelBeforeHours, 2);
    expect(p.booking.intakeFields.map((f) => f.key), [
      'hair_length',
      'occasion',
      'allergies',
    ]);
    expect(p.booking.intakeFields.first.isSelect, isTrue);
    expect(p.booking.intakeFields.first.label, 'طول شعرك');
    expect(p.labels.staff, 'خبيرة');
    expect(p.currencySymbol, '₪');
    expect(p.queueEnabled, isFalse);
  });

  test('home: sections parse; missing queue key is null', () {
    final h = HomeData.fromJson(fixture('home')['data']);
    expect(h.categories, isNotEmpty);
    expect(h.categories.first.shortName, 'العناية بالشعر وتصفيفه');
    expect(h.popular.first.staff.first.initials, 'ص');
    expect(h.featured, isEmpty);
    expect(h.queue, isNull);
  });

  test('service details: price, staff, related, rating', () {
    final s = Service.fromJson(fixture('service')['data']);
    expect(s.id, 38);
    expect(s.finalPrice, 150);
    expect(s.hasDiscount, isFalse);
    expect(s.images, hasLength(2));
    expect(s.related, isEmpty);
    expect(s.rating.count, 0);
  });

  test('availability: days + slots keep server starts_at verbatim', () {
    final days = (fixture('days')['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(AvailabilityDay.fromJson);
    expect(days.where((d) => d.available), isNotEmpty);
    final res = fixture('slots');
    final slots = (res['data'] as List)
        .cast<Map<String, dynamic>>()
        .map(Slot.fromJson)
        .toList();
    expect(slots.first.startsAt, '2026-10-20T09:00:00+03:00');
    expect(slots.first.hour, 9);
    expect(slots.first.staff.map((s) => s.name), contains('صوفيا'));
    expect(res['meta']['can_join_waitlist'], isFalse);
  });

  test('busy hours: closed days have null levels', () {
    final b = BusyHours.fromJson(fixture('busy_hours')['data']);
    expect(b.grid.firstWhere((d) => d.day == 'mon').closed, isTrue);
    expect(b.bestTimes, isNotEmpty);
    expect(b.nowLabel, isNotNull);
  });

  test('reviews meta: average and distribution', () {
    final meta = fixture('reviews')['meta'] as Map<String, dynamic>;
    final s = ReviewSummary.fromMeta(meta);
    expect(s.distribution.keys, containsAll([1, 2, 3, 4, 5]));
    expect(PageMeta.fromJson(meta).hasMore, isFalse);
  });

  test('booking: tolerant to object status and unknown fields', () {
    final b = Booking.fromJson({
      'id': 12,
      'number': 'EL-240418-07',
      'code': 'X7K2',
      'status': {'key': 'confirmed', 'label': 'مؤكد'},
      'service': {'id': 38, 'name': 'علاج'},
      'staff': {'id': 22, 'name': 'صوفيا'},
      'starts_at': '2026-10-20T16:30:00+03:00',
      'can_cancel': true,
      'cancel_is_late': 1,
      'timeline': [
        {'label': 'تم تأكيد الموعد', 'done': true},
      ],
      'something_new': {'a': 1},
    });
    expect(b.status, 'confirmed');
    expect(b.statusLabel, 'مؤكد');
    expect(b.canCancel, isTrue);
    expect(b.canReview, isFalse);
    expect(b.cancelIsLate, isTrue);
    // Wall clock: 16:30 salon time regardless of device timezone.
    expect(b.startsAt!.hour, 16);
    expect(b.qrPayload, 'X7K2');
  });

  test('wall clock parsing strips offsets', () {
    expect(asWallClock('2026-10-20T09:15:00+03:00')!.hour, 9);
    expect(asWallClock('2026-10-20T09:15:00Z')!.minute, 15);
    expect(asWallClock(null), isNull);
  });

  test('waitlist entry with offer', () {
    final e = WaitlistEntry.fromJson({
      'id': 5,
      'status': 'offered',
      'service': {'id': 38, 'name': 'علاج'},
      'date': '2026-10-21',
      'from_time': '16:00',
      'to_time': '20:00',
      'offer': {'time': '16:30', 'seconds_left': 582},
    });
    expect(e.isOffered, isTrue);
    expect(e.isActive, isTrue);
    expect(e.offer!.secondsLeft, 582);
  });

  test('my-ticket null and queue board labels', () {
    final board = QueueBoard.fromJson({
      'enabled': true,
      'open': true,
      'accepting': true,
      'now_serving': [
        {'label': 'A-004'},
      ],
      'waiting_count': 6,
    });
    expect(board.isClosed, isFalse);
    expect(board.nowServing, ['A-004']);
    expect(QueueBoard.fromJson({'enabled': false}).isClosed, isTrue);
  });

  test('notification read state from read_at', () {
    expect(
      AppNotification.fromJson({'id': 'a', 'title': 't', 'read_at': null}).read,
      isFalse,
    );
    expect(
      AppNotification.fromJson({
        'id': 'a',
        'title': 't',
        'read_at': '2026-01-01',
      }).read,
      isTrue,
    );
  });

  test('user with nested reliability', () {
    final u = AppUser.fromJson({
      'user': {'id': 1, 'name': 'ليان منصور', 'email': 'l@example.com'},
      'reliability': {'score': 92, 'label': 'موثوقية ممتازة'},
    });
    expect(u.firstName, 'ليان');
    expect(u.reliability.score, 92);
    expect(
      AppUser.fromJson({
        'id': 1,
        'name': 'x',
        'reliability': 80,
      }).reliability.score,
      80,
    );
  });
}
