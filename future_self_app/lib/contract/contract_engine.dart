import '../models/contract.dart';

class ContractEngine {
  /// 根据用户画像和目标生成契约规则。
  /// 规则：分心类标签越多、娱乐类坏习惯越多，娱乐限额越紧；
  /// 承诺专注时长直接采样，但设置娱乐限额下限保护休息需求。
  ContractRule generateRules(UserProfile profile, FutureGoal goal) {
    var entertainmentLimit = 90;

    final distractionTags = profile.personalityTags
        .where((t) => t == PersonalityTag.easilyDistracted ||
            t == PersonalityTag.threeMinutePassion ||
            t == PersonalityTag.phoneChecking)
        .length;
    entertainmentLimit -= distractionTags * 15;

    final entertainmentHabits = profile.badHabits
        .where((h) => h == BadHabit.shortVideo ||
            h == BadHabit.shortDrama ||
            h == BadHabit.doomScrolling ||
            h == BadHabit.bingeWatching)
        .length;
    entertainmentLimit -= entertainmentHabits * 10;

    entertainmentLimit -= (profile.estimatedScreenMinutes > 300 ? 30 : 0);

    if (entertainmentLimit < 30) entertainmentLimit = 30;

    return ContractRule(
      entertainmentDailyLimitMinutes: entertainmentLimit,
      focusDailyMinimumMinutes: goal.committedFocusMinutes,
    );
  }

  String generateSummary(UserProfile profile, FutureGoal goal, ContractRule rules) {
    final tagPart = profile.personalityTags.isEmpty
        ? '一个想变得更好的人'
        : '一个${profile.personalityTags.first.label}'
        '${profile.personalityTags.length > 1 ? '、容易${profile.personalityTags[1].label}' : ''}的人';
    final habitPart = profile.badHabits.isEmpty
        ? ''
        : '，${profile.badHabits.first.label}是你的老对手';
    final focusMin = rules.focusDailyMinimumMinutes;
    final limitMin = rules.entertainmentDailyLimitMinutes;
    final days = goal.targetDate.difference(DateTime.now()).inDays;

    return '曾经$tagPart$habitPart。'
        '而未来$days天后的你，要去「${goal.direction.label}」。'
        '所以现在的你决定：每天专注至少 $focusMin 分钟，'
        '娱乐 App 每天不超过 $limitMin 分钟。'
        '这是你对过去的告别，也是对未来的承诺。';
  }
}
