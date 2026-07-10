import Foundation

struct Configuration {
    let websiteId: String
    let host: String
    let baseURL: URL
    let flushInterval: TimeInterval
    let maxQueueSize: Int
    let batchSize: Int
}
