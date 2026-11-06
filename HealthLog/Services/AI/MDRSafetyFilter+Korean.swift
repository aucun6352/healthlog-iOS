import Foundation

/// The Korean rows of the MDR matrix (1.4 ko), split from
/// `MDRSafetyFilter.swift` for the file-length budget. They join the base rows
/// in ``MDRSafetyFilter`` and carry the same matrix row numbers and exemptions.
extension MDRSafetyFilter {
    static let koreanPatterns: [Pattern] = // swiftlint:disable force_try
        [
            // Korean rows (1.4 ko). Korean attaches particles to the noun ("고혈압이")
            // and Hangul sits outside `\b`, so these rows carry no word boundary.
            // Mirrors the server bank `src/lib/ai/safety/outbound-screen/locales/ko.ts`
            // in spirit, cut to this matrix's rows.
            // Row 7 — prediction ("오를 거예요", "감소가 예상돼요").
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(오를|올라갈|내려갈|떨어질|높아질|낮아질|늘어날|줄어들|상승할|하락할|증가할|감소할)\s*(것|거|겁니다|가능성)|(상승|하락|증가|감소)(이|가)?\s*(예상|예측)(돼|됩|된)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 7,
                label: "predictive_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(뇌졸중|심근경색|심장마비|심부전|심혈관\s*질환)[^.!?]{0,10}(위험|확률|가능성)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 7,
                label: "future_risk_ko"
            ),
            // Row 8 — recommendation verbs; a cited body or a clinician hand-off excuses them.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(권해요|권합니다|권해\s*드려요|권해\s*드립니다|권장해요|권장합니다|권장드려요|추천해요|추천합니다|추천드려요|권고해요|권고합니다)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 8,
                label: "prescriptive_ko",
                exemptions: [citationExemption, handOffExemption]
            ),
            // Row 8 — "~해야 해요", "~하는 게 좋아요": the Korean "you should".
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"야\s*(해요|합니다|돼요|됩니다)|(는|은)\s*(게|것이)\s*(좋아요|좋겠어요|좋습니다|좋을\s*거예요|바람직해요|바람직합니다)|(제안해요|제안합니다|제안드려요)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 8,
                label: "bare_prescriptive_ko",
                exemptions: [handOffExemption]
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(줄여|늘려|바꿔|낮춰|올려|조절해)\s*보(세요|시는\s*(건|게)|는\s*(건|게)|면)|(하시면|하면)\s*(좋겠|좋을\s*것|도움이\s*될\s*것)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 8,
                label: "implicit_advice_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"지금\s*(바로\s*)?[^.!?]{0,10}(드셔야|복용하셔야|드세요|복용하세요|먹어야|드십시오|복용하십시오)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 8,
                label: "must_take_now_ko"
            ),
            // Row 8 — a therapy or dose change by imperative. No digit may sit between, so
            // "약 2주" ("about two weeks") is not a medication.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(치료|처방|복용량|용량|약을|약은|약물을|약물은)[^.!?\d]{0,10}((바꾸|변경하|조절하|조정하|늘리|줄이|올리|낮추|중단하|끊으)(세요|십시오|셔야|는\s*(게|것이)\s*좋)|(바꿔|변경해|조절해|조정해|늘려|줄여|올려|낮춰|중단해|끊어)\s*(보세요|주세요|야\s*(해요|합니다)))"#,
                    options: .caseInsensitive
                ),
                matrixRow: 8,
                label: "therapy_change_ko"
            ),
            // Row 9 — diagnostic claims.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(고혈압|저혈압|당뇨|부정맥|심방세동|갑상선\s*기능\s*(항진|저하)|수면\s*무호흡)[^.!?]{0,40}(시사|의심|진단|징후|신호)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 9,
                label: "diagnostic_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(고혈압|저혈압|당뇨|부정맥|심방세동|질환|질병)(이|가)\s*(있으세요|있어요|있습니다|있네요|있는\s*것\s*같|맞아요|맞습니다)|앓고\s*(있|계)|진단(돼요|됩니다|할\s*수\s*있)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 9,
                label: "direct_condition_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(수치|값|측정값|기록|결과)(이|가|은|는|를|을)?[^.!?]{0,30}(시사|가리키|가리켜|암시)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 9,
                label: "values_indicate_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(고혈압|저혈압|당뇨|부정맥|무호흡|질환|결핍|장애)[^.!?]{0,20}(일\s*수|있을\s*수|가능성|의심)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 9,
                label: "reflective_suggestive_ko",
                exemptions: [handOffExemptionUnguarded]
            ),
            // Row 11 — causal claims. "때문에" counts only after a metric, so "기록이 없기
            // 때문에 수면 추세를…" (no data) passes.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(혈압|스트레스|맥박|심박|수면|체중)[^.!?]{0,15}(때문|탓|으로\s*인해|로\s*인해)|(혈압|스트레스|맥박|심박|수면|체중)[^.!?]{0,30}(유발|초래|야기|원인)|(유발|초래|야기|원인)[^.!?]{0,30}(혈압|스트레스|맥박|심박|수면|체중)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 11,
                label: "causal_ko"
            ),
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(상승|하락|증가|감소)(으로|로)\s*(이어|연결)|(높아지게|낮아지게|올라가게|내려가게|오르게|떨어지게)\s*(해요|합니다|만들|했)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 11,
                label: "leads_to_ko"
            ),
            // Row 14 — drug level and pharmacokinetics.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"약물\s*농도|혈중\s*약물\s*농도|혈장\s*농도|약효가?\s*(가장\s*)?(최고|정점)|최고\s*농도|최저\s*농도|(반감기|약동학)[^.!?]{0,30}(의미|시사|나타내|해석|보여)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 14,
                label: "drug_level_ko"
            ),
            // Row 0 — prompt-injection echo.
            Pattern(
                regex: try! NSRegularExpression(
                    pattern: #"(이전|앞의|앞선|모든|위의)\s*(지시|지침|규칙|명령|프롬프트)[^.!?]{0,6}(무시|잊)"#,
                    options: .caseInsensitive
                ),
                matrixRow: 0,
                label: "prompt_injection_ko"
            )
        ]
    // swiftlint:enable force_try
}
