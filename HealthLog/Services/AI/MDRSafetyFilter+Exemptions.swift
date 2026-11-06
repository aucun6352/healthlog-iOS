import Foundation

/// The exemptions of the MDR matrix, split from `MDRSafetyFilter.swift` for
/// the type-body budget when the Korean rows (1.4 ko) widened them.
extension MDRSafetyFilter {
    /// The concrete objects that make a recommendation a clinical instruction
    /// rather than a route to a clinician. Present in the sentence, no hand-off
    /// exemption applies.
    static let concreteIntervention =
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\b(Dosis|Dosierung|Tablette|Spritze|Therapie|Medikament\w*|"#
                + #"dose|dosage|tablet|medication|therapy|treatment)\b|"#
                // Korean: no `\b`, a particle follows the noun ("용량을").
                + #"(용량|복용량|알약|정제|주사|치료|처방|약을|약은|약물)"#,
            options: .caseInsensitive
        )

    /// A recommendation whose subject is a named guideline body. The 1.4.1
    /// citation policy relies on these bodies; a filter
    /// that calls "Die ESH-Leitlinien empfehlen …" prescriptive advice refuses
    /// the citation itself.
    ///
    /// `recommends?` is what R23's `bare_recommend_en` row fires on, so this
    /// exemption is what keeps "WHO recommends 150 minutes …" out of the
    /// refusal path. `empfiehlt`/`empfehlen` guard nothing today (the German
    /// row-8 regex matches `empfehl` + e/en/et only); they are listed so the
    /// exemption stays correct if a later row widens.
    static let citedBodyRecommends =
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"\b(Leitlinien?|ESH|ESC|AHA|ACC|ADA|WHO|EMA|guidelines?)\s+"#
                + #"(empfiehlt|empfehlen|recommends?|recommend)\b|"#
                // Korean is verb-final: the body opens the clause, the verb closes it.
                + #"(가이드라인|지침|학회|세계보건기구|ESH|ESC|AHA|ACC|ADA|WHO|EMA)[^.!?]{0,30}(권장|권고|권해|추천)"#,
            options: .caseInsensitive
        )

    /// The clinician hand-off. **R21 widened it** with "talk to your doctor":
    /// the two new bare-prescriptive rows below are built from the same words as
    /// the hand-off sentence the prompt actually wants, so the exemption has to
    /// know every ordinary way of naming that route, not just "ask" and
    /// "discuss".
    ///
    /// R11 asks the model for "1-3 questions or
    /// observations the person can discuss with their doctor", so the sentence
    /// "ask your doctor whether this could point to hypertension" is not a
    /// diagnostic claim leaking through — it is the requested output shape.
    /// Without the possibility word the sentence never reaches the row-9
    /// patterns at all, so this exemption can only ever soften the pairing.
    static let clinicianHandOff =
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: #"(ask\s+your\s+doctor|talk\s+to\s+your\s+(doctor|clinician)|"#
                + #"discuss(ing)?\s+(this\s+)?with\s+your\s+(doctor|clinician)|"#
                + #"mit\s+(deiner|Ihrer)\s+Ärztin|mit\s+(deinem|Ihrem)\s+Arzt|"#
                + #"ärztlich\s+(abklären|besprechen)|"#
                + #"(의사|주치의|담당\s*의|전문의|의료진|약사)(와|과|에게|께|한테|랑)[^.!?]{0,20}"#
                + #"(상담|상의|이야기|물어|여쭤|확인)|진료\s*(때|시|에서)[^.!?]{0,20}(확인|상담|이야기|물어))"#,
            options: .caseInsensitive
        )

    /// The two row-8 exemptions, named once. Every recommendation row carries
    /// the same pair, so spelling the struct out at each call site only invited
    /// them to drift apart — which is precisely the bug fix round 1 found (the
    /// old `prescriptive` row had one of the two and behaved differently from
    /// its English twin as a result).
    static var citationExemption: Exemption {
        Exemption(scope: .overlappingMatch, phrase: citedBodyRecommends, blockedBy: concreteIntervention)
    }

    static var handOffExemption: Exemption {
        Exemption(scope: .sentence, phrase: clinicianHandOff, blockedBy: concreteIntervention)
    }

    /// The row-9 hand-off, WITHOUT the concrete-intervention guard: "this could
    /// point to hypertension, ask your doctor" names no intervention, and
    /// blocking on those words there would refuse ordinary talking points.
    static var handOffExemptionUnguarded: Exemption {
        Exemption(scope: .sentence, phrase: clinicianHandOff)
    }
}
