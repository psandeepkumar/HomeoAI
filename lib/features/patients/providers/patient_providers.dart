/// Patient list and management providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/providers/providers.dart';

// ============================================================================
// PATIENT LIST PROVIDER
// ============================================================================

final patientListProvider = FutureProvider<List<Patient>>((ref) async {
  final repo = ref.watch(patientRepositoryProvider);
  return await repo.getAllPatients();
});

// ============================================================================
// PATIENT DETAIL PROVIDER
// ============================================================================

final patientDetailProvider = FutureProvider.family<Patient?, String>((ref, patientId) async {
  final repo = ref.watch(patientRepositoryProvider);
  return await repo.getPatientById(patientId);
});

// ============================================================================
// PATIENT CASES PROVIDER
// ============================================================================

final patientCasesProvider = FutureProvider.family<List<Case>, String>((ref, patientId) async {
  final repo = ref.watch(caseRepositoryProvider);
  return await repo.getCasesForPatient(patientId);
});

// ============================================================================
// PATIENT SEARCH PROVIDER
// ============================================================================

final patientSearchProvider = FutureProvider.family<List<Patient>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(patientListProvider).value ?? [];
  }
  final repo = ref.watch(patientRepositoryProvider);
  return await repo.searchPatients(query);
});

// ============================================================================
// RECENT CASES PROVIDER (for home screen)
// ============================================================================

final recentCasesProvider = FutureProvider<List<Case>>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  return await repo.getRecentCases(limit: 10);
});
