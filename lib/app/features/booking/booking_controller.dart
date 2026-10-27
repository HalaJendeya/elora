import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/place_service.dart';
import '../../data/models/booking.dart';
import '../../data/models/catalog.dart';
import '../../data/models/place.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/display.dart';
import 'booking_draft.dart';

enum CouponState { idle, checking, valid, invalid }

/// Single controller for the whole booking flow (steps 1–4). Lives exactly as
/// long as the booking route, so the draft survives moving between steps.
class BookingFlowController extends GetxController {
  BookingFlowController(
    this._catalog,
    this._bookings,
    this._place, {
    required this.serviceId,
    this.initialStaffId,
  });

  final CatalogRepository _catalog;
  final BookingRepository _bookings;
  final PlaceService _place;
  final int serviceId;
  final int? initialStaffId;

  static const steps = 4;

  final draft = const BookingDraft().obs;
  final step = 0.obs;

  // Setup
  final loading = true.obs;
  final error = RxnString();
  final staff = <Staff>[].obs;
  final place = Rxn<Place>();

  // Step 2
  final days = <AvailabilityDay>[].obs;
  final daysLoading = false.obs;
  final daysError = RxnString();
  final slots = <Slot>[].obs;
  final slotsLoading = false.obs;
  final slotsError = RxnString();
  final canJoinWaitlist = false.obs;
  int _slotsRequest = 0;
  int _daysRequest = 0;

  // Step 3
  final notes = TextEditingController();
  final couponInput = TextEditingController();
  final couponState = CouponState.idle.obs;
  final couponMessage = RxnString();
  final answerControllers = <String, TextEditingController>{};

  // Step 4
  final submitting = false.obs;
  final submitError = RxnString();
  final alternatives = <Slot>[].obs;

  List<IntakeField> get intakeFields =>
      place.value?.booking.intakeFields ?? const [];
  BookingRules get rules => place.value?.booking ?? const BookingRules();

  @override
  void onInit() {
    super.onInit();
    _setup();
  }

