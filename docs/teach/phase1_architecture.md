# Phase 1: High-Level Architecture & System Overview

## 1. The Pitch (Problem & Solution)
**ProtectBro** is a tactical shift scheduling system designed for military or security units. 
- **The Problem:** Manual scheduling leads to unfairness, high cognitive load on commanders, and difficulty managing last-minute changes (emergencies/no-shows).
- **The Solution:** An algorithm-based platform that balances workloads according to station difficulty, previous shift counts, and required rest times, all synchronized in real-time.

## 2. Tech Stack & Engineering Trade-offs
- **Frontend: Flutter (Dart)**
  - *Why?* Cross-platform capabilities (runs on iOS and Android from a single codebase) with near-native performance due to its direct GPU rendering engine.
- **Backend/Database: Firebase Firestore (NoSQL)**
  - *Why?* The core requirement was **Real-Time Synchronization**. If a commander updates a schedule, all guards must see it instantly. Firestore utilizes WebSockets to push updates seamlessly, prioritizing read/listen speed over complex SQL relationships.
- **Local Storage: `SharedPreferences`**
  - *Why?* Used to cache user login history locally on the device, minimizing unnecessary network calls and enabling rapid re-entry into the app.

## 3. Data Flow & State Management
- **Reactive UI:** The architecture relies heavily on `StreamBuilder`. The app establishes an open stream to Firestore collections (e.g., `guards`, `latest_schedule`).
- **Single Source of Truth:** The UI does not maintain complex local state arrays. Firestore acts as the definitive source of truth. When the database updates, the stream emits an event, and only the relevant UI widgets rebuild. This prevents state inconsistencies and reduces device memory consumption.

## 4. Authentication & Access Control
Instead of a heavy OAuth (Email/Password) system, the app uses a **Role-Based Token/Code System**:
- Each unit generates an `adminCode` (for commanders) and a `userCode` (for guards).
- *Engineering Decision:* In a field environment, users don't have time for tedious registration processes. This frictionless onboarding allows an entire unit to log in within seconds.

## NVIDIA Interview Focus Points
- **Decision Making:** Be ready to defend why you chose NoSQL over SQL (e.g., speed of real-time updates vs. relational data integrity).
- **Performance:** Emphasize how `StreamBuilder` optimizes UI rendering by rebuilding only what changes, saving CPU/Memory on mobile devices.
