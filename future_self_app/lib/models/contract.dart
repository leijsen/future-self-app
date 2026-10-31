enum PersonalityTag {
  procrastination('拖延'),
  easilyDistracted('易分心'),
  threeMinutePassion('三分钟热度'),
  nightOwl('晚睡强迫'),
  revengeBedtime('报复性熬夜'),
  socialDependency('社交依赖'),
  impulsiveness('冲动消费'),
  perfectionistDelay('完美主义拖延'),
  anxiety('容易焦虑'),
  phoneChecking('反复解锁手机');

  const PersonalityTag(this.label);
  final String label;
}

enum BadHabit {
  shortVideo('刷短视频'),
  shortDrama('追短剧'),
  lateNightGaming('熬夜打游戏'),
  doomScrolling('无目的刷信息流'),
  bingeWatching('追剧停不下来'),
  endlessShopping('逛购物App'),
  gossipReading('吃瓜不停'),
  messageChecking('反复看消息');

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
  certification('考证上岸'),
  fitness('健身塑形'),
  english('学英语'),
  reading('读书积累'),
  sideProject('做副业'),
  skillLearning('学新技能');

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
  gentle(1, '确认弹窗即可退出'),
  firm(2, '输入一段自己写给自己的话'),
  strict(3, '强制等待 60 秒倒计时');

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
