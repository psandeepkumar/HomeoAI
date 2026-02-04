/// Follow-up Tracking with Before/After Comparison
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart' as uuid;
import '../../../core/database/database.dart';
import '../../../core/providers/providers.dart';

class FollowUpScreen extends ConsumerStatefulWidget {
  final String caseId;
  
  const FollowUpScreen({super.key, required this.caseId});

  @override
  ConsumerState<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends ConsumerState<FollowUpScreen> {
  final _notesController = TextEditingController();
  final _changesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _changesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followUpsAsync = ref.watch(followUpsByCaseProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFollowUpDialog(),
          ),
        ],
      ),
      body: followUpsAsync.when(
        data: (followUps) {
          if (followUps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No follow-ups recorded yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFollowUpDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Follow-up'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: followUps.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final followUp = followUps[index];
              final isLatest = index == 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: Icon(Icons.event, color: isLatest ? Colors.blue : Colors.grey),
                  title: Text(DateFormat('MMM dd, yyyy').format(followUp.followUpDate)),
                  subtitle: Text(isLatest ? 'Latest Follow-up' : 'Follow-up ${followUps.length - index}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (followUp.changes != null) ...[
                            Text('Changes:', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(followUp.changes!, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 12),
                          ],
                          Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(followUp.notes, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Color _getImprovementColor(int? percentage) {
    if (percentage == null) return Colors.grey;
    if (percentage >= 70) return Colors.green;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showAddFollowUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Follow-up'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _changesController,
                decoration: const InputDecoration(
                  labelText: 'Changes Observed',
                  hintText: 'Improvements, aggravations, new symptoms...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes *',
                  hintText: 'Patient feedback, observations...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_notesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes are required')));
                return;
              }
              final repo = ref.read(followUpRepositoryProvider);
              await repo.createFollowUp(FollowUpsCompanion.insert(
                id: const uuid.Uuid().v4(),
                caseId: widget.caseId,
                followUpDate: DateTime.now(),
                notes: _notesController.text,
                changes: _changesController.text.isEmpty ? null : _changesController.text,
              ));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow-up added')));
                _notesController.clear();
                _changesController.clear();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