  Future<void> _setup() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _catalog.service(serviceId),
        _catalog.staff(serviceId: serviceId),
        _place.load(),
      ]);
      final service = results[0] as Service;
      staff.assignAll(results[1] as List<Staff>);
      place.value = results[2] as Place;
      for (final f in intakeFields.where((f) => !f.isSelect && !f.isBoolean)) {
        answerControllers[f.key] = TextEditingController();
      }
      var next = draft.value.copyWith(service: service);
      if (initialStaffId != null) {
        final match = staff.firstWhereOrNull((s) => s.id == initialStaffId);
        if (match != null) next = next.withStaff(match.ref);
      } else if (staff.isEmpty) {
        next = next.withStaff(null); // no choice to make → any specialist
      }
      draft.value = next;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  void retrySetup() => _setup();

  // ---------- navigation ----------

  bool get canContinue =>
      draft.value.stepComplete(step.value, fields: intakeFields);

  void next() {
    if (!canContinue) return;
    if (step.value == 0) loadDays();
    if (step.value == 2) {
      draft.value = draft.value.copyWith(notes: notes.text);
    }
    if (step.value < steps - 1) {
      step.value++;
    } else {
      confirm();
    }
  }

  /// Returns true when the flow handled back (moved a step back).
  bool back() {
    if (step.value == 0) return false;
    step.value--;
    return true;
  }

  // ---------- step 1 ----------

  void selectStaff(StaffRef? value) =>
      draft.value = draft.value.withStaff(value);

  // ---------- step 2 ----------

  Future<void> loadDays() async {
    final request = ++_daysRequest;
    daysLoading.value = true;
    daysError.value = null;
    try {
      final list = await _bookings.days(
        serviceId: serviceId,
        staffId: draft.value.staff?.id,
        days: min(max(rules.windowDays, 7), 30),
      );
      if (request != _daysRequest) return;
      days.assignAll(list);
      final current = draft.value.day;
      final keep = current == null
          ? null
          : list.firstWhereOrNull((d) => d.date == current.date);
      final pick =
          keep ?? list.firstWhereOrNull((d) => d.available) ?? list.firstOrNull;
      if (pick != null) selectDay(pick, keepSlot: keep != null);
    } on ApiException catch (e) {
      if (request == _daysRequest) daysError.value = e.message;
    } finally {
      if (request == _daysRequest) daysLoading.value = false;
    }
  }

  void selectDay(AvailabilityDay day, {bool keepSlot = false}) {
    if (!keepSlot) draft.value = draft.value.withDay(day);
    loadSlots();
  }

  Future<void> loadSlots() async {
    final day = draft.value.day;
    if (day == null) return;
    final request = ++_slotsRequest;
    slotsLoading.value = true;
    slotsError.value = null;
    slots.clear();
    try {
      final result = await _bookings.slots(
        serviceId: serviceId,
        date: day.date,
        staffId: draft.value.staff?.id,
      );
      if (request != _slotsRequest) return; // user tapped another day
      slots.assignAll(result.slots);
      canJoinWaitlist.value = result.canJoinWaitlist;
      final chosen = draft.value.slot;
      if (chosen != null &&
          !result.slots.any((s) => s.startsAt == chosen.startsAt)) {
        draft.value = draft.value.copyWith(slot: () => null);
      }
    } on ApiException catch (e) {
      if (request == _slotsRequest) slotsError.value = e.message;
    } finally {
      if (request == _slotsRequest) slotsLoading.value = false;
    }
  }

  void selectSlot(Slot slot) =>
      draft.value = draft.value.copyWith(slot: () => slot);

  void joinWaitlist() {
    Get.toNamed(
      Routes.waitlistJoin,
      arguments: {
        'serviceId': serviceId,
        'serviceName': draft.value.service?.name,
        'staffId': draft.value.staff?.id,
        'staffName': draft.value.staff?.name,
        'date': draft.value.day?.date,
      },
    );
  }

  // ---------- step 3 ----------

  void setAnswer(String key, dynamic value) =>
      draft.value = draft.value.withAnswer(key, value);

  void togglePolicy(bool value) =>
      draft.value = draft.value.copyWith(policyAccepted: value);

  Future<void> applyCoupon() async {
    final code = couponInput.text.trim();
    if (code.isEmpty || couponState.value == CouponState.checking) return;
    couponState.value = CouponState.checking;
    couponMessage.value = null;
    try {
      final result = await _bookings.checkCoupon(
        code: code,
        serviceId: serviceId,
      );
      if (!result.valid) {
        couponState.value = CouponState.invalid;
        couponMessage.value = result.message ?? 'الرمز غير صالح';
        draft.value = draft.value.copyWith(coupon: () => null);
        return;
      }
      draft.value = draft.value.copyWith(
        coupon: () => CouponResult(
          valid: true,
          code: result.code ?? code,
          message: result.message,
          originalPrice: result.originalPrice ?? draft.value.basePrice,
          finalPrice: result.finalPrice,
          discount: result.discount,
        ),
      );
      couponState.value = CouponState.valid;
      couponMessage.value = result.message;
    } on ApiException catch (e) {
      couponState.value = CouponState.invalid;
      couponMessage.value = e.fieldErrors['code'] ?? e.message;
      draft.value = draft.value.copyWith(coupon: () => null);
    }
  }

  void removeCoupon() {
    couponInput.clear();
    couponState.value = CouponState.idle;
    couponMessage.value = null;
    draft.value = draft.value.copyWith(coupon: () => null);
  }

  // ---------- step 4 ----------

  Future<void> confirm() async {
    if (submitting.value ||
        !draft.value.stepComplete(3, fields: intakeFields)) {
      return;
    }
    final d = draft.value.copyWith(notes: notes.text);
    submitting.value = true;
    submitError.value = null;
    alternatives.clear();
    try {
      final booking = await _bookings.create(
        serviceId: serviceId,
        staffId: d.staff?.id,
        startsAt: d.slot!.startsAt,
        notes: d.notes,
        answers: d.answers,
        couponCode: d.coupon?.code,
        paymentMethod: d.paymentMethod,
      );
      Get.offNamed(Routes.bookingSuccess, arguments: booking);
    } on ApiException catch (e) {
      if (e.hasCode('SLOT_UNAVAILABLE')) {
        alternatives.assignAll(_parseAlternatives(e.details['alternatives']));
        submitError.value = e.message;
      } else if (e.isValidation) {
        submitError.value = e.fieldErrors.values.firstOrNull ?? e.message;
      } else {
        submitError.value = e.message;
      }
    } finally {
      submitting.value = false;
    }
  }

  static List<Slot> _parseAlternatives(dynamic raw) => raw is List
      ? raw
            .whereType<Map<String, dynamic>>()
            .map(Slot.fromJson)
            .where((s) => s.startsAt.isNotEmpty)
            .toList()
      : const [];

  /// Picks a server-suggested alternative after SLOT_UNAVAILABLE.
  void useAlternative(Slot slot) {
    final date = slot.startsAt.length >= 10
        ? slot.startsAt.substring(0, 10)
        : null;
    var d = draft.value;
    if (date != null && d.day?.date != date) {
      final day =
          days.firstWhereOrNull((x) => x.date == date) ??
          AvailabilityDay(date: date, label: '', open: true, slotsCount: 1);
      d = d.withDay(day);
    }
    draft.value = d.copyWith(slot: () => slot);
    alternatives.clear();
    submitError.value = null;
  }

  /// SLOT_UNAVAILABLE without alternatives: go back to pick a new time.
  void pickAnotherTime() {
    alternatives.clear();
    submitError.value = null;
    step.value = 1;
    loadSlots();
  }

  @override
  void onClose() {
    notes.dispose();
    couponInput.dispose();
    for (final c in answerControllers.values) {
      c.dispose();
    }
    super.onClose();
  }
}

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is Map ? Get.arguments as Map : const {};
    final serviceId = args['serviceId'];
    if (serviceId is! int) {
      showMessage('تعذّر بدء الحجز', error: true);
      return;
    }
    Get.lazyPut(
      () => BookingFlowController(
        Get.find(),
        Get.find(),
        Get.find(),
        serviceId: serviceId,
        initialStaffId: args['staffId'] as int?,
      ),
    );
  }
}
