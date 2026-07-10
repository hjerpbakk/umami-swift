import Foundation

struct Event: Codable, Equatable {
    var id: UUID = UUID()
    let name: String
    let data: [String: AnalyticsValue]
}
