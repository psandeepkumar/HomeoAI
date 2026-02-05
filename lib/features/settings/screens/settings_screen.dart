/// Settings screen - App settings and demo data

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/data/sample_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Demo Data Section
          const _SectionHeader(title: 'Demo & Testing'),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all patients and cases from database'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Data?'),
                    content: const Text('This will permanently delete all patients, cases, and related data. This action cannot be undone!'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && context.mounted) {
                  try {
                    final db = ref.read(databaseProvider);
                    await db.delete(db.remedySuggestions).go();
                    await db.delete(db.mentalEmotionals).go();
                    await db.delete(db.physicalGenerals).go();
                    await db.delete(db.symptoms).go();
                    await db.delete(db.cases).go();
                    await db.delete(db.patients).go();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error clearing data: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Clear'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Load Sample Data'),
            subtitle: const Text('Add 3 demo patients with complete cases'),
            trailing: ElevatedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Load Sample Data?'),
                    content: const Text('This will add 3 demo patients:\n\n• Sarah Mitchell (Anxiety case)\n• Jennifer Lopez (Migraine case)\n• Tommy Anderson (Child ear infections)\n\nThis is useful for testing the app features.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Load Data')),
                    ],
                  ),
                );
                
                if (confirmed == true && context.mounted) {
                  try {
                    final db = ref.read(databaseProvider);
                    // Clear existing sample data first
                    final patients = await db.select(db.patients).get();
                    for (final patient in patients.where((p) => 
                      p.name == 'Sarah Mitchell' || 
                      p.name == 'Jennifer Lopez' || 
                      p.name == 'Tommy Anderson'
                    )) {
                      // Delete all related data
                      final cases = await (db.select(db.cases)..where((c) => c.patientId.equals(patient.id))).get();
                      for (final caseItem in cases) {
                        await (db.delete(db.symptoms)..where((s) => s.caseId.equals(caseItem.id))).go();
                        await (db.delete(db.physicalGenerals)..where((pg) => pg.caseId.equals(caseItem.id))).go();
                        await (db.delete(db.mentalEmotionals)..where((me) => me.caseId.equals(caseItem.id))).go();
                        await (db.delete(db.remedySuggestions)..where((rs) => rs.caseId.equals(caseItem.id))).go();
                      }
                      await (db.delete(db.cases)..where((c) => c.patientId.equals(patient.id))).go();
                      await (db.delete(db.patients)..where((p) => p.id.equals(patient.id))).go();
                    }
                    // Now load fresh sample data
                    await SampleDataGenerator.generateSampleData(db);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sample data loaded successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading data: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Load'),
            ),
          ),
          
          const Divider(),

          const SizedBox(height: 24),

          // Privacy & Data Section
          const _SectionHeader(title: 'Privacy & Data'),
          
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Data Storage'),
            subtitle: const Text('All patient data is stored locally on this device'),
          ),
          
          ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Cloud Sync'),
            subtitle: const Text('Disabled - No cloud backup'),
            trailing: const Icon(Icons.info_outline, size: 20),
          ),

          const SizedBox(height: 24),

          // About Section
          const _SectionHeader(title: 'About'),
          
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Disclaimer'),
            subtitle: const Text(
              'This app is for professional homeopathic practitioners only. '
              'Not medical advice.',
            ),
            isThreeLine: true,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
