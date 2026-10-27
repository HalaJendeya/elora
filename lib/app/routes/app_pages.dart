import 'package:get/get.dart';

import '../data/models/booking.dart';
import '../features/appointments/appointment_details.dart';
import '../features/auth/auth_controllers.dart';
import '../features/auth/auth_views.dart';
import '../features/booking/booking_controller.dart';
import '../features/booking/booking_success.dart';
import '../features/booking/booking_view.dart';
import '../features/notifications/notifications.dart';
import '../features/profile/profile.dart';
import '../features/queue/queue.dart';
import '../features/reviews/reviews.dart';
import '../features/salon/salon.dart';
import '../features/services/service_details.dart';
import '../features/shell/shell.dart';
import '../features/specialists/specialists.dart';
import '../features/startup/controllers/splash_controller.dart';
import '../features/startup/views/onboarding_screen.dart';
import '../features/startup/views/splash_screen.dart';
import '../features/waitlist/waitlist.dart';
import 'app_routes.dart';
import 'auth_guard.dart';

/// Every route with its own binding: controllers live exactly as long as
/// their screen.
class AppPages {
  AppPages._();

  static final _auth = [AuthMiddleware()];

  static final pages = <GetPage>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      // Eager: the splash view never reads its controller, but the
      // controller drives startup navigation.
      binding: BindingsBuilder(() {
        Get.put(SplashController(Get.find(), Get.find()));
      }),
    ),
    GetPage(name: Routes.onboarding, page: () => const OnboardingScreen()),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.main,
      page: () => const ShellScreen(),
      binding: ShellBinding(),
    ),
    GetPage(
      name: Routes.serviceDetails,
      page: () => ServiceDetailsScreen(id: Get.arguments as int),
      binding: ServiceDetailsBinding(),
    ),
    GetPage(
      name: Routes.specialists,
      page: () => const SpecialistsScreen(),
      binding: SpecialistsBinding(),
    ),
    GetPage(
      name: Routes.specialist,
      page: () => SpecialistScreen(id: Get.arguments as int),
      binding: SpecialistBinding(),
    ),
    GetPage(
      name: Routes.salon,
      page: () => const SalonScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => SalonController(Get.find())),
      ),
    ),
    GetPage(
      name: Routes.busyHours,
      page: () => const BusyHoursScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => BusyHoursController(Get.find())),
      ),
    ),
    GetPage(
      name: Routes.reviews,
      page: () => const ReviewsScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => ReviewsController(Get.find())),
      ),
    ),
    GetPage(
      name: Routes.serviceReviews,
      page: () => const ReviewsScreen(),
      binding: BindingsBuilder(() {
        final args = Get.arguments as Map;
        Get.lazyPut(
          () => ReviewsController(
            Get.find(),
            serviceId: args['id'] as int,
            serviceName: args['name'] as String?,
          ),
        );
      }),
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingFlowScreen(),
      binding: BookingBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.bookingSuccess,
      page: () => BookingSuccessScreen(
        booking: Get.arguments is Booking ? Get.arguments as Booking : null,
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.appointment,
      page: () => const AppointmentDetailsScreen(),
      binding: AppointmentDetailsBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.reschedule,
      page: () => const RescheduleScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => RescheduleController(Get.find(), Get.arguments as Booking),
        ),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.cancelBooking,
      page: () => const CancelBookingScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => CancelBookingController(Get.find(), Get.arguments as Booking),
        ),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.submitReview,
      page: () => const SubmitReviewScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => SubmitReviewController(Get.find(), Get.arguments as Booking),
        ),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.waitlist,
      page: () => const WaitlistScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => WaitlistController(Get.find(), Get.find())),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.waitlistJoin,
      page: () => const WaitlistJoinScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => WaitlistJoinController(Get.find(), Get.arguments as Map),
        ),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.waitlistEntry,
      page: () => const WaitlistEntryScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => WaitlistEntryController(Get.find(), Get.arguments as int),
        ),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.queue,
      page: () => const QueueBoardScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => QueueBoardController(Get.find(), Get.find())),
      ),
    ),
    GetPage(
      name: Routes.queueTicket,
      page: () => const QueueTicketScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => QueueTicketController(Get.find(), Get.find())),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileScreen(),
      binding: BindingsBuilder(
        () => Get.lazyPut(() => EditProfileController(Get.find(), Get.find())),
      ),
      middlewares: _auth,
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsScreen(),
      binding: BindingsBuilder(
        () =>
            Get.lazyPut(() => NotificationsController(Get.find(), Get.find())),
      ),
      middlewares: _auth,
    ),
  ];
}
