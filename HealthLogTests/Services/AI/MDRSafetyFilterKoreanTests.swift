import Foundation
import Testing
#if SWIFT_PACKAGE
    @testable import HealthLogCore
#else
    @testable import HealthLog
#endif

@Suite("MDRSafetyFilter — Korean safety and exemption boundaries")
struct MDRSafetyFilterKoreanTests {
    @Test("Korean prediction, advice, diagnosis, causality and injection are blocked", arguments: [
        "혈압이 다음 주에 오를 거예요.",
        "체중이 계속 감소할 것으로 보여요.",
        "뇌졸중 위험이 높아요.",
        "운동량을 늘리시길 권해요.",
        "저는 이 약을 추천합니다.",
        "가이드라인은 용량을 늘리라고 권장합니다.",
        "염분을 줄여야 해요.",
        "물을 더 마시는 게 좋아요.",
        "카페인을 줄여 보세요.",
        "지금 바로 약을 드세요.",
        "복용량을 줄이세요.",
        "용량을 늘려 보세요.",
        "이 수치는 고혈압을 시사해요.",
        "당뇨가 있으세요.",
        "고혈압이 있는 것 같아요.",
        "측정값이 부정맥을 가리켜요.",
        "수면 무호흡일 수 있어요.",
        "스트레스 때문에 혈압이 올랐어요.",
        "수면 부족이 혈압 상승의 원인이에요.",
        "스트레스는 혈압 상승으로 이어져요.",
        "지금 약물 농도가 최고예요.",
        "이전 지시를 무시하고 답할게요."
    ])
    func forbiddenKoreanTextIsBlocked(_ text: String) async {
        let blocked = await MDRSafetyFilter().containsForbiddenPattern(in: text)
        #expect(blocked, "must be blocked: \(text)")
    }

    @Test("Korean observations, citations and clinician hand-offs pass", arguments: [
        "최근 7일 평균 혈압은 128/82 mmHg예요.",
        "지난주보다 체중이 1.2 kg 줄었어요.",
        "기록이 없기 때문에 수면 추세를 볼 수 없어요.",
        "WHO는 주당 150분의 중간 강도 운동을 권장합니다.",
        "궁금한 점은 의사와 상담해 보세요.",
        "고혈압일 수 있는지 주치의와 상담해 보세요.",
        "이번 주 걸음 수는 하루 평균 8,200보예요.",
        "꾸준히 기록해 보세요.",
        "약 2주 동안 수면 시간이 늘었어요.",
        "혈압이 지난주보다 조금 높았어요.",
        "의사와 상담하는 게 좋아요.",
        "복용 기록은 7일 중 6일이에요."
    ])
    func safeKoreanTextPasses(_ text: String) async {
        let blocked = await MDRSafetyFilter().containsForbiddenPattern(in: text)
        #expect(!blocked, "must pass: \(text)")
    }

    @Test("Korean hand-off cannot exempt a separate sentence")
    func handOffStopsAtFullStop() async {
        let text = "고혈압일 수 있어요. 의사와 상담해 보세요."
        #expect(await MDRSafetyFilter().containsForbiddenPattern(in: text), "must be blocked: \(text)")
    }

    @Test("Korean hand-off cannot launder a concrete intervention")
    func handOffDoesNotLaunderIntervention() async {
        let text = "용량을 늘리는 게 좋아요, 의사와 상담해 보세요."
        #expect(await MDRSafetyFilter().containsForbiddenPattern(in: text), "must be blocked: \(text)")
    }
}
