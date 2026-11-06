import Foundation
@testable import HealthLog
import Testing

/// Korean local reports must not inherit the German/English fallback copy.
/// Pure locale and wording contracts; no renderer, network or patient data.
@Suite("Doctor report — Korean locale and copy")
struct DoctorReportKoreanLocaleTests {
    private struct Label {
        let text: (ReportLocale) -> String
        let de: String
        let en: String
        let ko: String
    }

    private func expectKorean(_ text: String) {
        #expect(text.range(of: "[가-힣]", options: .regularExpression) != nil, "\(text)")
        // The app's proper name is shared across all three languages.
        let copy = text.replacingOccurrences(of: "HealthLog", with: "")
        #expect(copy.range(of: "[A-Za-zÄÖÜäöüß]", options: .regularExpression) == nil, "\(text)")
    }

    @Test("ReportLocale round-trips Korean and rejects unsupported languages")
    func koreanLocaleIdentifiers() {
        #expect(ReportLocale.ko.foundationIdentifier == "ko_KR")
        #expect(ReportLocale.ko.bcp47 == "ko")
        #expect(ReportLocale(rawValue: "ko") == .ko)
        #expect(ReportLocale(rawValue: "fr") == nil)
        #expect(Set(ReportLocale.allCases) == [.de, .en, .ko])
        #expect(ReportLocale.de.foundationIdentifier == "de_DE")
        #expect(ReportLocale.en.foundationIdentifier == "en_US")
    }

