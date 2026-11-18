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
      appBar: AppBar(title: const Text('Future Self')),
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load contract: $e')),
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
                      Text('${contract.daysRemaining} days to your goal'),
                      const SizedBox(height: 12),
                      Text(
                        'Focus ≥ ${contract.rules.focusDailyMinimumMinutes} min/day · '
                        'Entertainment ≤ ${contract.rules.entertainmentDailyLimitMinutes} min/day',
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
        label: const Text('Start Focus'),
      ),
    );
  }
}

/// Usage Guard card: capability status, quota overview, entry point
class _UsageGuardCard extends ConsumerWidget {
  const _UsageGuardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilityAsync = ref.watch(capabilityProvider);
    final capability = capabilityAsync.value;

    final label = switch (capability) {
      ControlCapability.systemLevel => 'System-level blocking is on',
      ControlCapability.statisticsOnly => 'Statistics mode (accessibility not enabled)',
      ControlCapability.none => 'Guard not enabled',
      null => 'Detecting…',
    };
    final icon = switch (capability) {
      ControlCapability.systemLevel => Icons.verified_user,
      _ => Icons.shield_outlined,
    };

    return Card(
      child: ListTile(
        leading: Icon(icon, color: capability == ControlCapability.systemLevel
            ? Colors.green : Colors.orange),
        title: const Text('Usage Guard'),
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
                Text('Focus today', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '$minutes min',
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
