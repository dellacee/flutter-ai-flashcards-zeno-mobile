# Zeno — AI Learning Companion

> *Học từ bất kỳ thứ gì. Nhớ mãi mãi.*

Mobile-first AI flashcard app với spaced repetition (FSRS). Capture PDF/link/note → AI auto-gen flashcards → review hằng ngày.

## Status

🚧 **Phase: V1.0 Foundation** — đang setup dev env

## Roadmap

| Plan | Scope | Status |
|---|---|---|
| **V1.0** | Foundation, auth, deck/card CRUD thủ công, upload PDF | 🚧 In progress |
| V1.1 | Backend FastAPI, AI gen cards, FSRS review | ⏳ Planned |
| V1.2 | Chat RAG, push notification, offline polish | ⏳ Planned |
| V2 | Voice mode, multi-modal, bilingual | ⏳ Backlog |
| V3 | Knowledge graph, coach agent, social | ⏳ Backlog |

Spec: [docs/specs/2026-05-08-ai-learning-companion-design.md](docs/specs/2026-05-08-ai-learning-companion-design.md)
Plan 1: [docs/plans/2026-05-08-v1.0-foundation-and-auth.md](docs/plans/2026-05-08-v1.0-foundation-and-auth.md)

## Tech stack

- **Frontend**: Flutter 3.x, Dart 3.x, Riverpod 2.x, GoRouter, Material 3 Expressive, Isar v4
- **Backend** *(Plan 2+)*: FastAPI on Cloud Run, Pinecone vector DB
- **Cloud**: Firebase (Auth, Firestore, Storage, FCM, App Check, Analytics, Crashlytics)
- **AI**: Gemini Flash (gen), Claude Haiku (chat), Gemini Nano (on-device V2+)

## Setup local dev

### Prerequisites

```bash
# 1. Flutter SDK ≥ 3.24 — verify with:
flutter doctor

# 2. Firebase CLI:
npm install -g firebase-tools
firebase login

# 3. FlutterFire CLI:
dart pub global activate flutterfire_cli

# 4. Android Studio + Pixel 7 emulator (API 34+)

# 5. (Optional macOS) Xcode + iOS simulator
```

### Run

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Repo layout

```
mobile/
├── app/                    # Flutter app (V1.0+)
├── backend/                # FastAPI service (V1.1+)
├── docs/
│   ├── specs/              # Design specs
│   ├── plans/              # Implementation plans
│   └── decisions/          # ADRs
├── scripts/                # deploy / seed / eval scripts
├── .github/workflows/      # CI
├── firestore.rules
└── README.md
```

## Conventions

- **Branch**: `main` always shippable. Feature branches `feat/<scope>`, fixes `fix/<scope>`.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
- **TDD**: Domain logic + repositories có test trước. UI scaffolding skip TDD.
- **Lint**: `very_good_analysis` strict.

## License

Private — for personal learning + portfolio.
