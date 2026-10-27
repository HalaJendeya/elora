# ÉLORA — Feature → Endpoint Inventory

Source of truth for backend behaviour: `dori-elora.postman_collection.json` + live responses.
Figma defines presentation only. API notes printed on Figma frames are **not** treated as contract.

- Base URL: `https://dori.toldpath.com/api/v1` (override with `--dart-define=API_BASE_URL=...`)
- Place slug: `elora` (override with `--dart-define=PLACE_SLUG=...`)
- Headers: `Accept: application/json`, `Accept-Language: ar`, `Authorization: Bearer <token>` on 🔒 routes
- Success envelope: `{ success, message, data, meta? }`
- Error envelope (verified): `{ success:false, message, status, error:{ code, details } }`
  - `422 VALIDATION_ERROR` → `details` = `{ field: [messages] }` (verified on login/register)
  - `401 UNAUTHENTICATED` (verified on `auth/me` without token)
  - `404 NOT_FOUND` (verified on `services/99999`)
  - Documented only: `SLOT_UNAVAILABLE` (+ `details.alternatives`), `SLOT_TAKEN`
- Pagination (verified): `meta = { page, per_page, total, last_page }`; reviews add `average`, `distribution`.
- Collection scripts only store variables (`token`, ids) and assert `success == true`. No execution guards exist,
  so protected writes were **not** run blindly.

Legend — Impl: ✅ implemented · Live: ✅ verified live (read-only) · 📱 worked in the app on the user's phone (shape not inspected by me) · 🔸 contract only (not executed) · ⛔ blocked

| Feature | Method & path (under `/places/{slug}` unless noted) | Impl | Live | Notes |
|---|---|---|---|---|
| Health | `GET /ping` | ✅ | ✅ 200 | |
| Salon info, hours, booking rules, intake fields, labels | `GET /` | ✅ | ✅ 200 | `queue.enabled=false` currently |
| Home | `GET /home` | ✅ | ✅ 200 | `banners`, `featured` empty; `queue` key absent → treated as null |
| Categories | `GET /categories` | ✅ | ✅ 200 | `services_count` = 0 while the only service has `category_id: null` |
| Services list / search / filter | `GET /services?q&category_id&staff_id&max_duration&featured&group&sort&order&page&per_page` | ✅ | ✅ 200 | empty result shape verified |
| Service details | `GET /services/{id}` | ✅ | ✅ 200 | `related: []`, `rating` |
| Service reviews | `GET /services/{id}/reviews` | ✅ | ✅ 200 | empty |
| Staff list (+ by service) | `GET /staff[?service_id=]` | ✅ | ✅ 200 | `avatar` null → initials + `color` |
| Staff profile | `GET /staff/{id}` | ✅ | ✅ 200 | `services`, `latest_reviews` |
| Salon reviews | `GET /reviews` | ✅ | ✅ 200 | `meta.average`, `meta.distribution` |
| Busy hours | `GET /insights/busy-hours` | ✅ | ✅ 200 | `grid[].hours[].level` 0..1 or null when closed |
| Availability days | `GET /availability/days?service_id&days&staff_id?` | ✅ | ✅ 200 | |
| Availability slots | `GET /availability/slots?service_id&date&staff_id?` | ✅ | ✅ 200 | `meta.can_join_waitlist` true even on closed days |
| Register | `POST /auth/register` | ✅ | ✅ 422 only | validation shape verified; no account created |
| Login | `POST /auth/login` | ✅ | ✅ 422 · 📱 | validation shape verified; real login worked on user's phone |
| 🔒 Me (+ reliability) | `GET /auth/me` | ✅ | ✅ 200 | user fields + `reliability {score, level, label, completed, no_shows, late_cancellations, total}` |
| 🔒 Update profile | `PUT /auth/profile` (JSON) / `POST /auth/profile` (multipart `avatar`) | ✅ | ✅ PUT 200 | PUT returns the user **without** `reliability`; avatar multipart not run (not approved) |
| 🔒 Coupon check | `POST /coupons/check` | ✅ | ✅ 422 | `WELCOME10` → `COUPON_INVALID` + message; **valid-coupon shape still unseen** (no valid code available) |
| 🔒 Create booking | `POST /bookings` | ✅ | 📱 user device | `payment_method: cash` only |
| 🔒 Bookings | `GET /bookings?scope=upcoming|past` | ✅ | ✅ 200 | paged; same item shape as details | |
| 🔒 Booking details | `GET /bookings/{id}` | ✅ | ✅ 200 | `qr` = short text code; `total`; `answers_display`; `timeline[{status,label,done,at ISO|null,note}]` (no current flag); `cancel_reason`, `cancelled_late` | `code`, `qr`, `timeline`, `can_*`, `cancel_is_late` |
| 🔒 Reschedule | `POST /bookings/{id}/reschedule` | ✅ | 🔸 | |
| 🔒 Cancel | `POST /bookings/{id}/cancel` | ✅ | 🔸 | |
| 🔒 Review visit | `POST /bookings/{id}/review` | ✅ | 🔸 | only when `can_review` |
| 🔒 Join waitlist | `POST /waitlist` | ✅ | ✅ 201 | accepted on a closed day; `{id, status: waiting, status_label, date, from_time HH:MM, to_time, service, staff, offer, can_claim, booking_id}` | |
| 🔒 My waitlist | `GET /waitlist?active=1` | ✅ | ✅ 200 (empty) | `active=0` also 200; item shape still unseen | `active=0` assumed for history |
| 🔒 Waitlist entry | `GET /waitlist/{id}` | ✅ | ✅ 200 | `offered` state + `offer` shape still unseen | `offer.time`, `offer.seconds_left` |
| 🔒 Claim offer | `POST /waitlist/{id}/claim` | ✅ | 🔸 | `SLOT_TAKEN` |
| 🔒 Leave waitlist | `DELETE /waitlist/{id}` | ✅ | ✅ 200 | `data: null`; entry becomes `cancelled` | |
| Queue board | `GET /queue` | ✅ | ✅ 200 | currently `enabled:false` → closed state |
| 🔒 Take ticket | `POST /queue/tickets` | ✅ | 🔸 | |
| 🔒 My ticket | `GET /queue/my-ticket` | ✅ | ✅ 200 `data:null` | `data: null` when none |
| 🔒 Cancel ticket | `POST /queue/tickets/{id}/cancel` | ✅ | 🔸 | |
| 🔒 Notifications | `GET /notifications` | ✅ | ✅ 200 (empty) | `meta.unread` present; item shape still unseen (booking actions created none) | `url` like `bookings/12` |
| 🔒 Read all | `POST /notifications/read-all` | ✅ | ✅ 200 | `data: {unread: 0}` | no per-item read endpoint exists |
| 🔒 Logout | `POST /auth/logout` | ✅ | 🔸 | |

