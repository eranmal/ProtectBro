<div align="center">
  <img src="https://img.icons8.com/color/96/000000/shield.png" alt="ProtectBro Logo" width="80" />
  
  # ProtectBro 🛡️
  **Advanced Tactical Shift Management System**

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
    <img src="https://img.shields.io/badge/Architecture-SOLID-brightgreen?style=for-the-badge" />
  </p>
</div>

---

## 📌 Overview
**ProtectBro** is a sophisticated, real-time tactical shift and operations room (Hamal) management application. Designed with military precision in mind, it automates the complex task of scheduling guards, managing stations, and distributing shifts fairly across personnel based on difficulty metrics.

Wrapped in a premium, highly-animated **Cyber-Tactical** UI (Glassmorphism + Neon aesthetics), the system provides an intuitive experience for both commanders and standard guards, all powered by a robust **Cloud Firestore** backend.

---

## ✨ Key Features

* 🤖 **Algorithmic Scheduling Engine:** Automatically generates fair shift schedules based on individual guard constraints, past shift counts, and station difficulty levels. Features smart rest-time enforcement.
* 🔒 **Role-Based Access Control (RBAC):** Dynamic, secure access codes separating *Commanders* (Full read/write/edit access) from *Guards* (Read-only + personal shift interaction).
* ⚡ **Real-Time Data Sync:** Live synchronization across all active clients utilizing Firebase Streams. Shifts, guard statuses, and logs update instantly.
* 🎨 **Cyber-Tactical UI/UX:** A stunning, immersive user interface featuring:
  * Glassmorphism and Backdrop Blur effects.
  * Staggered entry animations and continuous micro-animations.
  * Centralized custom Theming to enforce design consistency.
* 📊 **Radar Matrix Dashboard:** A comprehensive, interactive data table providing a 24/7 overview of all stations and assigned personnel.
* 📝 **Real-Time Incident Logging:** Dedicated chat/log channels for every station, allowing guards to report incidents and handover notes live.

---

## 🏗️ Software Architecture & Design Patterns

The codebase was heavily refactored and engineered to adhere to **SOLID** principles, specifically focusing on **Separation of Concerns (SoC)**:

1. **Layered Architecture:** 
   - `models/` - Pure Dart data classes (Guard, Station, Shift).
   - `services/` - Business logic and algorithmic generation (`scheduler_service.dart`).
   - `screens/` - Stateful UI wrappers handling user flows.
   - `widgets/` - Reusable, isolated UI components (`CyberButton`, `RadarMatrix`, `GlassHistoryCard`).
   - `theme/` - Centralized design system (`app_theme.dart`) acting as the app's CSS.
2. **Component Reusability:** Complex screens were broken down into small, self-contained, stateless widgets to prevent monolith classes and reduce UI rebuild costs.
3. **Reactive Programming:** Extensive use of `StreamBuilder` ensuring that UI state is directly driven by the database state without manual synchronization.

---

## 💻 Tech Stack

* **Frontend:** Flutter (Dart)
  * Animations: `flutter_animate`
  * Typography: `google_fonts` (Heebo)
  * Local Storage: `shared_preferences`
* **Backend:** Firebase 
  * Database: Cloud Firestore (NoSQL)
  * Hosting: Firebase Hosting

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (v3.0.0 or higher)
* Dart SDK
* Firebase CLI (if you wish to deploy or modify the database rules)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/ProtectBro.git
   cd ProtectBro
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app locally (Web recommended for dashboard view):
   ```bash
   flutter run -d chrome
   ```

*(Note: The Firebase configuration files like `firebase_options.dart` are excluded from the repository for security reasons. You will need to link your own Firebase project to run the database).*

---

## 👨‍💻 Developer Notes
This project was developed with a strong emphasis on clean code, algorithmic efficiency, and modern UI capabilities in Flutter. It demonstrates proficiency in full-stack mobile/web architecture, database stream management, and advanced state presentation.

<div align="center">
  <br>
  <i>Built with ❤️ for efficiency and security.</i>
</div>
