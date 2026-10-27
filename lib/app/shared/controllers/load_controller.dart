import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../widgets/display.dart';

/// Loading / data / error state for a screen that shows one resource.
///
/// When [private] is true the response is dropped if the session changed
/// while the request was in flight (sign-out, account switch).
abstract class LoadController<T> extends GetxController {
  final data = Rxn<T>();
  final loading = true.obs;
  final error = RxnString();
  int _request = 0;

  bool get private => false;

  Future<T> fetch();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final request = ++_request;
    final session = Get.find<SessionService>();
    final epoch = session.epoch;
    error.value = null;
    if (data.value == null) loading.value = true;
    try {
      final value = await fetch();
      if (request != _request || isClosed) return;
      if (private && !session.isCurrent(epoch)) return;
      data.value = value;
      onLoaded(value);
    } on ApiException catch (e) {
      if (request == _request && !isClosed) error.value = e.message;
    } finally {
      if (request == _request && !isClosed) loading.value = false;
    }
  }

  void onLoaded(T value) {}
}

/// Renders loading / error / content for a [LoadController].
class LoadBuilder<T> extends StatelessWidget {
  const LoadBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  final LoadController<T> controller;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final value = controller.data.value;
      if (value != null) return builder(value);
      if (controller.loading.value) return const LoadingView();
      return ErrorView(
        message: controller.error.value ?? '',
        onRetry: controller.load,
      );
    });
  }
}
