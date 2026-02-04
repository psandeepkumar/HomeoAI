## HomeoAI Architecture Overview

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter UI Layer                        │
│  (Material 3, Screens, Widgets, Forms)                      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  State Management (Riverpod)                 │
│  - Providers for repositories, services, UI state           │
│  - Dependency injection container                           │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
┌────────▼──────────┐   ┌────────▼────────────┐
│   Repositories     │   │   Grok AI Client    │
│  (Data Access)     │   │  (xAI API calls)    │
└────────┬──────────┘   └─────────────────────┘
         │
┌────────▼──────────┐
│  Drift Database   │
│  (SQLite Local)   │
└───────────────────┘
```

---

### Data Flow Examples

#### **Creating a New Case**

1. User fills form in `CaseWizardScreen`
2. Form state managed by `CaseWizardProvider` (Riverpod)
3. On save, provider calls `CaseRepository.createCase()`
4. Repository inserts into Drift DB
5. UI updates via provider state changes

#### **Analyzing with Grok**

1. User selects symptoms and taps "Analyze"
2. UI calls `GrokClient.analyzeCase()`
3. Client formats prompt using `GrokPrompts`
4. HTTP request sent to xAI API
5. Response parsed to JSON
6. Results saved to `remedy_suggestions` table via `RemedySuggestionRepository`
7. UI displays results

---

### Key Design Decisions

**1. Offline-First Architecture**

- All data stored locally in SQLite
- Grok calls only on explicit user action
- No mandatory cloud sync

**2. Repository Pattern**

- Abstracts database operations
- Easy to test with mock repositories
- Centralized data access logic

**3. Riverpod for DI**

- Type-safe dependency injection
- Scoped providers for lifecycle management
- Easy to override for testing

**4. Drift for Type Safety**

- Compile-time SQL validation
- Generated DAOs eliminate boilerplate
- Migration support for schema evolution

**5. Prompt Engineering Approach**

- Prompts separated from client logic
- Structured JSON responses for parsing
- System prompt defines Grok's role consistently

---

### Security Layers

```
User Input → Form Validation → Repository → Drift (Local)
                                    ↓
API Key → Secure Storage → GrokClient → xAI API
```

- **User data**: Stays on device (SQLite)
- **API key**: Encrypted in platform keychain
- **Grok calls**: Anonymized, explicit consent required

---

### Performance Considerations

**Database:**

- Indices on `caseId`, `patientId`, `updatedAt`
- Batch inserts for symptoms
- Transactions for multi-table updates

**API Calls:**

- Client-side rate limiting (500ms between calls)
- Exponential backoff on errors
- Response caching per case

**UI:**

- FutureBuilder for async data
- Pagination for large lists
- Debounced text inputs

---

### Extension Points

**Adding New Features:**

1. **New Table**: Add to `database.dart` → run `build_runner` → create repository methods
2. **New Grok Prompt**: Add to `grok_prompts.dart` → add client method → call from UI
3. **New Screen**: Create in `features/<module>/screens/` → add route → update navigation

**Plugin Integration:**

- Speech-to-text: Add `speech_to_text` package → integrate in narrative screen
- File picker: Add `file_picker` → use in import/export screens
- Encryption: Add `sqflite_sqlcipher` → update database initialization

---

This architecture balances **flexibility** (easy to extend), **privacy** (local-first), and **maintainability** (clear separation of concerns).
