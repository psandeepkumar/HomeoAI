/// Repository pattern implementation for data access
/// 
/// Provides a clean abstraction layer between the UI/state management
/// and the drift database, encapsulating all CRUD operations.

import 'package:uuid/uuid.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;

const _uuid = Uuid();

// ============================================================================
// PATIENT REPOSITORY
// ============================================================================

class PatientRepository {
  final AppDatabase _db;

  PatientRepository(this._db);

  /// Get all patients
  Future<List<Patient>> getAllPatients() async {
    return await _db.select(_db.patients).get();
  }

  /// Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    return await (_db.select(_db.patients)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Search patients by name
  Future<List<Patient>> searchPatients(String query) async {
    return await (_db.select(_db.patients)
          ..where((p) => p.name.contains(query)))
        .get();
  }

  /// Create new patient
  Future<Patient> createPatient({
    required String name,
    DateTime? dateOfBirth,
    String? gender,
    String? occupation,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final patient = PatientsCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      dateOfBirth: drift.Value(dateOfBirth),
      gender: drift.Value(gender),
      occupation: drift.Value(occupation),
      address: drift.Value(address),
      contactPhone: drift.Value(contactPhone),
      contactEmail: drift.Value(contactEmail),
      notes: drift.Value(notes),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.patients).insert(patient);
    return (await getPatientById(id))!;
  }

  /// Update patient
  Future<bool> updatePatient(Patient patient) async {
    final updated = patient.copyWith(updatedAt: DateTime.now());
    return await _db.update(_db.patients).replace(updated);
  }

  /// Delete patient (cascades to all related cases)
  Future<int> deletePatient(String id) async {
    return await (_db.delete(_db.patients)..where((p) => p.id.equals(id)))
        .go();
  }
}

// ============================================================================
// CASE REPOSITORY
// ============================================================================

class CaseRepository {
  final AppDatabase _db;

  CaseRepository(this._db);

  /// Get all cases for a patient
  Future<List<Case>> getCasesForPatient(String patientId) async {
    return await (_db.select(_db.cases)
          ..where((c) => c.patientId.equals(patientId))
          ..orderBy([(c) => drift.OrderingTerm.desc(c.consultationDate)]))
        .get();
  }