    @Test("Korean disclaimer is Hangul and the existing de/en disclaimers stay verbatim")
    func disclaimerTranslations() {
        let ko = DoctorReportDisclaimer.text(for: .ko)
        expectKorean(ko)
        #expect(ko != DoctorReportDisclaimer.text(for: .de))
        #expect(ko != DoctorReportDisclaimer.text(for: .en))
        #expect(DoctorReportDisclaimer.text(for: .de)
            == "Lokaler Export, kein Server beteiligt, auf-Geraet erzeugt, kein medizinisches Dokument")
        #expect(DoctorReportDisclaimer.text(for: .en)
            == "Local export, no server involved, generated on-device, not a medical document")
    }

    @Test("Every report heading and table label is Korean; German and English labels stay unchanged")
    func reportLabels() {
        let labels: [Label] = [
            .init(text: PDFMeta.title, de: "Arztbericht", en: "Doctor Report", ko: "진료용 리포트"),
            .init(text: LocaleText.coverTitle, de: "Arztbericht", en: "Doctor Report", ko: "진료용 리포트"),
            .init(text: LocaleText.coverPatientLabel, de: "Patient", en: "Patient", ko: "환자"),
            .init(text: LocaleText.coverFullNameLabel, de: "Voller Name", en: "Full name", ko: "이름"),
            .init(text: LocaleText.coverInsurerLabel, de: "Krankenkasse", en: "Health insurer", ko: "건강보험사"),
            .init(text: LocaleText.coverInsuranceNumberLabel, de: "Versicherungsnummer", en: "Insurance number", ko: "보험 번호"),
            .init(text: LocaleText.coverPeriodLabel, de: "Berichtszeitraum", en: "Report period", ko: "보고 기간"),
            .init(text: LocaleText.coverGeneratedLabel, de: "Erstellt am", en: "Generated", ko: "생성 시각"),
            .init(text: LocaleText.coverVersionLabel, de: "App-Version", en: "App version", ko: "앱 버전"),
            .init(text: LocaleText.vitalsTitle, de: "Vitalwerte", en: "Vital signs", ko: "활력 징후"),
            .init(text: LocaleText.colKind, de: "Metrik", en: "Metric", ko: "항목"),
            .init(text: LocaleText.colCount, de: "Anzahl", en: "Count", ko: "건수"),
            .init(text: LocaleText.colMean, de: "Mittelwert", en: "Mean", ko: "평균"),
            .init(text: LocaleText.colMedian, de: "Median", en: "Median", ko: "중앙값"),
            .init(text: LocaleText.colMin, de: "Min", en: "Min", ko: "최소"),
            .init(text: LocaleText.colMax, de: "Max", en: "Max", ko: "최대"),
            .init(text: LocaleText.chartsTitle, de: "Verlauf", en: "Charts", ko: "추이"),
            .init(text: LocaleText.dataPoints, de: "Datenpunkte", en: "data points", ko: "개 데이터 포인트"),
            .init(text: LocaleText.medicationsTitle, de: "Medikamente", en: "Medications", ko: "복용 약"),
            .init(text: LocaleText.medicationsArchived, de: "Frueher genommen", en: "Previously taken", ko: "이전 복용 약"),
            .init(text: LocaleText.adherenceTitle, de: "Einnahmetreue", en: "Adherence", ko: "복약 순응도"),
            .init(text: LocaleText.moodTitle, de: "Stimmung", en: "Mood", ko: "기분"),
            .init(text: LocaleText.moodTagsLabel, de: "Haeufigste Tags", en: "Dominant tags", ko: "주요 태그")
        ]
        for label in labels {
            #expect(label.text(.de) == label.de)
            #expect(label.text(.en) == label.en)
            #expect(label.text(.ko) == label.ko)
            expectKorean(label.text(.ko))
        }
    }

    @Test("Mood summary keeps its format arguments in Korean and the existing de/en formats")
    func moodSummary() {
        #expect(LocaleText.moodSummaryFormat(for: .de) == "%d Eintraege, Durchschnitt %.1f / 5")
        #expect(LocaleText.moodSummaryFormat(for: .en) == "%d entries, average %.1f / 5")
        let text = String(
            format: LocaleText.moodSummaryFormat(for: .ko),
            locale: Locale(identifier: "ko_KR"), 7, 3.5
        )
        #expect(text == "기록 7건, 평균 3.5 / 5")
        expectKorean(text)
    }

    @Test("Korean adherence source, mismatch, unavailable, account and both row branches contain no foreign copy")
    func adherenceTranslations() {
        let account = DoctorReportSpec.AdherenceBlock.AccountFigure(rate: 90, taken: 27, expected: 30, medicationCount: 2)
        let row = DoctorReportSpec.AdherenceBlock.Row(
            medicationId: "med-1", medicationName: "시험약", applicable: true, rate: 90, taken: 27, expected: 30
        )
        let noSchedule = DoctorReportSpec.AdherenceBlock.Row(
            medicationId: "med-2", medicationName: "다른약", applicable: false, rate: nil, taken: nil, expected: nil
        )
        let source = LocaleText.adherenceSource(windowDays: 30, locale: .ko)
        let mismatch = LocaleText.adherenceWindowMismatch(windowDays: 30, periodDays: 90, locale: .ko)
        let unavailable = LocaleText.adherenceUnavailable(for: .ko)
        let accountText = LocaleText.adherenceAccount(account, windowDays: 30, locale: .ko)
        let rowText = LocaleText.adherenceRow(row, windowDays: 30, locale: .ko)
        let noScheduleText = LocaleText.adherenceRow(noSchedule, windowDays: 30, locale: .ko)
        for text in [source, mismatch, unavailable, accountText, rowText, noScheduleText] {
            expectKorean(text)
        }
        #expect(source.contains("30일"))
        #expect(mismatch.contains("90일") && mismatch.contains("30일"))
        #expect(accountText.contains("2개") && accountText.contains("30회 중 27회"))
        #expect(rowText.contains("시험약") && rowText.contains("30회 중 27회"))
        #expect(noScheduleText.contains("복용 일정 없음"))
        #expect(!noScheduleText.contains("%"))
        let block = DoctorReportSpec.AdherenceBlock(
            availability: .server, windowDays: 30, periodDays: 90, perMedication: [row], account: account
        )
        #expect(LocaleText.adherenceNotes(for: block, locale: .ko) == [source, accountText, mismatch])
        let unavailableBlock = DoctorReportSpec.AdherenceBlock(
            availability: .unavailable, windowDays: 30, periodDays: 90, perMedication: []
        )
        #expect(LocaleText.adherenceNotes(for: unavailableBlock, locale: .ko) == [unavailable])
    }

    @Test("Adding Korean leaves every German and English adherence sentence unchanged")
    func adherenceLegacyCopy() {
        let row = DoctorReportSpec.AdherenceBlock.Row(
            medicationId: "med-1", medicationName: "Test", applicable: true, rate: 90, taken: 27, expected: 30
        )
        let noSchedule = DoctorReportSpec.AdherenceBlock.Row(
            medicationId: "med-2", medicationName: "Test", applicable: false, rate: nil, taken: nil, expected: nil
        )
        let account = DoctorReportSpec.AdherenceBlock.AccountFigure(rate: 90, taken: 27, expected: 30, medicationCount: 2)
        for locale in [ReportLocale.de, .en] {
            let percent = HLNumberFormat.percent(90, locale: Locale(identifier: locale.foundationIdentifier))
            let actual = [
                LocaleText.adherenceSource(windowDays: 30, locale: locale),
                LocaleText.adherenceWindowMismatch(windowDays: 30, periodDays: 90, locale: locale),
                LocaleText.adherenceUnavailable(for: locale),
                LocaleText.adherenceAccount(account, windowDays: 30, locale: locale),
                LocaleText.adherenceRow(row, windowDays: 30, locale: locale),
                LocaleText.adherenceRow(noSchedule, windowDays: 30, locale: locale)
            ]
            let expected = locale == .de ? [
                "Einnahmetreue der letzten 30 Tage, vom HealthLog-Server nach Einnahmeplan berechnet.",
                "Fuer den Berichtszeitraum von 90 Tagen liefert der Server keine Einnahmetreue; gezeigt sind die letzten 30 Tage.",
                "Einnahmetreue nicht verfuegbar: Der HealthLog-Server war beim Erstellen nicht erreichbar.",
                "Alle Medikamente (2): 27 von 30 eingenommen (\(percent)) in 30 Tagen",
                "Test: 27 von 30 eingenommen (\(percent)) in 30 Tagen",
                "Test: kein Einnahmeplan in HealthLog, keine Einnahmetreue"
            ] : [
                "Adherence over the last 30 days, computed by the HealthLog server from the dosing schedule.",
                "The server provides no adherence for the 90-day report period; the last 30 days are shown.",
                "Adherence not available: the HealthLog server could not be reached when this report was made.",
                "All medications (2): 27 of 30 taken (\(percent)) in 30 days",
                "Test: 27 of 30 taken (\(percent)) in 30 days",
                "Test: no HealthLog schedule, no adherence rate"
            ]
            #expect(actual == expected)
        }
    }

    @Test("Date ranges join Korean endpoints with a tilde and preserve de/en joiners")
    func dateRangeJoiners() {
        // Midday Gregorian instants stay on the intended day in the CI timezone.
        let start = Date(timeIntervalSince1970: 1_781_697_600)
        let end = start.addingTimeInterval(7 * 86400)
        let ko = DateRangeFormatter.format(start: start, end: end, locale: .ko)
        #expect(ko.components(separatedBy: " ~ ").count == 2)
        #expect(!ko.contains("bis") && !ko.contains("to"))
        #expect(DateRangeFormatter.format(start: start, end: end, locale: .de).contains(" bis "))
        #expect(DateRangeFormatter.format(start: start, end: end, locale: .en).contains(" to "))
    }
}
