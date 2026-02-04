/// Case detail screen - displays complete case information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/providers.dart';
import '../../../core/export/exporters.dart';
import 'case_wizard_screen.dart';

final caseDetailProvider = FutureProvider.family<Case?, String>((ref, caseId) async {
  final repo = ref.watch(caseRepositoryProvider);
  return await repo.getCaseById(caseId);
});

final caseSymptomsProvider = FutureProvider.family<List<Symptom>, String>((ref, caseId) async {
  final repo = ref.watch(symptomRepositoryProvider);
  return await repo.getSymptomsForCase(caseId);
});

final casePhysicalGeneralsProvider = FutureProvider.family<PhysicalGeneral?, String>((ref, caseId) async {
  final repo = ref.watch(physicalGeneralsRepositoryProvider);
  return await repo.getForCase(caseId);
});

final caseMentalEmotionalProvider = FutureProvider.family<MentalEmotional?, String>((ref, caseId) async {
  final repo = ref.watch(mentalEmotionalRepositoryProvider);
  return await repo.getForCase(caseId);
});

final caseRemediesProvider = FutureProvider.family<List<RemedySuggestion>, String>((ref, caseId) async {
  final repo = ref.watch(remedySuggestionRepositoryProvider);
  return await repo.getSuggestionsForCase(caseId);
});

class CaseDetailScreen extends ConsumerWidget {
  final String caseId;

