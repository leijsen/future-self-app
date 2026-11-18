import '../../models/contract.dart';
import '../../state/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Convenience accessor for the current contract (null when unsigned)
final activeContractProvider = FutureProvider<Contract?>((ref) async {
  final storage = ref.watch(contractStorageProvider);
  return storage.load();
});
