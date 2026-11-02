import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/control/permission_guide_page.dart';
import '../platform/screen_time_control.dart';
import '../state/active_contract_provider.dart';
import '../state/focus_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractAsync = ref.watch(activeContractProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('未来自我')),
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('读取契约失败: $e')),
        data: (contract) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (contract != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('「${contract.goal.direction.label}」',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('距目标还有 ${contract.daysRemaining} 天'),
                      const SizedBox(height: 12),
                      Text(
                        '每日专注 ≥ ${contract.rules.focusDailyMinimumMinutes} 分钟 · '
                        '娱乐 ≤ ${contract.rules.entertainmentDailyLimitMinutes} 分钟',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const _TodayFocusCard(),
            const SizedBox(height: 16),
            const _UsageGuardCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/focus'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始专注'),
      ),
    );
  }
}

/// 使用守护卡片：能力状态 + 额度概况 + 入口
class _UsageGuardCard extends ConsumerWidget {
  const _UsageGuardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(capabilityProvider);
    final capability = capabilityAsync.value;

    final label = switch (capability) {
      ControlCapability.systemLevel => '系统级拦截已开启',
      ControlCapability.statisticsOnly => '统计模式（未开无障碍）',
      ControlCapability.none => '未开启守护',
      null => '检测中…',
    };
    final icon = switch (capability) {
      ControlCapability.systemLevel => Icons.verified_user,
      _ => Icons.shield_outlined,
    };

    return Card(
      child: ListTile(
        leading: Icon(icon, color: capability == ControlCapability.systemLevel
            ? Colors.green : Colors.orange),
        title: const Text('使用守护'),
        subtitle: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(capability == ControlCapability.systemLevel
            ? '/limits'
            : '/permissions'),
      ),
    );
  }
}

class _TodayFocusCard extends ConsumerWidget {
  const _TodayFocusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: FocusStats.todayFocusedMinutes(),
      builder: (context, snapshot) {
        final minutes = snapshot.data ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日专注', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '$minutes 分钟',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
