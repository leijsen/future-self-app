import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../platform/screen_time_control.dart';

/// 内置分组模板（常见国内娱乐应用包名）
const _presetGroups = <AppGroupLimit>[
  AppGroupLimit(
    groupId: 'short_video',
    name: '短视频',
    dailyLimitMinutes: 30,
    packageNames: [
      'com.smile.gifmaker',       // 快手
      'com.ss.android.ugc.aweme', // 抖音
      'com.tencent.weishi',       // 微视
      'xyz.appmaker.douyin',      // 抖音火山版
    ],
  ),
  AppGroupLimit(
    groupId: 'short_drama',
    name: '短剧',
    dailyLimitMinutes: 20,
    packageNames: [
      'com.dragon.read',          // 番茄小说(含短剧)
      'com.kuaishou.nebula',      // 红果短剧
    ],
  ),
  AppGroupLimit(
    groupId: 'game',
    name: '游戏',
    dailyLimitMinutes: 40,
    packageNames: [
      'com.tencent.tmgp.sgame',      // 王者荣耀
      'com.tencent.tmgp.pubgmhd',    // 和平精英
      'com.netease.dwrg',            // 蛋仔派对
    ],
  ),
  AppGroupLimit(
    groupId: 'social',
    name: '社交娱乐',
    dailyLimitMinutes: 60,
    packageNames: [
      'com.tencent.mm',   // 微信
      'com.xingin.xhs',   // 小红书
      'com.sina.weibo',   // 微博
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
      appBar: AppBar(title: const Text('应用限额')),
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
                      subtitle: Text('每日 ${g.dailyLimitMinutes} 分钟 · '
                          '${g.packageNames.length} 个应用'),
                      value: g.enabled,
                      onChanged: (v) => controller.toggleGroup(g.groupId, v),
                    ),
                    if (g.enabled)
                      Slider(
                        value: g.dailyLimitMinutes.toDouble(),
                        min: 10,
                        max: 180,
                        divisions: 17,
                        label: '${g.dailyLimitMinutes} 分钟',
                        onChanged: (v) =>
                            controller.updateLimit(g.groupId, v.round()),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          const Text(
            '提示：包名列表为预设模板，可在 M3 迭代中支持自定义添加应用。',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
