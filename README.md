# Zoria Pause

Toggle Android **Private DNS** on/off with one tap from a Quick Settings tile.
No servers, no VPN, no ads, no accounts — everything runs on-device.

## How it works

Private DNS is a secure system setting, so Android doesn't let apps flip it
with a normal permission. Zoria Pause asks for `WRITE_SECURE_SETTINGS` **once**
via [Shizuku](https://shizuku.rikka.app/) (or `adb`), then toggles the setting
directly — no VPN service, no background connection, no root required.

- **Quick Settings tile** — pause/resume Private DNS from anywhere
- **In-app setup guide** — illustrated Shizuku setup (Turkish + English)
- **Zero network** — the release build requests no `INTERNET` permission
- **Private by design** — no analytics, no accounts, no data leaves the device

## Requirements

- Android 7.0+ (API 24)
- [Shizuku](https://shizuku.rikka.app/) running (via wireless debugging or `adb`),
  granted once during setup

## Build

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

Stack: Flutter / Riverpod / GoRouter. Android only.

Optional crash reporting (debug builds) via Sentry:

```bash
flutter run --dart-define=SENTRY_DSN=https://<key>@<host>/<project>
```

## License

MIT — see [LICENSE](LICENSE).
