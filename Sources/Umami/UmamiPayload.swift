struct UmamiPayload: Encodable {
    let type: String
    let payload: Inner

    init(payload: Inner) {
        self.type = "event"
        self.payload = payload
    }

    struct Inner: Encodable {
        let website: String
        let hostname: String
        let id: String
        /// Omitted for pageviews; Umami treats a payload without a name as a pageview.
        let name: String?
        let title: String?
        let url: String
        let language: String
        let screen: String
        let data: [String: AnalyticsValue]
    }
}
