import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/contract.dart';
import '../contract/contract_engine.dart';

class OnboardingState {
  const OnboardingState({
    this.personalityTags = const [],
    this.badHabits = const [],
    this.estimatedScreenMinutes = 120,
    this.direction,
    this.targetDate,
    this.committedFocusMinutes = 45,
    this.exitChallengeLevel = ExitChallengeLevel.firm,
  });

  final List<PersonalityTag> personalityTags;
  final List<BadHabit> badHabits;
  final int estimatedScreenMinutes;
  final GoalDirection? direction;
  final DateTime? targetDate;
  final int committedFocusMinutes;
  final ExitChallengeLevel exitChallengeLevel;

  OnboardingState copyWith({
    List<PersonalityTag>? personalityTags,
    List<BadHabit>? badHabits,
    int? estimatedScreenMinutes,
    GoalDirection? direction,
    DateTime? targetDate,
    int? committedFocusMinutes,
    ExitChallengeLevel? exitChallengeLevel,
  }) {
    return OnboardingState(
      personalityTags: personalityTags ?? this.personalityTags,
      badHabits: badHabits ?? this.badHabits,
      estimatedScreenMinutes: estimatedScreenMinutes ?? this.estimatedScreenMinutes,
      direction: direction ?? this.direction,
      targetDate: targetDate ?? this.targetDate,
      committedFocusMinutes: committedFocusMinutes ?? this.committedFocusMinutes,
      exitChallengeLevel: exitChallengeLevel ?? this.exitChallengeLevel,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  final _engine = ContractEngine();

  @override
  OnboardingState build() => const OnboardingState();

  void toggleTag(PersonalityTag tag) {
    final tags = List.of(state.personalityTags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    state = state.copyWith(personalityTags: tags);
  }

  void toggleHabit(BadHabit habit) {
    final habits = List.of(state.badHabits);
    habits.contains(habit) ? habits.remove(habit) : habits.add(habit);
    state = state.copyWith(badHabits: habits);
  }

  void setEstimatedScreenMinutes(int minutes) =>
      state = state.copyWith(estimatedScreenMinutes: minutes);

  void setDirection(GoalDirection direction) =>
      state = state.copyWith(direction: direction);

  void setTargetDate(DateTime date) =>
      state = state.copyWith(targetDate: date);

  void setCommittedFocusMinutes(int minutes) =>
      state = state.copyWith(committedFocusMinutes: minutes);

  void setExitChallengeLevel(ExitChallengeLevel level) =>
      state = state.copyWith(exitChallengeLevel: level);

  Contract buildContract() {
    final profile = UserProfile(
      personalityTags: state.personalityTags,
      badHabits: state.badHabits,
      estimatedScreenMinutes: state.estimatedScreenMinutes,
    );
    final goal = FutureGoal(
      direction: state.direction ?? GoalDirection.skillLearning,
      targetDate: state.targetDate ?? DateTime.now().add(const Duration(days: 180)),
      committedFocusMinutes: state.committedFocusMinutes,
    );
    final rules = _engine.generateRules(profile, goal);

    return Contract(
      signedAt: DateTime.now(),
      profile: profile,
      goal: goal,
      rules: rules,
      exitChallengeLevel: state.exitChallengeLevel,
    );
  }

  String get contractSummary {
    final contract = buildContract();
    return _engine.generateSummary(contract.profile, contract.goal, contract.rules);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

final contractEngineProvider = Provider((_) => ContractEngine());

class ContractStorage {
  static const _boxName = 'contract_box';

  Future<void> save(Contract contract) async {
    final box = await Hive.openBox(_boxName);
    await box.put('active_contract', _encodeContract(contract));
    await box.put('signed', true);
  }

  Future<Contract?> load() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('active_contract');
    if (raw == null) return null;
    return _decodeContract(Map<String, dynamic>.from(raw));
  }

  Future<bool> hasSigned() async {
    final box = await Hive.openBox(_boxName);
    return box.get('signed') == true;
  }

  Map<String, dynamic> _encodeContract(Contract c) => {
    'signedAt': c.signedAt.toIso8601String(),
    'personalityTags': c.profile.personalityTags.map((t) => t.name).toList(),
    'badHabits': c.profile.badHabits.map((h) => h.name).toList(),
    'estimatedScreenMinutes': c.profile.estimatedScreenMinutes,
    'direction': c.goal.direction.name,
    'targetDate': c.goal.targetDate.toIso8601String(),
    'committedFocusMinutes': c.goal.committedFocusMinutes,
    'entertainmentLimit': c.rules.entertainmentDailyLimitMinutes,
    'focusMinimum': c.rules.focusDailyMinimumMinutes,
    'exitChallengeLevel': c.exitChallengeLevel.name,
  };

  Contract _decodeContract(Map<String, dynamic> m) => Contract(
    signedAt: DateTime.parse(m['signedAt']),
    profile: UserProfile(
      personalityTags: (m['personalityTags'] as List)
          .map((t) => PersonalityTag.values.byName(t))
          .toList(),
      badHabits: (m['badHabits'] as List)
          .map((h) => BadHabit.values.byName(h))
          .toList(),
      estimatedScreenMinutes: m['estimatedScreenMinutes'] as int,
    ),
    goal: FutureGoal(
      direction: GoalDirection.values.byName(m['direction']),
      targetDate: DateTime.parse(m['targetDate']),
      committedFocusMinutes: m['committedFocusMinutes'] as int,
    ),
    rules: ContractRule(
      entertainmentDailyLimitMinutes: m['entertainmentLimit'] as int,
      focusDailyMinimumMinutes: m['focusMinimum'] as int,
    ),
    exitChallengeLevel: ExitChallengeLevel.values.byName(m['exitChallengeLevel']),
  );
}

final contractStorageProvider = Provider((_) => ContractStorage());
