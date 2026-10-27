import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking.dart';

class BookingRepository {
  BookingRepository(this._api);

  final ApiClient _api;

  Future<List<AvailabilityDay>> days({
    required int serviceId,
    int? staffId,
    int days = 14,
  }) async => (await _api.get(
    _api.place('availability/days'),
    query: {'service_id': serviceId, 'staff_id': staffId, 'days': days},
  )).dataList.map(AvailabilityDay.fromJson).toList();

  Future<SlotsResult> slots({
    required int serviceId,
    required String date,
    int? staffId,
  }) async {
    final res = await _api.get(
      _api.place('availability/slots'),
      query: {'service_id': serviceId, 'date': date, 'staff_id': staffId},
    );
    return SlotsResult(
      slots: res.dataList.map(Slot.fromJson).toList(),
      canJoinWaitlist: res.meta['can_join_waitlist'] == true,
    );
  }

  Future<CouponResult> checkCoupon({
    required String code,
    required int serviceId,
  }) async {
    final res = await _api.post(
      _api.place('coupons/check'),
      auth: true,
      body: {'code': code, 'service_id': serviceId},
    );
    return CouponResult.fromJson(res.dataMap, message: res.message);
  }

  Future<Booking> create({
    required int serviceId,
    required String startsAt,
    int? staffId,
    String? notes,
    Map<String, dynamic> answers = const {},
    String? couponCode,
    String paymentMethod = 'cash',
  }) async {
    final res = await _api.post(
      _api.place('bookings'),
      auth: true,
      body: {
        'service_id': serviceId,
        'staff_id': staffId,
        'starts_at': startsAt,
        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        'answers': answers,
        'coupon_code': couponCode,
        'payment_method': paymentMethod,
      },
    );
    return Booking.fromJson(res.dataMap);
  }

  Future<Paged<Booking>> list({required bool upcoming, int page = 1}) async {
    final res = await _api.get(
      _api.place('bookings'),
      auth: true,
      query: {'scope': upcoming ? 'upcoming' : 'past', 'page': page},
    );
    return Paged(
      res.dataList.map(Booking.fromJson).toList(),
      PageMeta.fromJson(res.meta),
    );
  }

  Future<Booking> detail(int id) async => Booking.fromJson(
    (await _api.get(_api.place('bookings/$id'), auth: true)).dataMap,
  );

  Future<Booking> reschedule(
    int id, {
    required String startsAt,
    int? staffId,
  }) async => Booking.fromJson(
    (await _api.post(
      _api.place('bookings/$id/reschedule'),
      auth: true,
      body: {'starts_at': startsAt, 'staff_id': staffId},
    )).dataMap,
  );

  Future<String?> cancel(int id, {String? reason}) async => (await _api.post(
    _api.place('bookings/$id/cancel'),
    auth: true,
    body: {'reason': reason},
  )).message;

  Future<String?> review(
    int id, {
    required int rating,
    String? comment,
  }) async => (await _api.post(
    _api.place('bookings/$id/review'),
    auth: true,
    body: {'rating': rating, 'comment': comment},
  )).message;
}
