/// Grok AI Prompt Templates for Classical Homeopathic Case Analysis
/// 
/// This file contains structured prompt templates that guide Grok to perform
/// classical homeopathic analysis following the single-remedy approach.

class GrokPrompts {
  /// System prompt defining Grok's role as a Classical Homeopathic Case Analyst
  static const String systemPrompt = '''
Role: You are a Classical Homeopathic Case Analyst. Your purpose is to process unstructured patient narratives into a structured homeopathic totality to find the simillimum.

Core Logic & Hierarchy:

1. Analyze the Narrative: Extract the "Spontaneous Narrative." Identify the patient's primary concerns, tone, and emphasis.

2. Apply LSMC: Structure all physical complaints into Location, Sensation, Modalities, and Concomitants.

3. Prioritize the Totality: Rank symptoms according to the following homeopathic hierarchy:
   - MIND: Disposition, emotional triggers, and "Ailments from."
   - GENERALS: Thermals (Chilly/Hot), Thirst, Food Cravings/Aversions, and Sleep.
   - SRP (Strange, Rare, Peculiar): High-intensity, unique symptoms that individualize the case.

4. Repertorize: Map extracted symptoms to standard repertory rubrics (Kent/Synthesis style).

5. Differentiate: Provide a differential analysis of 3 potential remedies based on the Materia Medica.

Response Requirements:
- Tone: Clinical, precise, and observant.
- Safety: Include a disclaimer that results are for practitioner review only.
- Format: Return data in structured JSON format compatible with database storage.

Privacy & Ethics:
- Do not infer or reference any personally identifiable information.
- Focus solely on symptom patterns and homeopathic individualization.
- Never provide direct medical advice or suggest discontinuing conventional treatment.
''';

  /// Prompt for analyzing spontaneous narrative and extracting themes
  static String analyzeSpontaneousNarrative({
    required String narrative,
    String? patientAge,
    String? patientGender,
  }) {
    final demographics = _buildDemographics(patientAge, patientGender);
    
    return '''
Analyze the following spontaneous narrative from a patient $demographics.

NARRATIVE:
"""
$narrative
"""

Please extract and return a JSON object with the following structure:

{
  "portrait": "A 2-3 sentence clinical summary of the individual behind the disease",
  "primaryConcerns": ["concern1", "concern2", "concern3"],
  "emotionalTone": "Description of the patient's emotional state and manner of expression",
  "keyThemes": ["theme1", "theme2"],
  "suggestedQuestions": [
    "Clarifying question 1 about a specific symptom?",
    "Question 2 exploring modalities?",
    "Question 3 about mental/emotional state?"
  ]
}

Focus on what makes this case unique. Identify any peculiar expressions or striking symptoms mentioned.
''';
  }

  /// Prompt for highlighting Strange, Rare, Peculiar (SRP) symptoms
  static String highlightPeculiarSymptoms({
    required List<String> symptoms,
  }) {
    final symptomList = symptoms.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return '''
Review the following symptoms and identify which ones are Strange, Rare, or Peculiar (SRP) according to classical homeopathic principles.

SYMPTOMS:
$symptomList

Return a JSON object:

{
  "srpSymptoms": [
    {
      "index": 1,
      "symptom": "original symptom text",
      "reason": "Why this is considered peculiar/strange/rare",
      "intensity": "high|medium|low"
    }
  ],
  "commonSymptoms": [1, 3, 5],
  "analysis": "Brief explanation of what makes certain symptoms individualizing"
}

SRP criteria:
- Strange: Unusual, unexpected manifestations
- Rare: Uncommon in typical presentations
- Peculiar: Highly individual, specific to this patient
''';
  }

  /// Prompt for complete case analysis and repertorization
  static String analyzeCase({
    required String spontaneousNarrative,
    required List<SymptomData> chiefComplaints,
    required Map<String, dynamic> physicalGenerals,
    required Map<String, dynamic> mentalEmotional,
    required List<String> selectedKeySymptoms,
  }) {
    final complaintsText = _formatChiefComplaints(chiefComplaints);
    final generalsText = _formatPhysicalGenerals(physicalGenerals);
    final mentalsText = _formatMentalEmotional(mentalEmotional);
    final keySymptomsList = selectedKeySymptoms.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return '''
Perform a complete classical homeopathic case analysis on the following patient data.

SPONTANEOUS NARRATIVE:
"""
$spontaneousNarrative
"""

CHIEF COMPLAINTS (LSMC structured):
$complaintsText

PHYSICAL GENERALS:
$generalsText

MENTAL & EMOTIONAL:
$mentalsText

KEY SELECTED SYMPTOMS FOR REPERTORIZATION:
$keySymptomsList

Please return a comprehensive JSON analysis:

{
  "portrait": "Detailed portrait of the individual (3-4 sentences)",
  "symptomHierarchy": {
    "mind": ["mental symptom 1", "mental symptom 2"],
    "generals": ["general 1", "general 2"],
    "srp": ["peculiar 1", "peculiar 2"],
    "locals": ["local symptom 1"]
  },
  "repertoryRubrics": [
    {
      "rubric": "MIND - ANXIETY - health, about",
      "grade": 3,
      "source": "Kent",
      "justification": "Why this rubric applies to this case"
    }
  ],
  "remedySuggestions": [
    {
      "remedy": "Arsenicum album",
      "confidence": "high|medium|low",
      "grade": "A|B|C",
      "matchingSymptoms": ["symptom 1", "symptom 2"],
      "differentiatingFeatures": "Key features that suggest this remedy",
      "materiaComparison": "Brief comparison with the patient portrait"
    }
  ],
  "differentialAnalysis": "A clinical comparison of the top 3 remedies and why one stands out",
  "followUpQuestions": ["Question to clarify differential?"],
  "disclaimer": "IMPORTANT: This analysis is for professional homeopathic practitioner review only. Not medical advice. Consult a qualified healthcare provider."
}

Prioritize MIND symptoms and GENERALS. Focus on individualization, not disease diagnosis.
Limit remedy suggestions to top 5 maximum.
''';
  }

