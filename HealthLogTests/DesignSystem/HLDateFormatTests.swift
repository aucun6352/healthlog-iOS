import Foundation
@testable import HealthLog
import Testing

// swiftlint:disable force_unwrapping

/// A360-1 H1 — locks the date-format primitive that mirrors the server's
/// `User.dateFormat` (`AUTO | DMY | MDY | YMD`). Verifies each preference renders
/// the numeric field order its server counterpart pins (DMY → dd.MM.yyyy,
/// MDY → MM/dd/yyyy, YMD → yyyy-MM-dd) and that the raw values round-trip the
/// server enum.
@Suite("HLDateFormat")
struct HLDateFormatTests {
    /// A fixed instant: 2026-06-17 (June = month 06, day 17, year 2026) at
    /// midday UTC so no timezone shift crosses a day boundary in the test host.
    private var sample: Date {
        var c = DateComponents()
        c.year = 2026
        c.month = 6
        c.day = 17
        c.hour = 12
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    @Test("raw values mirror the server enum")
    func rawValuesMatchServer() {
        #expect(HLDateFormat.auto.rawValue == "AUTO")
        #expect(HLDateFormat.dayMonthYear.rawValue == "DMY")
        #expect(HLDateFormat.monthDayYear.rawValue == "MDY")
        #expect(HLDateFormat.yearMonthDay.rawValue == "YMD")
        #expect(HLDateFormat.allCases.count == 4)
    }

    @Test("DMY renders day-month-year (de-DE order)")
    func dmyOrder() throws {
        let s = HLDateFormat.dayMonthYear.formatDate(sample, style: .numeric)
        // de-DE numeric date: 17.06.2026 — day leads, dotted separators.
        #expect(s.contains("17"))
        #expect(s.contains("2026"))
        let dayIdx = try #require(s.range(of: "17")?.lowerBound)
        let yearIdx = try #require(s.range(of: "2026")?.lowerBound)
        #expect(dayIdx < yearIdx, "day must precede year in DMY (\(s))")
    }

    @Test("MDY renders month-day-year (en-US order)")
    func mdyOrder() throws {
        let s = HLDateFormat.monthDayYear.formatDate(sample, style: .numeric)
        // en-US numeric date: 6/17/2026 — month leads.
        #expect(s.contains("17"))
        #expect(s.contains("2026"))
        // Month (6) appears before the day (17) before the year.
        let dayIdx = try #require(s.range(of: "17")?.lowerBound)
        let yearIdx = try #require(s.range(of: "2026")?.lowerBound)
        #expect(dayIdx < yearIdx, "day must precede year in MDY (\(s))")
        // Slash separators are the en-US numeric convention.
        #expect(s.contains("/"), "en-US numeric date uses slashes (\(s))")
    }

    @Test("YMD renders ISO year-month-day order")
    func ymdOrder() throws {
        let s = HLDateFormat.yearMonthDay.formatDate(sample, style: .numeric)
        // en-CA numeric date: 2026-06-17 — year leads.
        #expect(s.contains("2026"))
        #expect(s.contains("17"))
        let yearIdx = try #require(s.range(of: "2026")?.lowerBound)
        let dayIdx = try #require(s.range(of: "17")?.lowerBound)
        #expect(yearIdx < dayIdx, "year must precede day in YMD (\(s))")
    }

    @Test("abbreviated style includes a month name and the year")
    func abbreviatedStyle() {
        let s = HLDateFormat.dayMonthYear.formatDate(sample, style: .abbreviated)
        #expect(s.contains("2026"))
        #expect(s.contains("17"))
    }

    @Test("static convenience reads the UserDefaults mirror")
    func staticConvenienceReadsMirror() throws {
        let suite = "HLDateFormatTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(HLDateFormat.yearMonthDay.rawValue, forKey: HLDateFormat.defaultsKey)
        #expect(HLDateFormat.current(defaults: defaults) == .yearMonthDay)

        let s = HLDateFormat.date(sample, style: .numeric, defaults: defaults)
        let yearIdx = try #require(s.range(of: "2026")?.lowerBound)
        let dayIdx = try #require(s.range(of: "17")?.lowerBound)
        #expect(yearIdx < dayIdx)
    }

    @Test("unset mirror defaults to AUTO")
    func unsetDefaultsToAuto() throws {
        let suite = "HLDateFormatTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(HLDateFormat.current(defaults: defaults) == .auto)
    }
}

/// Korean spelled-out dates keep the app language while numeric dates keep
/// the chosen field order. The pre-change Foundation styles are the de/en
/// regression oracle. Production uses TimeZone.current without an injection
/// seam, so pin a Gregorian civil date in one captured device timezone and use
/// that same timezone for every reference formatter (no global mutation).
@Suite("HLDateFormat — Korean app locale", .serialized)
@MainActor
struct HLDateFormatKoreanTests {
    nonisolated private static let pinned: [HLDateFormat] = [.dayMonthYear, .monthDayYear, .yearMonthDay]
    private static let styles: [HLDateFormat.Style] = [.numeric, .abbreviated, .long, .complete]
    private let ko = Locale(identifier: "ko_KR")
    private let timeZone = TimeZone.current

