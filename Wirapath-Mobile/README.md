# Wirapath — Your Path to Success

Wirapath is a Flutter mobile application built for the **Wirakarsa MBKM program**, designed to help students evaluate their tech-readiness, practice coding projects, and prepare for internship-level roles. It features a polished, multi-screen experience with skill assessments, a developer hub, CV screening, and simulation flows.

---

## 🚀 Features

### 🔐 Authentication
- **Splash Screen** — Animated entry screen on app launch.
- **Onboarding** — Step-by-step introduction for new users.
- **Sign In / Create Account** — Secure auth with social login support (Google, Facebook).
- **GitHub Integration** — Connect GitHub account via the assessment flow.

### 🏠 Home
- Dashboard with quick access to all main features.

### 📋 Readiness Center
Track and improve readiness for internship roles through structured tests:
- **Initial Test** — Baseline skill assessment with review.
- **Data Analysis Test** — Task-based data analysis challenges with review.
- **UX Design Test** — UX/UI design challenges with review.
- **Testing Test** — Software QA & testing challenges with review.
- **CV Screening** — Upload and get AI-powered CV analysis with results page.

### 💻 DevHub
Hands-on coding project challenges to build a portfolio:
- **React Testing Fundamentals** — Testing patterns for React apps.
- **CSS Responsive Mastery** — Responsive layout and CSS challenges.
- **React Component Basics** — Core React component design tasks.
- **Async JavaScript Mastery** — Promises, async/await, and event loop challenges.
- Each project has a dedicated **detail page**, a **code submission flow**, and a **result view**.

### 🎮 Simulation
Simulated internship scenarios to practice real-world tasks.

### 👤 Profile
Full user account management:
- **Personal Information** — View and edit user profile data.
- **Password & Security** — Update credentials and security settings.
- **Notifications** — Manage notification preferences.
- **Language & Appearance** — Localization and theme settings.
- **Integrations** — Third-party service connections.
- **Help & Support** — FAQs and support contact.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev/) |
| **Language** | [Dart](https://dart.dev/) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) `^3.3.1` |
| **Navigation** | [Go Router](https://pub.dev/packages/go_router) `^15.1.2` |
| **UI** | Material 3, [Google Fonts](https://pub.dev/packages/google_fonts) (Poppins), [Flutter SVG](https://pub.dev/packages/flutter_svg) |
| **Networking** | [http](https://pub.dev/packages/http) `^1.2.0` |
| **Backend** | Firebase (see `firebase.json`) |
| **Architecture** | Feature-based folder structure |

---

## 📁 Project Structure

```
lib/
├── main.dart               # App entry point
├── app.dart                # Root MaterialApp config
├── core/
│   ├── models/             # Shared data models
│   ├── providers/          # Global Riverpod providers
│   ├── router/             # Go Router configuration
│   ├── services/           # API & business logic services
│   ├── theme/              # App theme & design tokens
│   └── widgets/            # Shared/reusable widgets
└── features/
    ├── splash/             # Splash screen
    ├── onboarding/         # Onboarding flow
    ├── auth/               # Sign in & create account
    ├── assessment/         # Skill assessment & GitHub connect
    ├── main/               # Main shell with bottom navigation
    ├── home/               # Home dashboard
    ├── readiness/          # Readiness Center tests & CV screening
    ├── devhub/             # DevHub coding projects
    ├── simulation/         # Simulation feature
    ├── profile/            # User profile & settings
    └── initial_test/       # Initial test module
```

---

## 📋 Prerequisites

- **Flutter SDK:** `^3.11.5` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK:** Included with Flutter (`^3.10.0`)
- **IDE:** [VS Code](https://code.visualstudio.com/) with the Flutter extension, or [Android Studio](https://developer.android.com/studio)
- **Device:** Android Emulator, iOS Simulator, or a physical device

---

## ⚙️ Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/wirakarsa-mobile.git
   cd wirakarsa-mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify your environment:**
   ```bash
   flutter doctor
   ```

4. **Add Firebase config files** (required for backend features):
   - Android: place `google-services.json` in `android/app/`
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`

---

## 🏃 Running the Project

**Debug mode:**
```bash
flutter run
```

**Development entry point (with mock data):**
```bash
flutter run -t lib/main_dev.dart
```

**Release builds:**

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## ✅ Code Quality

Run the analyzer before submitting a PR:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

---

## 🤝 Contributing

1. **Fork** the repository.
2. **Create** a feature branch: `git checkout -b feature/your-feature-name`
3. **Commit** your changes: `git commit -m 'feat: add your feature'`
4. **Push** to your branch: `git push origin feature/your-feature-name`
5. **Open** a Pull Request.

> Please ensure `flutter analyze` passes with no errors before opening a PR.

---

## 📄 License

This project is developed for the **MBKM Wirakarsa program** and is set to `publish_to: none`. All rights reserved by the Wirapath Team.

---

Built with ❤️ by the **Wirapath Team**
