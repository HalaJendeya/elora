import 'json.dart';
import 'place.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    this.servicesCount = 0,
  });

  factory Category.fromJson(Json j) => Category(
    id: asInt(j['id']) ?? 0,
    name: asString(j['name']) ?? '',
    icon: asString(j['icon']),
    image: asString(j['image']),
    servicesCount: asInt(j['services_count']) ?? 0,
  );

  final int id;
  final String name;
  final String? icon;
  final String? image;
  final int servicesCount;

  /// Names come as "عربي (English)"; the UI shows the Arabic part only.
  String get shortName {
    final i = name.indexOf('(');
    return (i > 0 ? name.substring(0, i) : name).trim();
  }
}

class Rating {
  const Rating({this.average = 0, this.count = 0});

  factory Rating.fromJson(dynamic v) {
    final j = asMap(v);
    return Rating(
      average: asDouble(j['average']) ?? 0,
      count: asInt(j['count']) ?? 0,
    );
  }

  final double average;
  final int count;
}

/// Compact staff reference used inside services and slots.
class StaffRef {
  const StaffRef({
    required this.id,
    required this.name,
    this.title,
    this.avatar,
    this.initials,
    this.color,
  });

  factory StaffRef.fromJson(Json j) => StaffRef(
    id: asInt(j['id']) ?? 0,
    name: asString(j['name']) ?? '',
    title: asString(j['title']),
    avatar: asString(j['avatar']),
    initials: asString(j['initials']),
    color: asString(j['color']),
  );

  final int id;
  final String name;
  final String? title;
  final String? avatar;
  final String? initials;
  final String? color;
}

class Service {
  const Service({
    required this.id,
    required this.name,
    this.description,
    this.durationMinutes = 0,
    this.durationLabel,
    this.price = 0,
    this.salePrice,
    this.finalPrice = 0,
    this.discountPercent,
    this.capacity = 1,
    this.isGroup = false,
    this.image,
    this.thumb,
    this.images = const [],
    this.isFeatured = false,
    this.categoryId,
    this.categoryName,
    this.staff = const [],
    this.rating = const Rating(),
    this.related = const [],
    this.attributes = const [],
  });

  factory Service.fromJson(Json j) => Service(
    id: asInt(j['id']) ?? 0,
    name: asString(j['name']) ?? '',
    description: asString(j['description']),
    durationMinutes: asInt(j['duration_minutes']) ?? 0,
    durationLabel: asString(j['duration_label']),
    price: asDouble(j['price']) ?? 0,
    salePrice: asDouble(j['sale_price']),
    finalPrice: asDouble(j['final_price']) ?? asDouble(j['price']) ?? 0,
    discountPercent: asInt(j['discount_percent']),
    capacity: asInt(j['capacity']) ?? 1,
    isGroup: asBool(j['is_group']),
    image: asString(j['image']),
    thumb: asString(j['thumb']),
    images: j['images'] is List
        ? (j['images'] as List)
              .map((e) => e is Map ? asString(e['url']) : asString(e))
              .whereType<String>()
              .toList()
        : const [],
    isFeatured: asBool(j['is_featured']),
    categoryId: asInt(j['category_id']),
    categoryName: asString(asMap(j['category'])['name']),
    staff: asList(j['staff'], StaffRef.fromJson),
    rating: Rating.fromJson(j['rating']),
    related: asList(j['related'], Service.fromJson),
    attributes: j['attributes_display'] is List
        ? (j['attributes_display'] as List)
              .map((e) {
                if (e is Map) {
                  return '${e['label'] ?? ''}${e['value'] != null ? ': ${e['value']}' : ''}';
                }
                return '$e';
              })
              .where((e) => e.isNotEmpty)
              .toList()
        : const [],
  );

  final int id;
  final String name;
  final String? description;
  final int durationMinutes;
  final String? durationLabel;
  final double price;
  final double? salePrice;
  final double finalPrice;
  final int? discountPercent;
  final int capacity;
  final bool isGroup;
  final String? image;
  final String? thumb;
  final List<String> images;
  final bool isFeatured;
  final int? categoryId;
  final String? categoryName;
  final List<StaffRef> staff;
  final Rating rating;
  final List<Service> related;
  final List<String> attributes;

  bool get hasDiscount => finalPrice < price;
}

class Staff {
  const Staff({
    required this.id,
    required this.name,
    this.title,
    this.bio,
    this.avatar,
    this.initials,
    this.color,
    this.hours = const [],
    this.services = const [],
    this.rating = const Rating(),
    this.latestReviews = const [],
  });

  factory Staff.fromJson(Json j) => Staff(
    id: asInt(j['id']) ?? 0,
    name: asString(j['name']) ?? '',
    title: asString(j['title']),
    bio: asString(j['bio']),
    avatar: asString(j['avatar']),
    initials: asString(j['initials']),
    color: asString(j['color']),
    hours: asList(j['hours'], OpeningDay.fromJson),
    services: asList(j['services'], Service.fromJson),
    rating: Rating.fromJson(j['rating']),
    latestReviews: asList(j['latest_reviews'], Review.fromJson),
  );

  final int id;
  final String name;
  final String? title;
  final String? bio;
  final String? avatar;
  final String? initials;
  final String? color;
  final List<OpeningDay> hours;
  final List<Service> services;
  final Rating rating;
  final List<Review> latestReviews;

  StaffRef get ref => StaffRef(
    id: id,
    name: name,
    title: title,
    avatar: avatar,
    initials: initials,
    color: color,
  );
}

class Review {
  const Review({
    required this.id,
    required this.rating,
    this.comment,
    this.authorName,
    this.createdAt,
    this.createdLabel,
    this.reply,
    this.serviceName,
  });

