import '../../models/contract.dart';
import '../../state/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 便捷读取当前契约（若未签约返回 null）
final activeContractProvider = FutureProvider<Contract?>((ref) async {
  final storage = ref.watch(contractStorageProvider);
  return storage.load();
});
