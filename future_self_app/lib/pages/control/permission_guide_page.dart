import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../platform/screen_time_control.dart';

/// 能力探测 + 权限引导页。
/// Android: 引导开启「使用情况访问」与「无障碍服务」。
final capabilityProvider = FutureProvider<ControlCapability>((ref) async {
  final control = ref.watch(screenTimeControlProvider);
  return control.probeCapability();
});

class PermissionGuidePage extends ConsumerWidget {
  const PermissionGuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(capabilityProvider);
    final capability = capabilityAsync.value;

    final doneUsage = capability == ControlCapability.systemLevel ||
        capability == ControlCapability.statisticsOnly;
    final doneAccessibility = capability == ControlCapability.systemLevel;

    return Scaffold(
      appBar: AppBar(title: const Text('开启使用守护')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '只有开启这两个权限，App 才能真正替你拦住那些偷时间的应用。\n'
            '所有数据仅保存在本机。',
          ),
          const SizedBox(height: 24),
          _PermissionStep(
            index: 1,
            title: '使用情况访问权限',
            subtitle: '用于统计各应用每日使用时长',
            done: doneUsage,
          ),
          _PermissionStep(
            index: 2,
            title: '无障碍服务（未来自我 · 使用守护）',
            subtitle: '用于在应用额度用完时弹出拦截页',
            done: doneAccessibility,
          ),
          const SizedBox(height: 24),
          if (capability != null && capability != ControlCapability.systemLevel)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => ref.invalidate(capabilityProvider),
                  child: const Text('我已开启，重新检测'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/limits'),
                  child: const Text('暂时跳过（仅统计/演示模式）'),
                ),
              ],
            )
          else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text('守护已就绪！', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/limits'),
              child: const Text('去设置应用限额'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          color: done ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: done
            ? null
            : const Icon(Icons.chevron_right),
        onTap: done ? null : () => _openSettings(context),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    // 引导文案：真实跳转在原生插件收尾时实现，当前版本请用户手动前往设置
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 1
              ? '请前往：设置 → 安全 → 使用情况访问 → 允许「未来自我」'
              : '请前往：设置 → 无障碍 → 「未来自我 · 使用守护」并开启',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
