/// Patient profile screen - shows patient details and cases

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/patient_providers.dart';
import '../../cases/screens/case_wizard_screen.dart';
import '../../cases/screens/case_detail_screen.dart';
import 'patient_form_screen.dart';

class PatientProfileScreen extends ConsumerWidget {
  final String patientId;

  const PatientProfileScreen({
    required this.patientId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final casesAsync = ref.watch(patientCasesProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final patient = patientAsync.value;
              if (patient != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientFormScreen(patient: patient),
                  ),
                );
                ref.invalidate(patientDetailProvider(patientId));
              }
            },
          ),
        ],
      ),
      body: patientAsync.when(
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Patient not found'));
          }

          final age = patient.dateOfBirth != null
              ? DateTime.now().year - patient.dateOfBirth!.year
              : null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          patient.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (age != null) ...[
                            Text('$age years'),
                            if (patient.gender != null)
                              const Text(' • '),
                          ],
                          if (patient.gender != null)
                            Text(patient.gender!),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Details Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (patient.dateOfBirth != null)
                        _InfoRow(
                          icon: Icons.cake,
                          label: 'Date of Birth',
                          value: DateFormat.yMMMd().format(patient.dateOfBirth!),
                        ),
                      if (patient.occupation != null)
                        _InfoRow(
                          icon: Icons.work_outline,
                          label: 'Occupation',
                          value: patient.occupation!,
                        ),
                      if (patient.contactPhone != null)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: patient.contactPhone!,
                        ),
                      if (patient.contactEmail != null)
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: patient.contactEmail!,
                        ),
                      if (patient.address != null)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: patient.address!,
                        ),
                      if (patient.notes != null && patient.notes!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.notes,
                          label: 'Notes',
                          value: patient.notes!,
                        ),
                    ],
                  ),
                ),

                const Divider(),

                // Cases Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cases',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CaseWizardScreen(patientId: patientId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Case'),
                      ),
                    ],
                  ),
                ),

                casesAsync.when(
                  data: (cases) {
                    if (cases.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              const Text('No cases yet'),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cases.length,
                      itemBuilder: (context, index) {
                        final case_ = cases[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(context, case_.status),
                              child: Icon(
                                _getStatusIcon(case_.status),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(case_.title),
                            subtitle: Text(
                              DateFormat.yMMMd().format(case_.consultationDate),
                            ),
                            trailing: Chip(
                              label: Text(
                                case_.status.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor: _getStatusColor(context, case_.status).withOpacity(0.2),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CaseDetailScreen(caseId: case_.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading cases: $err'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'draft':
        return Icons.edit;
      default:
        return Icons.folder;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