  const CaseDetailScreen({required this.caseId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseDetailProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Case',
            onPressed: () => _editCase(context, caseAsync.value),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Case',
            onPressed: () => _exportCase(context, ref),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (case_) {
          if (case_ == null) {
            return const Center(child: Text('Case not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              case_.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(case_.status),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(case_.status).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              case_.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Consultation: ${DateFormat.yMMMd().format(case_.consultationDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Spontaneous Narrative
                if (case_.spontaneousNarrative != null) ...[
                  _SectionHeader(title: 'Spontaneous Narrative'),
                  _ContentCard(child: Text(case_.spontaneousNarrative!)),
                ],

                // Portrait Summary
                if (case_.portraitSummary != null) ...[
                  _SectionHeader(title: 'Patient Portrait'),
                  _ContentCard(
                    child: Text(
                      case_.portraitSummary!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                // Symptoms
                _SectionHeader(title: 'Symptoms'),
                _SymptomsSection(caseId: caseId),

                // Physical Generals
                _SectionHeader(title: 'Physical Generals'),
                _PhysicalGeneralsSection(caseId: caseId),

                // Mental & Emotional
                _SectionHeader(title: 'Mental & Emotional'),
                _MentalEmotionalSection(caseId: caseId),

                // Remedy Suggestions
                _SectionHeader(title: 'Remedy Analysis'),
                _RemediesSection(caseId: caseId),

                // Prescription
                if (case_.finalRemedyName != null) ...[
                  _SectionHeader(title: 'Prescription'),
                  _ContentCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: 'Remedy', value: case_.finalRemedyName!),
                        if (case_.finalRemedyPotency != null)
                          _DetailRow(label: 'Potency', value: case_.finalRemedyPotency!),
                        if (case_.finalRemedyDose != null)
                          _DetailRow(label: 'Dose', value: case_.finalRemedyDose!),
                        if (case_.prescriptionNotes != null)
                          _DetailRow(label: 'Notes', value: case_.prescriptionNotes!),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF66BB6A); // Green
      case 'active':
        return const Color(0xFF5E35B1); // Deep Purple
      case 'draft':
        return const Color(0xFFFF9800); // Vibrant Orange
      default:
        return Colors.grey;
    }
  }

  void _editCase(BuildContext context, Case? case_) {
    if (case_ == null) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CaseWizardScreen(
          patientId: case_.patientId,
          caseId: case_.id,
        ),
      ),
    );
  }

  Future<void> _exportCase(BuildContext context, WidgetRef ref) async {
    try {
      final case_ = await ref.read(caseDetailProvider(caseId).future);
      final patient = await ref.read(patientRepositoryProvider)
          .getPatientById(case_!.patientId);
      final symptoms = await ref.read(caseSymptomsProvider(caseId).future);
      final generals = await ref.read(casePhysicalGeneralsProvider(caseId).future);
      final mentals = await ref.read(caseMentalEmotionalProvider(caseId).future);
      final remedies = await ref.read(caseRemediesProvider(caseId).future);

      final file = await PDFExporter.exportCase(
        caseData: case_,
        patient: patient!,
        symptoms: symptoms,
        physicalGenerals: generals,
        mentalEmotional: mentals,
        remedySuggestions: remedies,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case exported to ${file.path}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // TODO: Open file with platform viewer
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;

  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SymptomsSection extends ConsumerWidget {
  final String caseId;

  const _SymptomsSection({required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(caseSymptomsProvider(caseId));

    return symptomsAsync.when(
      data: (symptoms) {
        if (symptoms.isEmpty) {
          return const _ContentCard(child: Text('No symptoms recorded'));
        }

        return _ContentCard(
          child: Column(
            children: symptoms.map((symptom) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (symptom.isMarkedSRP)
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            symptom.symptomText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (symptom.location != null)
                      Text('  Location: ${symptom.location}', style: const TextStyle(fontSize: 12)),
                    if (symptom.sensation != null)
                      Text('  Sensation: ${symptom.sensation}', style: const TextStyle(fontSize: 12)),
                    if (symptom.modalities != null)
                      Text('  Modalities: ${symptom.modalities}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const _ContentCard(child: CircularProgressIndicator()),
      error: (err, stack) => _ContentCard(child: Text('Error: $err')),
    );
  }
}

class _PhysicalGeneralsSection extends ConsumerWidget {
  final String caseId;

  const _PhysicalGeneralsSection({required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalsAsync = ref.watch(casePhysicalGeneralsProvider(caseId));

    return generalsAsync.when(
      data: (generals) {
        if (generals == null) {
          return const _ContentCard(child: Text('Not recorded'));
        }

        return _ContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (generals.thermalType != null)
                _DetailRow(label: 'Thermals', value: generals.thermalType!),
              if (generals.thirstQuantity != null)
                _DetailRow(label: 'Thirst', value: generals.thirstQuantity!),
              if (generals.cravings != null)
                _DetailRow(label: 'Cravings', value: generals.cravings!),
              if (generals.aversions != null)
                _DetailRow(label: 'Aversions', value: generals.aversions!),
              if (generals.sleepQuality != null)
                _DetailRow(label: 'Sleep', value: generals.sleepQuality!),
              if (generals.dreams != null)
                _DetailRow(label: 'Dreams', value: generals.dreams!),
            ],
          ),
        );
      },
      loading: () => const _ContentCard(child: CircularProgressIndicator()),
      error: (err, stack) => _ContentCard(child: Text('Error: $err')),
    );
  }
}

class _MentalEmotionalSection extends ConsumerWidget {
  final String caseId;

  const _MentalEmotionalSection({required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentalAsync = ref.watch(caseMentalEmotionalProvider(caseId));

    return mentalAsync.when(
      data: (mental) {
        if (mental == null) {
          return const _ContentCard(child: Text('Not recorded'));
        }

        return _ContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mental.disposition != null)
                _DetailRow(label: 'Disposition', value: mental.disposition!),
              if (mental.fears != null)
                _DetailRow(label: 'Fears', value: mental.fears!),
              if (mental.emotionalTriggers != null)
                _DetailRow(label: 'Triggers', value: mental.emotionalTriggers!),
              if (mental.keyEmotions != null)
                _DetailRow(label: 'Key Emotions', value: mental.keyEmotions!),
            ],
          ),
        );
      },
      loading: () => const _ContentCard(child: CircularProgressIndicator()),
      error: (err, stack) => _ContentCard(child: Text('Error: $err')),
    );
  }
}

class _RemediesSection extends ConsumerWidget {
  final String caseId;

  const _RemediesSection({required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remediesAsync = ref.watch(caseRemediesProvider(caseId));

    return remediesAsync.when(
      data: (remedies) {
        if (remedies.isEmpty) {
          return const _ContentCard(child: Text('No remedy suggestions'));
        }

        return _ContentCard(
          child: Column(
            children: remedies.take(5).map((remedy) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(remedy.grade ?? '?'),
                ),
                title: Text(
                  remedy.remedyName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: remedy.reason != null ? Text(remedy.reason!) : null,
                trailing: remedy.confidence != null
                    ? Chip(
                        label: Text(
                          remedy.confidence!.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : null,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const _ContentCard(child: CircularProgressIndicator()),
      error: (err, stack) => _ContentCard(child: Text('Error: $err')),
    );
  }
}
