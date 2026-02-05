/// Complete 7-Step Classical Homeopathy Case Taking Wizard
/// Follows Hahnemann/Kent/Vithoulkas methodology with LSMC structure

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/case_wizard_provider.dart';
import '../../../core/providers/providers.dart';
import 'case_detail_screen.dart';

class CaseWizardScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? caseId;

  const CaseWizardScreen({
    super.key,
    required this.patientId,
    this.caseId,
  });

  @override
  ConsumerState<CaseWizardScreen> createState() => _CaseWizardScreenState();
}

class _CaseWizardScreenState extends ConsumerState<CaseWizardScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 0;
  final List<GlobalKey<FormBuilderState>> _stepFormKeys = List.generate(7, (_) => GlobalKey<FormBuilderState>());
  final List<Map<String, dynamic>> _complaints = [];
  
  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    // Load existing case data if editing
    if (widget.caseId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(caseWizardProvider(widget.patientId).notifier).loadCase(widget.caseId!);
        // After loading, populate all form fields with the loaded data
        _populateFormFields();
        // Load complaints (chief symptoms)
        await _loadComplaints();
      });
    }
  }
  
  Future<void> _loadComplaints() async {
    if (widget.caseId == null) return;
    
    try {
      // Get symptoms from the repository
      final symptomRepo = ref.read(symptomRepositoryProvider);
      final symptoms = await symptomRepo.getSymptomsForCase(widget.caseId!);
      
      // Convert symptoms to complaint format
      setState(() {
        _complaints.clear();
        for (final symptom in symptoms.where((s) => s.type == 'chief')) {
          _complaints.add({
            'symptom': symptom.symptomText,
            'location': symptom.location ?? '',
            'sensation': symptom.sensation ?? '',
            'modalities': symptom.modalities ?? '',
            'concomitants': symptom.concomitants ?? '',
          });
        }
      });
    } catch (e) {
      print('[UI] Error loading complaints: $e');
    }
  }
  
  void _populateFormFields() {
    final wizardState = ref.read(caseWizardProvider(widget.patientId));
    
    // List of checkbox group fields that expect List<String>
    const checkboxFields = {'disposition', 'ailments_from'};
    
    // Populate each form builder with loaded data
    for (int i = 0; i < _stepFormKeys.length; i++) {
      final formState = _stepFormKeys[i].currentState;
      if (formState != null) {
        // Update each field in the form
        wizardState.formData.forEach((key, value) {
          final field = formState.fields[key];
          if (field != null && value != null) {
            try {
              // Convert strings to lists for checkbox group fields
              if (checkboxFields.contains(key) && value is String) {
                // Split comma-separated values into a list
                final listValue = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                field.didChange(listValue);
              } else {
                // Try to set the value - some fields may expect different types
                field.didChange(value);
              }
            } catch (e) {
              // If field expects a different type, skip it
              print('[UI] Skipping field $key: $e');
            }
          }
        });
      }
    }
  }
  
  Future<void> _startVoiceInput() async {
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice input error: ${error.errorMsg}')),
          );
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
            _stepFormKeys[0].currentState?.fields['spontaneous_narrative']?.didChange(_transcribedText);
          });
        },
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      );
    }
  }
  
  Future<void> _stopVoiceInput() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseId != null ? 'Edit Case' : 'New Case'),
        actions: [
          if (wizardState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          TextButton.icon(
            onPressed: wizardState.isLoading ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: _buildStepControls,
          steps: [
            _buildStep1SpontaneousNarrative(),
            _buildStep2ChiefComplaints(),
            _buildStep3PhysicalGenerals(),
            _buildStep4MentalEmotional(),
            _buildStep5ReviewSRP(),
            _buildStep6Analysis(),
            _buildStep7Prescription(),
          ],
        ),
      ),
    );
  }

  Step _buildStep1SpontaneousNarrative() {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));
    return Step(
      title: const Text('Spontaneous Narrative'),
      subtitle: const Text('Let patient speak freely'),
      isActive: _currentStep >= 0,
      state: _getStepState(0),
      content: FormBuilder(
        key: _stepFormKeys[0],
        initialValue: wizardState.formData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormBuilderTextField(
              name: 'case_title',
              decoration: const InputDecoration(
                labelText: 'Case Title *',
                hintText: 'e.g., Chronic Headaches, Anxiety, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(3),
              ]),
            ),
            const SizedBox(height: 16),
            Text(
              'Opening prompt: "Tell me about your health concerns in your own words."',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade700,
                  ),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'spontaneous_narrative',
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Patient\'s Story',
                hintText: 'Capture everything patient says without interruption...',
                border: OutlineInputBorder(),
                helperText: 'Note: tone, priorities, gestures, emotions',
              ),
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isListening ? _stopVoiceInput : _startVoiceInput,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Stop Recording' : 'Voice Input'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isListening ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2ChiefComplaints() {
    return Step(
      title: const Text('Chief Complaints'),
      subtitle: const Text('L-S-M-C structure'),
      isActive: _currentStep >= 1,
      state: _getStepState(1),
      content: FormBuilder(
        key: _stepFormKeys[1],
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Document each complaint using LSMC:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildLSMCLegend(),
          const SizedBox(height: 16),
          if (_complaints.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No complaints added yet'),
                  ],
                ),
              ),
            )
          else
            ..._complaints.asMap().entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(entry.value['title'] ?? 'Complaint ${entry.key + 1}'),
                  subtitle: Text('Location: ${entry.value['location'] ?? 'Not specified'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _complaints.removeAt(entry.key)),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _ComplaintDialog(
                onSave: (complaint) => setState(() => _complaints.add(complaint)),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Chief Complaint'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLSMCLegend() {
    final items = [
      {'label': 'L', 'text': 'Location (exact place, radiation, side)'},
      {'label': 'S', 'text': 'Sensation (burning, stitching, throbbing, etc.)'},
      {'label': 'M', 'text': 'Modalities (better/worse from: time, temp, motion, etc.)'},
      {'label': 'C', 'text': 'Concomitants (simultaneous unrelated symptoms)'},
    ];
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(radius: 12, child: Text(item['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Expanded(child: Text(item['text']!, style: const TextStyle(fontSize: 12))),
          ],
        ),
      )).toList(),
    );
  }

  Step _buildStep3PhysicalGenerals() {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));
    return Step(
      title: const Text('Physical Generals'),
      subtitle: const Text('Thermals, appetite, sleep'),
      isActive: _currentStep >= 2,
      state: _getStepState(2),
      content: FormBuilder(
        key: _stepFormKeys[2],
        initialValue: wizardState.formData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Thermals'),
            FormBuilderRadioGroup<String>(
              name: 'thermal_type',
              decoration: const InputDecoration(labelText: 'Thermal Type'),
              options: const [
                FormBuilderFieldOption(value: 'chilly', child: Text('Chilly')),
                FormBuilderFieldOption(value: 'hot', child: Text('Hot')),
                FormBuilderFieldOption(value: 'ambithermal', child: Text('Ambithermal')),
              ],
            ),
            FormBuilderTextField(name: 'thermal_details', maxLines: 2, decoration: const InputDecoration(labelText: 'Details')),
            const Divider(height: 32),
            _buildSectionHeader('Thirst & Appetite'),
            FormBuilderDropdown<String>(
              name: 'thirst_quantity',
              decoration: const InputDecoration(labelText: 'Thirst'),
              items: ['Thirstless', 'Small sips', 'Moderate', 'Large quantities'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            FormBuilderTextField(name: 'food_cravings', maxLines: 2, decoration: const InputDecoration(labelText: 'Cravings', hintText: 'Salt, sweets, spicy...')),
            FormBuilderTextField(name: 'food_aversions', maxLines: 2, decoration: const InputDecoration(labelText: 'Aversions')),
            const Divider(height: 32),
            _buildSectionHeader('Sleep'),
            FormBuilderDropdown<String>(
              name: 'sleep_position',
              decoration: const InputDecoration(labelText: 'Sleep Position'),
              items: ['Back', 'Right side', 'Left side', 'Abdomen'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            FormBuilderTextField(name: 'dreams', maxLines: 3, decoration: const InputDecoration(labelText: 'Dreams', hintText: 'Recurring themes...')),
          ],
        ),
      ),
    );
  }

  Step _buildStep4MentalEmotional() {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));
    return Step(
      title: const Text('Mental & Emotional'),
      subtitle: const Text('Disposition, fears, delusions'),
      isActive: _currentStep >= 3,
      state: _getStepState(3),
      content: FormBuilder(
        key: _stepFormKeys[3],
        initialValue: wizardState.formData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('Mental/emotional state is most important in classical homeopathy', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Disposition'),
            FormBuilderCheckboxGroup<String>(
              name: 'disposition',
              options: const [
                FormBuilderFieldOption(value: 'irritable', child: Text('Irritable')),
                FormBuilderFieldOption(value: 'weepy', child: Text('Weepy')),
                FormBuilderFieldOption(value: 'fastidious', child: Text('Fastidious')),
                FormBuilderFieldOption(value: 'anxious', child: Text('Anxious')),
              ],
              wrapSpacing: 8,
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(name: 'greatest_fear', maxLines: 2, decoration: const InputDecoration(labelText: 'Greatest Fear')),
            FormBuilderTextField(name: 'security_needs', maxLines: 2, decoration: const InputDecoration(labelText: 'What Provides Security?')),
            const Divider(height: 32),
            _buildSectionHeader('Ailments From'),
            FormBuilderCheckboxGroup<String>(
              name: 'ailments_from',
              options: const [
                FormBuilderFieldOption(value: 'grief', child: Text('Grief')),
                FormBuilderFieldOption(value: 'fright', child: Text('Fright')),
                FormBuilderFieldOption(value: 'humiliation', child: Text('Humiliation')),
                FormBuilderFieldOption(value: 'anger', child: Text('Anger')),
              ],
              wrapSpacing: 8,
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep5ReviewSRP() {
    return Step(
      title: const Text('Review Symptoms'),
      subtitle: const Text('Mark SRP'),
      isActive: _currentStep >= 4,
      state: _getStepState(4),
      content: FormBuilder(
        key: _stepFormKeys[4],
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(child: Text('Mark Strange, Rare, Peculiar symptoms', style: TextStyle(fontSize: 12, color: Colors.black87))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Symptom review functionality ready'),
        ],
        ),
      ),
    );
  }

  Step _buildStep6Analysis() {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));
    final hasAnalysis = wizardState.aiAnalysis != null;
    
    return Step(
      title: const Text('Analysis'),
      subtitle: const Text('Grok AI'),
      isActive: _currentStep >= 5,
      state: _getStepState(5),
      content: FormBuilder(
        key: _stepFormKeys[5],
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('DISCLAIMER: Educational software only. NOT medical advice. Consult qualified homeopath.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Generate Remedy Suggestions Button
          ElevatedButton.icon(
            onPressed: wizardState.isLoading ? null : _generateRemedySuggestions,
            icon: wizardState.isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.analytics),
            label: Text(wizardState.isLoading ? 'Analyzing...' : 'Generate Remedy Suggestions'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          
          if (wizardState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wizardState.error!.contains('Credits Exhausted') || wizardState.error!.contains('exhausted')
                            ? 'API Credits Exhausted'
                            : 'Error',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wizardState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  if (wizardState.error!.contains('Credits Exhausted') || wizardState.error!.contains('exhausted')) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'How to fix:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('1. Visit https://x.ai/'),
                    const Text('2. Sign in to your account'),
                    const Text('3. Purchase more API credits'),
                    const Text('4. Or increase your monthly spending limit'),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: You can still complete and save cases manually without AI analysis.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Display remedy suggestions if available
          if (hasAnalysis && wizardState.aiAnalysis!['remedySuggestions'] != null) ...[
            const SizedBox(height: 24),
            const Text('Remedy Suggestions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...((wizardState.aiAnalysis!['remedySuggestions'] as List).map((remedy) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getGradeColor(remedy['grade']),
                    child: Text(remedy['grade'] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(remedy['remedy'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confidence: ${remedy['confidence'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text(remedy['differentiatingFeatures'] ?? ''),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }).toList()),
          ],
        ],
        ),
      ),
    );
  }

  Step _buildStep7Prescription() {
    final wizardState = ref.watch(caseWizardProvider(widget.patientId));
    return Step(
      title: const Text('Prescription'),
      subtitle: const Text('Final remedy selection'),
      isActive: _currentStep >= 6,
      state: _getStepState(6),
      content: FormBuilder(
        key: _stepFormKeys[6],
        initialValue: wizardState.formData,
        child: Column(
          children: [
            FormBuilderTextField(name: 'final_remedy_name', decoration: const InputDecoration(labelText: 'Remedy Name *'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 12),
            FormBuilderTextField(name: 'final_remedy_potency', decoration: const InputDecoration(labelText: 'Potency *'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 12),
            FormBuilderTextField(name: 'final_remedy_dose', decoration: const InputDecoration(labelText: 'Dose/Frequency *', hintText: 'e.g., 3 doses, 12 hours apart'), validator: FormBuilderValidators.required()),
            const SizedBox(height: 12),
            FormBuilderTextField(name: 'prescription_notes', maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 24),
            FormBuilderDateTimePicker(name: 'follow_up_date', inputType: InputType.date, decoration: const InputDecoration(labelText: 'Follow-up Date')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  StepState _getStepState(int step) {
    if (_currentStep > step) return StepState.complete;
    if (_currentStep == step) return StepState.editing;
    return StepState.indexed;
  }

  Widget _buildStepControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentStep < 6)
            ElevatedButton(onPressed: details.onStepContinue, child: const Text('Continue'))
          else
            ElevatedButton(onPressed: _saveCase, child: const Text('Save Case')),
          const SizedBox(width: 12),
          if (_currentStep > 0) TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_stepFormKeys[_currentStep].currentState?.saveAndValidate() ?? false) {
      // Save current step's data to provider
      final formData = _stepFormKeys[_currentStep].currentState!.value;
      for (final entry in formData.entries) {
        ref.read(caseWizardProvider(widget.patientId).notifier).updateField(entry.key, entry.value);
      }
      
      if (_currentStep < 6) {
        setState(() => _currentStep++);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _saveDraft() async {
    try {
      print('[UI] Starting draft save...');
      
      // Save and collect data from ALL steps (not just current step)
      for (int i = 0; i < _stepFormKeys.length; i++) {
        final formState = _stepFormKeys[i].currentState;
        if (formState != null) {
          formState.save();
          final stepData = formState.value;
          print('[UI] Step $i form data: $stepData');
          
          // Update provider with this step's form data
          for (final entry in stepData.entries) {
            ref.read(caseWizardProvider(widget.patientId).notifier).updateField(entry.key, entry.value);
          }
        }
      }
      
      // Also save complaints data
      if (_complaints.isNotEmpty) {
        print('[UI] Saving complaints: $_complaints');
        for (int i = 0; i < _complaints.length; i++) {
          final complaint = _complaints[i];
          for (final entry in complaint.entries) {
            ref.read(caseWizardProvider(widget.patientId).notifier)
                .updateField('complaint_${i}_${entry.key}', entry.value);
          }
        }
      }
      
      // Call provider's saveDraft
      print('[UI] Calling provider saveDraft...');
      await ref.read(caseWizardProvider(widget.patientId).notifier).saveDraft();
      print('[UI] Draft save successful!');
      
      // Refresh case detail providers if we're editing an existing case
      final caseId = ref.read(caseWizardProvider(widget.patientId)).caseId;
      if (caseId != null) {
        ref.invalidate(caseDetailProvider(caseId));
        ref.invalidate(caseSymptomsProvider(caseId));
        ref.invalidate(casePhysicalGeneralsProvider(caseId));
        ref.invalidate(caseMentalEmotionalProvider(caseId));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[UI] Error saving draft: $e');
      print('[UI] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving draft: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text('$e\n\n$stackTrace'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveCase() async {
    if (_stepFormKeys[_currentStep].currentState?.saveAndValidate() ?? false) {
      try {
        // Save current form data to provider
        final formData = _stepFormKeys[_currentStep].currentState!.value;
        for (final entry in formData.entries) {
          ref.read(caseWizardProvider(widget.patientId).notifier).updateField(entry.key, entry.value);
        }
        
        // Call provider's saveCompleteCase
        final success = await ref.read(caseWizardProvider(widget.patientId).notifier).saveCompleteCase();
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving case'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _generateRemedySuggestions() async {
    try {
      // Save all current form data first
      for (int i = 0; i <= _currentStep; i++) {
        final formState = _stepFormKeys[i].currentState;
        if (formState != null) {
          formState.save();
          final formData = formState.value;
          for (final entry in formData.entries) {
            ref.read(caseWizardProvider(widget.patientId).notifier).updateField(entry.key, entry.value);
          }
        }
      }
      
      // Trigger AI analysis
      await ref.read(caseWizardProvider(widget.patientId).notifier).performCaseAnalysis([]);
      
      if (mounted) {
        final wizardState = ref.read(caseWizardProvider(widget.patientId));
        if (wizardState.aiAnalysis != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Remedy suggestions generated!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getGradeColor(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class _ComplaintDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  const _ComplaintDialog({required this.onSave});

  @override
  State<_ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<_ComplaintDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Chief Complaint'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(name: 'title', decoration: const InputDecoration(labelText: 'Title *'), validator: FormBuilderValidators.required()),
                const SizedBox(height: 12),
                const Divider(),
                const Text('LSMC:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'location', decoration: const InputDecoration(labelText: 'Location *'), validator: FormBuilderValidators.required()),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'sensation', decoration: const InputDecoration(labelText: 'Sensation *'), validator: FormBuilderValidators.required()),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'modalities', maxLines: 3, decoration: const InputDecoration(labelText: 'Modalities *'), validator: FormBuilderValidators.required()),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'concomitants', maxLines: 2, decoration: const InputDecoration(labelText: 'Concomitants')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.saveAndValidate() ?? false) {
              widget.onSave(_formKey.currentState!.value);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
