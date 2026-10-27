# ÉLORA — Progress (resume here)

Last updated: 2026-10-18. Endpoint contract + live results: [API_INVENTORY.md](API_INVENTORY.md).

## Project facts
- Flutter 3.44 / Dart 3.12. GetX (state, routes, DI) + `http`. No Riverpod/Provider/Dio.
- **Not a git repository** — nothing committed. Verify changes with your own VCS before shipping.
- Fonts: IBM Plex Sans Arabic + Amiri (OFL, from google/fonts) added under `assets/fonts/`; existing Georgia kept.
- Icons: tab-bar/star/arrow SVGs exported from Figma into `assets/icons/` (rendered via `flutter_svg`).
- New deps: `flutter_svg`, `qr_flutter`. A `web/` platform folder was generated only to preview the app.
- `.claude/launch.json` points the preview to a scratch static server; safe to delete.

## Structure
```
lib/app/core      config, network (ApiClient, ApiException, envelope), storage (secure token),
                  session (SessionService w/ epoch, PlaceService), theme, utils
lib/app/data      models (tolerant parsers) + repositories (catalog, booking, account/waitlist/queue/notifications)
lib/app/features  startup, auth, shell(tabs), home, services, specialists, salon(+busy hours), reviews,
                  booking (BookingDraft + one flow-scoped controller), appointments, waitlist, queue,
                  profile, notifications
lib/app/shared    widgets (header, buttons, fields, cards, states, sheets), LoadController
lib/app/routes    route names, pages+bindings, AuthMiddleware/AuthGate, DeepLinks allowlist
```
Key rules implemented: one `http.Client`; 401 on an authed call signs out; session `epoch` drops stale
private responses; logout clears token/user and rebuilds the shell; queue polling only while the route is
alive and app resumed, never overlapping; waitlist claim re-fetches the entry first; notification `url`
only navigates through the allowlist (waitlist offers → waitlist entry).

## Status by flow
| # | Flow | Implemented | Visually checked (vs Figma) | Live API |
|---|---|---|---|---|
| 1 | Splash → welcome → guest / register / login | ✅ | ✅ welcome, sign-in, errors, register | public ✅; login/register only 422 verified |
| 2 | Home → search/filter → service details | ✅ | ✅ home(guest), list, filter sheet, details | ✅ |
| 3 | Specialists (+ by service), profile | ✅ | ✅ list | ✅ |
| 4 | Salon info, hours, busy hours, reviews | ✅ | ✅ salon, busy hours, empty reviews | ✅ |
| 5 | Booking 4 steps → success | ✅ | ✅ steps 1–2 (fixture data) | availability ✅; create/coupon ⛔ |
| 6 | Appointments → details → reschedule / cancel | ✅ | ✅ list, details (fixture) | ⛔ |
| 7 | Submit review (only if `can_review`) | ✅ | ❌ | ⛔ |
| 8 | Waitlist join/list/detail/claim/expired/taken/leave | ✅ | ✅ offer state (fixture) | ⛔ |
| 9 | Live queue board / ticket / cancel / closed | ✅ | ✅ open board (fixture); closed state is live reality | board ✅ (closed) |
| 10 | Profile → edit/avatar → logout | ✅ | ✅ profile (fixture) | ⛔ |
| 11 | Notifications → read-all → destinations | ✅ | ✅ (fixture) | ⛔ |

"Fixture" = rendered with clearly fake test data in `test/screens/screens_golden_test.dart`, not live results.

## Verification done
- `dart format`, `flutter analyze` → no issues.
- `flutter test` → 66 passing: API client (headers, query encoding, UTF-8, 422/401/404/business codes,
  timeout, network), model parsing against **captured live responses** (`test/fixtures`), booking draft
  rules, validators, deep-link allowlist, session/logout/stale-response guarantees, widget tests (auth
  redirect, login validation, guest home RTL, guest appointments gate, 320px + 1.4× text).
- 20 screen captures at 390×844 with real fonts: `test/screens/goldens/*.png`
  (`flutter test --update-goldens test/screens` to regenerate).
