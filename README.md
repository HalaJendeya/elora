# ÉLORA

Arabic (RTL) beauty-salon app on the Dori platform. Flutter + GetX + `http`.

```
flutter pub get
flutter run --dart-define=API_BASE_URL=https://dori.toldpath.com/api/v1 --dart-define=PLACE_SLUG=elora
```
Both defines are optional (those are the defaults).

- Endpoint inventory, live verification and design/API discrepancies: [docs/API_INVENTORY.md](docs/API_INVENTORY.md)
- Implementation status and blockers: [docs/PROGRESS.md](docs/PROGRESS.md)
- Tests: `flutter test` (screen captures: `flutter test --update-goldens test/screens`)

## Fonts
All bundled fonts are under the SIL Open Font License: IBM Plex Sans Arabic, Amiri, and
**Gelasio** (`assets/fonts/Gelasio-OFL.txt`). The Figma design specifies Georgia for the Latin
wordmark/monogram; Georgia is a commercial Microsoft font, so the app uses Gelasio, which is
designed to be metric-compatible with it. The repository builds as-is.
