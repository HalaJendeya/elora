import 'json.dart';

class OpeningDay {
  const OpeningDay({
    required this.day,
    required this.label,
    required this.open,
    this.ranges = const [],
  });

  factory OpeningDay.fromJson(Json j) => OpeningDay(
    day: asString(j['day']) ?? '',
    label: asString(j['label']) ?? '',
    open: asBool(j['open']),
    ranges: asStringList(j['ranges']),
  );

  final String day;
  final String label;
  final bool open;
  final List<String> ranges;
}

class IntakeField {
  const IntakeField({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.required = false,
  });

  factory IntakeField.fromJson(Json j) => IntakeField(
    key: asString(j['key']) ?? '',
    label:
        asString(j['label_ar']) ??
        asString(j['label']) ??
        asString(j['label_en']) ??
        '',
    type: asString(j['type']) ?? 'text',
    options: asStringList(j['options']),
    required: asBool(j['required']),
  );

  final String key;
  final String label;

  /// `select`, `text`, `textarea`, `boolean`, `number` …
  final String type;
  final List<String> options;
  final bool required;

  bool get isSelect => type == 'select' || type == 'radio';
  bool get isBoolean =>
      type == 'boolean' ||
      type == 'bool' ||
      type == 'checkbox' ||
      type == 'yes_no';
  bool get isMultiline => type == 'textarea';
  bool get isNumber => type == 'number';
}

class BookingRules {
  const BookingRules({
    this.windowDays = 30,
    this.minNoticeMinutes = 0,
    this.cancelBeforeHours = 0,
    this.maxActiveBookings,
    this.autoConfirm = true,
    this.intakeFields = const [],
  });

  factory BookingRules.fromJson(Json j) => BookingRules(
    windowDays: asInt(j['window_days']) ?? 30,
    minNoticeMinutes: asInt(j['min_notice_minutes']) ?? 0,
    cancelBeforeHours: asInt(j['cancel_before_hours']) ?? 0,
    maxActiveBookings: asInt(j['max_active_bookings']),
    autoConfirm: asBool(j['auto_confirm'], true),
    intakeFields: asList(j['intake_fields'], IntakeField.fromJson),
  );

  final int windowDays;
  final int minNoticeMinutes;
  final int cancelBeforeHours;
  final int? maxActiveBookings;
  final bool autoConfirm;
  final List<IntakeField> intakeFields;
}

class PlaceLabels {
  const PlaceLabels({
    this.staff = 'خبيرة',
    this.staffPlural = 'فريق الصالون',
    this.service = 'خدمة',
    this.servicePlural = 'الخدمات',
    this.booking = 'موعد',
  });

  factory PlaceLabels.fromJson(Json j) => PlaceLabels(
    staff: asString(j['staff']) ?? 'خبيرة',
    staffPlural: asString(j['staff_plural']) ?? 'فريق الصالون',
    service: asString(j['service']) ?? 'خدمة',
    servicePlural: asString(j['service_plural']) ?? 'الخدمات',
    booking: asString(j['booking']) ?? 'موعد',
  );

  final String staff;
  final String staffPlural;
  final String service;
  final String servicePlural;
  final String booking;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.cover,
    this.labels = const PlaceLabels(),
    this.phone,
    this.whatsapp,
    this.address,
    this.openNow = false,
    this.openingHours = const [],
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.booking = const BookingRules(),
    this.queueEnabled = false,
    this.currencySymbol = '₪',
    this.timezone,
  });

  factory Place.fromJson(Json j) {
    final contact = asMap(j['contact']);
    final rating = asMap(j['rating']);
    return Place(
      id: asInt(j['id']) ?? 0,
      name: asString(j['name']) ?? 'ÉLORA',
      description: asString(j['description']),
      logo: asString(j['logo']),
      cover: asString(j['cover']),
      labels: PlaceLabels.fromJson(asMap(j['labels'])),
      phone: asString(contact['phone']),
      whatsapp: asString(contact['whatsapp']),
      address: asString(contact['address']),
      openNow: asBool(j['open_now']),
      openingHours: asList(j['opening_hours'], OpeningDay.fromJson),
      ratingAverage: asDouble(rating['average']) ?? 0,
      ratingCount: asInt(rating['count']) ?? 0,
      booking: BookingRules.fromJson(asMap(j['booking'])),
      queueEnabled: asBool(asMap(j['queue'])['enabled']),
      currencySymbol: asString(j['currency_symbol']) ?? '₪',
      timezone: asString(j['timezone']),
    );
  }

  final int id;
  final String name;
  final String? description;
  final String? logo;
  final String? cover;
  final PlaceLabels labels;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final bool openNow;
  final List<OpeningDay> openingHours;
  final double ratingAverage;
  final int ratingCount;
  final BookingRules booking;
  final bool queueEnabled;
  final String currencySymbol;
  final String? timezone;
}
