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

    static func userAgent(config: Configuration, device: DeviceInfo) -> String {
        "\(config.host)/\(device.appVersion) (\(device.deviceModel); \(device.osName) \(device.osVersion))"
    }
}
