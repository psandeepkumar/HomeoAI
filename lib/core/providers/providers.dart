/// Riverpod Providers for dependency injection and state management
/// 
/// Centralizes all providers for database, repositories, and services

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../database/database.dart';
import '../repositories/repositories.dart';
import '../ai/grok_client.dart';
import '../ai/gemini_client.dart';

// ============================================================================
// DATABASE PROVIDER
// ============================================================================

/// Singleton database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PatientRepository(db);
});

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CaseRepository(db);
});

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SymptomRepository(db);
});

final physicalGeneralsRepositoryProvider = Provider<PhysicalGeneralsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PhysicalGeneralsRepository(db);
});

final mentalEmotionalRepositoryProvider = Provider<MentalEmotionalRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return MentalEmotionalRepository(db);
});

final remedySuggestionRepositoryProvider = Provider<RemedySuggestionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return RemedySuggestionRepository(db);
});

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FollowUpRepository(db);
});

// ============================================================================
// SHARED PREFERENCES PROVIDER
// ============================================================================

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ============================================================================
// AI PROVIDER CONFIGURATION (from .env file)
// ============================================================================

/// AI Provider enum
enum AIProvider {
  grok,
  gemini;

  static AIProvider fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'gemini':
        return AIProvider.gemini;
      case 'grok':
      default:
        return AIProvider.grok;
    }
  }
}

/// Current AI provider selection
final aiProviderSelectionProvider = Provider<AIProvider>((ref) {
  final providerName = dotenv.env['AI_PROVIDER'];
  return AIProvider.fromString(providerName);
});

/// Fetches Grok API key from environment variables
final grokApiKeyProvider = Provider<String?>((ref) {
  final apiKey = dotenv.env['GROK_API_KEY'];
  if (apiKey == null || apiKey.isEmpty || apiKey == 'your_grok_api_key_here') {
    return null;
  }
  return apiKey;
});

/// Fetches Gemini API key from environment variables
final geminiApiKeyProvider = Provider<String?>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
    return null;
  }
  return apiKey;
});

// ============================================================================
// AI CLIENT PROVIDERS
// ============================================================================

final grokClientProvider = Provider<GrokClient?>((ref) {
  final apiKey = ref.watch(grokApiKeyProvider);
  
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }
  return GrokClient(apiKey: apiKey);
});

final geminiClientProvider = Provider<GeminiClient?>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }
  return GeminiClient(apiKey: apiKey);
});

/// Active AI client based on selected provider
final activeAIClientProvider = Provider<dynamic>((ref) {
  final selectedProvider = ref.watch(aiProviderSelectionProvider);
  
  switch (selectedProvider) {
    case AIProvider.gemini:
      return ref.watch(geminiClientProvider);
    case AIProvider.grok:
      return ref.watch(grokClientProvider);
  }
});