    private func withSample(_ body: (Date) throws -> Void) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 17, hour: 13, minute: 5)))
        try body(date)
    }

    private func legacyStyle(_ style: HLDateFormat.Style, locale: Locale, time: Bool = false) -> Date.FormatStyle {
        let dateStyle: Date.FormatStyle.DateStyle = switch style {
        case .numeric: .numeric
        case .abbreviated: .abbreviated
        case .long: .long
        case .complete: .complete
        }
        return Date.FormatStyle(
            date: dateStyle, time: time ? .shortened : .omitted,
            locale: locale, calendar: Calendar(identifier: .gregorian), timeZone: timeZone
        )
    }

    private func numericDate(_ date: Date, for order: HLDateFormat) -> String {
        date.formatted(legacyStyle(.numeric, locale: order.formattingLocale))
    }

    @Test("All pinned orders spell months and weekdays in Korean", arguments: pinned)
    func koreanSpelledDates(order: HLDateFormat) throws {
        try withSample { date in
            for style in [HLDateFormat.Style.abbreviated, .long, .complete] {
                let text = order.formatDate(date, style: style, appLocale: ko)
                #expect(text.contains("월"), "\(order) / \(style): \(text)")
                #expect(text.range(of: "[A-Za-z]", options: .regularExpression) == nil, "\(text)")
            }
        }
    }

    @Test("Korean numeric dates preserve each pinned order", arguments: pinned)
    func koreanNumericDates(order: HLDateFormat) throws {
        try withSample { date in
            let text = order.formatDate(date, style: .numeric, appLocale: ko)
            #expect(text == numericDate(date, for: order))
            // ICU versions differ in zero-padding; field order and separators
            // must remain pinned in either case (17.6.2026 / 17.06.2026).
            let separator: Character = order == .dayMonthYear ? "." : order == .monthDayYear ? "/" : "-"
            let expected: [Int] = switch order {
            case .dayMonthYear: [17, 6, 2026]
            case .monthDayYear: [6, 17, 2026]
            case .yearMonthDay: [2026, 6, 17]
            case .auto: []
            }
            #expect(text.split(separator: separator).compactMap { Int($0) } == expected)
        }
    }

    @Test("Korean date-times honour H12/H24 and preserve pinned numeric dates", arguments: pinned)
    func koreanDateTimes(order: HLDateFormat) throws {
        let suite = "HLDateFormatKoreanTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try withSample { date in
            for preference in [HLTimeFormat.twelveHour, .twentyFourHour] {
                defaults.set(preference.rawValue, forKey: HLTimeFormat.defaultsKey)
                for style in Self.styles {
                    let text = order.formatDateTime(date, style: style, defaults: defaults, appLocale: ko)
                    #expect(text.range(of: "[A-Za-z]", options: .regularExpression) == nil, "\(text)")
                    if preference == .twelveHour {
                        #expect(text.contains("오후"), "13:05 must use the Korean PM marker: \(text)")
                    } else {
                        #expect(text.contains("13:05"))
                        #expect(!text.contains("오전") && !text.contains("오후"))
                    }
                    if style == .numeric {
                        let time = preference == .twelveHour ? "오후 1:05" : "13:05"
                        #expect(text == "\(numericDate(date, for: order)) \(time)")
                    } else {
                        #expect(text.contains("월"))
                    }
                }
            }
        }
    }

    @Test("German and English app locales keep the pre-change pinned-locale behaviour", arguments: ["de_DE", "en_US"])
    func pinnedLocaleRegression(appLocale: String) throws {
        let suite = "HLDateFormatKoreanTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try withSample { date in
            for order in Self.pinned {
                for style in Self.styles {
                    let expected = date.formatted(legacyStyle(style, locale: order.formattingLocale))
                    #expect(order.formatDate(date, style: style, appLocale: Locale(identifier: appLocale)) == expected)
                    for preference in HLTimeFormat.allCases {
                        defaults.set(preference.rawValue, forKey: HLTimeFormat.defaultsKey)
                        var components = Locale.Components(locale: order.formattingLocale)
                        if preference != .auto {
                            components.hourCycle = preference == .twelveHour ? .oneToTwelve : .zeroToTwentyThree
                        }
                        let expectedTime = date.formatted(legacyStyle(style, locale: Locale(components: components), time: true))
                        let actual = order.formatDateTime(date, style: style, defaults: defaults, appLocale: Locale(identifier: appLocale))
                        #expect(actual == expectedTime, "\(order) / \(style) / \(preference)")
                    }
                }
            }
        }
    }

    @Test("AUTO continues to use the device locale regardless of the app-locale argument")
    func autoIsUnaffected() throws {
        let suite = "HLDateFormatKoreanTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try withSample { date in
            for style in Self.styles {
                for appLocale in [ko, Locale(identifier: "de_DE"), Locale(identifier: "en_US")] {
                    #expect(HLDateFormat.auto.formatDate(date, style: style, appLocale: appLocale)
                        == date.formatted(legacyStyle(style, locale: .current)))
                    for preference in HLTimeFormat.allCases {
                        defaults.set(preference.rawValue, forKey: HLTimeFormat.defaultsKey)
                        let actual = HLDateFormat.auto.formatDateTime(date, style: style, defaults: defaults, appLocale: appLocale)
                        #expect(actual == date.formatted(legacyStyle(style, locale: preference.formattingLocale, time: true)))
                    }
                }
            }
        }
    }
}

