# Umami

A small Swift package that sends app analytics to a self-hosted [Umami](https://umami.is) backend. It is privacy-first (no IDFA, no App Tracking Transparency prompt) and has no third-party dependencies.

## Requirements

- iOS 15+ or macOS 12+
- A running Umami instance and a website id for your app

## Installation

Add the package via Swift Package Manager:

```swift
.package(url: "https://github.com/hjerpbakk/umami-swift", from: "1.0.0")
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

// Opt-out:
Umami.setEnabled(false)
```

`baseURL` defaults to my own ingest host (`https://hjerpbakk-analytics.fly.dev`), so if you're pointing at that instance you can leave it out and just call `Umami.configure(websiteId:host:)`. If you self-host Umami elsewhere, pass your own `baseURL`.

`configure` also takes `flushInterval` (default 15 seconds) and `maxQueueSize` (default 500), if you want to tune how often and how much gets sent.

Event data values are passed as `AnalyticsValue`, which supports string, int, double, and bool literals directly, as in the `level_completed` example above.

## How it maps to Umami

- Each install gets a random id, generated once and stored on device. That id is sent as the visitor.
- An `app_started` event is sent on launch and each time the app returns to the foreground, so Umami can count sessions.
- Anything passed as event data (like `level` and `won` above) shows up as metadata on the event in Umami.
- On macOS there's no foreground/background lifecycle to hook into, so `app_started` only fires once, on launch, and one run of the app counts as one session. Events are still sent while the app runs, on the periodic flush timer, and anything not yet sent when the app quits is kept on disk and sent the next time it launches.

## Privacy

Umami has no concept of IDFA and does not need App Tracking Transparency. The install id lives in `UserDefaults` and resets if the app is uninstalled and reinstalled, so it does not follow a user across installs or devices.

## License

MIT. See [LICENSE](LICENSE).
