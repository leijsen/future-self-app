import 'package:flutter_test/flutter_test.dart';
import 'package:future_self/models/contract.dart';
import 'package:future_self/contract/contract_engine.dart';

void main() {
  final engine = ContractEngine();

  group('ContractEngine.generateRules', () {
    test('无标签无习惯时给出宽松默认限额', () {
      final rules = engine.generateRules(
        const UserProfile(
          personalityTags: [],
          badHabits: [],
          estimatedScreenMinutes: 120,
        ),
        FutureGoal(
          direction: GoalDirection.reading,
          targetDate: DateTime.now().add(const Duration(days: 180)),
          committedFocusMinutes: 45,
        ),
      );
      expect(rules.entertainmentDailyLimitMinutes, 90);
      expect(rules.focusDailyMinimumMinutes, 45);
    });

    test('分心标签越多限额越紧', () {
      final rules = engine.generateRules(
        const UserProfile(
          personalityTags: [
            PersonalityTag.easilyDistracted,
            PersonalityTag.threeMinutePassion,
            PersonalityTag.phoneChecking,
          ],
          badHabits: [BadHabit.shortVideo, BadHabit.shortDrama],
          estimatedScreenMinutes: 120,
        ),
        FutureGoal(
          direction: GoalDirection.english,
          targetDate: DateTime.now().add(const Duration(days: 180)),
          committedFocusMinutes: 60,
        ),
      );
      // 90 - 45(3个分心标签) - 20(2个娱乐习惯) = 25 → 地板值 30
      expect(rules.entertainmentDailyLimitMinutes, 30);
    });

    test('重度手机用户额外收紧但保底 30 分钟', () {
      final rules = engine.generateRules(
        const UserProfile(
          personalityTags: [],
          badHabits: [],
          estimatedScreenMinutes: 400,
        ),
        FutureGoal(
          direction: GoalDirection.fitness,
          targetDate: DateTime.now().add(const Duration(days: 90)),
          committedFocusMinutes: 30,
        ),
      );
      expect(rules.entertainmentDailyLimitMinutes, 60);
    });
  });

  group('ContractEngine.generateSummary', () {
    test('摘要包含方向与数字', () {
      final summary = engine.generateSummary(
        const UserProfile(
          personalityTags: [PersonalityTag.procrastination],
          badHabits: [BadHabit.shortVideo],
          estimatedScreenMinutes: 180,
        ),
        FutureGoal(
          direction: GoalDirection.certification,
          targetDate: DateTime.now().add(const Duration(days: 180)),
          committedFocusMinutes: 45,
        ),
        const ContractRule(
          entertainmentDailyLimitMinutes: 60,
          focusDailyMinimumMinutes: 45,
        ),
      );
      expect(summary, contains('考证上岸'));
      expect(summary, contains('60'));
      expect(summary, contains('45'));
    });
  });
}
