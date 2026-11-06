import Foundation

/// The doctor report's fixed labels in each report language (split from
/// `DoctorReportSectionDrawer.swift` for the file-length budget, like
/// `DoctorReportAdherenceText.swift`).
enum LocaleText {
    static func coverTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Arztbericht"
        case .en: "Doctor Report"
        case .ko: "진료용 리포트"
        }
    }

    static func coverPatientLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Patient"
        case .en: "Patient"
        case .ko: "환자"
        }
    }

    static func coverFullNameLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Voller Name"
        case .en: "Full name"
        case .ko: "이름"
        }
    }

    static func coverInsurerLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Krankenkasse"
        case .en: "Health insurer"
        case .ko: "건강보험사"
        }
    }

    static func coverInsuranceNumberLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Versicherungsnummer"
        case .en: "Insurance number"
        case .ko: "보험 번호"
        }
    }

    static func coverPeriodLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Berichtszeitraum"
        case .en: "Report period"
        case .ko: "보고 기간"
        }
    }

    static func coverGeneratedLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Erstellt am"
        case .en: "Generated"
        case .ko: "생성 시각"
        }
    }

    static func coverVersionLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "App-Version"
        case .en: "App version"
        case .ko: "앱 버전"
        }
    }

    static func vitalsTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Vitalwerte"
        case .en: "Vital signs"
        case .ko: "활력 징후"
        }
    }

    static func colKind(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Metrik"
        case .en: "Metric"
        case .ko: "항목"
        }
    }

    static func colCount(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Anzahl"
        case .en: "Count"
        case .ko: "건수"
        }
    }

    static func colMean(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Mittelwert"
        case .en: "Mean"
        case .ko: "평균"
        }
    }

    static func colMedian(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Median"
        case .en: "Median"
        case .ko: "중앙값"
        }
    }

    static func colMin(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Min"
        case .en: "Min"
        case .ko: "최소"
        }
    }

    static func colMax(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Max"
        case .en: "Max"
        case .ko: "최대"
        }
    }

    static func chartsTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Verlauf"
        case .en: "Charts"
        case .ko: "추이"
        }
    }

    static func dataPoints(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Datenpunkte"
        case .en: "data points"
        case .ko: "개 데이터 포인트"
        }
    }

    static func medicationsTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Medikamente"
        case .en: "Medications"
        case .ko: "복용 약"
        }
    }

    static func medicationsArchived(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Frueher genommen"
        case .en: "Previously taken"
        case .ko: "이전 복용 약"
        }
    }

    static func adherenceTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Einnahmetreue"
        case .en: "Adherence"
        case .ko: "복약 순응도"
        }
    }

    static func moodTitle(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Stimmung"
        case .en: "Mood"
        case .ko: "기분"
        }
    }

    static func moodSummaryFormat(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "%d Eintraege, Durchschnitt %.1f / 5"
        case .en: "%d entries, average %.1f / 5"
        case .ko: "기록 %d건, 평균 %.1f / 5"
        }
    }

    static func moodTagsLabel(for locale: ReportLocale) -> String {
        switch locale {
        case .de: "Haeufigste Tags"
        case .en: "Dominant tags"
        case .ko: "주요 태그"
        }
    }
}
