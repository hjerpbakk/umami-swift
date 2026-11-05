# umami-swift

An open-source Swift package that sends privacy-first app analytics to a self-hosted Umami backend. No third-party dependencies. My apps use it.

## Build and test

```bash
swift build
swift test
```

`Package.swift` uses tools 5.9 and supports iOS 15, macOS 12 and watchOS 9. The tests mock the network with `MockURLProtocol`.

## Releasing

- Add an entry to `CHANGELOG.md` for every release, newest first.
- The README install snippet pins a version (`from: "1.7.0"`). Update it with the release.
