# HomeoAI - Classical Homeopathy Case Taking App

A comprehensive Flutter application for classical homeopathic case taking, analysis, and remedy selection powered by **AI** (Grok or Gemini). Designed for Windows, iOS, and Android with offline-first local storage and intelligent AI assistance.

---

## 🚀 Setup Instructions

### Prerequisites

- Flutter SDK (3.0 or higher)
- AI API Key from one of the supported providers:
  - **Grok** from [x.ai](https://x.ai/) (recommended for clinical precision)
  - **Gemini** from [Google AI Studio](https://aistudio.google.com/app/apikey) (free tier available)

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd HomeoAI
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure AI Provider**

   Create a `.env` file in the project root (copy from `.env.example`):

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file and add your API key(s):

   ```env
   # Choose your preferred AI provider
   AI_PROVIDER=grok

   # Grok API Key (from https://x.ai/)
   GROK_API_KEY=xai-your-actual-api-key-here

   # Gemini API Key (from https://aistudio.google.com/)
   GEMINI_API_KEY=your-gemini-api-key-here
   ```

   **Supported AI Providers:**
   - `grok` - xAI's Grok (best for clinical homeopathy analysis)
   - `gemini` - Google's Gemini (free tier available, fast responses)

   > **Important**: Never commit the `.env` file to version control. It's already added to `.gitignore`.

4. **Run the app**
   ```bash
   flutter run -d windows   # For Windows
   flutter run -d android   # For Android
   flutter run -d chrome    # For web testing
   ```

---

## 🎯 Features

### Core Functionality

- **Patient Management**: Create and manage patient profiles with demographics and medical history
- **Structured Case Taking**: Multi-step wizard following classical homeopathy methodology:
  - Spontaneous narrative capture (with optional voice-to-text)
  - Chief complaints with L-S-M-C structure (Location, Sensation, Modalities, Concomitants)
  - Physical generals (thermals, thirst, appetite, sleep, dreams)
  - Mental & emotional disposition
  - SRP (Strange, Rare, Peculiar) symptom identification
- **AI-Powered Analysis**: Integration with Grok or Gemini AI for:
  - Patient portrait summarization
  - Clarifying question suggestions
  - Peculiar symptom highlighting
  - Remedy repertorization and differential analysis
  - Materia medica comparisons
- **Local Database**: Full offline capability with SQLite/Drift
- **Export**: Generate PDF reports and JSON backups
- **Follow-up Tracking**: Document post-prescription observations

### Privacy & Security

- **100% Local Storage**: Patient data stored only on device
- **Explicit AI Consent**: User controls when data is sent to AI provider
- **Flexible AI Providers**: Choose between Grok (xAI) or Gemini (Google) for analysis
- **Secure Configuration**: API credentials stored in .env file (not version controlled)
- **No Built-in Repertory**: Respects licensing constraints

---

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.x (Material 3)
- **State Management**: Riverpod 2.x
- **Database**: Drift (type-saf) or Gemini (Google AI Studio) via Dio HTTP client
- **Configuration**: flutter_dotenv for environment managem
- **AI Integration**: Grok (xAI API) via Dio HTTP client
- **Forms**: flutter_form_builder
- **Export**: pdf, printing packages

### Project Structure

```
lib/
├── core/(xAI) API client
│   │   ├── gemini_client.dart        # Gemini (Google) API client
│   ├── ai/
│   │   ├── grok_client.dart          # Grok API client with retry logic
│   │   └── grok_prompts.dart         # Structured prompt templates
│   ├── database/
│   │   └── database.dart             # Drift schema & tables
│   ├── repositories/
│   │   └── repositories.dart         # Data access layer
│   ├── providers/
│   │   └── providers.dart            # Riverpod DI providers
│   └── export/
│       └── exporters.dart            # PDF/JSON export utilities
├── features/
│   ├── cases/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── patients/
│   └── analysis/
└── main.dart
```

### Database Schema

**Tables:**

- `patients` - Patient demographics
- `cases` - Individual consultations
- `symptoms` - LSMC-structured symptoms
- `physical_generals` - Thermals, thirst, etc.
- `mental_emotionals` - Disposition, fears, triggers
- `remedy_suggestions` - AI/manual remedy suggestions
- `repertory_rubrics` - Identified rubrics
- `follow_ups` - Post-prescription notes
- `ai_audit_logs` - Transparency tracking

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Xcode (for iOS) or Android Studio (for Android)
- Grok API Key from [xAI](https://x.ai/)

### Installation

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd HomeoAI
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate drift code**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**

   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

### Configuration

#### Grok API Key Setup

On first launch, navigate to **Settings** and enter your Grok API key. The key is stored securely using `flutter_secure_storage`.

Alternatively, set it programmatically:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/providers.dart';

// In your settings screen
await saveGrokApiKey(ref, 'your-xai-api-key');
```

---

## 📖 Usage Guide

### Creating a New Case

1. **Add Patient**: Tap the FAB → Enter patient details
2. **Start Case Wizard**:
   - **Step 1**: Capture spontaneous narrative (text or voice)
   - **Step 2**: Document chief complaints (add multiple with LSMC)
   - **Step 3**: Record physical generals
   - **Step 4**: Note mental/emotional state
   - **Step 5**: Review and mark peculiar symptoms
   - **Step 6**: Analyze with Grok (select key symptoms → tap "Analyze")
   - **Step 7**: Prescribe remedy and schedule follow-up

### AI Analysis Features

#### Spontaneous Narrative Analysis

```dart
final response = await grokClient.analyzeSpontaneousNarrative(
  narrative: "Patient's story...",
  patientAge: "35",
  patientGender: "Female",
);
// Returns: portrait, themes, suggested questions
```

#### Case Repertorization

```dart
final analysis = await grokClient.analyzeCase(
  spontaneousNarrative: narrative,
  chiefComplaints: complaints,
  physicalGenerals: generals,
  mentalEmotional: mentals,
  selectedKeySymptoms: keySymptoms,
);
// Returns: rubrics, remedy suggestions, differential analysis
```

### Exporting Cases

**PDF Export:**

```dart
final file = await PDFExporter.exportCase(
  caseData: case,
  patient: patient,
  symptoms: symptoms,
  // ... other data
);
// Opens share dialog
```

**JSON Backup:**

```dart
final file = await JSONExporter.exportCase(/* ... */);
// Saves structured JSON for re-import
```

---

## 🧠 Grok AI Integration

### Prompt Engineering

The app uses structured prompts defined in `grok_prompts.dart`:

- **System Prompt**: Defines Grok's role as a Classical Homeopathic Analyst
- **Task Prompts**: Specific instructions for narrative analysis, SRP detection, repertorization

### Rate Limiting & Retries

- Client-side throttling (500ms minimum between requests)
- Exponential backoff on errors
- 429 (rate limit) handling with retry-after

### Privacy Controls

- All Grok calls require explicit user action (no automatic processing)
- Anonymized data sent (no PII in prompts)
- Audit logging in `ai_audit_logs` table

---

## 🛠️ Development

### Code Generation

Run after schema changes:

```bash
dart run build_runner watch
```

### Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### Linting

```bash
flutter analyze
```

---

## 📦 Dependencies

| Package                  | Purpose                  |
| ------------------------ | ------------------------ |
| `flutter_riverpod`       | State management         |
| `drift`                  | Type-safe SQL database   |
| `dio`                    | HTTP client for Grok API |
| `flutter_form_builder`   | Complex form handling    |
| `uuid`                   | Unique ID generation     |
| `pdf`                    | PDF report generation    |
| `flutter_secure_storage` | Encrypted key storage    |
| `path_provider`          | File system access       |

---

## 🔒 Security & Privacy

### Data Storage

- All patient data stored locally in SQLite database
- No cloud sync by default
- Optional export/import for backups

### API Key Management

- Grok API key encrypted with platform keychain
- Never committed to version control
- Configurable per-user

### Compliance Notes

- **HIPAA**: Local-only storage reduces compliance scope (consult legal advisor)
- **No Built-in Repertory**: Avoids copyright/licensing issues
- **Disclaimer**: All AI outputs labeled "for practitioner review only"

---

## 🗺️ Roadmap

### Phase 1 (MVP) ✅

- [x] Database schema & repositories
- [x] Grok client & prompts
- [x] Basic case wizard UI
- [x] PDF/JSON export

### Phase 2 (AI Integration)

- [ ] Complete UI screens
- [ ] Voice transcription
- [ ] AI analysis screens
- [ ] Follow-up management

### Phase 3 (Polish)

- [ ] Unit/widget tests
- [ ] Localization (i18n)
- [ ] Optional DB encryption
- [ ] Advanced search/filtering

---

## 🤝 Contributing

This is a specialized healthcare application. Contributions should:

- Follow classical homeopathy principles
- Respect patient privacy
- Include tests for critical paths
- Adhere to Flutter/Dart best practices

---

## ⚖️ Legal Disclaimer

**This software is for professional homeopathic practitioners only.**

- Does NOT provide medical advice
- Does NOT diagnose, treat, or cure any disease
- AI suggestions require verification by qualified practitioners
- Users are responsible for all clinical decisions
- Consult appropriate healthcare providers

---

## 📄 License

[Specify your license - e.g., MIT, GPL, proprietary]

---

## 📧 Support

For questions or issues:

- **Email**: [your-email]
- **Issues**: [GitHub Issues URL]
- **Docs**: [Additional documentation URL]

---

## 🙏 Acknowledgments

- Classical homeopathy methodology based on Kent, Hahnemann, and modern masters
- Grok AI by xAI for intelligent analysis capabilities
- Flutter community for excellent tooling

---

**Built with ❤️ for the homeopathic community**
