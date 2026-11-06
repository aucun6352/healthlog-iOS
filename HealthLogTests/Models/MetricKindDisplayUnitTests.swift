import Foundation
@testable import HealthLog
import Testing

@Suite("MetricKind — localized display units")
struct MetricKindDisplayUnitTests {
    @Test("Display time units retain German CI labels", arguments: ["h", "min"])
    func timeUnitLabels(_ unit: String) {
        #expect(MetricKind.displayUnitLabel(unit) == unit)
    }

    @Test("Non-time units pass through unchanged", arguments: ["kg", "mmHg", "bpm", "%", ""])
    func otherUnitsPassThrough(_ unit: String) {
        #expect(MetricKind.displayUnitLabel(unit) == unit)
    }

    @Test("Unit preferences retain hour and minute labels in German CI")
    func preferenceTimeUnitLabels() {
        #expect(UnitPreferences.standard.unitLabel(for: .sleep) == "h")
        #expect(UnitPreferences.standard.unitLabel(for: .timeInDaylight) == "min")
    }

    @Test("Display-unit catalog keys translate time units without changing de/en", arguments: [
        ("unit.display.hours", "시간", "h"),
        ("unit.display.minutes", "분", "min"),
        ("workout.hrZones.duration.seconds %lld", "%lld초", "%lld s")
    ])
    func timeUnitCatalog(key: String, korean: String, legacy: String) throws {
        let catalog = try ParityCatalog.load()
        let entry = try #require(catalog.strings[key], "missing \(key)")
        #expect(ParityCatalog.value(entry, language: "ko") == korean)
        for language in ["de", "en"] {
            #expect(ParityCatalog.value(entry, language: language) == legacy, "\(key) / \(language)")
        }
    }
}
