/// Grok AI Client for xAI API integration
/// 
/// Handles all communication with the Grok API including:
/// - Request construction with proper prompts
/// - Rate limiting and retry logic
/// - Response parsing and validation
/// - Error handling and user feedback

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grok_prompts.dart';

/// Configuration for Grok API
class GrokConfig {
  static const String baseUrl = 'https://api.x.ai/v1';
  static const String chatCompletionsEndpoint = '/chat/completions';
  static const String defaultModel = 'grok-beta';
  static const int defaultMaxTokens = 4096;
  static const double defaultTemperature = 0.3; // Lower for clinical precision
  static const Duration timeout = Duration(seconds: 60);
  static const int maxRetries = 3;
}

/// Exception types for Grok API errors
class GrokException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;

  GrokException(this.message, {this.statusCode, this.type});

  @override
  String toString() => 'GrokException: $message (status: $statusCode, type: $type)';
}

/// Response model for Grok API
class GrokResponse {
  final String id;
  final String content;
  final int? tokensUsed;
  final Map<String, dynamic>? metadata;

  GrokResponse({
    required this.id,
    required this.content,
    this.tokensUsed,
    this.metadata,
  });

  /// Parse content as JSON (for structured responses)
  Map<String, dynamic>? get jsonContent {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

/// Main Grok Client service
class GrokClient {
  final Dio _dio;
  final String _apiKey;
  int _requestCount = 0;
  DateTime? _lastRequestTime;

  GrokClient({
    required String apiKey,
    Dio? dio,
  })  : _apiKey = apiKey,
        _dio = dio ?? _createDio(apiKey);

  static Dio _createDio(String apiKey) {
    final dio = Dio(BaseOptions(
      baseUrl: GrokConfig.baseUrl,
      connectTimeout: GrokConfig.timeout,
      receiveTimeout: GrokConfig.timeout,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[GrokClient] $obj'),
    ));

    return dio;
  }

  /// Rate limiting check (simple client-side throttle)
  Future<void> _checkRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inMilliseconds < 500) {
        // Min 500ms between requests
        await Future.delayed(Duration(milliseconds: 500 - timeSinceLastRequest.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();
    _requestCount++;
  }

  /// Core API call method with retry logic
  Future<GrokResponse> _callAPI({
    required String userPrompt,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    await _checkRateLimit();

    final messages = <Map<String, String>>[];
    
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    
    messages.add({'role': 'user', 'content': userPrompt});

    final requestBody = {
      'model': GrokConfig.defaultModel,
      'messages': messages,
      'temperature': temperature ?? GrokConfig.defaultTemperature,
      'max_tokens': maxTokens ?? GrokConfig.defaultMaxTokens,
    };

    for (int attempt = 0; attempt < GrokConfig.maxRetries; attempt++) {
      try {
        final response = await _dio.post(
          GrokConfig.chatCompletionsEndpoint,
          data: requestBody,
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          final choices = data['choices'] as List;
          
          if (choices.isEmpty) {
            throw GrokException('No response choices returned');
          }

          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          final usage = data['usage'] as Map<String, dynamic>?;

          return GrokResponse(
            id: data['id'] as String,
            content: content.trim(),
            tokensUsed: usage?['total_tokens'] as int?,
            metadata: data,
          );
        } else {
          throw GrokException(
            'Unexpected status code: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        // Check for credit exhaustion error (429 with specific message)
        if (e.response?.statusCode == 429) {
          final errorBody = e.response?.data;
          if (errorBody is Map && errorBody['error']?.toString().contains('exhausted') == true) {
            throw GrokException(
              'API Credits Exhausted: Your Grok API account has run out of credits. Please visit https://x.ai/ to purchase more credits or check your spending limit.',
              statusCode: 429,
              type: 'CREDITS_EXHAUSTED',
            );
          }
          
          // Regular rate limiting - wait and retry
          final retryAfter = e.response?.headers.value('retry-after');
          final waitSeconds = int.tryParse(retryAfter ?? '5') ?? 5;
          
          if (attempt < GrokConfig.maxRetries - 1) {
            await Future.delayed(Duration(seconds: waitSeconds));
            continue;
          }
          
          throw GrokException(
            'Rate limit exceeded. Please wait a moment and try again.',
            statusCode: 429,
            type: 'RATE_LIMITED',
          );
        }

        if (attempt == GrokConfig.maxRetries - 1) {
          throw GrokException(
            e.message ?? 'API request failed',
            statusCode: e.response?.statusCode,
            type: e.type.toString(),
          );
        }

        // Exponential backoff for other errors
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      } catch (e) {
        if (attempt == GrokConfig.maxRetries - 1) {
          throw GrokException('Unexpected error: $e');
        }
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }

    throw GrokException('Max retries exceeded');
  }

  // =========================================================================
  // PUBLIC API METHODS
  // =========================================================================

  /// Analyze spontaneous narrative and extract themes
  Future<Map<String, dynamic>> analyzeSpontaneousNarrative({
    required String narrative,
    String? patientAge,
    String? patientGender,
  }) async {
    final prompt = GrokPrompts.analyzeSpontaneousNarrative(
      narrative: narrative,
      patientAge: patientAge,
      patientGender: patientGender,
    );

    final response = await _callAPI(
      systemPrompt: GrokPrompts.systemPrompt,
      userPrompt: prompt,
    );

    final json = response.jsonContent;
    if (json == null) {
      throw GrokException('Failed to parse JSON response from Grok');
    }

    return json;
  }

  /// Highlight Strange, Rare, Peculiar (SRP) symptoms
  Future<Map<String, dynamic>> highlightPeculiarSymptoms({
    required List<String> symptoms,
  }) async {
    if (symptoms.isEmpty) {
      return {
        'srpSymptoms': [],
        'commonSymptoms': [],
        'analysis': 'No symptoms provided for analysis.',
      };
    }

    final prompt = GrokPrompts.highlightPeculiarSymptoms(symptoms: symptoms);

    final response = await _callAPI(
      systemPrompt: GrokPrompts.systemPrompt,
      userPrompt: prompt,
    );

    final json = response.jsonContent;
    if (json == null) {
      throw GrokException('Failed to parse JSON response from Grok');
    }

    return json;
  }

  /// Perform complete case analysis and repertorization
  Future<Map<String, dynamic>> analyzeCase({
    required String spontaneousNarrative,
    required List<SymptomData> chiefComplaints,
    required Map<String, dynamic> physicalGenerals,
    required Map<String, dynamic> mentalEmotional,
    required List<String> selectedKeySymptoms,
  }) async {
    final prompt = GrokPrompts.analyzeCase(
      spontaneousNarrative: spontaneousNarrative,
      chiefComplaints: chiefComplaints,
      physicalGenerals: physicalGenerals,
      mentalEmotional: mentalEmotional,
      selectedKeySymptoms: selectedKeySymptoms,
    );

    final response = await _callAPI(
      systemPrompt: GrokPrompts.systemPrompt,
      userPrompt: prompt,
      maxTokens: 8192, // Larger response needed for full analysis
    );

    final json = response.jsonContent;
    if (json == null) {
      throw GrokException('Failed to parse JSON response from Grok');
    }

    return json;
  }

  /// Compare specific remedies in differential
  Future<Map<String, dynamic>> compareRemedies({
    required List<String> remedies,
    required String patientPortrait,
    required List<String> keySymptoms,
  }) async {
    if (remedies.isEmpty) {
      throw GrokException('No remedies provided for comparison');
    }

    final prompt = GrokPrompts.compareRemedies(
      remedies: remedies,
      patientPortrait: patientPortrait,
      keySymptoms: keySymptoms,
    );

    final response = await _callAPI(
      systemPrompt: GrokPrompts.systemPrompt,
      userPrompt: prompt,
    );

    final json = response.jsonContent;
    if (json == null) {
      throw GrokException('Failed to parse JSON response from Grok');
    }

    return json;
  }

  /// Suggest follow-up questions
  Future<Map<String, dynamic>> suggestFollowUpQuestions({
    required String currentData,
    required List<String> missingAreas,
  }) async {
    final prompt = GrokPrompts.suggestFollowUpQuestions(
      currentData: currentData,
      missingAreas: missingAreas,
    );

    final response = await _callAPI(
      systemPrompt: GrokPrompts.systemPrompt,
      userPrompt: prompt,
    );

    final json = response.jsonContent;
    if (json == null) {
      throw GrokException('Failed to parse JSON response from Grok');
    }

    return json;
  }

  /// Get client statistics
  Map<String, dynamic> getStats() {
    return {
      'totalRequests': _requestCount,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
    };
  }
}

/// Riverpod provider for GrokClient
/// API key should be fetched from secure storage
final grokClientProvider = Provider<GrokClient>((ref) {
  // TODO: Replace with actual API key from secure storage
  const apiKey = String.fromEnvironment('GROK_API_KEY', defaultValue: '');
  
  if (apiKey.isEmpty) {
    throw Exception('GROK_API_KEY not configured. Add it to secure storage.');
  }

  return GrokClient(apiKey: apiKey);
});