- Release web build ran in the browser pane against the live API (welcome → guest home → services).
  Pane became hidden mid-session, so remaining visual checks used the golden captures.
- Bugs found and fixed during verification: transparent bottom sheets, missing `≈` glyph, overflow at
  1.4× text on 320px, sync throw for missing token, web images blocked by missing CORS on `/uploads`
  (HTML-element fallback; mobile unaffected).

## Field reports
- 2026-10-18 (user, real phone): sign-in with the test account worked. **The app crashed right after
  creating a booking.** No device log was available. Reproduced in `test/booking_flow_test.dart`:
  a long or image-type `qr` value threw `InputTooLongException` while the success screen was building.
  Fixed so `BookingQr` accepts an inline image, an image URL or encodable text, and otherwise shows the
  plain code. The success screen now captures its booking when the route is created (no longer cast
  from `Get.arguments` on rebuild), and release builds show an inline notice instead of an error block.
  **The crash is not confirmed fixed on the device**; that needs a re-run plus the real create/detail response shape.
- A real booking now exists on the live server for the test account; cancel it from مواعيدي if it's not wanted.

- 2026-10-19 (user, real phone): after the fix, booking and opening it from مواعيدي work. **The post-booking crash is resolved.**

## 2026-10-19 additions
- Release config: Android `INTERNET` permission (release APKs previously had no network access), iOS
  photo/camera usage strings (avatar picker would have crashed on iOS), app label "ÉLORA".
  `applicationId` is still `com.example.elora` — change it before publishing.
- Notifications: `UnreadService` keeps the unread count (on sign-in, launch restore and app resume;
  reset on sign-out). A bell with a badge in the home header and the count in the profile menu.
- Appointments: paging (`page`/`last_page`), silent refresh when the tab is reopened, and a
  "قيّمي زيارتكِ" action on past visits only when the server sends `can_review`.
- Profile: "كيف تُحتسب الدرجة؟" explainer limited to documented rules (0–100 per salon, late
  cancellation lowers it, `cancel_before_hours` from the salon). An invented "priority" claim taken from Figma sample copy was removed.
- Home banners open only allowlisted in-app destinations (protected ones go through sign-in).
- Tests: 73 passing (+`test/features_test.dart`: badge, guest has no badge, paging, review action, tab refresh).

## 2026-10-19 API hardening
- **Shape logger (debug builds only):** every response prints `[API] METHOD path → status {field: type, …}`
  — keys and value types, never values, tokens or request bodies. Run from the IDE in debug, use the
  app, and paste the `[API]` lines to verify the unverified endpoints. Off in release.
- GETs retry once on network failure or timeout; writes never retry (no duplicate bookings).
- 429 → "طلبات كثيرة…" message. An expired token now signs out with "انتهت جلستكِ" instead of failing silently.
- Notifications: tolerant parsing (flat or nested `data`; `read_at`/`seen_at`/`is_read`/`is_seen`/`unread`),
  wrapped lists, unread total from `meta` or wrapper, paging, immediate badge clear after read-all.
- Re-probed public endpoints with every filter the app sends (featured, group, sort, max_duration,
  staff_id, category_id, q, page 2, staff-filtered days/slots, 422 bad date, 404 unknown service): all match the parsers.
- Tests: 81 passing (+`test/hardening_test.dart`).

## 2026-10-19 live protected reads (test token)
- Verified 200s: `auth/me`, bookings upcoming/past, booking details, waitlist (both scopes, empty),
  my-ticket (`null`), notifications (empty, `meta.unread`). Only shapes were printed, never values.
- Fixed from live data: timeline showed raw ISO timestamps and had no current step (server sends no
  flag) → formatted times + derived current step; added intake answers, cancel reason (+ late marker),
  discount row; statuses `arrived`/`in_progress` mapped; profile shows completed / no-show /
  late-cancellation counts from `reliability`.
- Sanitized capture for regression tests: `test/fixtures/private_sanitized.json` (all personal values fake).
- Tests: 88 passing; captures `06_02b_appointment_live`, `09_01b_profile_live`.

