import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/account_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_guard.dart';

/// Shared form plumbing: field errors (client + server 422), busy flag.
abstract class _AuthFormController extends GetxController {
  _AuthFormController(this.repo, this.session);

  final AuthRepository repo;
  final SessionService session;

  final errors = <String, String>{}.obs;
  final formError = RxnString();
  final loading = false.obs;
  final obscure = true.obs;

  PendingDestination? get destination => Get.arguments is PendingDestination
      ? Get.arguments as PendingDestination
      : null;

  String? error(String field) => errors[field];

  void clearError(String field) {
    if (errors.containsKey(field)) errors.remove(field);
    formError.value = null;
  }

  Future<void> run(Future<void> Function() action) async {
    if (loading.value) return;
    formError.value = null;
    loading.value = true;
    try {
      await action();
    } on ApiException catch (e) {
      if (e.isValidation && e.fieldErrors.isNotEmpty) {
        errors.assignAll(e.fieldErrors);
      } else {
        formError.value = e.message;
      }
    } finally {
      loading.value = false;
    }
  }
}

class LoginController extends _AuthFormController {
  LoginController(super.repo, super.session);

  final email = TextEditingController();
  final password = TextEditingController();

  bool validate() {
    final map = <String, String>{};
    final e = Validators.email(email.text);
    final p = Validators.loginPassword(password.text);
    if (e != null) map['email'] = e;
    if (p != null) map['password'] = p;
    errors.assignAll(map);
    return map.isEmpty;
  }

  Future<void> submit() async {
    if (!validate()) return;
    await run(() async {
      final result = await repo.login(
        email: email.text,
        password: password.text,
      );
      await session.signIn(result);
      AuthGate.resume(destination);
    });
  }

  void goToRegister() => Get.offNamed(Routes.register, arguments: destination);

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}

class RegisterController extends _AuthFormController {
  RegisterController(super.repo, super.session);

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final obscureConfirm = true.obs;

  bool validate() {
    final map = <String, String>{};
    void check(String key, String? message) {
      if (message != null) map[key] = message;
    }

    check('name', Validators.name(name.text));
    check('email', Validators.email(email.text));
    check('phone', Validators.phone(phone.text));
    check('password', Validators.newPassword(password.text));
    check(
      'password_confirmation',
      Validators.confirm(confirm.text, password.text),
    );
    errors.assignAll(map);
    return map.isEmpty;
  }

  Future<void> submit() async {
    if (!validate()) return;
    await run(() async {
      final result = await repo.register(
        name: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
      );
      await session.signIn(result);
      AuthGate.resume(destination);
    });
  }

  void goToLogin() => Get.offNamed(Routes.login, arguments: destination);

  @override
  void onClose() {
    for (final c in [name, email, phone, password, confirm]) {
      c.dispose();
    }
    super.onClose();
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginController(Get.find(), Get.find()));
  }
}

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RegisterController(Get.find(), Get.find()));
  }
}
