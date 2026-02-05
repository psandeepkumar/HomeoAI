/// State providers for case wizard functionality
/// Manages form data, auto-save, and AI analysis

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/repositories/repositories.dart';
import '../../../core/ai/grok_prompts.dart';
import '../../../core/ai/grok_client.dart' show GrokClient;
import '../../../core/providers/providers.dart';

part 'case_wizard_provider.g.dart';

// ============================================================================
// CASE WIZARD STATE
// ============================================================================

class CaseWizardState {
  final String? caseId;
  final String patientId;
  final Map<String, dynamic> formData;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? aiAnalysis;

  CaseWizardState({
    this.caseId,
    required this.patientId,
    this.formData = const {},
    this.isLoading = false,
    this.error,
    this.aiAnalysis,
  });

  CaseWizardState copyWith({
    String? caseId,
    String? patientId,
    Map<String, dynamic>? formData,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? aiAnalysis,
  }) {
    return CaseWizardState(
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }
}

// ============================================================================
// CASE WIZARD PROVIDER
// ============================================================================

@riverpod
class CaseWizard extends _$CaseWizard {
  late final CaseRepository _caseRepo;
  late final SymptomRepository _symptomRepo;
  late final PhysicalGeneralsRepository _generalsRepo;
  late final MentalEmotionalRepository _mentalRepo;
  late final RemedySuggestionRepository _remedyRepo;
  late final dynamic _aiClient; // Can be GrokClient or GeminiClient

  @override
  CaseWizardState build(String patientId) {
    _caseRepo = ref.watch(caseRepositoryProvider);
    _symptomRepo = ref.watch(symptomRepositoryProvider);
    _generalsRepo = ref.watch(physicalGeneralsRepositoryProvider);
    _mentalRepo = ref.watch(mentalEmotionalRepositoryProvider);
    _remedyRepo = ref.watch(remedySuggestionRepositoryProvider);
    _aiClient = ref.watch(activeAIClientProvider);
    
    return CaseWizardState(patientId: patientId);
  }

  /// Load existing case data for editing
  Future<void> loadCase(String caseId) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final caseData = await _caseRepo.getCaseById(caseId);
      if (caseData == null) {
        state = state.copyWith(isLoading: false, error: 'Case not found');
        return;
      }
      
      // Load all case data
      final symptoms = await _symptomRepo.getSymptomsForCase(caseId);
      final generals = await _generalsRepo.getForCase(caseId);
      final mental = await _mentalRepo.getForCase(caseId);
      
      // Build form data from loaded case - use snake_case to match form field names
      final formData = <String, dynamic>{
        'case_title': caseData.title,
        'spontaneous_narrative': caseData.spontaneousNarrative ?? '',
        'final_remedy_name': caseData.finalRemedyName ?? '',
        'final_remedy_potency': caseData.finalRemedyPotency ?? '',
        'final_remedy_dose': caseData.finalRemedyDose ?? '',
        'prescription_notes': caseData.prescriptionNotes ?? '',
      };
      
      // Add physical generals if available
      if (generals != null) {
        formData['thermal_type'] = generals.thermalType ?? '';
        formData['thermal_details'] = generals.thermalDetails ?? '';
        formData['thirst_quantity'] = generals.thirstQuantity ?? '';
        formData['food_cravings'] = generals.cravings ?? '';
        formData['food_aversions'] = generals.aversions ?? '';
        formData['sleep_position'] = generals.sleepPosition ?? '';
        formData['dreams'] = generals.dreams ?? '';
      }
      
      // Add mental/emotional if available
      if (mental != null) {
        // Convert comma-separated strings to lists for checkbox groups
        formData['disposition'] = _stringToList(mental.disposition);
        formData['greatest_fear'] = mental.fears ?? '';
        formData['ailments_from'] = _stringToList(mental.emotionalTriggers);
      }
      
