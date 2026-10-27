import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/place_service.dart';
import '../../core/session/session_service.dart';
import '../../core/session/unread_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/validators.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';
import '../../routes/app_nav.dart';

class ProfileController extends GetxController {
  ProfileController(this.session);

  final SessionService session;
  final loggingOut = false.obs;

  bool get signedIn => session.isSignedIn;

  @override
  void onReady() {
    super.onReady();
    session.refreshUser();
  }

  Future<void> logout() async {
    final ok = await showConfirmSheet(
      title: 'تسجيل الخروج',
      message: 'هل أنتِ متأكدة من رغبتكِ في تسجيل الخروج من حسابكِ؟',
      confirmLabel: 'تسجيل الخروج',
      cancelLabel: 'البقاء في الحساب',
      icon: Icons.logout_rounded,
    );
    if (!ok) return;
    loggingOut.value = true;
    await session.signOut();
    loggingOut.value = false;
    // Private tab controllers reset themselves on the session change; the
    // shell itself must not be rebuilt (see AppNav).
    AppNav.toMain(tab: 0);
  }
}

/// Figma 09.01.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (!c.session.isSignedIn) {
          return Column(
            children: [
              const EloraHeader(showBack: false),
              const PageTitle(
                eyebrow: 'مساحتكِ الخاصة',
                title: 'حسابي',
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    EmptyView(
                      icon: Icons.person_outline_rounded,
                      title: 'أهلًا بكِ في ÉLORA',
                      message: 'سجّلي الدخول لإدارة مواعيدكِ وملفكِ الشخصي.',
                      actionLabel: 'تسجيل الدخول',
                      onAction: () => Get.toNamed(Routes.login),
                    ),
                    Center(
                      child: LinkButton(
                        label: 'إنشاء حساب',
                        onPressed: () => Get.toNamed(Routes.register),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Menu(
                      items: [
                        _Item(
                          Icons.info_outline_rounded,
                          'معلومات الصالون',
                          () => Get.toNamed(Routes.salon),
                        ),
                        const _Item(
                          Icons.language_rounded,
                          'اللغة · العربية',
                          null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        final user = c.session.user.value;
        final unread = Get.find<UnreadService>().count.value;
        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const EloraHeader(showBack: false),
            const PageTitle(
              eyebrow: 'مساحتكِ الخاصة',
              title: 'حسابي',
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            ),
            if (user == null)
              const LoadingView()
            else ...[
              Center(
                child: Stack(
                  children: [
                    PersonAvatar(
                      name: user.name,
                      imageUrl: user.avatar,
                      size: 92,
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.white, width: 2),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Get.toNamed(Routes.editProfile),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Colors.white,
                              semanticLabel: 'تعديل',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.name,
                style: AppText.display.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              if (user.phone != null)
                Text(
                  user.phone!,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                ),
              if (user.email != null)
                Text(
                  user.email!,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              if (user.reliability.score != null) ...[
                const SizedBox(height: 18),
                _Reliability(r: user.reliability),
              ],
            ],
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Menu(
                items: [
                  _Item(
                    Icons.edit_outlined,
                    'تعديل الملف الشخصي',
                    () => Get.toNamed(Routes.editProfile),
                  ),
                  _Item(
                    Icons.calendar_month_outlined,
                    'مواعيدي',
                    () => AppNav.toMain(tab: 2),
                  ),
                  _Item(
                    Icons.format_list_bulleted_rounded,
                    'قائمة الانتظار',
                    () => Get.toNamed(Routes.waitlist),
                  ),
                  _Item(
                    Icons.confirmation_number_outlined,
                    'الدور الحي',
                    () => Get.toNamed(Routes.queue),
                  ),
                  _Item(
                    Icons.notifications_none_rounded,
                    unread > 0 ? 'الإشعارات · $unread جديدة' : 'الإشعارات',
                    () => Get.toNamed(Routes.notifications),
                  ),
                  _Item(
                    Icons.info_outline_rounded,
                    'معلومات الصالون',
                    () => Get.toNamed(Routes.salon),
                  ),
                  const _Item(Icons.language_rounded, 'اللغة · العربية', null),
                  _Item(
                    Icons.logout_rounded,
                    'تسجيل الخروج',
                    c.logout,
                    danger: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ÉLORA · الإصدار 1.0',
              style: AppText.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}

/// Explains the score using only rules the API documents: it is per salon,
/// 0–100, and late cancellation lowers it.
void showReliabilityInfo() {
  final hours = Get.find<PlaceService>().place.value?.booking.cancelBeforeHours;
  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('درجة الالتزام', style: AppText.h2),
            const SizedBox(height: 8),
            const Text(
              'مؤشر من 0 إلى 100 يعكس التزامكِ بمواعيدكِ في هذا الصالون، '
              'ويستند إلى سجل زياراتكِ: المكتملة، وعدم الحضور، والإلغاء المتأخر.',
              style: AppText.body,
            ),
            const SizedBox(height: 8),
            Text(
              hours == null || hours == 0
                  ? 'الإلغاء المتأخر يخفّض الدرجة.'
                  : 'الإلغاء قبل أقل من $hours ساعة من الموعد يُعدّ إلغاءً متأخرًا ويخفّض الدرجة.',
              style: AppText.body,
            ),
            const SizedBox(height: 8),
            const Text(
              'يحتسب الصالون الدرجة، وتظهر هنا كما يرسلها.',
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'حسنًا', onPressed: () => Get.back()),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );
}

class _Reliability extends StatelessWidget {
  const _Reliability({required this.r});

  final Reliability r;

  @override
  Widget build(BuildContext context) {
    final score = r.score!.clamp(0, 100);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.blushStrong),
        gradient: const LinearGradient(
          colors: [Color(0xFFF6ECE8), Color(0xFFFAF6F0)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.label != null) Text(r.label!, style: AppText.eyebrow),
                const Text('درجة الالتزام', style: AppText.h2),
                Text(
                  r.description ?? 'مؤشر التزامكِ بمواعيدكِ في ÉLORA.',
                  style: AppText.caption,
                ),
                if (r.hasStats) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (r.completed != null)
                        StatusChip(
                          label: 'مكتملة ${r.completed}',
                          tone: StatusTone.success,
                        ),
                      if (r.noShows != null)
                        StatusChip(label: 'عدم حضور ${r.noShows}'),
                      if (r.lateCancellations != null)
                        StatusChip(
                          label: 'إلغاء متأخر ${r.lateCancellations}',
                          tone: StatusTone.warning,
                        ),
                    ],
                  ),
                ],
                LinkButton(
                  label: 'كيف تُحتسب الدرجة؟',
                  onPressed: showReliabilityInfo,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'درجة الالتزام $score من 100',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 5,
                      backgroundColor: AppColors.cardFill,
                      color: AppColors.primary,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$score',
                          style: const TextStyle(
                            fontFamily: AppText.latin,
                            fontSize: 24,
                          ),
                        ),
                        TextSpan(
                          text: '/100',
                          style: AppText.caption.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  const _Item(this.icon, this.label, this.onTap, {this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
}

class _Menu extends StatelessWidget {
  const _Menu({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return EloraCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            ListTile(
              onTap: items[i].onTap,
              minTileHeight: 56,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cardFill,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  items[i].icon,
                  size: 18,
                  color: AppColors.primaryDeep,
                ),
              ),
              title: Text(
                items[i].label,
                style: AppText.bodyStrong.copyWith(
                  color: items[i].danger ? AppColors.primaryDeep : null,
                ),
              ),
              trailing: items[i].onTap == null || items[i].danger
                  ? null
                  : const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textSecondary,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- edit

class EditProfileController extends GetxController {
  EditProfileController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionService _session;
  final ImagePicker _picker = ImagePicker();

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final avatarPath = RxnString();
  final errors = <String, String>{}.obs;
  final saving = false.obs;
  final saved = false.obs;
  final error = RxnString();

  AppUser? get user => _session.user.value;

  @override
  void onInit() {
    super.onInit();
    name.text = user?.name ?? '';
    phone.text = user?.phone ?? '';
    email.text = user?.email ?? '';
  }

  Future<void> pickAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file != null) avatarPath.value = file.path;
    } catch (_) {
      showMessage('تعذّر فتح معرض الصور', error: true);
    }
  }

  Future<void> save() async {
    final map = <String, String>{};
    final n = Validators.name(name.text);
    final p = Validators.phone(phone.text);
    if (n != null) map['name'] = n;
    if (p != null) map['phone'] = p;
    errors.assignAll(map);
    saved.value = false;
    error.value = null;
    if (map.isNotEmpty || saving.value) return;
    saving.value = true;
    final epoch = _session.epoch;
    try {
      final updated = avatarPath.value != null
          ? await _auth.uploadAvatar(
              avatarPath.value!,
              name: name.text,
              phone: phone.text,
            )
          : await _auth.updateProfile(name: name.text, phone: phone.text);
      if (!_session.isCurrent(epoch)) return;
      // Responses may omit reliability; keep the cached one.
      _session.user.value = AppUser(
        id: updated.id == 0 ? (user?.id ?? 0) : updated.id,
        name: updated.name.isEmpty ? name.text.trim() : updated.name,
        email: updated.email ?? user?.email,
        phone: updated.phone ?? phone.text.trim(),
        avatar: updated.avatar ?? user?.avatar,
        reliability: updated.reliability.score == null
            ? (user?.reliability ?? const Reliability())
            : updated.reliability,
      );
      avatarPath.value = null;
      saved.value = true;
    } on ApiException catch (e) {
      if (e.isValidation && e.fieldErrors.isNotEmpty) {
        errors.assignAll(e.fieldErrors);
      } else {
        error.value = e.message;
      }
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.onClose();
  }
}

/// Figma 09.02 / 09.03.
class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: Obx(
                () => ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const PageTitle(
                      eyebrow: 'بياناتكِ الشخصية',
                      title: 'تعديل الملف الشخصي',
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: c.pickAvatar,
                        child: c.avatarPath.value != null
                            ? CircleAvatar(
                                radius: 46,
                                backgroundImage: ResizeImage(
                                  FileImage(File(c.avatarPath.value!)),
                                  width: 300,
                                ),
                              )
                            : PersonAvatar(
                                name: c.user?.name ?? '',
                                imageUrl: c.user?.avatar,
                                size: 92,
                              ),
                      ),
                    ),
                    Center(
                      child: LinkButton(
                        label: 'تغيير الصورة',
                        onPressed: c.pickAvatar,
                      ),
                    ),
                    const SizedBox(height: 8),
                    EloraTextField(
                      label: 'الاسم الكامل',
                      controller: c.name,
                      error: c.errors['name'],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => c.errors.remove('name'),
                    ),
                    const SizedBox(height: 12),
                    EloraTextField(
                      label: 'رقم الهاتف',
                      controller: c.phone,
                      error: c.errors['phone'],
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => c.errors.remove('phone'),
                    ),
                    const SizedBox(height: 12),
                    EloraTextField(
                      label: 'البريد الإلكتروني',
                      controller: c.email,
                      enabled: false,
                      textDirection: TextDirection.ltr,
                      helper: 'لا يمكن تعديل البريد الإلكتروني حاليًا.',
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'حفظ التغييرات',
                      loading: c.saving.value,
                      loadingLabel: 'جارٍ الحفظ…',
                      onPressed: c.save,
                    ),
                    if (c.saved.value) ...[
                      const SizedBox(height: 14),
                      const NoticeBox(
                        tone: StatusTone.success,
                        title: '✓ تم حفظ التغييرات',
                        message: 'تم تحديث بيانات حسابكِ بنجاح.',
                      ),
                    ],
                    if (c.error.value != null) ...[
                      const SizedBox(height: 14),
                      NoticeBox(title: 'تعذّر الحفظ', message: c.error.value),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
