import 'package:get/get.dart';

import '../../data/models/place.dart';
import '../../data/repositories/catalog_repository.dart';

/// Public salon configuration (labels, hours, booking rules), cached for the
/// whole app lifetime. Not private data, so it survives sign-out.
class PlaceService extends GetxService {
  PlaceService(this._repo);

  final CatalogRepository _repo;
  final place = Rxn<Place>();
  Future<Place>? _inFlight;

  String get currency => place.value?.currencySymbol ?? '₪';
  PlaceLabels get labels => place.value?.labels ?? const PlaceLabels();

  Future<Place> load({bool force = false}) {
    if (!force && place.value != null) return Future.value(place.value!);
    return _inFlight ??= _repo
        .place()
        .then((value) {
          place.value = value;
          return value;
        })
        .whenComplete(() => _inFlight = null);
  }

  void update(Place value) => place.value = value;
}
