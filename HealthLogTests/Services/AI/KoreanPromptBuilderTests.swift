import Foundation
import Testing
#if SWIFT_PACKAGE
    @testable import HealthLogCore
#else
    @testable import HealthLog
#endif

/// Only pure text builders are exercised: no FoundationModels session or device support is needed.
@Suite("Korean AI prompt builders — locale text and legacy anchors")
@MainActor
struct KoreanPromptBuilderTests {
    enum Surface: String, CaseIterable, Sendable {
        case briefing, trend, medication, reminder, mood, miniTurn, refusal, unsupported, privacy, binder
    }

    private static let korean = Locale(identifier: "ko_KR")
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)
    private static let germanMarkers = [
        "Daten", "Messungen", "Stimmung", "Nutzer", "Frage", "UNVERHANDELBAR", "heute", "gestern", "letzte"
    ]

    @Test("Every Korean builder contains Hangul and excludes German markers", arguments: Surface.allCases, [false, true])
    func koreanBuildersUseKorean(surface: Surface, populated: Bool) {
        let text = render(surface, locale: Self.korean, populated: populated)
        expectKorean(text)
    }

    @Test("German and English builder anchors are preserved", arguments: Surface.allCases)
    func legacyBuilderAnchors(_ surface: Surface) {
        let anchors = legacyAnchors(surface)
        let de = render(surface, locale: Locale(identifier: "de_DE"), populated: true)
        let en = render(surface, locale: Locale(identifier: "en_US"), populated: true)
        #expect(de.contains(anchors.de), "German anchor for \(surface.rawValue): \(anchors.de)")
        #expect(en.contains(anchors.en), "English anchor for \(surface.rawValue): \(anchors.en)")
    }

    @Test("Korean reminder slots are localized", arguments: [
        (ReminderPhraseContext.Slot.morning, "아침"), (.noon, "점심"), (.afternoon, "오후"), (.evening, "저녁"), (.night, "밤")
    ])
    func koreanReminderSlots(slot: ReminderPhraseContext.Slot, label: String) {
        let context = ReminderPhraseContext(medicationName: "Sample", slot: slot, scheduledAt: Self.now)
        let text = SmartReminderPhrasePrompt.build(context: context, locale: Self.korean)
        #expect(text.contains("- 시간대: \(label)\n"))
        expectKorean(text)
    }

    @Test("Korean privacy prompt localizes relative days and retains guardrail and input fences")
    func koreanPrivacyRelativeDaysAndFence() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.startOfDay(for: Self.now).addingTimeInterval(12 * 3600)
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: now))
        let threeDaysAgo = try #require(calendar.date(byAdding: .day, value: -3, to: now))
        let snapshot = HealthSnapshot(
            latestBP: .init(sys: 128, dia: 82, date: now),
            latestPulse: .init(bpm: 72, date: yesterday),
            latestWeight: .init(kg: 72.5, date: threeDaysAgo)
        )
        let text = PrivacyFirstPromptBuilder.compose(userText: "?", snapshot: snapshot, now: now, locale: Self.korean)
        #expect(text.contains("• 혈압: 128/82 mmHg (오늘)"))
        #expect(text.contains("• 맥박: 72 bpm (어제)"))
        #expect(text.contains("kg (3일 전)"))
        #expect(text.contains("\n절대 원칙:\n- 의학적 진단을 절대 내리지 않는다."))
        #expect(text.contains("\n<user-input>\n?\n</user-input>\n"))
        expectKorean(text)
    }

    @Test("Korean binder localizes each data slice", arguments: MiniCoachPrompt.AllowedCategory.allCases)
    func koreanBinderCategories(_ category: MiniCoachPrompt.AllowedCategory) {
        let measurements = sampleMeasurements(populated: true)
        let moods = [MoodEntry(id: "mood", recordedAt: Self.now, score: 4)]
        let text = MiniCoachDataBinder(locale: Self.korean).bind(
            category: category, measurements: measurements, moods: moods, now: Self.now
        )
        expectKorean(text)
        switch category {
        case .dataLookup: #expect(text.contains("지표별 최근 값"))
        case .periodSummary: #expect(text.contains("기간: 최근 7일"))
        case .historicLookup: #expect(text.contains("기록 기간:"))
        case .comparison: #expect(text.contains("비교:"))
        }
    }

    private func expectKorean(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) {
        // Input fixtures contain no Hangul, so the builder must supply it.
        #expect(text.unicodeScalars.contains { (0xAC00 ... 0xD7A3).contains($0.value) }, sourceLocation: sourceLocation)
        for marker in Self.germanMarkers {
            #expect(!text.contains(marker), "German marker '\(marker)' in Korean output: \(text)", sourceLocation: sourceLocation)
        }
    }

    private func sampleMeasurements(populated: Bool) -> [HealthLog.Measurement] {
        guard populated else { return [] }
        return [
            HealthLog.Measurement(id: "recent", kind: .weight, recordedAt: Self.now, value: .scalar(72.5)),
            HealthLog.Measurement(id: "prior", kind: .weight, recordedAt: Self.now.addingTimeInterval(-10 * 86400), value: .scalar(73))
        ]
    }

    private func render(_ surface: Surface, locale: Locale, populated: Bool) -> String {
        let measurements = sampleMeasurements(populated: populated)
        switch surface {
        case .briefing:
            return OnDeviceBriefingPrompt.build(measurements: measurements, healthScore: nil, locale: locale)
        case .trend:
            return TrendObservationPrompt.build(
                metric: .weight, scalars: populated ? [73, 72.5] : [], delta: populated ? -0.5 : nil,
                direction: .stable, seriesCount: measurements.count, locale: locale
            )
        case .medication:
            return MedicationExtractionPrompt.build(rawText: populated ? "Sample 5 mg" : "", locale: locale)
        case .reminder:
            let context = ReminderPhraseContext(
                medicationName: "Sample", slot: .morning, scheduledAt: Self.now,
                streakDays: populated ? 3 : 0, missedPrevious: populated
            )
            return SmartReminderPhrasePrompt.build(context: context, locale: locale)
        case .mood:
            return MoodTagExtractionPrompt.build(rawNote: populated ? "Work" : "", existingTags: populated ? ["work"] : [], locale: locale)
        case .miniTurn:
            let history: [HistoryLine] = populated ? [.init(role: .user, text: "?"), .init(role: .assistant, text: "72.5 kg")] : []
            return MiniCoachPrompt.userTurn(ask: "?", category: .dataLookup, boundContext: "72.5 kg", history: history, locale: locale)
        case .refusal:
            return MiniCoachPrompt.refusalCopy(locale: locale)
        case .unsupported:
            return MiniCoachPrompt.unsupportedFallback(locale: locale)
        case .privacy:
            let snapshot = HealthSnapshot(
                latestBP: .init(sys: 128, dia: 82, date: Self.now), last7dStepsAvg: 8200,
                last7dSleepAvgHours: 7.5, activeMedications: ["Sample 5 mg"], recentMoodAvg: 4
            )
            return PrivacyFirstPromptBuilder.compose(userText: "?", snapshot: populated ? snapshot : .empty, now: Self.now, locale: locale)
        case .binder:
            let moods = populated ? [MoodEntry(id: "mood", recordedAt: Self.now, score: 4)] : []
            return MiniCoachDataBinder(locale: locale).bind(category: .dataLookup, measurements: measurements, moods: moods, now: Self.now)
        }
    }

    private func legacyAnchors(_ surface: Surface) -> (de: String, en: String) {
        switch surface {
        case .briefing: ("Daten der letzten 7 Tage:", "Last 7 days of data:")
        case .trend: ("Zeitfenster: letzte 30 Tage", "Window: last 30 days")
        case .medication: ("OCR-Transkript eines Medikamenten-Packungsfotos:", "OCR transcript from a medication-package photo:")
        case .reminder: ("Tageszeit: Morgen", "slot: morning")
        case .mood: ("Bereits gesetzte Tags (NICHT wiederholen): work", "Tags already on the entry (do NOT repeat): work")
        case .miniTurn: ("Frage des Nutzers (Kategorie: data-lookup):", "User ask (category: data-lookup):")
        case .refusal: ("die du erfasst hast", "the data you logged")
        case .unsupported: ("Mini-Coach erfordert iOS 26+", "Mini-Coach requires iOS 26+")
        case .privacy: ("UNVERHANDELBAR:", "NON-NEGOTIABLE:")
        case .binder: ("Letzter Wert je Metrik", "Latest reading per metric")
        }
    }
}
