enum PayloadBuilder {
    static func build(event: Event, config: Configuration,
                      device: DeviceInfo, visitorId: String) -> UmamiPayload {
        var data: [String: AnalyticsValue] = [
            "app_version": .string(device.appVersion),
            "build": .string(device.build),
            "os_version": .string(device.osVersion),
            "device_model": .string(device.deviceModel),
        ]
        for (key, value) in event.data { data[key] = value } // caller overrides metadata

        return UmamiPayload(payload: .init(
            website: config.websiteId,
            hostname: config.host,
            id: visitorId,
            name: event.name,
            title: event.title,
            url: event.url ?? "/",
            language: device.locale,
            screen: device.screen,
            data: data))
    }

    /// A Safari-style user agent for the platform, with no app identity in it.
    /// Umami's bot filter (isbot) silently drops requests whose agent does not
    /// look like a browser, and it matches substrings, so a host like
    /// "bookscanner.ios" flags as a scanner bot. The app identifies itself in
    /// the payload (website id, hostname, app_version), never here.
    static func userAgent(device: DeviceInfo) -> String {
        let underscored = device.osVersion.replacingOccurrences(of: ".", with: "_")
        if device.osName == "macOS" {
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X \(underscored)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(device.osVersion) Safari/605.1.15"
        }
        let platform = device.deviceModel.hasPrefix("iPad")
            ? "iPad; CPU OS \(underscored)"
            : "iPhone; CPU iPhone OS \(underscored)"
        return "Mozilla/5.0 (\(platform) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(device.osVersion) Mobile/15E148 Safari/604.1"
    }
}