## 2026-10-19 approved live writes (test account)
- Ran only what was approved: coupon check, waitlist join → read → leave (entry left as `cancelled`),
  unchanged profile PUT, notifications read-all. The existing booking and avatar were not touched.
- Fixed: waitlist offers now follow the server's `can_claim`; read-all uses the returned unread count.
- Still unseen live: a valid coupon response, a waitlist `offered` state/claim, queue tickets (queue
  disabled for this salon), notification items, reschedule/cancel/review responses, avatar upload.
- Tests: 95 passing.

## 2026-10-20 field report: freeze after booking
- User report: after a booking the app stopped responding. Reproduced in `test/booking_flow_test.dart`:
  leaving the success screen ran `Get.offAllNamed(Routes.main)` while the tab shell was still in the
  stack; when GetX disposed the old shell it deleted the tab controllers *by type*, including the ones
  the new shell was using ("ShellController not found"), so the tabs rendered but ignored every tap.
- Fix: `lib/app/routes/app_nav.dart`: `AppNav.toMain(tab:)` pops back to the live shell and switches
  tabs; it only builds a new shell when none exists. Used by booking success (all exits), logout, the
  profile → مواعيدي shortcut, the closed-queue button, post-login resume, notification taps and banners.
- Rule for future code: **never `offAllNamed`/`toNamed` to `Routes.main` directly; use `AppNav`.**
- Regression tests: success → home / system back / appointment → back, logout, profile shortcut.
  Tests: 100 passing. **Not yet confirmed on the device.**

## 2026-10-27 launcher icon + release APK
- Icon: brand monogram "É" (Gelasio, standing in for Georgia; rose `#985663` + rose rule on cream `#FAF6F0`), from the
  Figma 11.01 "App" mark. Source art is rendered by `tool/icon/render_icon_test.dart` into
  `assets/icon/`; platform icons come from `flutter_launcher_icons.yaml` (Android all densities +
  adaptive, iOS, web). Regenerate: `flutter test tool/icon/render_icon_test.dart` then
  `dart run flutter_launcher_icons`.
- Release signing: `android/app/build.gradle.kts` reads `android/key.properties` (git-ignored).
  Without it, release builds are **debug-signed** (installable for testing, rejected by Google Play).
  To sign for real, create a keystore yourself and add `key.properties`:
  ```
  keytool -genkey -v -keystore %USERPROFILE%elora-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias elora
  ```
  ```
  storePassword=…
  keyPassword=…
  keyAlias=elora
  storeFile=C:/Users/<you>/elora-release.jks
  ```
  Keep the keystore and passwords backed up; Play updates need the same key.
- Still `applicationId com.example.elora`; Google Play rejects `com.example.*`; pick the final ID before the first upload.

## 2026-10-27 font licensing: Georgia → Gelasio
- Georgia (Microsoft, commercial) is no longer bundled. The Latin wordmark/monogram uses **Gelasio**
  (SIL OFL, `assets/fonts/Gelasio-OFL.txt`), designed to be metric-compatible with Georgia, so
  layouts are unchanged. All bundled fonts are now open-licensed; the repo builds as-is.
- Variable font files (400–700 + italic); the app only uses the regular and italic instances.
- Launcher icon re-rendered with Gelasio (mark re-centred: Gelasio sits higher in its line box);
  screen captures regenerated.

## Blockers / next steps
1. **Test account needed** for slug `elora` (or a staging slug) to verify protected reads and writes live.
   Nothing was registered, logged in, booked or cancelled on the live server.
2. Not yet run on Android/iOS (no emulator/device attached); keyboard insets and secure storage verified only by code/tests.
3. Unverified response shapes (parsed defensively): coupon check, booking create/detail (`qr`, `timeline`),
   waitlist entry/claim, my-ticket, notifications, profile multipart.
4. Design gaps not implemented by choice: "forgot password" (no endpoint), add-to-calendar (no package/API),
   electronic payment (backend lacks it), per-notification read (no endpoint).
