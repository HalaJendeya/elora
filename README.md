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
IBM Plex Sans Arabic and Amiri (SIL Open Font License) are included under `assets/fonts/`.
The Latin wordmark/monogram uses **Georgia**, a commercial Microsoft font that is **not** in this
repository. Before building, place your own licensed copies in `assets/fonts/`:
`georgia.ttf`, `georgiab.ttf`, `georgiai.ttf`, `georgiaz.ttf`.
