import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/contract.dart';
import '../../state/onboarding_controller.dart';

class ContractSignPage extends ConsumerStatefulWidget {
  const ContractSignPage({super.key});

  @override
  ConsumerState<ContractSignPage> createState() => _ContractSignPageState();
}

class _ContractSignPageState extends ConsumerState<ContractSignPage> {
  bool _signing = false;

  Future<void> _sign() async {
    setState(() => _signing = true);
    final controller = ref.read(onboardingProvider.notifier);
    final contract = controller.buildContract();
    await ref.read(contractStorageProvider).save(contract);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('你的自律契约')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.contractSummary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.8,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('提前退出专注时，你对自己多狠？',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final level in ExitChallengeLevel.values)
            RadioGroup<ExitChallengeLevel>(
              groupValue: state.exitChallengeLevel,
              onChanged: (v) => controller.setExitChallengeLevel(v!),
              child: RadioListTile<ExitChallengeLevel>(
                title: Text('第 ${level.level} 档'),
                subtitle: Text(level.description),
                value: level,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            '签署后，这份契约会真正约束你的手机使用。修改契约需要 24 小时冷静期。',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _signing ? null : _sign,
            child: _signing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('我，签署这份契约'),
          ),
        ],
      ),
    );
  }
}
