import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../platform/screen_time_control.dart';

/// Capability probe and permission guide page.
/// Android: guides the user to enable Usage Access and the Accessibility Service.
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
      appBar: AppBar(title: const Text('Enable Usage Guard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Only with these two permissions can the app actually block the apps that steal your time.\n'
            'All data stays on this device.',
          ),
          const SizedBox(height: 24),
          _PermissionStep(
            index: 1,
            title: 'Usage Access',
            subtitle: 'Used to measure daily time spent in each app',
            done: doneUsage,
          ),
          _PermissionStep(
            index: 2,
            title: 'Accessibility Service (Future Self · Usage Guard)',
            subtitle: 'Used to show the block page when an app runs out of its quota',
            done: doneAccessibility,
          ),
          const SizedBox(height: 24),
          if (capability != null && capability != ControlCapability.systemLevel)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => ref.invalidate(capabilityProvider),
                  child: const Text('I enabled them - re-check'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/limits'),
                  child: const Text('Skip for now (stats / demo mode only)'),
                ),
              ],
            )
          else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text('Guard is ready!', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/limits'),
              child: const Text('Set app limits'),
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
    // Guide copy: deep-linking to Settings lands with the native plugin; for now the user goes there manually
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 1
              ? 'Go to: Settings -> Security -> Usage Access -> allow "Future Self"'
              : 'Go to: Settings -> Accessibility -> "Future Self · Usage Guard" and turn it on',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
