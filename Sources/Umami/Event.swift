struct Event: Codable, Equatable {
    let name: String
    let data: [String: AnalyticsValue]
}
