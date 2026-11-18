import '../models/contract.dart';

class ContractEngine {
  /// Generate contract rules from the user profile and goal.
  /// Rules: more distraction tags and entertainment habits tighten the entertainment limit;
  /// the committed focus duration is used as-is, with a floor on the entertainment limit to protect rest.
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
        ? 'a person who wants to get better'
        : 'a person who is ${profile.personalityTags.first.label}'
        '${profile.personalityTags.length > 1 ? ' and ${profile.personalityTags[1].label}' : ''}';
    final habitPart = profile.badHabits.isEmpty
        ? ''
        : ', and ${profile.badHabits.first.label} is an old enemy of yours';
    final focusMin = rules.focusDailyMinimumMinutes;
    final limitMin = rules.entertainmentDailyLimitMinutes;
    final days = goal.targetDate.difference(DateTime.now()).inDays;

    return 'Once, you were $tagPart$habitPart. '
        'And $days days from now, you want to reach "${goal.direction.label}". '
        'So the you of today decides: focus for at least $focusMin minutes every day, '
        'and spend no more than $limitMin minutes a day on entertainment apps. '
        'This is your farewell to the past, and your promise to the future.';
  }
}
