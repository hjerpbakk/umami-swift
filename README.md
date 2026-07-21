# Umami

A small Swift package that sends app analytics to a self-hosted [Umami](https://umami.is) backend. It is privacy-first (no IDFA, no App Tracking Transparency prompt) and has no third-party dependencies.

![An iOS app with umami-swift sending events over HTTPS straight to the Umami container on Fly.io, which writes to Supabase, while the Cloudflare Worker used by websites is skipped](https://hjerpbakk.com/img/umami-for-apps/app-analytics.png)

## Guides

Three write-ups walk through the whole setup:

- [Self-hosting Umami](https://hjerpbakk.com/blog/2026/07/11/self-hosting-umami): standing up the Umami backend on Fly.io with a Cloudflare Worker in front.
- [Umami for apps](https://hjerpbakk.com/blog/2026/07/14/umami-for-apps): adding this package to an app and how the events show up in Umami.
- [Reporting app errors](https://hjerpbakk.com/blog/2026/07/19/umami-error-reporting): counting handled errors and crashes as plain Umami events.

## Requirements

- iOS 15+, macOS 12+, or watchOS 9+
- A running Umami instance and a website id for your app

## Installation

Add the package via Swift Package Manager:

```swift
.package(url: "https://github.com/hjerpbakk/umami-swift", from: "1.6.0")
```

See the [changelog](CHANGELOG.md) for what changed in each version.

## Usage

Configure once at launch, then track events from anywhere in your app.

```swift
import Umami

// At launch:
Umami.configure(
    websiteId: "your-website-id",
    host: "your-app-domain",
    baseURL: URL(string: "https://your-umami-host")!
)

// Anywhere:
Umami.track("game_started")
Umami.track("level_completed", ["level": 7, "won": true])

// When the user moves to another screen:
Umami.screen("settings")

// When a handled error is worth counting:
Umami.error("save_failed", error)

// Opt-out:
Umami.setEnabled(false)
```

`host` is the domain you entered when adding the website in Umami. Apps have no real domain, so pick a stable pseudo-domain like `myapp.ios` and use the same string in both places; keeping it stable keeps the app's data under one entry across releases.

`baseURL` is required: point it at your own Umami instance. There is no default, so events only go where you send them and never to someone else's server by accident.

`configure` also takes `flushInterval` (default 15 seconds) and `maxQueueSize` (default 500), if you want to tune how often and how much gets sent.

Event data values are passed as `AnalyticsValue`, which supports string, int, double, and bool literals directly, as in the `level_completed` example above.

## How it maps to Umami

- Every event carries a random visitor id that lives in memory only and rotates when the calendar day changes. Nothing is stored on the device, so usage on different days can never be linked. Since the id dies with the process, each app launch in practice counts as a new visitor; a day is the id's ceiling, not its typical lifetime. This mirrors the anonymous, cookieless model Umami uses on the web, where visitors are a rotating server-side hash rather than a stored identifier.
- A pageview for `/` and an `app_started` event are sent on launch and each time the app returns to the foreground. The pageview is what populates the dashboard's Overview tab (visitors, visits, views); custom events alone only show up under Events.
- `Umami.screen("settings")` sends a pageview for `/settings`, so screens show up in the pages list and add to the view count. Use it if you want per-screen numbers; skip it if launches are enough.
- Anything passed as event data (like `level` and `won` above) shows up as metadata on the event in Umami.
- `Umami.error("save_failed", error)` sends a custom event named `error_save_failed`, so errors sort together in the Events tab and each failure path gets its own count. Pass a static, snake-case name for the failure path; the optional `Error` value adds the error's type, domain, and code as metadata. Cancellations are control flow, not failures, so don't report them.
- A crash (an uncaught exception or a fatal signal) is reported on the next launch as an `error_app_crashed` event, carrying the exception or signal name (for example `NSRangeException` or `SIGSEGV`) in the same type/domain/code fields. Reporting from a crashing process is unreliable, so the client only writes a one-line marker at crash time and sends the event when the app starts again. Pass `reportCrashes: false` to `configure` to opt out, for example when another crash reporter owns the process.
- On macOS there's no foreground/background lifecycle to hook into, so `app_started` only fires once, on launch, and one run of the app counts as one session. Events are still sent while the app runs, on the periodic flush timer, and anything not yet sent when the app quits is kept on disk and sent the next time it launches.
- On watchOS the same lifecycle hooks exist as on iOS: entering the background flushes the queue, and returning to the foreground sends a new launch pageview and `app_started`. Watch apps are backgrounded aggressively, so expect more, shorter sessions than on iPhone. If a watch app and its iPhone app share one website id, prefix the watch screen and event names (for example `watch-menu` and `watch_game_started`) so the platforms stay distinguishable.

## Privacy

Umami has no concept of IDFA and does not need App Tracking Transparency. The visitor id is random, exists only in memory, and rotates at least daily, so it cannot follow a user across days, installs, or devices, and nothing identifying is ever written to the device. This keeps the app client on the same footing as Umami's cookieless web tracking, where nothing is stored in the browser either.

Error and crash reports stay just as anonymous. An error report carries only the static name you pass plus the error's type, domain, and code, all identifiers baked into code. The client never reads `localizedDescription` or `userInfo`, so message text, file paths, and anything the user typed can never end up in a report. A crash report carries only the exception or signal name, never its `reason`, `userInfo`, or a stack trace. Error events take no data parameter, on purpose, so each one stays exactly as anonymous as every other event.

## License

MIT. See [LICENSE](LICENSE).