/// b215 — locks the compact **day + month** helper that appends the year ONLY
/// when the date isn't in `now`'s calendar year, so historical rows (the
/// workouts overview, the measurement feed) are never ambiguous about which
/// year they belong to. `now`, `locale` and `calendar` are all injected so the
/// suite is deterministic across time zones and host locales.
@Suite("HLDateFormat.dayMonth (year-when-not-current)")
struct HLDateFormatDayMonthTests {
    /// A fixed Gregorian/UTC calendar so the year comparison is stable
    /// regardless of the test host's time zone.
    private var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// Build a fixed instant at midday UTC so no timezone shift crosses a day
    /// (or year) boundary in the test host.
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = 12
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private let de = Locale(identifier: "de_DE")
    private let en = Locale(identifier: "en_US")

    @Test("same year → no year appended (de)")
    func sameYearDE() {
        let s = HLDateFormat.dayMonth(
            date(2026, 6, 14), relativeTo: date(2026, 9, 1), locale: de, calendar: utcCalendar
        )
        #expect(s.contains("14"))
        #expect(!s.contains("2026"), "same-year form must stay compact (\(s))")
    }

    @Test("same year → no year appended (en)")
    func sameYearEN() {
        let s = HLDateFormat.dayMonth(
            date(2026, 3, 2), relativeTo: date(2026, 9, 1), locale: en, calendar: utcCalendar
        )
        #expect(!s.contains("2026"), "same-year form must stay compact (\(s))")
    }

    @Test("prior year → year shown (de)")
    func priorYearDE() {
        let s = HLDateFormat.dayMonth(
            date(2024, 6, 14), relativeTo: date(2026, 9, 1), locale: de, calendar: utcCalendar
        )
        #expect(s.contains("14"))
        #expect(s.contains("2024"), "prior-year date must surface the year (\(s))")
    }

    @Test("prior year → year shown (en)")
    func priorYearEN() {
        let s = HLDateFormat.dayMonth(
            date(2024, 6, 14), relativeTo: date(2026, 9, 1), locale: en, calendar: utcCalendar
        )
        #expect(s.contains("2024"), "prior-year date must surface the year (\(s))")
    }

    @Test("year boundary: Dec 31 last year vs Jan 1 this year")
    func yearBoundary() {
        let now = date(2026, 1, 1)
        // Dec 31 of the previous year is NOT the current year → year shown.
        let lastYear = HLDateFormat.dayMonth(
            date(2025, 12, 31), relativeTo: now, locale: en, calendar: utcCalendar
        )
        #expect(lastYear.contains("2025"), "Dec 31 last year must show the year (\(lastYear))")
        // Jan 1 of the current year → compact form, no year.
        let thisYear = HLDateFormat.dayMonth(
            date(2026, 1, 1), relativeTo: now, locale: en, calendar: utcCalendar
        )
        #expect(!thisYear.contains("2026"), "same-year Jan 1 must stay compact (\(thisYear))")
    }

    @Test("de and en render locale-specific forms for the same date")
    func localeForms() {
        let now = date(2026, 9, 1)
        let d = date(2024, 3, 5)
        let deStr = HLDateFormat.dayMonth(d, relativeTo: now, locale: de, calendar: utcCalendar)
        let enStr = HLDateFormat.dayMonth(d, relativeTo: now, locale: en, calendar: utcCalendar)
        #expect(deStr.contains("2024") && enStr.contains("2024"))
        #expect(deStr != enStr, "de and en day+month forms must differ (\(deStr) vs \(enStr))")
    }

    @Test("appendingYearIfNeeded threads the year onto a weekday+time base")
    func appendingYearWeekdayBase() {
        let now = date(2026, 9, 1)
        let base = Date.FormatStyle()
            .weekday(.abbreviated).day().month().hour().minute()
            .locale(en)
        let historical = HLDateFormat.appendingYearIfNeeded(
            date(2023, 6, 14), base: base, relativeTo: now, calendar: utcCalendar
        )
        #expect(historical.contains("2023"), "historical row must show the year (\(historical))")
        let current = HLDateFormat.appendingYearIfNeeded(
            date(2026, 6, 14), base: base, relativeTo: now, calendar: utcCalendar
        )
        #expect(!current.contains("2026"), "current-year row must stay compact (\(current))")
    }
}
