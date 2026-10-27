import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/catalog.dart';
import '../models/place.dart';

/// Filters supported by `GET /services` (see API_INVENTORY.md).
class ServiceQuery {
  const ServiceQuery({
    this.q,
    this.categoryId,
    this.staffId,
    this.maxDuration,
    this.featured = false,
    this.group = false,
    this.sort,
    this.order,
  });

  final String? q;
  final int? categoryId;
  final int? staffId;
  final int? maxDuration;
  final bool featured;
  final bool group;

  /// `order` | `price` | `duration` | `popular` | `rating` | `name`.
  final String? sort;

  /// `asc` | `desc`.
  final String? order;

  ServiceQuery copyWith({
    String? q,
    int? Function()? categoryId,
    int? Function()? staffId,
    int? Function()? maxDuration,
    bool? featured,
    bool? group,
    String? Function()? sort,
    String? Function()? order,
  }) => ServiceQuery(
    q: q ?? this.q,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
    staffId: staffId != null ? staffId() : this.staffId,
    maxDuration: maxDuration != null ? maxDuration() : this.maxDuration,
    featured: featured ?? this.featured,
    group: group ?? this.group,
    sort: sort != null ? sort() : this.sort,
    order: order != null ? order() : this.order,
  );

  /// Number of filters set from the advanced filter sheet.
  int get advancedCount =>
      (staffId != null ? 1 : 0) +
      (maxDuration != null ? 1 : 0) +
      (featured ? 1 : 0) +
      (group ? 1 : 0) +
      (sort != null ? 1 : 0);

  Map<String, dynamic> toQuery(int page, int perPage) => {
    'q': q?.trim(),
    'category_id': categoryId,
    'staff_id': staffId,
    'max_duration': maxDuration,
    if (featured) 'featured': 1,
    if (group) 'group': 1,
    'sort': sort,
    'order': order,
    'page': page,
    'per_page': perPage,
  };
}

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<Place> place() async =>
      Place.fromJson((await _api.get(_api.place())).dataMap);

  Future<HomeData> home() async =>
      HomeData.fromJson((await _api.get(_api.place('home'))).dataMap);

  Future<List<Category>> categories() async => (await _api.get(
    _api.place('categories'),
  )).dataList.map(Category.fromJson).toList();

  Future<Paged<Service>> services(
    ServiceQuery query, {
    int page = 1,
    int perPage = 15,
  }) async {
    final res = await _api.get(
      _api.place('services'),
      query: query.toQuery(page, perPage),
    );
    return Paged(
      res.dataList.map(Service.fromJson).toList(),
      PageMeta.fromJson(res.meta),
    );
  }

  Future<Service> service(int id) async =>
      Service.fromJson((await _api.get(_api.place('services/$id'))).dataMap);

  Future<List<Staff>> staff({int? serviceId}) async => (await _api.get(
    _api.place('staff'),
    query: {'service_id': serviceId},
  )).dataList.map(Staff.fromJson).toList();

  Future<Staff> staffMember(int id) async =>
      Staff.fromJson((await _api.get(_api.place('staff/$id'))).dataMap);

  Future<(Paged<Review>, ReviewSummary)> placeReviews({int page = 1}) async {
    final res = await _api.get(_api.place('reviews'), query: {'page': page});
    return (
      Paged(
        res.dataList.map(Review.fromJson).toList(),
        PageMeta.fromJson(res.meta),
      ),
      ReviewSummary.fromMeta(res.meta),
    );
  }

  Future<(Paged<Review>, ReviewSummary)> serviceReviews(
    int serviceId, {
    int page = 1,
  }) async {
    final res = await _api.get(
      _api.place('services/$serviceId/reviews'),
      query: {'page': page},
    );
    return (
      Paged(
        res.dataList.map(Review.fromJson).toList(),
        PageMeta.fromJson(res.meta),
      ),
      ReviewSummary.fromMeta(res.meta),
    );
  }

  Future<BusyHours> busyHours() async => BusyHours.fromJson(
    (await _api.get(_api.place('insights/busy-hours'))).dataMap,
  );
}
