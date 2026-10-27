import 'package:elora/app/core/utils/formatters.dart';
import 'package:elora/app/core/utils/validators.dart';
import 'package:elora/app/routes/app_routes.dart';
import 'package:elora/app/routes/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deep link allowlist', () {
    test('booking urls open appointment details', () {
      final d = DeepLinks.resolve('bookings/12')!;
      expect(d.route, Routes.appointment);
      expect(d.arguments, {'id': 12});
      expect(DeepLinks.resolve('/bookings/12/review')!.arguments, {
        'id': 12,
        'review': true,
      });
    });

    test('waitlist offers open the waitlist flow', () {
      expect(DeepLinks.resolve('waitlist/7')!.route, Routes.waitlistEntry);
      expect(DeepLinks.resolve('waitlist/7/claim')!.arguments, 7);
    });

    test('queue and absolute urls resolve by path only', () {
      expect(DeepLinks.resolve('queue/my-ticket')!.route, Routes.queueTicket);
      expect(
        DeepLinks.resolve(
          'https://dori.toldpath.com/places/elora/queue',
        )!.route,
        Routes.queue,
      );
    });

    test('anything else is rejected', () {
      for (final bad in [
        null,
        '',
        'admin/users',
        'bookings/abc',
        'javascript:alert(1)',
        '../../etc',
        'login',
      ]) {
        expect(DeepLinks.resolve(bad), isNull, reason: '$bad');
      }
    });
  });

  group('validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('layan@email'), isNotNull);
      expect(Validators.email(' layan@example.com '), isNull);
    });

    test('phone', () {
      expect(Validators.phone('05912'), isNotNull);
      expect(Validators.phone('0591234567'), isNull);
      expect(Validators.phone('+970 59 123 4567'), isNull);
    });

    test('password rules are left to the server', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('a'), isNull);
      expect(Validators.confirm('a', 'b'), isNotNull);
      expect(Validators.confirm('a', 'a'), isNull);
    });
  });

  group('formatters', () {
    test('12h salon time', () {
      expect(Fmt.time12('09:00'), '9:00 ص');
      expect(Fmt.time12('16:30'), '4:30 م');
      expect(Fmt.time12('00:15'), '12:15 ص');
      expect(Fmt.time12('12:00'), '12:00 م');
    });

    test('price and countdown', () {
      expect(Fmt.price(150), '150 ₪');
      expect(Fmt.price(12.5), '12.50 ₪');
      expect(Fmt.countdown(582), '09:42');
      expect(Fmt.countdown(-3), '00:00');
      expect('٠١٢٣'.latinDigits, '0123');
    });
  });
}
