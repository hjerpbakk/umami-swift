# Umami

A small Swift package that sends app analytics to a self-hosted [Umami](https://umami.is) backend. It is privacy-first (no IDFA, no App Tracking Transparency prompt) and has no third-party dependencies.

## Requirements

- iOS 15+ or macOS 12+
- A running Umami instance and a website id for your app

## Installation

Add the package via Swift Package Manager:

```swift
.package(url: "https://github.com/hjerpbakk/umami-swift", from: "1.2.0")
```

## Usage

Configure once at launch, then track events from anywhere in your app.

```swift
import Umami

// At launch:
Umami.configure(
    websiteId: "your-website-id",
    host: "cardgame.ios",
    baseURL: URL(string: "https://your-umami-host")!
)

// Anywhere:
Umami.track("game_started")
Umami.track("level_completed", ["level": 7, "won": true])

// When the user moves to another screen:
Umami.screen("settings")

// Opt-out:
Umami.setEnabled(false)
```

`baseURL` defaults to my own ingest host (`https://hjerpbakk-analytics.fly.dev`), so if you're pointing at that instance you can leave it out and just call `Umami.configure(websiteId:host:)`. If you self-host Umami elsewhere, pass your own `baseURL`.

`configure` also takes `flushInterval` (default 15 seconds) and `maxQueueSize` (default 500), if you want to tune how often and how much gets sent.

Event data values are passed as `AnalyticsValue`, which supports string, int, double, and bool literals directly, as in the `level_completed` example above.

## How it maps to Umami

- Every event carries a random visitor id that lives in memory only and rotates when the calendar day changes. Nothing is stored on the device, so usage on different days can never be linked. Since the id dies with the process, each app launch in practice counts as a new visitor; a day is the id's ceiling, not its typical lifetime. This mirrors the anonymous, cookieless model Umami uses on the web, where visitors are a rotating server-side hash rather than a stored identifier.
- A pageview for `/` and an `app_started` event are sent on launch and each time the app returns to the foreground. The pageview is what populates the dashboard's Overview tab (visitors, visits, views); custom events alone only show up under Events.
- `Umami.screen("settings")` sends a pageview for `/settings`, so screens show up in the pages list and add to the view count. Use it if you want per-screen numbers; skip it if launches are enough.
- Anything passed as event data (like `level` and `won` above) shows up as metadata on the event in Umami.
- On macOS there's no foreground/background lifecycle to hook into, so `app_started` only fires once, on launch, and one run of the app counts as one session. Events are still sent while the app runs, on the periodic flush timer, and anything not yet sent when the app quits is kept on disk and sent the next time it launches.

## Privacy

Umami has no concept of IDFA and does not need App Tracking Transparency. The visitor id is random, exists only in memory, and rotates at least daily, so it cannot follow a user across days, installs, or devices, and nothing identifying is ever written to the device. This keeps the app client on the same footing as Umami's cookieless web tracking, where nothing is stored in the browser either.

Versions 1.0 and 1.1 stored a persistent install id in `UserDefaults`; 1.2.0 deletes that key the first time `configure` runs, so updating also removes the old identifier from the device.

## License

MIT. See [LICENSE](LICENSE).