## Discrepancies (Figma vs API)

| Figma | API reality | Decision |
|---|---|---|
| Electronic payment option (05.06) | Collection only shows `payment_method: "cash"`; frame itself notes card capture is absent | Show cash only; e-payment rendered disabled "غير متاح" |
| "Forgot password" link | No endpoint | Link hidden |
| Per-notification read state / tap-to-read | Only `read-all` | Unread styling from `read_at`/`is_read`; "mark all read" action |
| Category icons (spa, nails, …) | `icon` keys like `scissors`, `brush` + `image` | Icon-key → Material icon map, image fallback |
| Staff photos, "years of experience", review counts | `avatar` null, no experience field | Initials avatar with server `color`; extra fields hidden |
| Waitlist offer from "queue notification" frame (08.05) | It is a waitlist offer | Routed to waitlist entry screen |
| Language row in profile | App is Arabic-only | Row shows "العربية" (informational) |
| Typography 7–9 px body text | Not readable on device | Body text mapped to an 11–15 px scale; Amiri/Georgia display sizes kept |
| Theme `primary_color: #0EA5E9` returned by API | Brand palette is rose `#B76E79` | Brand palette from Figma used; API theme ignored |

## Blockers

1. ~~No test token~~ — token provided 2026-10-19; protected **reads** verified. Remaining writes need approval.
   Previously: **No dedicated test account / token.** Protected reads and all writes (booking, cancel, waitlist, queue, review,
   profile) are implemented against the contract but **not executed live**. Need either a dedicated test account
   for slug `elora` or a staging slug. Registering/logging in on the production host was intentionally not done.
2. `qr` field format in booking details is unknown (URL vs payload) — rendered as QR from `qr` string, falling back to `code`.
