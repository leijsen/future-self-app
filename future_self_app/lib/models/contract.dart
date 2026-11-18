enum PersonalityTag {
  procrastination('prone to procrastinating'),
  easilyDistracted('easily distracted'),
  threeMinutePassion('quick to lose interest'),
  nightOwl('a night owl'),
  revengeBedtime('stuck in revenge bedtime scrolling'),
  socialDependency('overly reliant on social media'),
  impulsiveness('an impulse spender'),
  perfectionistDelay('a perfectionist who stalls'),
  anxiety('prone to anxiety'),
  phoneChecking('constantly unlocking the phone');

  const PersonalityTag(this.label);
  final String label;
}

enum BadHabit {
  shortVideo('scrolling short videos'),
  shortDrama('binging short dramas'),
  lateNightGaming('gaming late at night'),
  doomScrolling('doomscrolling feeds'),
  bingeWatching('unable to stop binge-watching'),
  endlessShopping('endlessly browsing shopping apps'),
  gossipReading('chasing gossip nonstop'),
  messageChecking('checking messages over and over');

  const BadHabit(this.label);
  final String label;
}

class UserProfile {
  const UserProfile({
    required this.personalityTags,
    required this.badHabits,
    required this.estimatedScreenMinutes,
  });

  final List<PersonalityTag> personalityTags;
  final List<BadHabit> badHabits;
  final int estimatedScreenMinutes;
}

enum GoalDirection {
  certification('pass a certification exam'),
  fitness('get in shape'),
  english('learn English'),
  reading('build a reading habit'),
  sideProject('launch a side project'),
  skillLearning('learn a new skill');

  const GoalDirection(this.label);
  final String label;
}

class FutureGoal {
  const FutureGoal({
    required this.direction,
    required this.targetDate,
    required this.committedFocusMinutes,
  });

  final GoalDirection direction;
  final DateTime targetDate;
  final int committedFocusMinutes;
}

enum ExitChallengeLevel {
  gentle(1, 'Confirm in a dialog to exit'),
  firm(2, 'Type the words you wrote to yourself'),
  strict(3, 'Wait out a forced 60-second countdown');

  const ExitChallengeLevel(this.level, this.description);
  final int level;
  final String description;
}

class ContractRule {
  const ContractRule({
    required this.entertainmentDailyLimitMinutes,
    required this.focusDailyMinimumMinutes,
  });

  final int entertainmentDailyLimitMinutes;
  final int focusDailyMinimumMinutes;
}

class Contract {
  const Contract({
    required this.signedAt,
    required this.profile,
    required this.goal,
    required this.rules,
    required this.exitChallengeLevel,
  });

  final DateTime signedAt;
  final UserProfile profile;
  final FutureGoal goal;
  final ContractRule rules;
  final ExitChallengeLevel exitChallengeLevel;

  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  DateTime get targetDate => goal.targetDate;
}
