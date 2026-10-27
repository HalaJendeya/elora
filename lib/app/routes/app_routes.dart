abstract class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const serviceDetails = '/service';
  static const specialists = '/specialists';
  static const specialist = '/specialist';
  static const salon = '/salon';
  static const busyHours = '/busy-hours';
  static const reviews = '/reviews';
  static const serviceReviews = '/service-reviews';
  static const booking = '/booking';
  static const bookingSuccess = '/booking-success';
  static const appointment = '/appointment';
  static const reschedule = '/reschedule';
  static const cancelBooking = '/cancel-booking';
  static const submitReview = '/submit-review';
  static const waitlist = '/waitlist';
  static const waitlistJoin = '/waitlist-join';
  static const waitlistEntry = '/waitlist-entry';
  static const queue = '/queue';
  static const queueTicket = '/queue-ticket';
  static const editProfile = '/edit-profile';
  static const notifications = '/notifications';

  /// Routes that need a signed-in customer.
  static const protected = {
    booking,
    bookingSuccess,
    appointment,
    reschedule,
    cancelBooking,
    submitReview,
    waitlist,
    waitlistJoin,
    waitlistEntry,
    queueTicket,
    editProfile,
    notifications,
  };
}

/// Destination remembered while a guest signs in.
class PendingDestination {
  const PendingDestination(this.route, [this.arguments]);

  final String route;
  final dynamic arguments;
}
