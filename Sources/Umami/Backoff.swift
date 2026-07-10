import Foundation

enum Backoff {
    static func delay(failures: Int, base: TimeInterval = 2, cap: TimeInterval = 300) -> TimeInterval {
        guard failures > 0 else { return 0 }
        let value = base * pow(2.0, Double(failures - 1))
        return min(value, cap)
    }
}
