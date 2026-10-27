# umami-swift

An open-source Swift package that sends privacy-first app analytics to a self-hosted Umami backend. No third-party dependencies. It is used by my apps and uses semantic versioning.

## Build and test

```bash
swift build
swift test
```

Package manifest is `Package.swift` (tools 5.9, iOS 15, macOS 12, watchOS 9). One library target `Umami` in `Sources/Umami`, tests in `Tests/UmamiTests` (network is mocked with `MockURLProtocol`).

## Releasing

- Add an entry to `CHANGELOG.md` for every release, newest first.
- The README install snippet pins a version (`from: "1.7.0"`). Update it with the release.
- Anything that breaks the public API needs a new major version.
