# fasn — Complete Build Instructions

## What's in this app

| Screen       | Feature                                                                 |
|-------------|-------------------------------------------------------------------------|
| Routine     | 7-day dashboard with animated progress rings, alarms with TTS, expiry  |
| Notes       | Grid notes with color-coding, bold text, color pickers                  |
| Gratitude   | Journal + Affirmations + Insights heatmap + AI companion (Lumina)      |
| Music       | Storage player with seek bar, shuffle, loop, vinyl animation            |
| Settings    | Profile, AI API config, flowers toggle, data management                 |

---

## Step 1 — Prerequisites

- Flutter SDK 3.16 or newer → https://flutter.dev/docs/get-started/install
- Android Studio or VS Code with Flutter/Dart extensions
- JDK 17+
- Android SDK API 21+ (minSdk), API 34 (targetSdk)

---

## Step 2 — Download Poppins Font

Place these 5 files inside `assets/fonts/`:

1. Download from https://fonts.google.com/specimen/Poppins
2. Get: `Poppins-Light.ttf`, `Poppins-Regular.ttf`, `Poppins-Medium.ttf`, `Poppins-SemiBold.ttf`, `Poppins-Bold.ttf`

---

## Step 3 — Install Dependencies

```bash
cd fasn
flutter pub get
```

---

## Step 4 — Run / Debug

```bash
# List connected devices
flutter devices

# Run debug build
flutter run

# Run on specific device
flutter run -d <device_id>
```

---

## Step 5 — Build Release APK

```bash
# Standard APK (universal)
flutter build apk --release

# Split by ABI (smaller per device, recommended)
flutter build apk --split-per-abi --release

# App Bundle for Play Store
flutter build appbundle --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## Step 6 — Configure AI (in-app)

1. Open fasn → Settings → AI Configuration
2. Enter your API Base URL, API Key, and Model name
3. Quick presets available for: OpenAI, Anthropic, Groq, Ollama

**Compatible with any OpenAI-spec API:**
- OpenAI: `https://api.openai.com/v1` + `gpt-4o-mini`
- Groq (free tier): `https://api.groq.com/openai/v1` + `llama3-8b-8192`
- Anthropic: `https://api.anthropic.com/v1` + `claude-3-haiku-20240307`
- Local Ollama: `http://localhost:11434/v1` + `llama3`

---

## Permissions

The app requests at runtime:
| Permission            | Purpose                              |
|-----------------------|--------------------------------------|
| POST_NOTIFICATIONS    | Task alarms (Android 13+)            |
| SCHEDULE_EXACT_ALARM  | Precise alarm scheduling             |
| READ_MEDIA_AUDIO      | Music player (Android 13+)           |
| READ_EXTERNAL_STORAGE | Music player (Android 12 and below)  |
| VIBRATE               | Alarm vibration                      |

---

## Project Structure

```
fasn/lib/
├── main.dart                          # Entry point
├── models/
│   ├── models.dart                    # All Hive models
│   └── models.g.dart                  # Manual type adapters (no codegen needed)
├── services/
│   ├── hive_service.dart              # All local storage operations
│   ├── notification_service.dart      # Alarm scheduling + TTS
│   └── ai_service.dart               # AI API calls (OpenAI-compat)
├── screens/
│   ├── splash_screen.dart             # "I love you rabbit" splash
│   ├── main_shell.dart               # Bottom nav shell (5 tabs)
│   ├── routine/routine_screen.dart    # Routine dashboard
│   ├── notes/
│   │   ├── notes_screen.dart          # Notes grid
│   │   └── note_editor_screen.dart    # Rich note editor
│   ├── gratitude/
│   │   ├── gratitude_screen.dart      # Journal + Affirmations + Insights
│   │   ├── gratitude_entry_screen.dart# Entry editor with mood picker
│   │   └── chat_screen.dart          # Lumina AI chat
│   ├── music/music_screen.dart        # Music player
│   └── settings/settings_screen.dart  # Settings (profile + AI + data)
├── widgets/
│   ├── progress_ring.dart             # Animated gradient progress ring
│   ├── floating_flowers.dart          # Optimised 30fps flower animation
│   └── motivational_popup.dart        # Morning/evening motivation dialog
└── utils/
    ├── app_theme.dart                 # Full baby-pink Material 3 theme
    └── constants.dart                 # Motivational quotes list
```

---

## Troubleshooting

**"Hive type not registered" crash on startup**
→ Run a clean build: `flutter clean && flutter pub get && flutter run`

**Music player shows no songs**
→ Grant audio/storage permission in Settings → Apps → fasn → Permissions

**Alarms not firing in background**
→ Android 12+: grant "Alarms & Reminders" in Settings → Special App Access
→ Some OEMs (MIUI, OneUI) require battery optimisation to be disabled for fasn

**AI not responding**
→ Check Settings → AI Configuration: ensure Base URL ends correctly (e.g., `.../v1`)
→ The API key must have sufficient credits/quota
→ For Anthropic: their API uses a different auth header format — Groq or OpenAI recommended

**Google Fonts (Poppins) not loading offline**
→ Add the 5 Poppins .ttf files to `assets/fonts/` — the app will use them as local fallback

**Build error: "desugar_jdk_libs" version**
→ Update Android Gradle Plugin: in `android/build.gradle` update `classpath` to `8.2.0`
