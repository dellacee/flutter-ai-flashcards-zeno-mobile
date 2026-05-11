# AI Learning Companion — Design Spec

**Status:** Draft v1 (pending user approval)
**Author:** Thư (lyminhthu24032005@gmail.com)
**Date:** 2026-05-08
**Working dir:** `D:\mobile`
**Stack:** Flutter / Dart / Firebase / FastAPI (Cloud Run) / REST APIs

---

## 1. Vision

> *"Học từ bất kỳ thứ gì. Nhớ mãi mãi."*

Một mobile app giúp người học **capture** content (PDF, link, ảnh, video), AI tự **synthesize** thành flashcards & summary, rồi dùng **spaced repetition** để giữ kiến thức lâu dài. Tập trung **mobile-first** — khe hở thị trường mà NotebookLM (web-only) và Anki (mobile UX cổ) đang bỏ ngỏ.

Tên working: `Zeno` (sẽ chốt sau khi check trademark + .app domain).

---

## 2. Target users

**Primary persona — "Sinh viên / người tự học Việt Nam"**
- 18–32 tuổi
- Sinh viên đại học/cao học, người đi làm tự học (career switch, IELTS/TOEIC, đọc paper kỹ thuật, học code)
- Học nội dung **song ngữ** (Việt + Anh)
- Thiết bị chính: smartphone Android (Việt Nam ~75% Android share), iPhone phụ
- Pocket-of-time learner: học 5–15 phút lúc xe bus, trước ngủ, lunch break

**Why mobile-first:** Học chính trên laptop dễ phân tâm; mobile review chỉ cần 5 phút lẻ và gắn liền với thói quen unlock điện thoại.

**Non-goals (out of scope user):**
- Học sinh tiểu học/THCS (cần parental control, gamification kiểu khác)
- Researcher hardcore với LaTeX-heavy paper (V3+ problem)
- Doanh nghiệp / corporate training (B2B)

---

## 3. JTBD — 5 pain points

| # | Pain | Pillar | Phase |
|---|---|---|---|
| 1 | **Capture** — có PDF/article/video, đọc xong là quên | Multi-modal ingest | V1 |
| 2 | **Synthesize** — không kịp đọc full, cần summary chất lượng | AI summary + chat (RAG) | V1 |
| 3 | **Retain** — forgetting curve, quên 80% sau 1 tuần | Spaced repetition (FSRS) | V1 |
| 4 | **Apply** — kiến thức rời rạc, không kết nối khái niệm | Knowledge graph + bilingual cards | V2/V3 |
| 5 | **Coach** — không biết học tiếp gì, gap ở đâu | Weekly review agent | V3 |

**Rule:** Mọi feature đề xuất sau này phải map về 1 trong 5 pillar. Không map → cắt.

---

## 4. Competitive positioning

| Tool | Điểm mạnh | Điểm yếu | Bạn beat ở đâu |
|---|---|---|---|
| **Anki** | SRS chuẩn, free, OSS | UX cổ, không AI, mobile xấu | Mobile-first + AI gen + tiếng Việt |
| **NotebookLM** | Chat RAG mạnh, free | Web-only, không SRS, không offline | Mobile + SRS + offline |
| **RemNote** | Note + SRS lai | Web-first, đắt ($8/m), phức tạp | Đơn giản hơn, focus mobile |
| **Quizlet** | Có SRS + game | UI trẻ con, AI yếu, paywall | AI mạnh hơn, không paywall core |
| **Readwise** | Highlight sync mạnh | $10/m, không SRS auto | Free + AI auto-gen cards |

**Đặt cược chính:** *Mobile-first AI flashcard cho người Việt* — chưa ai làm tốt cả 3 vector này cùng lúc.

---

## 5. Scope — V1 MVP (5–6 tuần)

### In scope
- **Auth**: Google Sign-In + Email/Password (Firebase Auth)
  - ~~Email magic link~~ deprecated — Firebase Dynamic Links shutting down 2025/2026
  - Apple Sign-In: defer V1.2 (cần Apple Dev account + Mac)
