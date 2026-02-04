/// Patient form screen - create/edit patient

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers/providers.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  final Patient? patient;

  const PatientFormScreen({this.patient, super.key});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  bool get isEditing => widget.patient != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient' : 'New Patient'),
      ),
      body: FormBuilder(
        key: _formKey,
        initialValue: {
          if (widget.patient != null) ...{
            'name': widget.patient!.name,
            'dateOfBirth': widget.patient!.dateOfBirth,
            'gender': widget.patient!.gender,
            'occupation': widget.patient!.occupation,
            'address': widget.patient!.address,
            'contactPhone': widget.patient!.contactPhone,
            'contactEmail': widget.patient!.contactEmail,
            'notes': widget.patient!.notes,
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              
              FormBuilderDateTimePicker(
                name: 'dateOfBirth',
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              ),
              const SizedBox(height: 16),
              
              FormBuilderDropdown<String>(
                name: 'gender',
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
              ),
              const SizedBox(height: 16),
              
              FormBuilderTextField(
                name: 'occupation',
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 16),
              
              FormBuilderTextField(
                name: 'contactPhone',
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              FormBuilderTextField(
                name: 'contactEmail',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: FormBuilderValidators.email(),
              ),
              const SizedBox(height: 16),
              
              FormBuilderTextField(
                name: 'address',
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              FormBuilderTextField(
                name: 'notes',
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                  hintText: 'Any additional information...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _savePatient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Patient' : 'Create Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final values = _formKey.currentState!.value;
      final repo = ref.read(patientRepositoryProvider);

      if (isEditing) {
        // Update existing patient
        final updated = widget.patient!.copyWith(
          name: values['name'],
          dateOfBirth: drift.Value(values['dateOfBirth']),
          gender: drift.Value(values['gender']),
          occupation: drift.Value(values['occupation']),
          address: drift.Value(values['address']),
          contactPhone: drift.Value(values['contactPhone']),
          contactEmail: drift.Value(values['contactEmail']),
          notes: drift.Value(values['notes']),
        );
        await repo.updatePatient(updated);
      } else {
        // Create new patient
        await repo.createPatient(
          name: values['name'],
          dateOfBirth: values['dateOfBirth'],
          gender: values['gender'],
          occupation: values['occupation'],
          address: values['address'],
          contactPhone: values['contactPhone'],
          contactEmail: values['contactEmail'],
          notes: values['notes'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Patient updated successfully' : 'Patient created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
