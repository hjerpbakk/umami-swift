# Changelog

Notable changes for anyone using umami-swift, newest first. The project follows [semantic versioning](https://semver.org/), so a new major version is the only place to expect a breaking change.

## 1.6.0 - 2026-07-19

- Crashes are now counted automatically. An uncaught exception or fatal signal is written to a one-line marker at crash time and reported as an `error_app_crashed` event on the next launch, carrying only the exception or signal name.
- `configure` gains `reportCrashes` (default `true`). Pass `false` when another crash reporter already owns the process.

## 1.5.0 - 2026-07-19

- Added `Umami.error("save_failed", error)` for handled errors. It sends a custom event named `error_save_failed`, and when you pass the caught `Error` it adds the error's type, domain, and code. Message text such as `localizedDescription` and `userInfo` is never read, and there is no data parameter, so an error event stays as anonymous as every other event.

## 1.4.0 - 2026-07-15

- Added watchOS support (watchOS 9+). Backgrounding flushes the queue, and returning to the foreground sends a fresh launch pageview and `app_started`, the same as on iOS.

## 1.3.0 - 2026-07-14

- `baseURL` is now a required argument to `configure` (breaking change). Earlier versions defaulted it to my own ingest host, so a missing value silently sent your events to my server. If you relied on the old default, pass `baseURL: URL(string: "https://hjerpbakk-analytics.fly.dev")!`.

## 1.2.0 - 2026-07-14

- Replaced the persistent install id with a random visitor id that lives only in memory and rotates when the calendar day changes. Nothing identifying is written to the device.
- Updating from 1.0 or 1.1 deletes the old install id those versions stored in `UserDefaults`, so the previous identifier is removed the first time `configure` runs.

## 1.1.0 - 2026-07-13

- A launch pageview is now sent on every launch and every return to the foreground, so the dashboard Overview (visitors, visits, views) fills in instead of only the Events tab.
- Added `Umami.screen("settings")`, which reports a screen as a pageview so it shows up in the pages list.

## 1.0.0 - 2026-07-10

- First release. `Umami.configure`, `Umami.track`, and `Umami.setEnabled` on top of a disk-backed, batched event queue with network backoff, so a launch without network loses nothing and the UI never waits for analytics. iOS 15+ and macOS 12+, with no third-party dependencies.
