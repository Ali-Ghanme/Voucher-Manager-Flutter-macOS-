import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/voucher_repository_impl.dart';
import '../../domain/repositories/voucher_repository.dart';

/// Singleton repository instance shared across the app.
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  return VoucherRepositoryImpl();
});

/// Convenience provider exposing the concrete impl when UI needs the
/// extra `canUndo` getter that isn't part of the abstract contract.
final voucherRepositoryImplProvider = Provider<VoucherRepositoryImpl>((ref) {
  return ref.watch(voucherRepositoryProvider) as VoucherRepositoryImpl;
});

/// Tracks whether the app is currently in "Compact Floating Mode".
final isCompactModeProvider = StateProvider<bool>((ref) => false);