- **Ingest** *(deferred to V1.1 — bundled with backend & AI pipeline)*:
  - ~~Upload PDF (≤30MB, ≤200 pages)~~ V1.0 chỉ tạo card thủ công; PDF/URL/image ingest move sang V1.1 khi build backend FastAPI + Cloud Storage direct
  - Lý do: Firebase Storage giờ require Blaze plan (paid) → defer cho tới khi có backend pipeline thật sự cần
- **AI processing**:
  - Auto-generate flashcards: 3 types — Q/A, cloze deletion, MCQ
  - Generate summary (TL;DR ~150 từ + bullet key points)
  - Default 10–25 cards/document, user adjustable
- **Review (FSRS algorithm)**:
  - Daily review queue
  - Swipe gesture: Again/Hard/Good/Easy
  - Streak counter
  - Stats: retention rate, cards learned
- **Chat with content (RAG)**:
  - Ask question về document đã ingest
  - Cite source (page reference)
  - Stream response
- **Library**:
  - Folder/deck hierarchy (1 cấp deep)
  - Tag system
  - Search (full-text)
- **Notifications**:
  - Daily review reminder (FCM + local fallback)
  - Customizable time
- **Offline**:
  - Review hoạt động fully offline
  - Sync queue khi có mạng
- **Settings**:
  - Theme (light/dark/system)
  - Notification time
  - Daily new card limit

### Out of scope (V1)
- Voice mode, audio summary → V2
- YouTube ingest → V2
- Handwriting OCR → V2
- Knowledge graph → V3
- Social/sharing → V3
- Export to Anki → V3
- Web companion → V3
- Premium tier → V3
- Real-time collaboration → never (out of vision)

### Definition of done — V1
- [ ] User có thể tạo deck **thủ công** (V1.0) / từ PDF (V1.1+), review, chat — end-to-end
- [ ] App chạy được offline (review only)
- [ ] Daily notification gửi đúng giờ
- [ ] FSRS review schedule đúng (test ≥10 cards qua 7 ngày)
- [ ] LLM cost monitoring đặt cap $0.50/user/day
- [ ] App Check + Firestore rules production-ready
- [ ] Crash-free rate ≥99% trên 5 device test
- [ ] Lighthouse-equivalent perf: cold start ≤2s, review screen 60fps
- [ ] Đăng được internal TestFlight + Play Console internal track

---

## 6. Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Dart 3.x)                │
│                                                          │
│  Presentation     ┌─ home / library / review / chat /   │
│                   │  ingest / settings (per feature)    │
│                   └─ shared widgets (cards, dialogs)    │
│                                                          │
│  Domain           ┌─ entities (Deck, Card, Document)    │
│                   ├─ usecases (ReviewCard, IngestPDF)   │
│                   └─ repositories (interfaces)          │
│                                                          │
│  Data             ┌─ remote (Firestore, Storage, REST)  │
│                   ├─ local (Isar, SharedPrefs)          │
│                   └─ repository impls + sync queue      │
│                                                          │
│  Core             ┌─ DI (Riverpod providers)            │
│                   ├─ routing (GoRouter)                 │
│                   ├─ theme (Material 3 + tokens)        │
│                   └─ utils (logger, error handling)     │
└─────────────┬───────────────────────┬────────────────────┘
              │                       │
              │ Firebase SDK          │ HTTPS (REST + SSE)
              ▼                       ▼
   ┌──────────────────┐    ┌─────────────────────────────┐
   │     FIREBASE     │    │   BACKEND (FastAPI)         │
   │                  │    │   on Google Cloud Run       │
   │  • Auth          │    │                             │
   │  • Firestore     │    │   Endpoints:                │
   │  • Storage       │    │   POST /ingest/pdf          │
   │  • FCM           │    │   POST /ingest/url          │
   │  • App Check     │    │   POST /generate-cards      │
   │  • Analytics     │    │   POST /chat (SSE stream)   │
   │                  │    │   POST /summarize           │
   └──────────────────┘    │   GET  /healthz             │
                           └────────┬────────────────────┘
                                    │
                          ┌─────────┼──────────┐
                          ▼         ▼          ▼
                     Pinecone   Gemini Flash  Claude Haiku
                     (vectors,  (gen cards,    (chat — quality)
                      free 100k embeddings)
                      vectors)