  /// Prompt for comparing specific remedies in a differential
  static String compareRemedies({
    required List<String> remedies,
    required String patientPortrait,
    required List<String> keySymptoms,
  }) {
    final remedyList = remedies.join(', ');
    final symptomList = keySymptoms.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    return '''
Provide a detailed differential comparison of the following remedies in the context of this patient case.

PATIENT PORTRAIT:
$patientPortrait

KEY SYMPTOMS:
$symptomList

REMEDIES TO COMPARE:
$remedyList

Return JSON:

{
  "comparison": [
    {
      "remedy": "Remedy name",
      "matchingPoints": ["matches this case in...", "also shows..."],
      "missingPoints": ["lacks this symptom", "doesn't explain..."],
      "materiaHighlights": "Key materia medica characteristics",
      "score": 0.0-1.0
    }
  ],
  "recommendation": "Which remedy appears most similar and why",
  "cautionaryNotes": "Important differential points to consider"
}
''';
  }

  /// Prompt for suggesting follow-up questions based on incomplete data
  static String suggestFollowUpQuestions({
    required String currentData,
    required List<String> missingAreas,
  }) {
    final areas = missingAreas.join(', ');

    return '''
Based on the current case data, suggest clarifying questions to complete the homeopathic totality.

CURRENT DATA:
$currentData

MISSING/INCOMPLETE AREAS:
$areas

Return JSON:

{
  "questions": [
    {
      "area": "Thermals|Mentals|Modalities|etc.",
      "question": "Specific question to ask patient",
      "purpose": "What this question will help clarify"
    }
  ],
  "priority": "Which area should be explored first"
}

Focus on questions that help individualize the case and identify the simillimum.
''';
  }

  // Helper methods for formatting

  static String _buildDemographics(String? age, String? gender) {
    if (age == null && gender == null) return '';
    if (age != null && gender != null) return '($gender, age $age)';
    if (age != null) return '(age $age)';
    return '($gender)';
  }

  static String _formatChiefComplaints(List<SymptomData> complaints) {
    if (complaints.isEmpty) return 'None recorded';
    
    return complaints.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final c = entry.value;
      return '''
Complaint $i: ${c.title}
  Location: ${c.location ?? 'not specified'}
  Sensation: ${c.sensation ?? 'not specified'}
  Modalities: ${c.modalities ?? 'not specified'}
  Concomitants: ${c.concomitants ?? 'not specified'}
''';
    }).join('\n');
  }

  static String _formatPhysicalGenerals(Map<String, dynamic> generals) {
    final buffer = StringBuffer();
    
    if (generals['thermals'] != null) {
      buffer.writeln('Thermals: ${generals['thermals']}');
    }
    if (generals['thirst'] != null) {
      buffer.writeln('Thirst: ${generals['thirst']}');
    }
    if (generals['appetite'] != null) {
      buffer.writeln('Appetite/Cravings/Aversions: ${generals['appetite']}');
    }
    if (generals['sleep'] != null) {
      buffer.writeln('Sleep: ${generals['sleep']}');
    }
    if (generals['dreams'] != null) {
      buffer.writeln('Dreams: ${generals['dreams']}');
    }
    if (generals['perspiration'] != null) {
      buffer.writeln('Perspiration: ${generals['perspiration']}');
    }
    
    return buffer.isEmpty ? 'Not recorded' : buffer.toString().trim();
  }

  static String _formatMentalEmotional(Map<String, dynamic> mental) {
    final buffer = StringBuffer();
    
    if (mental['disposition'] != null) {
      buffer.writeln('Disposition: ${mental['disposition']}');
    }
    if (mental['fears'] != null) {
      buffer.writeln('Fears: ${mental['fears']}');
    }
    if (mental['emotionalTriggers'] != null) {
      buffer.writeln('Emotional Triggers/Ailments From: ${mental['emotionalTriggers']}');
    }
    if (mental['keyEmotions'] != null) {
      buffer.writeln('Key Emotions: ${mental['keyEmotions']}');
    }
    
    return buffer.isEmpty ? 'Not recorded' : buffer.toString().trim();
  }
}

/// Data class for symptom information used in prompts
class SymptomData {
  final String title;
  final String? location;
  final String? sensation;
  final String? modalities;
  final String? concomitants;

  const SymptomData({
    required this.title,
    this.location,
    this.sensation,
    this.modalities,
    this.concomitants,
  });
}
