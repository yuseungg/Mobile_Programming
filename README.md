# 여백 (Yeobaek)

> Training wheels for reading poetry — the AI never interprets a poem for you. It **only asks questions**, so you read it yourself.

Chung-Ang University, Mobile Programming team project (4 people) · Flutter + OpenRouter + Firebase

---

## Where we are

| Stage | What | Status |
| --- | --- | --- |
| **1 · Screens** | 13 screens and the navigation between them. Clickable end to end on fake data | ✅ Done (name unification: `docs/여백-이름대조표.md`) |
| **2 · Features** | Firebase Auth · Firestore, the question agent, the save-first lock, model-written comparison and summary | ✅ Wired up (what is left is under [Not done yet](#not-done-yet)) |
| 3 · Integration | Walk the demo scenario, build the APK, submit (week 15) | In progress |

On `develop`: `flutter analyze` reports 0 issues and `flutter test` passes **357 tests**. GitHub Actions runs the same checks on every PR.

Two releases have gone to `main` so far — #19 (mid-term checkpoint) and #38 (sign-in gate, model-written S07 · S09, empathy and profile wiring, fourth poem).

## Running it

```bash
flutter pub get
flutter run
```

**Real Firebase is the default.** The app opens on S01 sign-in; after signing in it passes through the S13 intro and lands on the home screen.

Firebase is configured **for Android only** (`lib/firebase_options.dart`). On Chrome and Windows it falls back to the fake repositories even when the flag is on.

To run on fake data without Firebase:

```bash
flutter run --dart-define=USE_FIREBASE=false
```

The demo account in fake mode is `demo@gmail.com` / `yeobaek1`.

To let the model write the questions, comparisons and summaries, pass the OpenRouter key with `--dart-define`. **Never put the key in the code or in this repository.**

```bash
flutter run --dart-define=OPENROUTER_API_KEY=<the key from the professor>
```

Without a key the app does not die — it falls back to pre-written questions and sentences (plan ch. 9, "offline and failure handling").

The models live in `lib/data/settings_options.dart` and are chosen on S11 — `nvidia/nemotron-3.5-lightning:free` for questions (careful, slow) and `dots-studio/dots-3-note-preview:free` for comparisons (fast). Both are free models whose calls were verified against the professor's key on 2026-11-17.

## Checks

```bash
flutter analyze    # CI fails if this reports anything at all
flutter test
```

The Firestore security rules are tested separately against the emulator — see `firestore_test/README.md`.

## Documents

The source-of-truth documents live in `docs/`, in Korean. **The feature set is settled by the plan** — changing it takes a team decision first.

| Document | What is in it |
| --- | --- |
| [`docs/여백-지침서.md`](docs/여백-지침서.md) | One-page summary of the rules to follow while writing code. **Read this before you start** |
| [`docs/여백-기획서최종.md`](docs/여백-기획서최종.md) | Features F1–F8, screens S01–S12, the agent, data, design tokens. **The source of truth** |
| [`docs/명세서.md`](docs/명세서.md) | The specification we hand in — why we are building this, features, screen flow |
| [`docs/여백-화면분업.md`](docs/여백-화면분업.md) | Stage 1 — screens, the navigation table, the definition of done |
| [`docs/여백-코딩분업.md`](docs/여백-코딩분업.md) | Stage 2 — folder owners, contracts, branch and PR rules |
| [`docs/여백-네이밍규칙.md`](docs/여백-네이밍규칙.md) | Glossary; class, file, route and Firestore names |
| [`docs/여백-이름대조표.md`](docs/여백-이름대조표.md) | Old branch names (part-b · part-d) → the names we use now |

## Product principles

1. **The AI does not give answers.** Every response ends in a question, and asks only one thing at a time.
2. **Saving is the only thing that unlocks.** Until you save your own interpretation you cannot see the expert interpretations, other people's conversations, or the background of the poem.
3. **We do not grade.** The standard is the evidence inside the poem, not a textbook. No score, ranking or reward is given for the quality of an interpretation.
4. The words **"정답" (correct answer), "해설" (explication) and "올바른" (proper)** appear nowhere in the app.
5. **Myeongjo (serif) for the poem and the reader's own writing, Gothic (sans) for the app.**
6. The AI does not invent words the reader never wrote. Quotes are checked **in code** against the source text (`lib/writers/quote_check.dart`, `lib/agent/tools/verify_quote.dart`).

## Screens and owners

| ID | Screen | File | Owner |
| --- | --- | --- | --- |
| S01 | Sign in | `lib/features/auth/sign_in_screen.dart` | C |
| S02 | Sign up | `lib/features/auth/sign_up_screen.dart` | C |
| S13 | Intro (after sign-in, before home · moves on by itself after 30s) | `lib/features/intro/intro_screen.dart` | D |
| S03 | Home | `lib/features/home/home_screen.dart` | B |
| S04 | Reading | `lib/features/reading/reading_screen.dart` | B |
| S05 | Conversation | `lib/features/chat/chat_screen.dart` | A |
| S06 | Write up · save | `lib/features/save/save_screen.dart` | B |
| S07 | Compare | `lib/features/compare/comparison_screen.dart` | D |
| S08 | Conversation list | `lib/features/community/community_list_screen.dart` | D |
| S09 | Conversation view | `lib/features/community/community_detail_screen.dart` | D |
| S10 | Settings | `lib/features/settings/settings_screen.dart` | C |
| S11 | Edit settings | `lib/features/settings/settings_edit_screen.dart` | C |
| S12 | Profile | `lib/features/profile/profile_screen.dart` | D |

The bottom tab bar (Poems / Everyone's conversations / Settings) shows only on S03 · S08 · S10. Route names live in one place, `lib/app/router.dart`.

## Folders

```
lib/
├─ main.dart                     C   start Firebase → pick the repositories → run the app
├─ firebase_options.dart             Android config (the file only; no secrets are committed)
├─ app/
│  ├─ router.dart                C   routes · navigation
│  ├─ auth_gate.dart             C   sign-in branch (the gate at app start)
│  ├─ tab_shell.dart             C   bottom tab bar
│  ├─ theme.dart                 A   colors · fonts (design tokens live only here)
│  └─ strings.dart               everyone — UI strings (add only your own screen's lines)
├─ data/                         C
│  ├─ repositories.dart              one place to swap the repositories (useFakes / useFirebase)
│  ├─ repositories/                  interfaces — screens see nothing else
│  ├─ models/                        Poem, Reading, ExpertInterpretation, Settings …
│  ├─ fakes/                         in-memory fake repositories + fake_data.dart
│  ├─ firestore/                     the real Firestore · Firebase Auth implementations
│  └─ local/                         settings go to device storage (SharedPreferences)
├─ agent/                        A   the question agent — OpenRouter calls, output guard,
│                                   tools (verify_quote · search_poem_lines), fallback questions
├─ writers/                      D   what the model writes — S07 comparison sentence · S09
│                                   summary, quote checking, prompts, failure fallbacks
├─ compare/                      D   my interpretation ↔ expert interpretation relation,
│                                   expert interpretation parser
├─ ports/                        D   how D's screens (S07·S08·S09·S12) read their data
├─ rewards/                      D   what saving produces — new badge · public conversation
│                                   (rules only; C's repository transaction does the calling)
├─ shared/widgets/
│  ├─ poem_view.dart             B   the poem body (shared by S04 · S05 · S07)
│  ├─ app_loading.dart           D   shared loading (16 mascot frames · LOADING wave)
│  └─ buttons · fields · cards · bubbles · char counter   A
└─ features/                     the screens (owners in the table above)

assets/poems/*.json              poem body · expert interpretations · badge (one set)
assets/badges/                   badge images — still empty (an icon stands in when missing)
assets/mascot/                   16 loading-mascot frames
assets/images/                   seasonal theme — header band · mascots · logo · texture · shelf
assets/fonts/                    NanumMyeongjo · Noto Sans KR (SIL OFL)
firestore.rules                  server rules · firestore_test/ checks them on the emulator
docs/                            source-of-truth documents (Korean)
```

## How we work together

- Branches: `main` ← `develop` ← `feat/<area>-<description>`. PRs always target `develop`, need **at least one approval**, and are squash merged
- Every PR runs `flutter analyze` · `flutter test` · the security-rule tests on GitHub Actions (`.github/workflows/ci.yml`)
- Do not touch code outside your own folders. Ask the owner, or propose it as a small PR. Owners are listed in `.github/CODEOWNERS`, which requests a review automatically when your area changes
- Changes to `pubspec.yaml` · `router.dart` go in a **small PR that contains nothing else**
- Colors and fonts belong in `theme.dart`, UI strings in `strings.dart`. Never write a color code or a Korean string straight into a screen file
- Line numbers count **from 1** (`lines[lineNo - 1]`)
- The background of a poem is `creationBackground`, not `context`
- Secrets (the OpenRouter key, `google-services.json`) are never committed. If one slips in, ask the professor to reissue the key immediately
- Commit messages: `feat:` `fix:` `refactor:` `docs:` `chore:` + a description in Korean

## Not done yet

- **Badge images** (`assets/badges/{poemId}.png`) — the folder is empty, so each poem currently shows a stand-in icon (`lib/features/profile/badge_image.dart`)
- **Model names** — `dots-studio/dots-3-note-preview:free` is a preview and may be taken down. If it changes, only `lib/data/settings_options.dart` needs editing
- **Stage 3** — walking the demo scenario, the release APK, submission

## The poems

Only poems whose copyright has expired: 윤동주 "서시", 김소월 "진달래꽃", 이장희 "봄은 고양이로다", and Robert Frost "The Road Not Taken" (1916). Modern poems still under copyright are not included.

Adding a poem means adding **three things as one set** — the body, the expert interpretations and the badge (`assets/poems/<poemId>.json` · `assets/badges/<poemId>.png`).