  /// Get case by ID
  Future<Case?> getCaseById(String id) async {
    return await (_db.select(_db.cases)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get recent cases (for dashboard)
  Future<List<Case>> getRecentCases({int limit = 10}) async {
    return await (_db.select(_db.cases)
          ..orderBy([(c) => drift.OrderingTerm.desc(c.updatedAt)])
          ..limit(limit))
        .get();
  }

  /// Create new case
  Future<Case> createCase({
    required String patientId,
    required String title,
    DateTime? consultationDate,
    String? spontaneousNarrative,
    String status = 'draft',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final caseData = CasesCompanion(
      id: drift.Value(id),
      patientId: drift.Value(patientId),
      title: drift.Value(title),
      consultationDate: drift.Value(consultationDate ?? now),
      spontaneousNarrative: drift.Value(spontaneousNarrative),
      status: drift.Value(status),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await _db.into(_db.cases).insert(caseData);
    return (await getCaseById(id))!;
  }

  /// Update case
  Future<bool> updateCase(Case caseData) async {
    final updated = caseData.copyWith(updatedAt: DateTime.now());
    return await _db.update(_db.cases).replace(updated);
  }

  /// Update case portrait summary
  Future<void> updatePortraitSummary(String caseId, String summary) async {
    await (_db.update(_db.cases)..where((c) => c.id.equals(caseId)))
        .write(CasesCompanion(portraitSummary: drift.Value(summary)));
  }

  /// Update case status
  Future<void> updateCaseStatus(String caseId, String status) async {
    await (_db.update(_db.cases)..where((c) => c.id.equals(caseId)))
        .write(CasesCompanion(
      status: drift.Value(status),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  /// Save final remedy prescription
  Future<void> savePrescription({
    required String caseId,
    required String remedyName,
    String? potency,
    String? dose,
    String? notes,
  }) async {
    await (_db.update(_db.cases)..where((c) => c.id.equals(caseId)))
        .write(CasesCompanion(
      finalRemedyName: drift.Value(remedyName),
      finalRemedyPotency: drift.Value(potency),
      finalRemedyDose: drift.Value(dose),
      prescriptionNotes: drift.Value(notes),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  /// Delete case
  Future<int> deleteCase(String id) async {
    return await (_db.delete(_db.cases)..where((c) => c.id.equals(id))).go();
  }
}

// ============================================================================
// SYMPTOM REPOSITORY
// ============================================================================

class SymptomRepository {
  final AppDatabase _db;

  SymptomRepository(this._db);

  /// Get all symptoms for a case
  Future<List<Symptom>> getSymptomsForCase(String caseId) async {
    return await (_db.select(_db.symptoms)
          ..where((s) => s.caseId.equals(caseId))
          ..orderBy([(s) => drift.OrderingTerm.desc(s.priorityRank)]))
        .get();
  }

  /// Get symptoms by type
  Future<List<Symptom>> getSymptomsByType(String caseId, String type) async {
    return await (_db.select(_db.symptoms)
          ..where((s) => s.caseId.equals(caseId) & s.type.equals(type)))
        .get();
  }

  /// Get peculiar/SRP symptoms
  Future<List<Symptom>> getPeculiarSymptoms(String caseId) async {
    return await (_db.select(_db.symptoms)
          ..where((s) => s.caseId.equals(caseId) & s.isMarkedSRP.equals(true)))
        .get();
  }

  /// Add symptom
  Future<Symptom> addSymptom({
    required String caseId,
    required String type,
    required String text,
    String? location,
    String? sensation,
    String? modalities,
    String? concomitants,
    bool isPeculiar = false,
    bool isMarkedSRP = false,
    int? priorityRank,
  }) async {
    final id = _uuid.v4();

    final symptom = SymptomsCompanion(
      id: drift.Value(id),
      caseId: drift.Value(caseId),
      type: drift.Value(type),
      symptomText: drift.Value(text),
      location: drift.Value(location),
      sensation: drift.Value(sensation),
      modalities: drift.Value(modalities),
      concomitants: drift.Value(concomitants),
      isPeculiar: drift.Value(isPeculiar),
      isMarkedSRP: drift.Value(isMarkedSRP),
      priorityRank: drift.Value(priorityRank),
      createdAt: drift.Value(DateTime.now()),
    );

    await _db.into(_db.symptoms).insert(symptom);
    return (await getSymptomById(id))!;
  }

  /// Get symptom by ID
  Future<Symptom?> getSymptomById(String id) async {
    return await (_db.select(_db.symptoms)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update symptom
  Future<bool> updateSymptom(Symptom symptom) async {
    return await _db.update(_db.symptoms).replace(symptom);
  }

  /// Mark symptom as SRP
  Future<void> markAsSRP(String symptomId, bool isSRP) async {
    await (_db.update(_db.symptoms)..where((s) => s.id.equals(symptomId)))
        .write(SymptomsCompanion(isMarkedSRP: drift.Value(isSRP)));
  }

  /// Delete symptom
  Future<int> deleteSymptom(String id) async {
    return await (_db.delete(_db.symptoms)..where((s) => s.id.equals(id)))
        .go();
  }
}

// ============================================================================
// PHYSICAL GENERALS REPOSITORY
// ============================================================================

class PhysicalGeneralsRepository {
  final AppDatabase _db;

  PhysicalGeneralsRepository(this._db);

  /// Get physical generals for a case
  Future<PhysicalGeneral?> getForCase(String caseId) async {
    return await (_db.select(_db.physicalGenerals)
          ..where((pg) => pg.caseId.equals(caseId)))
        .getSingleOrNull();
  }

  /// Create or update physical generals
  Future<PhysicalGeneral> upsert({
    required String caseId,
    String? thermalType,
    String? thermalDetails,
    String? thirstQuantity,
    String? thirstFrequency,
    String? thirstTemperature,
    String? appetite,
    String? cravings,
    String? aversions,
    String? sleepQuality,
    String? sleepPosition,
    bool? sleepRefreshing,
    String? dreams,
    String? perspiration,
    String? bowelHabits,
    String? urinarySymptoms,
    String? otherGenerals,
  }) async {
    final existing = await getForCase(caseId);
    final now = DateTime.now();

    if (existing != null) {
      // Update
      final updated = PhysicalGeneralsCompanion(
        id: drift.Value(existing.id),
        thermalType: drift.Value(thermalType),
        thermalDetails: drift.Value(thermalDetails),
        thirstQuantity: drift.Value(thirstQuantity),
        thirstFrequency: drift.Value(thirstFrequency),
        thirstTemperature: drift.Value(thirstTemperature),
        appetite: drift.Value(appetite),
        cravings: drift.Value(cravings),
        aversions: drift.Value(aversions),
        sleepQuality: drift.Value(sleepQuality),
        sleepPosition: drift.Value(sleepPosition),
        sleepRefreshing: drift.Value(sleepRefreshing),
        dreams: drift.Value(dreams),
        perspiration: drift.Value(perspiration),
        bowelHabits: drift.Value(bowelHabits),
        urinarySymptoms: drift.Value(urinarySymptoms),
        otherGenerals: drift.Value(otherGenerals),
        updatedAt: drift.Value(now),
      );
      await (_db.update(_db.physicalGenerals)
            ..where((pg) => pg.id.equals(existing.id)))
          .write(updated);
      return (await getForCase(caseId))!;
    } else {
      // Create
      final id = _uuid.v4();
      final data = PhysicalGeneralsCompanion(
        id: drift.Value(id),
        caseId: drift.Value(caseId),
        thermalType: drift.Value(thermalType),
        thermalDetails: drift.Value(thermalDetails),
        thirstQuantity: drift.Value(thirstQuantity),
        thirstFrequency: drift.Value(thirstFrequency),
        thirstTemperature: drift.Value(thirstTemperature),
        appetite: drift.Value(appetite),
        cravings: drift.Value(cravings),
        aversions: drift.Value(aversions),
        sleepQuality: drift.Value(sleepQuality),
        sleepPosition: drift.Value(sleepPosition),
        sleepRefreshing: drift.Value(sleepRefreshing),
        dreams: drift.Value(dreams),
        perspiration: drift.Value(perspiration),
        bowelHabits: drift.Value(bowelHabits),
        urinarySymptoms: drift.Value(urinarySymptoms),
        otherGenerals: drift.Value(otherGenerals),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
      await _db.into(_db.physicalGenerals).insert(data);
      return (await getForCase(caseId))!;
    }
  }
}

// ============================================================================
// MENTAL EMOTIONAL REPOSITORY
// ============================================================================

class MentalEmotionalRepository {
  final AppDatabase _db;

  MentalEmotionalRepository(this._db);

  /// Get mental/emotional data for a case
  Future<MentalEmotional?> getForCase(String caseId) async {
    return await (_db.select(_db.mentalEmotionals)
          ..where((me) => me.caseId.equals(caseId)))
        .getSingleOrNull();
  }

  /// Create or update mental/emotional data
  Future<MentalEmotional> upsert({
    required String caseId,
    String? disposition,
    String? fears,
    String? emotionalTriggers,
    String? keyEmotions,
    String? intellectMemory,
    String? willpower,
    String? otherMentals,
  }) async {
    final existing = await getForCase(caseId);
    final now = DateTime.now();

    if (existing != null) {
      final updated = MentalEmotionalsCompanion(
        id: drift.Value(existing.id),
        disposition: drift.Value(disposition),
        fears: drift.Value(fears),
        emotionalTriggers: drift.Value(emotionalTriggers),
        keyEmotions: drift.Value(keyEmotions),
        intellectMemory: drift.Value(intellectMemory),
        willpower: drift.Value(willpower),
        otherMentals: drift.Value(otherMentals),
        updatedAt: drift.Value(now),
      );
      await (_db.update(_db.mentalEmotionals)
            ..where((me) => me.id.equals(existing.id)))
          .write(updated);
      return (await getForCase(caseId))!;
    } else {
      final id = _uuid.v4();
      final data = MentalEmotionalsCompanion(
        id: drift.Value(id),
        caseId: drift.Value(caseId),
        disposition: drift.Value(disposition),
        fears: drift.Value(fears),
        emotionalTriggers: drift.Value(emotionalTriggers),
        keyEmotions: drift.Value(keyEmotions),
        intellectMemory: drift.Value(intellectMemory),
        willpower: drift.Value(willpower),
        otherMentals: drift.Value(otherMentals),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );
      await _db.into(_db.mentalEmotionals).insert(data);
      return (await getForCase(caseId))!;
    }
  }
}

// ============================================================================
// REMEDY SUGGESTION REPOSITORY
// ============================================================================

class RemedySuggestionRepository {
  final AppDatabase _db;

  RemedySuggestionRepository(this._db);

  /// Get all remedy suggestions for a case
  Future<List<RemedySuggestion>> getSuggestionsForCase(String caseId) async {
    return await (_db.select(_db.remedySuggestions)
          ..where((rs) => rs.caseId.equals(caseId))
          ..orderBy([(rs) => drift.OrderingTerm.desc(rs.createdAt)]))
        .get();
  }

  /// Get saved remedy suggestions
  Future<List<RemedySuggestion>> getSavedSuggestions(String caseId) async {
    return await (_db.select(_db.remedySuggestions)
          ..where((rs) =>
              rs.caseId.equals(caseId) & rs.savedByUser.equals(true)))
        .get();
  }

  /// Add remedy suggestion
  Future<RemedySuggestion> addSuggestion({
    required String caseId,
    required String remedyName,
    required String source,
    String? grade,
    String? confidence,
    String? reason,
    String? matchingSymptoms,
    String? differentiatingFeatures,
    bool savedByUser = false,
  }) async {
    final id = _uuid.v4();

    final suggestion = RemedySuggestionsCompanion(
      id: drift.Value(id),
      caseId: drift.Value(caseId),
      remedyName: drift.Value(remedyName),
      source: drift.Value(source),
      grade: drift.Value(grade),
      confidence: drift.Value(confidence),
      reason: drift.Value(reason),
      matchingSymptoms: drift.Value(matchingSymptoms),
      differentiatingFeatures: drift.Value(differentiatingFeatures),
      savedByUser: drift.Value(savedByUser),
      createdAt: drift.Value(DateTime.now()),
    );

    await _db.into(_db.remedySuggestions).insert(suggestion);
    return (await _getSuggestionById(id))!;
  }

  Future<RemedySuggestion?> _getSuggestionById(String id) async {
    return await (_db.select(_db.remedySuggestions)
          ..where((rs) => rs.id.equals(id)))
        .getSingleOrNull();
  }

  /// Toggle saved status
  Future<void> toggleSaved(String id, bool saved) async {
    await (_db.update(_db.remedySuggestions)..where((rs) => rs.id.equals(id)))
        .write(RemedySuggestionsCompanion(savedByUser: drift.Value(saved)));
  }

  /// Delete suggestion
  Future<int> deleteSuggestion(String id) async {
    return await (_db.delete(_db.remedySuggestions)
          ..where((rs) => rs.id.equals(id)))
        .go();
  }
}

// ============================================================================
// FOLLOW-UP REPOSITORY
// ============================================================================

class FollowUpRepository {
  final AppDatabase _db;

  FollowUpRepository(this._db);

  /// Get all follow-ups for a case
  Future<List<FollowUp>> getFollowUpsForCase(String caseId) async {
    return await (_db.select(_db.followUps)
          ..where((fu) => fu.caseId.equals(caseId))
          ..orderBy([(fu) => drift.OrderingTerm.desc(fu.followUpDate)]))
        .get();
  }

  /// Add follow-up
  Future<FollowUp> addFollowUp({
    required String caseId,
    required DateTime followUpDate,
    required String notes,
    String? changes,
    String? remedyAdjustment,
  }) async {
    final id = _uuid.v4();

    final followUp = FollowUpsCompanion(
      id: drift.Value(id),
      caseId: drift.Value(caseId),
      followUpDate: drift.Value(followUpDate),
      notes: drift.Value(notes),
      changes: drift.Value(changes),
      remedyAdjustment: drift.Value(remedyAdjustment),
      createdAt: drift.Value(DateTime.now()),
    );

    await _db.into(_db.followUps).insert(followUp);
    return (await _getFollowUpById(id))!;
  }

  Future<FollowUp?> _getFollowUpById(String id) async {
    return await (_db.select(_db.followUps)..where((fu) => fu.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update follow-up
  Future<bool> updateFollowUp(FollowUp followUp) async {
    return await _db.update(_db.followUps).replace(followUp);
  }

  /// Delete follow-up
  Future<int> deleteFollowUp(String id) async {
    return await (_db.delete(_db.followUps)..where((fu) => fu.id.equals(id)))
        .go();
  }
}
