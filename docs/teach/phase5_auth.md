# Phase 5: Security & Authentication - `auth_screen.dart` & `unit_selection_screen.dart`

## Overview
These two files represent the security and onboarding flow of the application. They implement a **Two-Tier Authentication System**:
1.  **Identity Layer (`auth_screen.dart`):** Verifies *who* the user is using standard Firebase Auth (Google OAuth, Email/Password).
2.  **Authorization & Role Layer (`unit_selection_screen.dart`):** Determines *what* the user is allowed to do by validating Unit Codes (`adminCode` vs. `userCode`).

## Design Principles & Architecture

### 1. Separation of Concerns (Identity vs. Roles)
By decoupling the user's identity (their Google Account) from their specific role in a unit, you created a scalable architecture. If a soldier moves to a different unit, they don't need a new account; they simply enter a new Unit Code.

### 2. Role-Based Access Control (RBAC)
The `_joinUnit` method implements dynamic RBAC. It queries Firestore to see if the entered code matches the `adminCode` or `userCode` of a group. If it matches the `adminCode`, it flags `isAdmin = true` and saves this boolean to the user's profile in Firestore. This dictates which UI components (like the Edit/Delete buttons in `main.dart`) are rendered.

### 3. Web-First Considerations
In `auth_screen.dart`, you specifically utilized `signInWithPopup` for Google Auth. This indicates you built the app with Flutter Web in mind. Popups prevent the browser from navigating away and losing the Flutter application's local state, ensuring a seamless user experience.

---

## NVIDIA Interview Questions & Answers (`auth` & `unit_selection`)

### Q1: Why did you separate the Identity (Google Auth) from the Unit Roles (Unit Code) instead of just adding a "unit" field when they register?
**Answer:** Decoupling identity from authorization allows for much greater flexibility. A user's identity (Email/Google) is permanent, but their assignment to a unit is temporary. This architecture allows a single user to leave one unit and join another in the future using a new code, without needing to delete and recreate their core account.

### Q2: In `unit_selection_screen.dart` inside `_joinUnit`, you query Firestore sequentially: first you `await` the admin code query, and if it fails, you `await` the user code query. How could you optimize this?
**Answer:** Sequential queries cause unnecessary latency because the second network request waits for the first to finish. To optimize this, I would fire both queries concurrently using `Future.wait([adminQuery, userQuery])`. This runs both requests in parallel, cutting the network waiting time effectively in half.

### Q3: You store the `isAdmin` boolean directly on the client and pass it to `MainManagerScreen`. How do you prevent a malicious user from modifying the client-side code, forcing `isAdmin = true`, and bypassing your security?
**Answer:** Client-side security is never enough because the client can always be manipulated. The true source of security must be **Firebase Security Rules**. Even if a user hacks the Flutter app to show the Admin UI, when the app tries to execute an admin command (like deleting a station), the Firestore Security Rules on the backend will check the user's actual token/role. If the backend doesn't recognize them as an admin, the write operation will be blocked with a `Permission Denied` error.

### Q4: How do you secure the Firestore database so a regular guard cannot just read the `adminCode` from the database and elevate their own privileges?
**Answer:** I would structure the Firestore Security Rules so that the `groups` document limits read access. Fields like `adminCode` should be moved to a private sub-collection or protected by rules that only allow users whose UID is already registered as an admin to read that specific field.

### Q5: What happens if a user's network connection drops exactly after Firebase Auth succeeds, but before the `users` document is created in Firestore?
**Answer:** This creates a partial failure state where the user is authenticated but lacks a database profile, breaking the app logic. To solve this reliably, I would remove the client-side profile creation. Instead, I would write a **Firebase Cloud Function** triggered by `functions.auth.user().onCreate()`. When the backend detects a new user, it automatically initializes their database document. This guarantees atomicity and keeps the client code clean.
