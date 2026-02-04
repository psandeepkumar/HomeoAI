/// Drift database schema for HomeoAI
/// 
/// Defines tables for patients, cases, symptoms, follow-ups, and remedy suggestions
/// using the drift package for type-safe SQL operations.

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================

/// Patients table - stores basic patient demographics
@DataClassName('Patient')
class Patients extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().withLength(min: 1, max: 200)();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text().nullable().withLength(max: 50)();
  TextColumn get occupation => text().nullable().withLength(max: 200)();
  TextColumn get address => text().nullable()();
  TextColumn get contactPhone => text().nullable().withLength(max: 50)();
  TextColumn get contactEmail => text().nullable().withLength(max: 200)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cases table - stores individual case consultations
@DataClassName('Case')
class Cases extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get patientId => text().references(Patients, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  DateTimeColumn get consultationDate => dateTime()();
  
  // Spontaneous narrative and AI-generated summary
  TextColumn get spontaneousNarrative => text().nullable()();
  TextColumn get portraitSummary => text().nullable()();
  
  // Case status: draft, active, completed, archived
  TextColumn get status => text().withDefault(const Constant('draft'))();
  
  // Final remedy details (if prescribed)
  TextColumn get finalRemedyName => text().nullable()();
  TextColumn get finalRemedyPotency => text().nullable()();
  TextColumn get finalRemedyDose => text().nullable()();
  TextColumn get prescriptionNotes => text().nullable()();
  
  // Metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Symptoms table - stores structured symptoms for each case
@DataClassName('Symptom')
class Symptoms extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  // Symptom type: chief, general, mental, peculiar, local
  TextColumn get type => text()();
  
  // LSMC structure for chief complaints
  TextColumn get symptomText => text()(); // Main symptom description
  TextColumn get location => text().nullable()();
  TextColumn get sensation => text().nullable()();
  TextColumn get modalities => text().nullable()(); // JSON array or comma-separated
  TextColumn get concomitants => text().nullable()();
  
  // Flags and priority
  BoolColumn get isPeculiar => boolean().withDefault(const Constant(false))();
  BoolColumn get isMarkedSRP => boolean().withDefault(const Constant(false))();
  IntColumn get priorityRank => integer().nullable()(); // 1-10, user-assigned importance
  
  // Metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Physical Generals table - stores thermals, thirst, appetite, sleep, etc.
@DataClassName('PhysicalGeneral')
class PhysicalGenerals extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  // Thermals
  TextColumn get thermalType => text().nullable()(); // chilly, hot, ambithermal
  TextColumn get thermalDetails => text().nullable()();
  
  // Thirst
  TextColumn get thirstQuantity => text().nullable()(); // large, small, thirstless
  TextColumn get thirstFrequency => text().nullable()();
  TextColumn get thirstTemperature => text().nullable()(); // cold, warm, room temp
  
  // Appetite & Food
  TextColumn get appetite => text().nullable()();
  TextColumn get cravings => text().nullable()(); // JSON array or comma-separated
  TextColumn get aversions => text().nullable()();
  
  // Sleep
  TextColumn get sleepQuality => text().nullable()();
  TextColumn get sleepPosition => text().nullable()();
  BoolColumn get sleepRefreshing => boolean().nullable()();
  TextColumn get dreams => text().nullable()();
  
  // Other generals
  TextColumn get perspiration => text().nullable()();
  TextColumn get bowelHabits => text().nullable()();
  TextColumn get urinarySymptoms => text().nullable()();
  TextColumn get otherGenerals => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mental & Emotional table - stores disposition, fears, triggers
@DataClassName('MentalEmotional')
class MentalEmotionals extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get disposition => text().nullable()(); // irritable, mild, yielding, etc.
  TextColumn get fears => text().nullable()(); // JSON array or comma-separated
  TextColumn get emotionalTriggers => text().nullable()(); // ailments from grief, etc.
  TextColumn get keyEmotions => text().nullable()();
  TextColumn get intellectMemory => text().nullable()();
  TextColumn get willpower => text().nullable()();
  TextColumn get otherMentals => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Remedy Suggestions table - stores AI-generated or manual remedy suggestions
@DataClassName('RemedySuggestion')
class RemedySuggestions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get remedyName => text()();
  TextColumn get source => text()(); // 'grok', 'manual', 'analysis'
  TextColumn get grade => text().nullable()(); // A, B, C or confidence level
  TextColumn get confidence => text().nullable()(); // high, medium, low
  TextColumn get reason => text().nullable()(); // Why this remedy was suggested
  TextColumn get matchingSymptoms => text().nullable()(); // JSON array
  TextColumn get differentiatingFeatures => text().nullable()();
  
  BoolColumn get savedByUser => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Repertory Rubrics table - stores rubrics identified by Grok or manually
@DataClassName('RepertoryRubric')
class RepertoryRubrics extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get rubric => text()(); // e.g., "MIND - ANXIETY - health, about"
  IntColumn get grade => integer().nullable()(); // 1-3 or null
  TextColumn get source => text().nullable()(); // Kent, Synthesis, etc.
  TextColumn get justification => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Follow-ups table - stores post-prescription observations
@DataClassName('FollowUp')
class FollowUps extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  DateTimeColumn get followUpDate => dateTime()();
  TextColumn get notes => text()();
  TextColumn get changes => text().nullable()(); // Improvements, aggravations, new symptoms
  TextColumn get remedyAdjustment => text().nullable()(); // Any changes to prescription
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// AI Audit Log table - tracks all Grok API calls for transparency
@DataClassName('AIAuditLog')
class AIAuditLogs extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get caseId => text().nullable().references(Cases, #id, onDelete: KeyAction.cascade)();
  
  TextColumn get promptType => text()(); // analyze, suggest, highlight, etc.
  TextColumn get requestHash => text()(); // Hash of anonymized payload
  DateTimeColumn get requestTime => dateTime()();
  BoolColumn get success => boolean()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get tokensUsed => integer().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [
  Patients,
  Cases,
  Symptoms,
  PhysicalGenerals,
  MentalEmotionals,
  RemedySuggestions,
  RepertoryRubrics,
  FollowUps,
  AIAuditLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will go here
        // if (from < 2) {
        //   await m.addColumn(cases, cases.newColumn);
        // }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'homeoai.db'));
    return NativeDatabase(file);
  });
}
