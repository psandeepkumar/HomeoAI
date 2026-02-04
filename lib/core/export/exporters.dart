/// Export utilities for PDF and JSON generation
/// 
/// Provides methods to export case data in various formats

import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../database/database.dart';

// ============================================================================
// PDF EXPORT
// ============================================================================

class PDFExporter {
  /// Generate a PDF report for a complete case
  static Future<File> exportCase({
    required Case caseData,
    required Patient patient,
    List<Symptom>? symptoms,
    PhysicalGeneral? physicalGenerals,
    MentalEmotional? mentalEmotional,
    List<RemedySuggestion>? remedySuggestions,
    List<FollowUp>? followUps,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Professional Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 2),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLASSICAL HOMEOPATHY CASE REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Patient: ${patient.name}', style: const pw.TextStyle(fontSize: 14)),
                        pw.Text('Age: ${patient.dateOfBirth != null ? _calculateAge(patient.dateOfBirth!) : "N/A"} | Gender: ${patient.gender ?? "N/A"}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Case Date: ${_formatDate(caseData.consultationDate)}', style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Case ID: ${caseData.id.substring(0, 8)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Spontaneous Narrative
          if (caseData.spontaneousNarrative != null) ...[
            _buildSectionTitle('1. SPONTANEOUS NARRATIVE'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Text(caseData.spontaneousNarrative!, style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 20),
          ],

          // Chief Complaints with LSMC Table
          if (symptoms != null && symptoms.isNotEmpty) ...[
            _buildSectionTitle('2. CHIEF COMPLAINTS (LSMC)'),
            _buildLSMCTable(symptoms.where((s) => s.type == 'chief').toList()),
            pw.SizedBox(height: 20),
          ],

          // Physical Generals Table
          if (physicalGenerals != null) ...[
            _buildSectionTitle('3. PHYSICAL GENERALS'),
            _buildPhysicalGeneralsTable(physicalGenerals),
            pw.SizedBox(height: 20),
          ],

          // Mental & Emotional
          if (mentalEmotional != null) ...[
            _buildSectionTitle('4. MENTAL & EMOTIONAL STATE'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Note: Mental/emotional symptoms are of highest importance in classical homeopathy', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 8),
                  _buildMentalEmotionalTable(mentalEmotional),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // SRP Symptoms
          if (symptoms != null && symptoms.where((s) => s.isMarkedSRP).isNotEmpty) ...[
            _buildSectionTitle('5. STRANGE, RARE, PECULIAR (SRP) SYMPTOMS'),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.amber50, border: pw.Border.all(color: PdfColors.amber400, width: 2)),
              child: pw.Column(
                children: [
                  ..._buildSimpleSymptomsList(symptoms.where((s) => s.isMarkedSRP).toList()),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Remedy Suggestions with Comparison Table
          if (remedySuggestions != null && remedySuggestions.isNotEmpty) ...[
            _buildSectionTitle('6. REMEDY ANALYSIS & DIFFERENTIAL'),
            _buildRemedyComparisonTable(remedySuggestions),
            pw.SizedBox(height: 20),
          ],

          // Final Prescription
          if (caseData.finalRemedyName != null) ...[
            _buildSectionTitle('7. PRESCRIPTION'),
            _buildPrescriptionBox(caseData),
            pw.SizedBox(height: 20),
          ],

          // Follow-ups Timeline
          if (followUps != null && followUps.isNotEmpty) ...[
            _buildSectionTitle('FOLLOW-UP PROGRESS'),
            _buildFollowUpTimeline(followUps),
            pw.SizedBox(height: 20),
          ],

          // Disclaimer
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 10),
          _buildDisclaimer(),
        ],
      ),
    );

    // Save to file
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/case_${caseData.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(Patient patient, Case caseData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Classical Homeopathy Case Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Patient: ${patient.name}'),
        if (patient.dateOfBirth != null)
          pw.Text('Age: ${_calculateAge(patient.dateOfBirth!)} years'),
        if (patient.gender != null) pw.Text('Gender: ${patient.gender}'),
        pw.Text('Case Date: ${_formatDate(caseData.consultationDate)}'),
        pw.Text('Status: ${caseData.status.toUpperCase()}'),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _buildParagraph(String text) {
    return pw.Text(text, textAlign: pw.TextAlign.justify);
  }

  static List<pw.Widget> _buildSymptomsList(List<Symptom> symptoms) {
    return symptoms.map((symptom) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('• ${symptom.symptomText}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (symptom.location != null)
              pw.Text('  Location: ${symptom.location}', style: const pw.TextStyle(fontSize: 10)),
            if (symptom.sensation != null)
              pw.Text('  Sensation: ${symptom.sensation}', style: const pw.TextStyle(fontSize: 10)),
            if (symptom.modalities != null)
              pw.Text('  Modalities: ${symptom.modalities}', style: const pw.TextStyle(fontSize: 10)),
            if (symptom.concomitants != null)
              pw.Text('  Concomitants: ${symptom.concomitants}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );
    }).toList();
  }

  static List<pw.Widget> _buildSimpleSymptomsList(List<Symptom> symptoms) {
    return symptoms.map((s) => pw.Text('• ${s.symptomText}')).toList();
  }

  static pw.Widget _buildPhysicalGenerals(PhysicalGeneral pg) {
    final items = <String>[];
    if (pg.thermalType != null) items.add('Thermals: ${pg.thermalType}');
    if (pg.thirstQuantity != null) items.add('Thirst: ${pg.thirstQuantity}');
    if (pg.cravings != null) items.add('Cravings: ${pg.cravings}');
    if (pg.aversions != null) items.add('Aversions: ${pg.aversions}');
    if (pg.sleepQuality != null) items.add('Sleep: ${pg.sleepQuality}');
    if (pg.dreams != null) items.add('Dreams: ${pg.dreams}');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) => pw.Text('• $item')).toList(),
    );
  }

  static pw.Widget _buildMentalEmotional(MentalEmotional me) {
    final items = <String>[];
    if (me.disposition != null) items.add('Disposition: ${me.disposition}');
    if (me.fears != null) items.add('Fears: ${me.fears}');
    if (me.emotionalTriggers != null) items.add('Triggers: ${me.emotionalTriggers}');
    if (me.keyEmotions != null) items.add('Key Emotions: ${me.keyEmotions}');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) => pw.Text('• $item')).toList(),
    );
  }

  static pw.Widget _buildRemedySuggestions(List<RemedySuggestion> suggestions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: suggestions.take(5).map((remedy) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${remedy.remedyName} (${remedy.confidence ?? remedy.grade ?? 'N/A'})',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (remedy.reason != null)
                pw.Text('  ${remedy.reason}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildPrescription(Case caseData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Remedy: ${caseData.finalRemedyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (caseData.finalRemedyPotency != null) pw.Text('Potency: ${caseData.finalRemedyPotency}'),
        if (caseData.finalRemedyDose != null) pw.Text('Dose: ${caseData.finalRemedyDose}'),
        if (caseData.prescriptionNotes != null) pw.Text('Notes: ${caseData.prescriptionNotes}'),
      ],
    );
  }

  static pw.Widget _buildFollowUps(List<FollowUp> followUps) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: followUps.map((fu) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${_formatDate(fu.followUpDate)}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(fu.notes, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods for enhanced PDF formatting
  static pw.Widget _buildLSMCTable(List<Symptom> symptoms) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: ['Complaint', 'Location', 'Sensation', 'Modalities', 'Concomitants'],
      data: symptoms.map((s) => [
        s.symptomText,
        s.location ?? 'N/A',
        s.sensation ?? 'N/A',
        s.modalities ?? 'N/A',
        s.concomitants ?? 'N/A',
      ]).toList(),
    );
  }

  static pw.Widget _buildPhysicalGeneralsTable(PhysicalGeneral pg) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      cellStyle: const pw.TextStyle(fontSize: 9),
      data: [
        ['Thermal Type', pg.thermalType ?? 'Not specified'],
        ['Thirst', pg.thirstQuantity ?? 'Not specified'],
        ['Appetite', pg.appetite ?? 'Not specified'],
        ['Food Cravings', pg.cravings ?? 'None noted'],
        ['Food Aversions', pg.aversions ?? 'None noted'],
        ['Sleep Position', pg.sleepPosition ?? 'Not specified'],
        ['Dreams', pg.dreams ?? 'None reported'],
        ['Perspiration', pg.perspiration ?? 'Not specified'],
      ],
    );
  }

  static pw.Widget _buildMentalEmotionalTable(MentalEmotional me) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      cellStyle: const pw.TextStyle(fontSize: 9),
      data: [
        ['Disposition', me.disposition ?? 'Not specified'],
        ['Fears', me.fears ?? 'Not discussed'],
        ['Key Emotions', me.keyEmotions ?? 'Not specified'],
        ['Emotional Triggers', me.emotionalTriggers ?? 'Not specified'],
      ],
    );
  }

  static pw.Widget _buildRemedyComparisonTable(List<RemedySuggestion> remedies) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headers: ['Remedy', 'Confidence', 'Differentiating Points'],
      data: remedies.take(5).map((r) => [
        r.remedyName,
        r.confidence ?? r.grade ?? 'N/A',
        r.reason ?? 'See materia medica comparison',
      ]).toList(),
    );
  }

  static pw.Widget _buildPrescriptionBox(Case caseData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
        color: PdfColors.green50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('℞', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Remedy: ${caseData.finalRemedyName}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (caseData.finalRemedyPotency != null) pw.Text('Potency: ${caseData.finalRemedyPotency}', style: const pw.TextStyle(fontSize: 12)),
          if (caseData.finalRemedyDose != null) pw.Text('Dosage: ${caseData.finalRemedyDose}', style: const pw.TextStyle(fontSize: 12)),
          if (caseData.prescriptionNotes != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(caseData.prescriptionNotes!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFollowUpTimeline(List<FollowUp> followUps) {
    return pw.Column(
      children: followUps.asMap().entries.map((entry) {
        final fu = entry.value;
        final index = entry.key;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            color: index == 0 ? PdfColors.blue50 : null,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 80,
                child: pw.Column(
                  children: [
                    pw.Text(_formatDate(fu.followUpDate), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (fu.changes != null) pw.Text('Changes: ${fu.changes}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(fu.notes, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildDisclaimer() {
    return pw.Text(
      'DISCLAIMER: This case analysis is for professional homeopathic practitioner review only. '
      'It does not constitute medical advice. Always consult a qualified healthcare provider.',
      style: const pw.TextStyle(fontSize: 8),
      textAlign: pw.TextAlign.center,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}

// ============================================================================
// JSON EXPORT
// ============================================================================

class JSONExporter {
  /// Export a complete case as JSON for backup/import
  static Future<File> exportCase({
    required Case caseData,
    required Patient patient,
    List<Symptom>? symptoms,
    PhysicalGeneral? physicalGenerals,
    MentalEmotional? mentalEmotional,
    List<RemedySuggestion>? remedySuggestions,
    List<FollowUp>? followUps,
  }) async {
    final json = {
      'exportVersion': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'patient': _patientToJson(patient),
      'case': _caseToJson(caseData),
      if (symptoms != null) 'symptoms': symptoms.map(_symptomToJson).toList(),
      if (physicalGenerals != null) 'physicalGenerals': _physicalGeneralsToJson(physicalGenerals),
      if (mentalEmotional != null) 'mentalEmotional': _mentalEmotionalToJson(mentalEmotional),
      if (remedySuggestions != null) 'remedySuggestions': remedySuggestions.map(_remedyToJson).toList(),
      if (followUps != null) 'followUps': followUps.map(_followUpToJson).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/case_${caseData.id}_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(json));
    return file;
  }

  static Map<String, dynamic> _patientToJson(Patient p) => {
        'id': p.id,
        'name': p.name,
        'dateOfBirth': p.dateOfBirth?.toIso8601String(),
        'gender': p.gender,
        'occupation': p.occupation,
        'address': p.address,
        'contactPhone': p.contactPhone,
        'contactEmail': p.contactEmail,
        'notes': p.notes,
      };

  static Map<String, dynamic> _caseToJson(Case c) => {
        'id': c.id,
        'title': c.title,
        'consultationDate': c.consultationDate.toIso8601String(),
        'spontaneousNarrative': c.spontaneousNarrative,
        'portraitSummary': c.portraitSummary,
        'status': c.status,
        'finalRemedyName': c.finalRemedyName,
        'finalRemedyPotency': c.finalRemedyPotency,
        'finalRemedyDose': c.finalRemedyDose,
        'prescriptionNotes': c.prescriptionNotes,
      };

  static Map<String, dynamic> _symptomToJson(Symptom s) => {
        'type': s.type,
        'text': s.symptomText,
        'location': s.location,
        'sensation': s.sensation,
        'modalities': s.modalities,
        'concomitants': s.concomitants,
        'isPeculiar': s.isPeculiar,
        'isMarkedSRP': s.isMarkedSRP,
        'priorityRank': s.priorityRank,
      };

  static Map<String, dynamic> _physicalGeneralsToJson(PhysicalGeneral pg) => {
        'thermalType': pg.thermalType,
        'thermalDetails': pg.thermalDetails,
        'thirstQuantity': pg.thirstQuantity,
        'thirstFrequency': pg.thirstFrequency,
        'appetite': pg.appetite,
        'cravings': pg.cravings,
        'aversions': pg.aversions,
        'sleepQuality': pg.sleepQuality,
        'dreams': pg.dreams,
      };

  static Map<String, dynamic> _mentalEmotionalToJson(MentalEmotional me) => {
        'disposition': me.disposition,
        'fears': me.fears,
        'emotionalTriggers': me.emotionalTriggers,
        'keyEmotions': me.keyEmotions,
      };

  static Map<String, dynamic> _remedyToJson(RemedySuggestion r) => {
        'remedyName': r.remedyName,
        'source': r.source,
        'grade': r.grade,
        'confidence': r.confidence,
        'reason': r.reason,
      };

  static Map<String, dynamic> _followUpToJson(FollowUp fu) => {
        'followUpDate': fu.followUpDate.toIso8601String(),
        'notes': fu.notes,
        'changes': fu.changes,
      };
}
