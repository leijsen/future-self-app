import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('未来自我')),
      body: const Center(
        child: Text('契约已签署，M2 将在此展示今日进度。'),
      ),
    );
  }
}
