import Foundation
@testable import HealthLog
import Testing

/// Korean durations spell out their units; German/English keep their compact
/// h/min labels. Catalog reads are independent of the test host's language.
@Suite("Korean duration and unit catalog")
struct KoreanDurationUnitTests {
    @Test("Workout duration formats translate Korean units and preserve de/en placeholders")
    func workoutDurationCatalog() throws {
        let catalog = try ParityCatalog.load()
        let formats = [
            ("workout.hrZones.duration.hoursMinutes %lld %lld", "%1$lld시간 %2$lld분", "%1$lld h %2$lld min"),
            ("workout.hrZones.duration.minutes %lld", "%lld분", "%lld min")
        ]
        for (key, ko, legacy) in formats {
            let entry = try #require(catalog.strings[key], "missing \(key)")
            #expect(ParityCatalog.value(entry, language: "ko") == ko)
            for language in ["de", "en"] {
                #expect(ParityCatalog.value(entry, language: language) == legacy, "\(key) / \(language)")
            }
        }
    }

    @Test("Hour, minute and dashboard sleep units use Korean without changing de/en")
    func sharedUnitCatalog() throws {
        let catalog = try ParityCatalog.load()
        for (key, ko, de, en) in [
            ("h", "시간", "h", "h"),
            ("min", "분", "Min.", "min"),
            ("dashboard.metric.unit.sleep", "시간", "h", "h")
        ] {
            let entry = try #require(catalog.strings[key], "missing \(key)")
            #expect(ParityCatalog.value(entry, language: "ko") == ko)
            #expect(ParityCatalog.value(entry, language: "de") == de)
            #expect(ParityCatalog.value(entry, language: "en") == en)
        }
    }
}