```

### 6.1 Tech decisions

| Item | Choice | Reason |
|---|---|---|
| Language | **Dart 3.x** | Stack constraint |
| Framework | **Flutter 3.x** | Stack constraint |
| State mgmt | **Riverpod 2.x** (codegen) | Type-safe, modern, ít boilerplate hơn Bloc |
| Routing | **GoRouter** | Official, deep link, type-safe routes |
| Local DB | **Isar v4** | Fastest NoSQL Flutter, query strong, async |
| Networking | **Dio** + **retrofit** codegen | Interceptor đẹp, retry logic |
| Codegen | `freezed`, `json_serializable`, `riverpod_generator` | Standard 2026 stack |
| Analytics | Firebase Analytics + **Sentry** | Free tier đủ, Sentry catch crash detail |
| Lint | `very_good_analysis` | Stricter than default |
| CI | GitHub Actions (test + build APK) | Free for public/private |
| Backend | **FastAPI on Cloud Run** | Streaming SSE, scale-to-zero, không 9-min timeout như Functions |
| LLM (gen) | **Gemini Flash 2.0** | Free tier 1500 RPD, rẻ nhất khi vượt |
| LLM (chat) | **Claude Haiku 4.5** | Quality cao + giá rẻ Anthropic |
| LLM (on-device V2+) | **Gemini Nano** | Free, offline, summary nhẹ |
| Embeddings | **Gemini text-embedding-004** | Đi cùng ecosystem Gemini, 768-dim |
| Vector DB | **Pinecone Free** → **pgvector** khi scale | 100k vectors free đủ MVP |
| OCR | **Google ML Kit** (on-device) | Free, offline, tiếng Việt OK |
| PDF parse | `pdf_text` Dart + fallback `pdfplumber` (Python) backend | Text-based PDF Dart, scan dùng OCR backend |
| FSRS impl | `fsrs` Python (port) hoặc tự implement Dart | Algorithm rõ, ~200 lines |

### 6.2 Anti-patterns avoided
- ❌ Tự build OAuth — dùng Firebase Auth
- ❌ Bloc + injectable + freezed hell — over-engineering cho solo dev
- ❌ Microservices — 1 backend service đủ
- ❌ Tự host LLM (Llama/Mistral) — không justify GPU cost ở scale này
- ❌ Realtime collaborative editing — không phải core JTBD
- ❌ Custom design system from scratch — extend Material 3 thôi

---

## 7. Data model (Firestore + Isar)

### 7.1 Firestore collections

```
users/{uid}
  ├─ displayName, email, photoURL, createdAt
  ├─ settings: { reviewTime, dailyNewCardLimit, theme, locale }
  └─ stats: { streak, totalReviews, retention7d, retention30d }

users/{uid}/decks/{deckId}
  ├─ title, description, tags[], coverColor, icon
  ├─ sourceDocs: [{docId, type: pdf|url|text|image, title}]
  ├─ cardCount, dueCount, createdAt, updatedAt

users/{uid}/decks/{deckId}/cards/{cardId}
  ├─ type: qa | cloze | mcq
  ├─ front, back, options[] (for mcq), clozeText (for cloze)
  ├─ sourceDocId, sourceChunkRef
  ├─ fsrs: { stability, difficulty, due, lastReview, reps, lapses, state }
  └─ createdAt, updatedAt

users/{uid}/documents/{docId}
  ├─ title, type, sourceUrl, storageRef
  ├─ summary, keyPoints[], lang
  ├─ status: processing | ready | failed
  └─ chunkCount, vectorNamespace (= docId)

users/{uid}/chats/{chatId}
  ├─ deckId | docId
  ├─ messages: [{role, content, sources[], ts}]
  └─ updatedAt
