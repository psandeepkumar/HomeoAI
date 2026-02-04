/// Gemini AI Client for Google AI Studio API integration
/// 
/// Handles all communication with the Gemini API including:
/// - Request construction with proper prompts
/// - Response parsing and validation
/// - Error handling and user feedback

import 'dart:convert';
import 'package:dio/dio.dart';

/// Configuration for Gemini API
class GeminiConfig {
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String defaultModel = 'gemini-1.5-flash';
  static const Duration timeout = Duration(seconds: 60);
  static const int maxRetries = 3;
}

/// Exception types for Gemini API errors
class GeminiException implements Exception {
  final String message;
  final int? statusCode;
  final String? type;

  GeminiException(this.message, {this.statusCode, this.type});

  @override
  String toString() => 'GeminiException: $message (status: $statusCode, type: $type)';
}

/// Response model for Gemini API
class GeminiResponse {
  final String content;
  final Map<String, dynamic>? metadata;

  GeminiResponse({
    required this.content,
    this.metadata,
  });

  /// Parse content as JSON (for structured responses)
  Map<String, dynamic>? get jsonContent {
    try {
      // Remove markdown code blocks if present
      String cleanContent = content.trim();
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      }
      if (cleanContent.startsWith('```')) {
        cleanContent = cleanContent.substring(3);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      return jsonDecode(cleanContent.trim()) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

/// Main Gemini Client service
class GeminiClient {
  final Dio _dio;
  final String _apiKey;
  final String _model;
  int _requestCount = 0;
  DateTime? _lastRequestTime;

  GeminiClient({
    required String apiKey,
    String model = GeminiConfig.defaultModel,
    Dio? dio,
  })  : _apiKey = apiKey,
        _model = model,
        _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: GeminiConfig.baseUrl,
      connectTimeout: GeminiConfig.timeout,
      receiveTimeout: GeminiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[GeminiClient] $obj'),
    ));

    return dio;
  }

  /// Rate limiting check (simple client-side throttle)
  Future<void> _checkRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inMilliseconds < 500) {
        await Future.delayed(
          Duration(milliseconds: 500 - timeSinceLastRequest.inMilliseconds),
        );
      }
    }
    _lastRequestTime = DateTime.now();
    _requestCount++;
  }

  /// Generate content using Gemini
  Future<GeminiResponse> generateContent({
    required String prompt,
    double? temperature,
    int? maxTokens,
  }) async {
    await _checkRateLimit();

    try {
      final response = await _dio.post(
        '/models/$_model:generateContent',
        queryParameters: {
          'key': _apiKey,
        },
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            if (temperature != null) 'temperature': temperature,
            if (maxTokens != null) 'maxOutputTokens': maxTokens,
          },
        },
      );

      if (response.statusCode != 200) {
        throw GeminiException(
          'API request failed',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException('No response generated');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List;
      final text = parts[0]['text'] as String;

      return GeminiResponse(
        content: text,
        metadata: data['usageMetadata'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw GeminiException('Unexpected error: $e');
    }
  }

  /// Analyze homeopathic case
  Future<Map<String, dynamic>> analyzeCase({
    required String caseData,
    required String analysisType,
  }) async {
    final prompt = _buildCaseAnalysisPrompt(caseData, analysisType);
    
    final response = await generateContent(
      prompt: prompt,
      temperature: 0.3,
      maxTokens: 4096,
    );

    final jsonContent = response.jsonContent;
    if (jsonContent == null) {
      throw GeminiException('Failed to parse JSON response');
    }

    return jsonContent;
  }

  String _buildCaseAnalysisPrompt(String caseData, String analysisType) {
    switch (analysisType) {
      case 'portrait':
        return '''You are an expert classical homeopath. Analyze this case and create a patient portrait.

Case Data:
$caseData

Provide a JSON response with this structure:
{
  "portrait": "A narrative description of the patient's constitutional picture, mental/emotional state, and physical characteristics",
  "clarifyingQuestions": ["Question 1", "Question 2", "Question 3"],
  "peculiarSymptoms": ["Peculiar symptom 1", "Peculiar symptom 2"],
  "keySymptoms": ["Key symptom 1", "Key symptom 2", "Key symptom 3"]
}

Focus on strange, rare, and peculiar symptoms. Be concise and clinical.''';

      case 'repertorization':
        return '''You are an expert classical homeopath. Analyze this case and suggest remedies based on symptom repertorization.

Case Data:
$caseData

Provide a JSON response with this structure:
{
  "remedies": [
    {
      "remedy": "Remedy name",
      "grade": "A/B/C",
      "confidence": 85,
      "matchingSymptoms": ["Symptom 1", "Symptom 2"],
      "differentiatingFeatures": "What makes this remedy stand out",
      "materiaComparison": "Brief materia medica comparison"
    }
  ]
}

Provide top 5 remedies. Grade A for best match, B for good match, C for possible match.''';

      default:
        return caseData;
    }
  }

  GeminiException _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'API error';
      if (data is Map && data['error'] != null) {
        message = data['error']['message'] ?? message;
      }

      return GeminiException(
        message,
        statusCode: statusCode,
        type: 'api_error',
      );
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return GeminiException('Request timeout', type: 'timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return GeminiException('Connection error', type: 'network');
    } else {
      return GeminiException('Unknown error: ${e.message}');
    }
  }

  /// Get current request count
  int get requestCount => _requestCount;

  /// Reset request count (useful for testing/monitoring)
  void resetRequestCount() {
    _requestCount = 0;
  }
}
