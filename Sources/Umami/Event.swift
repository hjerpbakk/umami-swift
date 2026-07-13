import Foundation

/// A named custom event, or a pageview when `name` is nil.
struct Event: Codable, Equatable {
    var id: UUID = UUID()
    let name: String?
    var url: String? = nil
    var title: String? = nil
    let data: [String: AnalyticsValue]
}
