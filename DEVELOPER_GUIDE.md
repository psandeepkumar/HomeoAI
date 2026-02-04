# HomeoAI - Developer Setup Guide

## Quick Start

### 1. Environment Setup

**Install Flutter:**

```bash
# Verify installation
flutter doctor -v

# Should show:
# ✓ Flutter (Channel stable, 3.x.x)
# ✓ Android toolchain
# ✓ Xcode (for macOS)
# ✓ VS Code / Android Studio
```

**Clone and Configure:**

```bash
git clone <repository-url>
cd HomeoAI
flutter pub get
```

### 2. Code Generation

Drift requires code generation for type-safe database access:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on changes)
dart run build_runner watch
```

**Generated files:**

- `lib/core/database/database.g.dart`

### 3. Grok API Key

Obtain a key from [xAI](https://x.ai/):

1. Sign up / log in
2. Navigate to API keys
3. Create new key
4. Copy and store securely

**Add to app:**

- Launch app → Settings → Enter API key
- Or use secure storage directly:
  ```dart
  await saveGrokApiKey(ref, 'xai-your-key-here');
  ```

**For development/testing:**

```bash
# Set environment variable (optional)
export GROK_API_KEY="xai-your-key"
flutter run --dart-define=GROK_API_KEY=$GROK_API_KEY
```

---

## Project Structure Explained

```
lib/
├── core/                       # Shared infrastructure
│   ├── ai/
│   │   ├── grok_client.dart   # HTTP client with retry logic
│   │   └── grok_prompts.dart  # Prompt templates & system instructions
│   ├── database/
│   │   └── database.dart      # Drift schema (run build_runner after changes)
│   ├── repositories/
│   │   └── repositories.dart  # Data access layer (CRUD operations)
│   ├── providers/
│   │   └── providers.dart     # Riverpod dependency injection
│   └── export/
│       └── exporters.dart     # PDF/JSON export utilities
├── features/                   # Feature modules (TODO)
│   ├── cases/                 # Case management screens
│   ├── patients/              # Patient list/profile screens
│   └── analysis/              # AI analysis results screens
└── main.dart                   # App entry point
```

---

## Development Workflow

### Making Database Changes

1. **Modify schema** in `lib/core/database/database.dart`:

   ```dart
   // Add a new column
   class Patients extends Table {
     // ... existing columns
     TextColumn get newField => text().nullable()();
   }
   ```

2. **Regenerate code**:

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Update schema version** and add migration:

   ```dart
   @override
   int get schemaVersion => 2; // Increment

   @override
   MigrationStrategy get migration {
     return MigrationStrategy(
       onUpgrade: (m, from, to) async {
         if (from < 2) {
           await m.addColumn(patients, patients.newField);
         }
       },
     );
   }
   ```

### Adding New Grok Prompts

1. **Add method** in `grok_prompts.dart`:

   ```dart
   static String myNewAnalysis({required String data}) {
     return '''
     Analyze the following...

     Return JSON:
     {
       "result": "..."
     }
     ''';
   }
   ```

2. **Add client method** in `grok_client.dart`:

   ```dart
   Future<Map<String, dynamic>> performNewAnalysis(String data) async {
     final prompt = GrokPrompts.myNewAnalysis(data: data);
     final response = await _callAPI(
       systemPrompt: GrokPrompts.systemPrompt,
       userPrompt: prompt,
     );
     return response.jsonContent!;
   }
   ```

3. **Call from UI** using provider:
   ```dart
   final client = ref.read(grokClientProvider);
   if (client != null) {
     final result = await client.performNewAnalysis(data);
   }
   ```

---

## Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific file
flutter test test/repositories_test.dart

# With coverage
flutter test --coverage
```

**Example test:**

```dart
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('PatientRepository creates patient', () async {
    final repo = PatientRepository(db);
    final patient = await repo.createPatient(name: 'Test Patient');
    expect(patient.name, 'Test Patient');
  });
}
```

### Widget Tests

```dart
testWidgets('Home screen shows new case button', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: HomeoAIApp()),
  );
  expect(find.text('New Case'), findsOneWidget);
});
```

---

## Common Tasks

### Reset Database

```bash
# iOS Simulator
xcrun simctl get_app_container booted <bundle-id> data
# Then delete homeoai.db

# Android Emulator
adb shell run-as com.yourcompany.homeoai
rm -rf databases/
```

### Debug Grok API Calls

Enable logging in `grok_client.dart`:

```dart
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  logPrint: (obj) => debugPrint('[Grok] $obj'),
));
```

### Export Sample Data

```dart
final exporter = PDFExporter();
final file = await exporter.exportCase(/* ... */);
print('Exported to: ${file.path}');
```

---

## Troubleshooting

### "Table doesn't exist" error

- Forgot to run `build_runner`
- Check `database.g.dart` exists
- Uninstall/reinstall app to recreate DB

### "API key not configured"

- Check `flutter_secure_storage` permissions
- iOS: Ensure Keychain Sharing enabled in Xcode
- Android: Verify EncryptedSharedPreferences support

### Build failures after schema change

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Performance Tips

### Database Optimization

- Add indices to frequently queried columns
- Use transactions for bulk inserts
- Limit queries with `.limit()` and pagination

### Grok API Efficiency

- Cache recent responses per case
- Debounce user actions (avoid spam)
- Use `temperature: 0.3` for deterministic outputs

### UI Responsiveness

- Offload heavy computations to isolates
- Use `FutureBuilder` / `AsyncValue` for async data
- Implement pagination for long lists

---

## Code Style

**Follow Dart conventions:**

```bash
dart format lib/ test/
dart analyze
```

**Key principles:**

- Prefer immutable data (`final` everywhere)
- Use named parameters for clarity
- Document public APIs with `///`
- Handle errors explicitly (no silent failures)

---

## Release Checklist

- [ ] All tests passing (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Update version in `pubspec.yaml`
- [ ] Generate release builds
  ```bash
  flutter build apk --release
  flutter build ios --release
  ```
- [ ] Test on physical devices (iOS + Android)
- [ ] Verify PDF/JSON exports work
- [ ] Check Grok API rate limits for production
- [ ] Add release notes to `CHANGELOG.md`

---

## Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Drift Guide**: https://drift.simonbinder.eu/
- **Riverpod**: https://riverpod.dev/
- **Grok API**: https://docs.x.ai/

---

**Questions?** Open an issue or contact the maintainer.
