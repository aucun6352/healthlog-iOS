import Foundation

public extension MetricKind {
    /// The unit as a reader sees it. `unit` is the canonical wire unit the
    /// server stores and receives ("h", "min"), so it never changes; only the
    /// time units are words, and they route through the catalog (Korean
    /// "시간" / "분", de and en unchanged). Every other unit passes through.
    static func displayUnitLabel(_ unit: String) -> String {
        switch unit {
        case "h": String(localized: "unit.display.hours")
        case "min": String(localized: "unit.display.minutes")
        default: unit
        }
    }
}