```

### 7.2 Isar local schema (offline cache)
Mirror minimal subset cho offline review:
```
LocalDeck { id, title, dueCount, lastSync }
LocalCard { id, deckId, type, front, back, fsrs, dirty (bool) }
LocalReview { cardId, rating, ts, synced (bool) }
```

Sync strategy:
- **Pull**: Firestore listener → cập nhật Isar (last-write-wins)
- **Push**: review log → SyncQueue → batch upload mỗi 30s hoặc khi online
- **Conflict**: server wins (đơn giản; collab không phải scope)

### 7.3 Vector store (Pinecone)
- Namespace = `{uid}_{docId}`
- Index dim = 768 (Gemini text-embedding-004)
- Metadata: `{chunkIndex, page, text (≤500 chars)}`
- Chunk size: ~500 tokens, overlap 50

### 7.4 Firestore security rules (skeleton)
```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth.uid == uid;
}
```
Plus App Check enforcement on all reads/writes.

---

## 8. Key user flows

### Flow A — First-time onboard
1. Open app → splash → onboard (3 slides ~10s)
2. Tap "Get started" → Auth screen → Google Sign-In
3. Land on Home (empty state) → CTA "Add your first material"
4. Show ingest sheet → user picks PDF
5. Upload → progress bar → "AI is reading..." (~30–60s)
6. Cards generated → preview screen ("Generated 18 cards. Review?")
7. Optional: rename deck, edit cards
8. Save → Home with first deck shown

### Flow B — Daily review (core retention loop)
1. Notification 7am: "12 cards due today 🔥"
2. Open app → Review tab auto-active
3. Card shown front → tap to flip → 4 buttons (Again/Hard/Good/Easy)
4. Swipe gesture also works (left=Again, right=Easy)
5. After 12 cards → completion screen ("+15 XP, streak 8 days")
6. CTA: "Review another deck" or "Done"

### Flow C — Chat with content
1. From deck detail → tap "Ask"
2. Chat screen with deck/doc context
3. User types question → SSE stream answer
4. Each answer cites source: "From [Sinh học 12 — page 42]"
5. Tap citation → preview chunk in modal
6. CTA at bottom: "Make this a card" → adds to deck

### Flow D — Add from share sheet (mobile native integration)
1. Read article in browser → tap Share → Zeno
2. App opens with URL pre-filled
3. Pick deck or "New deck"
4. Process in background → notification "Cards ready 🎉"

---

## 9. UX principles

- **3-tab bottom nav** — Home / Library / Review. Không drawer.
- **Gesture-first review** — swipe Tinder-style cảm giác premium hơn button
- **Loading states**: skeleton + shimmer, không spinner
- **Animations**: 200–300ms ease-out, dùng `flutter_animate`
- **Empty states**: illustrated + CTA cụ thể, không "No data"
- **Theme**: Material 3 Expressive, dark mode default, accent colorblind-safe
- **Typography**: Inter (latin) + Be Vietnam Pro (VN diacritics tốt)
- **Haptic**: light feedback khi swipe card, success
- **Accessibility**: contrast WCAG AA, font scale 100–200%, screen reader labels

**Design benchmark:** Linear (clean enterprise), Things 3 (motion), Duolingo (gamification light), Arc Search (information density mobile).

---

## 10. Risks & mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | LLM cost blowup | High | High | Per-user daily quota (50 gens, 100 chat msgs); Gemini Flash chính; prompt caching; show usage to user |
| 2 | PDF parse fail (scan, math, đa cột) | High | Med | Text-based ưu tiên `pdf_text`; scan → ML Kit OCR; math/diagram defer V3 |
| 3 | Scope creep | High | High | Feature freeze V1; mọi idea → V2 backlog file riêng |
| 4 | FSRS implementation sai | Med | High | Dùng port có test reference; viết unit test với 100+ test case từ FSRS-Optimizer |
| 5 | Firestore cost (read-heavy) | Med | Med | Aggregate counters; Isar cache; pagination 20/page |
| 6 | App Store/Play Store reject | Med | High | Privacy policy + ToS sẵn từ V1; tránh gather user content cho training |
| 7 | LLM hallucinate cards sai | Med | Med | "Source citation" mọi card; user review/edit trước save; few-shot prompting |
| 8 | Offline sync conflict | Low | Med | Server-wins simple; log conflict; collab not in scope |
| 9 | Tiếng Việt OCR/parse kém | Med | Med | Test với 5+ PDF tiếng Việt thật; ML Kit + tesseract fallback |
| 10 | Timeline slip | High | Med | V1 freeze sau tuần 6 dù chưa xong → ship cái có; V2 push sau |

---

## 11. Timeline

| Phase | Tuần | Output | Ship |
|---|---|---|---|
| **0. Setup** | 0.5 | Firebase project, Cloud Run skeleton, repo + CI, monorepo structure | — |
| **V1.0 Auth + ingest PDF + manual cards** | 1.5 | Tạo deck thủ công, upload PDF, list cards | Internal alpha |
| **V1.1 AI gen cards + FSRS review** | 2 | Loop học hoàn chỉnh, swipe review | TestFlight internal |
| **V1.2 Chat (RAG) + notif + offline** | 2 | MVP shippable | Beta TestFlight + Play internal |
| **— Pause: dùng thật 2 tuần —** | 2 | Feedback log, V2 priority quyết | — |
| **V2 Voice + multi-modal + bilingual** | 3–4 | Differentiator | Public TestFlight + Play closed |
| **V3 Coach + social + monetize** | 4–6 (optional) | Moat features | Public release |

**Total V1+V2 (portfolio-ready):** ~10–12 tuần
**Effort:** 10–15h/tuần buổi tối

**Cadence:**
- Daily: 1–2h coding (weeknight) hoặc 4–6h (weekend)
- Weekly: review what shipped, update V2 backlog, commit feedback notes

---

## 12. Project layout (proposed)

```
D:\mobile\
├── app/                          # Flutter app
│   ├── lib/
│   │   ├── core/                # DI, routing, theme, utils
│   │   ├── features/
│   │   │   ├── auth/            # data / domain / presentation
│   │   │   ├── home/
│   │   │   ├── library/
│   │   │   ├── ingest/
│   │   │   ├── review/          # FSRS lives here
│   │   │   ├── chat/
│   │   │   └── settings/
│   │   └── main.dart
│   ├── test/
│   ├── integration_test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend/                      # FastAPI service
│   ├── app/
│   │   ├── routers/             # ingest, chat, generate
│   │   ├── services/            # llm, vector, parser
│   │   ├── prompts/
│   │   └── main.py
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
├── docs/
│   ├── specs/                   # design docs
│   ├── decisions/               # ADRs
│   └── prompts/                 # versioned prompts
├── scripts/                     # deploy, seed, eval
├── .github/workflows/           # CI
├── firebase.json
├── firestore.rules
├── .gitignore
└── README.md
```

---

## 13. Open questions (resolve before/during writing-plans)

1. **App name**: `Zeno` vs `Mindloop` vs `Gist` — check trademark + .app domain trong tuần 0
2. **Backend hosting region**: `asia-southeast1` (Singapore) cho latency VN tốt nhất
3. **Account deletion flow**: Apple yêu cầu in-app delete — implement từ V1 hay V2? → đề xuất V1 để approve store dễ
4. **TOS / Privacy Policy**: tự draft hay dùng template (Termly/Iubenda)?
5. **Feedback channel V1**: in-app form vs email vs Tally form?
6. **Beta testers**: kêu ai dùng V1.2? Cần ≥5 người để có signal

---

## 14. Success metrics (V1 — first 30 days post-launch)

**North Star:** Số card được review/user/tuần (đo retention loop)

**Activation:**
- ≥70% user tạo ≥1 deck trong session đầu
- ≥50% user review ≥5 cards trong tuần đầu

**Retention:**
- D1 retention ≥40%, D7 ≥20%, D30 ≥10%
- ≥30% user có streak ≥3 ngày

**Quality:**
- Crash-free rate ≥99%
- AI-gen card "kept" rate ≥70% (không bị user xoá ngay)
- Chat answer satisfaction (👍/👎) ≥75% positive

---

## 15. References

- FSRS algorithm: https://github.com/open-spaced-repetition/fsrs4anki
- Riverpod docs: https://riverpod.dev
- Flutter best practices 2026: pending — verify in writing-plans phase
- Firebase pricing: https://firebase.google.com/pricing
- Gemini API pricing: https://ai.google.dev/pricing
- Anthropic pricing: https://www.anthropic.com/pricing

---

## Approval

- [ ] Target user confirmed
- [ ] V1 scope confirmed (no additions)
- [ ] Tech stack confirmed
- [ ] Architecture confirmed
- [ ] Timeline acceptable

**Next step after approval:** invoke `superpowers:writing-plans` skill → break V1 into implementation tasks (per feature, per repo).
