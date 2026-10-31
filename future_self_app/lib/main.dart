import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/home_page.dart';
import 'pages/onboarding/past_self_page.dart';
import 'pages/onboarding/future_self_page.dart';
import 'pages/onboarding/contract_sign_page.dart';
import 'state/onboarding_controller.dart';

Future<void> main() async {
  await Hive.initFlutter();
  runApp(const ProviderScope(child: FutureSelfApp()));
}

class FutureSelfApp extends ConsumerWidget {
  const FutureSelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '未来自我',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(contractStorageProvider);

  return GoRouter(
    initialLocation: '/onboarding/past',
    redirect: (context, state) async {
      final hasSigned = await storage.hasSigned();
      final inOnboarding = state.matchedLocation.startsWith('/onboarding');
      if (!hasSigned && !inOnboarding) return '/onboarding/past';
      if (hasSigned && inOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding/past',
        builder: (_, _) => const PastSelfPage(),
      ),
      GoRoute(
        path: '/onboarding/future',
        builder: (_, _) => const FutureSelfPage(),
      ),
      GoRoute(
        path: '/onboarding/contract',
        builder: (_, _) => const ContractSignPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomePage(),
      ),
    ],
  );
});
