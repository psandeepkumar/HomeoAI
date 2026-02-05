/// Sample Data Generator for Demo/Testing
/// Provides realistic homeopathy case examples

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';

class SampleDataGenerator {
  static const _uuid = Uuid();

  static Future<void> generateSampleData(AppDatabase db) async {
    // Sample Patient 1: Anxious Professional
    final patient1Id = _uuid.v4();
    await db.into(db.patients).insert(PatientsCompanion.insert(
      id: patient1Id,
      name: 'Sarah Mitchell',
      dateOfBirth: Value(DateTime(1990, 3, 15)),
      gender: const Value('Female'),
      contactPhone: const Value('+1-555-0123'),
      contactEmail: const Value('demo@example.com'),
      address: const Value('123 Demo Street, Sample City'),
    ));

    final case1Id = _uuid.v4();
    await db.into(db.cases).insert(CasesCompanion.insert(
      id: case1Id,
      patientId: patient1Id,
      title: 'Initial Consultation',
      consultationDate: DateTime(2024, 1, 15),
      spontaneousNarrative: const Value('''I've been experiencing terrible anxiety for the past 6 months. It started after my promotion at work. I wake up at 3 AM with heart palpitations and can't fall back asleep. I'm constantly worried about making mistakes at work, even though I'm performing well. My boss says I'm doing great, but I can't shake this feeling of impending doom. I've also noticed I'm very particular about cleanliness - my desk must be perfectly organized or I feel agitated. Sometimes I get sharp pains in my chest when the anxiety peaks.'''),
      status: const Value('active'),
      finalRemedyName: const Value('Arsenicum Album'),
      finalRemedyPotency: const Value('200C'),
      finalRemedyDose: const Value('3 doses, 12 hours apart'),
      prescriptionNotes: const Value('Patient shows clear Arsenicum picture: anxiety worse 1-3 AM, fastidiousness, restlessness, fear of illness. Start with 200C and observe for 2 weeks.'),
    ));

    // Chief Complaints for Patient 1
    await db.batch((batch) {
      batch.insertAll(db.symptoms, [
        SymptomsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          type: 'chief',
          symptomText: 'Anxiety with palpitations',
          location: const Value('Chest/Heart'),
          sensation: const Value('Pounding, fluttering'),
          modalities: const Value('Worse: 3 AM, before presentations. Better: after reassurance'),
          concomitants: const Value('Chest pain, sweating, trembling'),
          isMarkedSRP: const Value(true),
        ),
        SymptomsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          type: 'chief',
          symptomText: 'Insomnia from anxiety',
          location: const Value('Mind'),
          sensation: const Value('Racing thoughts, cannot shut mind off'),
          modalities: const Value('Worse: 3 AM sharp. Better: warm milk, reading'),
          isMarkedSRP: const Value(false),
        ),
        SymptomsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          type: 'peculiar',
          symptomText: 'Extreme fastidiousness about desk organization',
          isMarkedSRP: const Value(true),
        ),
      ]);
    });

    // Physical Generals for Patient 1
    await db.into(db.physicalGenerals).insert(PhysicalGeneralsCompanion.insert(
      id: _uuid.v4(),
      caseId: case1Id,
      thermalType: const Value('chilly'),
      thirstQuantity: const Value('Large quantities'),
      cravings: const Value('Salt, cheese, pickles'),
      aversions: const Value('Sweets'),
      sleepPosition: const Value('Right side'),
      dreams: const Value('Falling, being late for work, tsunamis'),
      perspiration: const Value('Profuse on palms when anxious'),
    ));

    // Mental/Emotional for Patient 1
    await db.into(db.mentalEmotionals).insert(MentalEmotionalsCompanion.insert(
      id: _uuid.v4(),
      caseId: case1Id,
      disposition: const Value('Anxious, fastidious, conscientious'),
      fears: const Value('Making mistakes, losing control, illness'),
      keyEmotions: const Value('Anxiety, worry, restlessness'),
      emotionalTriggers: const Value('Increased responsibility at work'),
    ));

    // Remedy Suggestions for Patient 1
    await db.batch((batch) {
      batch.insertAll(db.remedySuggestions, [
        RemedySuggestionsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          remedyName: 'Arsenicum Album',
          source: 'Manual/Demo',
          confidence: const Value('90%'),
          grade: const Value('A'),
          reason: const Value('Anxiety with restlessness, fastidiousness, fear of illness, worse 1-3 AM, desires for warmth and company'),
        ),
        RemedySuggestionsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          remedyName: 'Nux Vomica',
          source: 'Manual/Demo',
          confidence: const Value('75%'),
          grade: const Value('B'),
          reason: const Value('Ambitious professional, perfectionism, irritability - but lacks the characteristic impatience and anger'),
        ),
        RemedySuggestionsCompanion.insert(
          id: _uuid.v4(),
          caseId: case1Id,
          remedyName: 'Phosphorus',
          source: 'Manual/Demo',
          confidence: const Value('60%'),
          grade: const Value('C'),
          reason: const Value('Anxiety, craving for salt and cold drinks, sympathetic nature - but less restless than typical Phos'),
        ),
      ]);
    });

    // Sample Patient 2: Migraine with Hormonal Pattern
    final patient2Id = _uuid.v4();
    await db.into(db.patients).insert(PatientsCompanion.insert(
      id: patient2Id,
      name: 'Jennifer Lopez',
      dateOfBirth: Value(DateTime(1982, 5, 20)),
      gender: const Value('Female'),
      contactPhone: const Value('+1-555-0456'),
    ));

    final case2Id = _uuid.v4();
    await db.into(db.cases).insert(CasesCompanion.insert(
      id: case2Id,
      patientId: patient2Id,
      title: 'Initial Consultation',
      consultationDate: DateTime(2024, 2, 10),
      spontaneousNarrative: const Value('''I get these terrible headaches every month right before my period. The pain is so bad I have to lie down in a dark room. It feels like my head is being squeezed in a vice, and I see zigzag lines before the headache starts. Any light or noise makes it unbearable. I also cry easily during this time - even commercials make me weep. I crave chocolate intensely. The headaches started about 2 years ago after my divorce.'''),
      status: const Value('active'),
    ));

    await db.batch((batch) {
      batch.insertAll(db.symptoms, [
        SymptomsCompanion.insert(
          id: _uuid.v4(),
          caseId: case2Id,
          type: 'chief',
          symptomText: 'Premenstrual migraine',
          location: const Value('Left temple, radiating to left eye'),
          sensation: const Value('Throbbing, bursting, vice-like pressure'),
          modalities: const Value('Worse: before menses, light, noise, motion. Better: lying still in dark room, firm pressure'),
          concomitants: const Value('Visual aura (zigzags), nausea, photophobia'),
          isMarkedSRP: const Value(false),
        ),
      ]);
    });

    await db.into(db.mentalEmotionals).insert(MentalEmotionalsCompanion.insert(
      id: _uuid.v4(),
      caseId: case2Id,
      disposition: const Value('Weepy, gentle, yielding'),
      keyEmotions: const Value('Sadness, easily moved to tears, needs consolation'),
      emotionalTriggers: const Value('Grief from divorce'),
    ));

    // Sample Patient 3: Child with Ear Infections
    final patient3Id = _uuid.v4();
    await db.into(db.patients).insert(PatientsCompanion.insert(
      id: patient3Id,
      name: 'Tommy Anderson',
      dateOfBirth: Value(DateTime(2020, 8, 10)),
      gender: const Value('Male'),
      contactPhone: const Value('+1-555-0789'),
    ));

    final case3Id = _uuid.v4();
    await db.into(db.cases).insert(CasesCompanion.insert(
      id: case3Id,
      patientId: patient3Id,
      title: 'Initial Consultation',
      consultationDate: DateTime(2024, 2, 20),
      spontaneousNarrative: const Value('''Tommy gets ear infections every few months. When he has one, he screams inconsolably and nothing helps except being carried around. He pulls at his right ear and won't let anyone touch it. He's usually a sweet child, but during infections he becomes very clingy and wants only mom. He refuses water when sick but craves ice cream. He's always hot - kicks off blankets at night and wants windows open even in winter.'''),
      status: const Value('active'),
    ));

    await db.batch((batch) {
      batch.insertAll(db.symptoms, [
        SymptomsCompanion.insert(
          id: _uuid.v4(),
          caseId: case3Id,
          type: 'chief',
          symptomText: 'Recurrent right ear infections',
          location: const Value('Right ear, mostly'),
          sensation: const Value('Sharp, stabbing pain'),
          modalities: const Value('Worse: lying down, night, touch. Better: being carried, open air'),
          concomitants: const Value('Fever, irritability, thirstlessness'),
          isMarkedSRP: const Value(false),
        ),
      ]);
    });

    await db.into(db.physicalGenerals).insert(PhysicalGeneralsCompanion.insert(
      id: _uuid.v4(),
      caseId: case3Id,
      thermalType: const Value('hot'),
      thirstQuantity: const Value('Thirstless'),
      cravings: const Value('Ice cream, cold drinks'),
      sleepPosition: const Value('Abdomen'),
    ));

    await db.into(db.mentalEmotionals).insert(MentalEmotionalsCompanion.insert(
      id: _uuid.v4(),
      caseId: case3Id,
      disposition: const Value('Clingy when sick, wants to be carried constantly'),
      keyEmotions: const Value('Irritable during illness, consolation worsens'),
    ));
  }

  static Future<void> clearAllData(AppDatabase db) async {
    await db.delete(db.followUps).go();
    // await db.delete(db.aiAuditLogs).go(); // Skip if table doesn't exist yet
    await db.delete(db.remedySuggestions).go();
    await db.delete(db.repertoryRubrics).go();
    await db.delete(db.mentalEmotionals).go();
    await db.delete(db.physicalGenerals).go();
    await db.delete(db.symptoms).go();
    await db.delete(db.cases).go();
    await db.delete(db.patients).go();
  }
}