  factory Review.fromJson(Json j) {
    final reply = j['reply'];
    final customer = asMap(j['customer']);
    return Review(
      id: asInt(j['id']) ?? 0,
      rating: asInt(j['rating']) ?? 0,
      comment: asString(j['comment']),
      authorName:
          asString(j['customer_name']) ??
          asString(customer['name']) ??
          asString(j['author']) ??
          asString(j['name']),
      createdAt: asDate(j['created_at']),
      createdLabel: asString(j['created_human']) ?? asString(j['date_label']),
      reply: reply is Map
          ? asString(reply['text'] ?? reply['body'])
          : asString(reply),
      serviceName: asString(asMap(j['service'])['name']),
    );
  }

  final int id;
  final int rating;
  final String? comment;
  final String? authorName;
  final DateTime? createdAt;
  final String? createdLabel;
  final String? reply;
  final String? serviceName;
}

class ReviewSummary {
  const ReviewSummary({
    this.average = 0,
    this.total = 0,
    this.distribution = const {},
  });

  factory ReviewSummary.fromMeta(Json meta) {
    final dist = <int, int>{};
    asMap(meta['distribution']).forEach((k, v) {
      final key = int.tryParse(k);
      if (key != null) dist[key] = asInt(v) ?? 0;
    });
    return ReviewSummary(
      average: asDouble(meta['average']) ?? 0,
      total: asInt(meta['total']) ?? 0,
      distribution: dist,
    );
  }

  final double average;
  final int total;
  final Map<int, int> distribution;
}

class QueueSummary {
  const QueueSummary({
    this.enabled = false,
    this.open = false,
    this.waitingCount = 0,
    this.estimatedWaitMinutes,
  });

  factory QueueSummary.fromJson(Json j) => QueueSummary(
    enabled: asBool(j['enabled']),
    open: asBool(j['open']),
    waitingCount: asInt(j['waiting_count']) ?? 0,
    estimatedWaitMinutes: asInt(j['estimated_wait_minutes']),
  );

  final bool enabled;
  final bool open;
  final int waitingCount;
  final int? estimatedWaitMinutes;
}

class HomeBanner {
  const HomeBanner({this.title, this.subtitle, this.image, this.url});

  factory HomeBanner.fromJson(Json j) => HomeBanner(
    title: asString(j['title']),
    subtitle: asString(j['subtitle']),
    image: asString(j['image']),
    url: asString(j['url']) ?? asString(j['link']),
  );

  final String? title;
  final String? subtitle;
  final String? image;
  final String? url;
}

class HomeData {
  const HomeData({
    required this.place,
    this.banners = const [],
    this.categories = const [],
    this.featured = const [],
    this.popular = const [],
    this.staff = const [],
    this.latestReviews = const [],
    this.queue,
  });

  factory HomeData.fromJson(Json j) => HomeData(
    place: Place.fromJson(asMap(j['place'])),
    banners: asList(j['banners'], HomeBanner.fromJson),
    categories: asList(j['categories'], Category.fromJson),
    featured: asList(j['featured'], Service.fromJson),
    popular: asList(j['popular'], Service.fromJson),
    staff: asList(j['staff'], Staff.fromJson),
    latestReviews: asList(j['latest_reviews'], Review.fromJson),
    queue: asMapOrNull(j['queue']) == null
        ? null
        : QueueSummary.fromJson(asMap(j['queue'])),
  );

  final Place place;
  final List<HomeBanner> banners;
  final List<Category> categories;
  final List<Service> featured;
  final List<Service> popular;
  final List<Staff> staff;
  final List<Review> latestReviews;
  final QueueSummary? queue;
}

class BusyHour {
  const BusyHour({required this.hour, required this.open, this.level});

  factory BusyHour.fromJson(Json j) => BusyHour(
    hour: asInt(j['hour']) ?? 0,
    open: asBool(j['open']),
    level: asDouble(j['level']),
  );

  final int hour;
  final bool open;
  final double? level;
}

class BusyDay {
  const BusyDay({
    required this.day,
    required this.label,
    this.hours = const [],
  });

  factory BusyDay.fromJson(Json j) => BusyDay(
    day: asString(j['day']) ?? '',
    label: asString(j['label']) ?? '',
    hours: asList(j['hours'], BusyHour.fromJson),
  );

  final String day;
  final String label;
  final List<BusyHour> hours;

  bool get closed => hours.every((h) => !h.open);
}

class BestTime {
  const BestTime({required this.label, required this.time, this.level});

  factory BestTime.fromJson(Json j) => BestTime(
    label: asString(j['label']) ?? '',
    time: asString(j['time']) ?? '',
    level: asDouble(j['level']),
  );

  final String label;
  final String time;
  final double? level;
}

class BusyHours {
  const BusyHours({
    this.fromHour = 0,
    this.toHour = 0,
    this.grid = const [],
    this.bestTimes = const [],
    this.nowOpen = false,
    this.nowLevel,
    this.nowLabel,
  });

  factory BusyHours.fromJson(Json j) {
    final now = asMap(j['now']);
    return BusyHours(
      fromHour: asInt(j['from_hour']) ?? 0,
      toHour: asInt(j['to_hour']) ?? 0,
      grid: asList(j['grid'], BusyDay.fromJson),
      bestTimes: asList(j['best_times'], BestTime.fromJson),
      nowOpen: asBool(now['open']),
      nowLevel: asDouble(now['level']),
      nowLabel: asString(now['label']),
    );
  }

  final int fromHour;
  final int toHour;
  final List<BusyDay> grid;
  final List<BestTime> bestTimes;
  final bool nowOpen;
  final double? nowLevel;
  final String? nowLabel;

  bool get isEmpty => grid.isEmpty;
}
