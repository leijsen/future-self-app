import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../platform/screen_time_control.dart';

/// Built-in group templates (package names of common entertainment apps)
const _presetGroups = <AppGroupLimit>[
  AppGroupLimit(
    groupId: 'short_video',
    name: 'Short video',
    dailyLimitMinutes: 30,
    packageNames: [
      'com.smile.gifmaker',       // Kuaishou
      'com.ss.android.ugc.aweme', // Douyin
      'com.tencent.weishi',       // Weishi
      'xyz.appmaker.douyin',      // Douyin Huoshan
    ],
  ),
  AppGroupLimit(
    groupId: 'short_drama',
    name: 'Short drama',
    dailyLimitMinutes: 20,
    packageNames: [
      'com.dragon.read',          // Fanqie Novel (includes short dramas)
      'com.kuaishou.nebula',      // Hongguo Short Drama
    ],
  ),
  AppGroupLimit(
    groupId: 'game',
    name: 'Games',
    dailyLimitMinutes: 40,
    packageNames: [
      'com.tencent.tmgp.sgame',      // Honor of Kings
      'com.tencent.tmgp.pubgmhd',    // Peacekeeper Elite
      'com.netease.dwrg',            // Eggy Party
    ],
  ),
  AppGroupLimit(
    groupId: 'social',
    name: 'Social',
    dailyLimitMinutes: 60,
    packageNames: [
      'com.tencent.mm',   // WeChat
      'com.xingin.xhs',   // Xiaohongshu
      'com.sina.weibo',   // Weibo
      'com.tencent.mobileqq', // QQ
    ],
  ),
];

final appGroupsProvider =
    NotifierProvider<AppGroupsController, List<AppGroupLimit>>(
  AppGroupsController.new,
);

class AppGroupsController extends Notifier<List<AppGroupLimit>> {
  static const _boxName = 'app_groups';

  @override
  List<AppGroupLimit> build() {
    _load();
    return _presetGroups;
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    final enabled = box.get('enabled_group_ids',
        defaultValue: _presetGroups.map((g) => g.groupId).toList());
    final limitsRaw = Map<String, dynamic>.from(
        (box.get('limits') as Map?)?.cast<String, dynamic>() ?? {});
    state = [
      for (final g in _presetGroups)
        g.copyWithLimit(
          enabled ? enabled.contains(g.groupId) : true,
          limitsRaw[g.groupId] as int? ?? g.dailyLimitMinutes,
        ),
    ];
  }

  Future<void> toggleGroup(String groupId, bool value) async {
    state = [
      for (final g in state)
        if (g.groupId == groupId) g.copyWithLimit(value, g.dailyLimitMinutes) else g,
    ];
    final box = await Hive.openBox(_boxName);
    await box.put('enabled_group_ids',
        state.where((g) => (g as _EnabledAppGroupLimit).enabled).map((g) => g.groupId).toList());
    _syncToNative();
  }

  Future<void> updateLimit(String groupId, int minutes) async {
    state = [
      for (final g in state)
        if (g.groupId == groupId) g.copyWithLimit(true, minutes) else g,
    ];
    final box = await Hive.openBox(_boxName);
    final limits = Map<String, int>.from(
        (box.get('limits') as Map?)?.cast<String, int>() ?? {});
    limits[groupId] = minutes;
    await box.put('limits', limits);
    _syncToNative();
  }

  Future<void> _syncToNative() async {
    final control = ref.read(screenTimeControlProvider);
    await control.setAppLimits(
      state.where((g) => g is _EnabledAppGroupLimit && g.enabled).toList(),
    );
  }
}

extension on AppGroupLimit {
  AppGroupLimit copyWithLimit(bool enabled, int minutes) =>
      _EnabledAppGroupLimit(this, enabled, minutes);
}

class _EnabledAppGroupLimit extends AppGroupLimit {
  _EnabledAppGroupLimit(AppGroupLimit base, this.enabled, int minutes)
      : super(
          groupId: base.groupId,
          name: base.name,
          dailyLimitMinutes: minutes,
          packageNames: base.packageNames,
        );

  final bool enabled;
}

class LimitsPage extends ConsumerWidget {
  const LimitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(appGroupsProvider);
    final controller = ref.read(appGroupsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('App Limits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in groups) ...[
            if (g is _EnabledAppGroupLimit)
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(g.name),
                      subtitle: Text('${g.dailyLimitMinutes} min/day · '
                          '${g.packageNames.length} apps'),
                      value: g.enabled,
                      onChanged: (v) => controller.toggleGroup(g.groupId, v),
                    ),
                    if (g.enabled)
                      Slider(
                        value: g.dailyLimitMinutes.toDouble(),
                        min: 10,
                        max: 180,
                        divisions: 17,
                        label: '${g.dailyLimitMinutes} min',
                        onChanged: (v) =>
                            controller.updateLimit(g.groupId, v.round()),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Note: the package list is a preset template. Custom app selection is planned for the M3 iteration.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