      state = state.copyWith(
        caseId: caseId,
        formData: formData,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Helper to convert comma-separated string to list for checkbox groups
  List<String> _stringToList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// Update form field
  void updateField(String key, dynamic value) {
    state = state.copyWith(
      formData: {...state.formData, key: value},
    );
  }

  /// Helper to convert form field value to String or null
  String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is List) {
      if (value.isEmpty) return null;
      // Join list items with comma for storage
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  /// Save draft case
  Future<void> saveDraft() async {
    try {
      state = state.copyWith(isLoading: true);

      print('[CaseWizard] Saving draft with formData: ${state.formData}');
      print('[CaseWizard] Patient ID: ${state.patientId}');
      print('[CaseWizard] Case ID: ${state.caseId}');

      if (state.caseId == null) {
        // Create new case
        print('[CaseWizard] Creating new case...');
        final caseRecord = await _caseRepo.createCase(
          patientId: state.patientId,
          title: state.formData['case_title'] ?? 'Untitled Case',
          spontaneousNarrative: state.formData['spontaneous_narrative'],
          status: 'draft',
        );
        print('[CaseWizard] Case created with ID: ${caseRecord.id}');
        state = state.copyWith(caseId: caseRecord.id);
      } else {
        // Update existing case
        print('[CaseWizard] Updating existing case: ${state.caseId}');
        final existingCase = await _caseRepo.getCaseById(state.caseId!);
        if (existingCase != null) {
          await _caseRepo.updateCase(
            existingCase.copyWith(
              title: (state.formData['case_title'] as String?) ?? existingCase.title,
              spontaneousNarrative: drift.Value(
                state.formData['spontaneous_narrative'] as String?,
              ),
              finalRemedyName: drift.Value(
                _toStringOrNull(state.formData['final_remedy_name']),
              ),
              finalRemedyPotency: drift.Value(
                _toStringOrNull(state.formData['final_remedy_potency']),
              ),
              finalRemedyDose: drift.Value(
                _toStringOrNull(state.formData['final_remedy_dose']),
              ),
              prescriptionNotes: drift.Value(
                _toStringOrNull(state.formData['prescription_notes']),
              ),
            ),
          );
          print('[CaseWizard] Case updated successfully');
        } else {
          throw Exception('Case not found: ${state.caseId}');
        }
      }

      // Now save all the additional data to their respective tables
      final caseId = state.caseId!;

      // Save Physical Generals
      if (state.formData.containsKey('thermal_type') ||
          state.formData.containsKey('thirst_quantity') ||
          state.formData.containsKey('food_cravings') ||
          state.formData.containsKey('food_aversions') ||
          state.formData.containsKey('sleep_position') ||
          state.formData.containsKey('dreams')) {
        print('[CaseWizard] Saving physical generals...');
        print('[CaseWizard] thermal_type: ${state.formData['thermal_type']}');
        print('[CaseWizard] thirst_quantity: ${state.formData['thirst_quantity']}');
        print('[CaseWizard] food_cravings: ${state.formData['food_cravings']}');
        print('[CaseWizard] food_aversions: ${state.formData['food_aversions']}');
        print('[CaseWizard] sleep_position: ${state.formData['sleep_position']}');
        print('[CaseWizard] dreams: ${state.formData['dreams']}');
        
        await _generalsRepo.upsert(
          caseId: caseId,
          thermalType: _toStringOrNull(state.formData['thermal_type']),
          thirstQuantity: _toStringOrNull(state.formData['thirst_quantity']),
          cravings: _toStringOrNull(state.formData['food_cravings']),
          aversions: _toStringOrNull(state.formData['food_aversions']),
          sleepQuality: _toStringOrNull(state.formData['sleep_position']),
          dreams: _toStringOrNull(state.formData['dreams']),
        );
        print('[CaseWizard] Physical generals saved successfully');
      }

      // Save Mental/Emotional
      if (state.formData.containsKey('disposition') ||
          state.formData.containsKey('greatest_fear') ||
          state.formData.containsKey('ailments_from')) {
        print('[CaseWizard] Saving mental/emotional...');
        print('[CaseWizard] disposition: ${state.formData['disposition']}');
        print('[CaseWizard] greatest_fear: ${state.formData['greatest_fear']}');
        print('[CaseWizard] ailments_from: ${state.formData['ailments_from']}');
        
        await _mentalRepo.upsert(
          caseId: caseId,
          disposition: _toStringOrNull(state.formData['disposition']),
          fears: _toStringOrNull(state.formData['greatest_fear']),
          emotionalTriggers: _toStringOrNull(state.formData['ailments_from']),
        );
        print('[CaseWizard] Mental/emotional saved successfully');
      }

      // Save Chief Complaints as Symptoms
      final complaintsToSave = <Map<String, dynamic>>[];
      for (final entry in state.formData.entries) {
        if (entry.key.startsWith('complaint_')) {
          final parts = entry.key.split('_');
          if (parts.length >= 3) {
            final index = int.tryParse(parts[1]);
            if (index != null) {
              final field = parts[2];
              while (complaintsToSave.length <= index) {
                complaintsToSave.add({});
              }
              complaintsToSave[index][field] = entry.value;
            }
          }
        }
      }

      if (complaintsToSave.isNotEmpty) {
        print('[CaseWizard] Saving ${complaintsToSave.length} chief complaints...');
        
        // Delete existing symptoms for this case first
        final existingSymptoms = await _symptomRepo.getSymptomsForCase(caseId);
        for (final symptom in existingSymptoms) {
          await _symptomRepo.deleteSymptom(symptom.id);
        }
        
        // Add new symptoms
        for (final complaint in complaintsToSave) {
          if (complaint['title'] != null && complaint['title'].toString().isNotEmpty) {
            await _symptomRepo.addSymptom(
              caseId: caseId,
              type: 'chief_complaint',
              text: complaint['title'] as String,
              location: complaint['location'] as String?,
              sensation: complaint['sensation'] as String?,
              modalities: complaint['modalities'] as String?,
              concomitants: complaint['concomitants'] as String?,
            );
          }
        }
      }

      print('[CaseWizard] Draft saved successfully!');
      
      // Verify data was saved correctly
      final savedCase = await _caseRepo.getCaseById(caseId);
      print('[CaseWizard] Verified saved case: title="${savedCase?.title}", narrative="${savedCase?.spontaneousNarrative}"');
      final savedSymptoms = await _symptomRepo.getSymptomsForCase(caseId);
      print('[CaseWizard] Verified ${savedSymptoms.length} symptoms saved');
      final savedGenerals = await _generalsRepo.getForCase(caseId);
      print('[CaseWizard] Verified physical generals: ${savedGenerals != null ? "exists" : "null"}');
      final savedMental = await _mentalRepo.getForCase(caseId);
      print('[CaseWizard] Verified mental/emotional: ${savedMental != null ? "exists" : "null"}');
      

      state = state.copyWith(isLoading: false, error: null);
      print('[CaseWizard] Draft saved successfully!');
    } catch (e, stackTrace) {
      print('[CaseWizard] Error saving draft: $e');
      print('[CaseWizard] Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw so the UI can catch and display the error
    }
  }

  /// Analyze spontaneous narrative with AI
  Future<Map<String, dynamic>?> analyzeSpontaneousNarrative() async {
    if (_aiClient == null) {
      state = state.copyWith(error: 'AI service not configured');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true);

      final result = await _aiClient!.analyzeSpontaneousNarrative(
        narrative: state.formData['spontaneousNarrative'] ?? '',
      );

      state = state.copyWith(isLoading: false, error: null);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Highlight peculiar symptoms with AI
  Future<Map<String, dynamic>?> highlightPeculiarSymptoms(
    List<String> symptoms,
  ) async {
    if (_aiClient == null) {
      state = state.copyWith(error: 'AI service not configured');
      return null;
    }

    try {
      state = state.copyWith(isLoading: true);

      final result = await _aiClient!.highlightPeculiarSymptoms(
        symptoms: symptoms,
      );

      state = state.copyWith(isLoading: false, error: null);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Perform complete case analysis with AI
  Future<void> performCaseAnalysis(List<String> selectedSymptoms) async {
    if (_aiClient == null) {
      state = state.copyWith(error: 'AI service not configured');
      return;
    }

    if (state.caseId == null) {
      await saveDraft();
    }

    try {
      state = state.copyWith(isLoading: true);

      // Prepare data
      final chiefComplaints = _buildChiefComplaintsData();
      final physicalGenerals = _buildPhysicalGeneralsData();
      final mentalEmotional = _buildMentalEmotionalData();

      final result = await _aiClient!.analyzeCase(
        spontaneousNarrative: state.formData['spontaneousNarrative'] ?? '',
        chiefComplaints: chiefComplaints,
        physicalGenerals: physicalGenerals,
        mentalEmotional: mentalEmotional,
        selectedKeySymptoms: selectedSymptoms,
      );

      // Save remedy suggestions
      if (result['remedySuggestions'] != null && state.caseId != null) {
        final suggestions = result['remedySuggestions'] as List;
        for (final suggestion in suggestions) {
          await _remedyRepo.addSuggestion(
            caseId: state.caseId!,
            remedyName: suggestion['remedy'],
            source: 'grok',
            grade: suggestion['grade'],
            confidence: suggestion['confidence'],
            reason: suggestion['differentiatingFeatures'],
            matchingSymptoms: (suggestion['matchingSymptoms'] as List?)?.join(', '),
            differentiatingFeatures: suggestion['materiaComparison'],
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        aiAnalysis: result,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Save complete case
  Future<bool> saveCompleteCase() async {
    try {
      state = state.copyWith(isLoading: true);

      // Ensure case exists
      if (state.caseId == null) {
        await saveDraft();
      }

      if (state.caseId == null) {
        throw Exception('Failed to create case record');
      }

      final caseId = state.caseId!;

      // Save physical generals
      await _generalsRepo.upsert(
        caseId: caseId,
        thermalType: _toStringOrNull(state.formData['thermal_type']),
        thirstQuantity: _toStringOrNull(state.formData['thirst_quantity']),
        cravings: _toStringOrNull(state.formData['food_cravings']),
        aversions: _toStringOrNull(state.formData['food_aversions']),
        sleepQuality: _toStringOrNull(state.formData['sleep_position']),
        dreams: _toStringOrNull(state.formData['dreams']),
      );

      // Save mental/emotional
      await _mentalRepo.upsert(
        caseId: caseId,
        disposition: _toStringOrNull(state.formData['disposition']),
        fears: _toStringOrNull(state.formData['greatest_fear']),
        emotionalTriggers: _toStringOrNull(state.formData['ailments_from']),
      );

      // Save prescription (using correct field names from Step 7)
      final remedyName = _toStringOrNull(state.formData['final_remedy_name']);
      if (remedyName != null && remedyName.isNotEmpty) {
        await _caseRepo.savePrescription(
          caseId: caseId,
          remedyName: remedyName,
          potency: _toStringOrNull(state.formData['final_remedy_potency']),
          dose: _toStringOrNull(state.formData['dose']),
          notes: _toStringOrNull(state.formData['prescription_notes']),
        );
      }

      // Update case status
      await _caseRepo.updateCaseStatus(caseId, 'completed');

      // Save portrait summary if available
      if (state.aiAnalysis?['portrait'] != null) {
        await _caseRepo.updatePortraitSummary(
          caseId,
          state.aiAnalysis!['portrait'],
        );
      }

      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e, stackTrace) {
      print('Error saving case: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Helper methods
  List<SymptomData> _buildChiefComplaintsData() {
    // TODO: Build from actual complaint list (for now, single complaint)
    if (state.formData['complaint_title'] != null) {
      return [
        SymptomData(
          title: state.formData['complaint_title'],
          location: state.formData['complaint_location'],
          sensation: state.formData['complaint_sensation'],
          modalities: state.formData['complaint_modalities'],
          concomitants: state.formData['complaint_concomitants'],
        ),
      ];
    }
    return [];
  }

  Map<String, dynamic> _buildPhysicalGeneralsData() {
    return {
      'thermals': state.formData['thermals'],
      'thirst': state.formData['thirst_quantity'],
      'appetite': state.formData['cravings'] != null || state.formData['aversions'] != null
          ? 'Cravings: ${state.formData['cravings'] ?? 'none'}, Aversions: ${state.formData['aversions'] ?? 'none'}'
          : null,
      'sleep': state.formData['sleep_quality'],
      'dreams': state.formData['dreams'],
    };
  }

  Map<String, dynamic> _buildMentalEmotionalData() {
    return {
      'disposition': state.formData['disposition'],
      'fears': state.formData['fears'],
      'emotionalTriggers': state.formData['emotional_triggers'],
      'keyEmotions': state.formData['key_emotions'],
    };
  }
}
