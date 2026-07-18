import Foundation

/// Extracts mechanical, code-defined fields from an error. Deliberately never
/// reads `localizedDescription` or `userInfo`: those can carry user content
/// (file names, entered text), which must never reach analytics.
enum ErrorMetadata {
    static func data(for error: (any Error)?) -> [String: AnalyticsValue] {
        guard let error else { return [:] }
        let ns = error as NSError
        return [
            "error_type": .string(String(describing: type(of: error))),
            "error_domain": .string(ns.domain),
            "error_code": .int(ns.code)
        ]
    }
}
