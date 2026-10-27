import 'app_routes.dart';

/// Resolves server-provided in-app paths (notification `url`, e.g.
/// `bookings/12`) through an allowlist. Anything unknown resolves to null and
/// is ignored — the server can never push the app to an arbitrary route.
class DeepLinks {
  DeepLinks._();

  static final _patterns = <(RegExp, PendingDestination Function(Match))>[
    (
      RegExp(r'^bookings?/(\d+)(/review)?$'),
      (m) {
        final id = int.parse(m.group(1)!);
        return m.group(2) != null
            ? PendingDestination(Routes.appointment, {'id': id, 'review': true})
            : PendingDestination(Routes.appointment, {'id': id});
      },
    ),
    (
      RegExp(r'^bookings?$'),
      (_) => const PendingDestination(Routes.main, {'tab': 2}),
    ),
    // Waitlist offers open the waitlist flow even when grouped under "queue"
    // in Figma (08.05).
    (
      RegExp(r'^waitlist/(\d+)(/claim|/offer)?$'),
      (m) => PendingDestination(Routes.waitlistEntry, int.parse(m.group(1)!)),
    ),
    (RegExp(r'^waitlist$'), (_) => const PendingDestination(Routes.waitlist)),
    (
      RegExp(r'^queue/(my-ticket|tickets/\d+)$'),
      (_) => const PendingDestination(Routes.queueTicket),
    ),
    (RegExp(r'^queue$'), (_) => const PendingDestination(Routes.queue)),
    (
      RegExp(r'^services?/(\d+)$'),
      (m) => PendingDestination(Routes.serviceDetails, int.parse(m.group(1)!)),
    ),
    (
      RegExp(r'^staff/(\d+)$'),
      (m) => PendingDestination(Routes.specialist, int.parse(m.group(1)!)),
    ),
    (
      RegExp(r'^notifications$'),
      (_) => const PendingDestination(Routes.notifications),
    ),
  ];

  static PendingDestination? resolve(String? url) {
    if (url == null) return null;
    var path = url.trim();
    if (path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    // Absolute URLs are only accepted for their path, never for navigation
    // outside the app.
    path = uri.path.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.replaceFirst(RegExp(r'^(app/|places/[^/]+/)'), '');
    for (final (pattern, build) in _patterns) {
      final match = pattern.firstMatch(path);
      if (match != null) return build(match);
    }
    return null;
  }
}
