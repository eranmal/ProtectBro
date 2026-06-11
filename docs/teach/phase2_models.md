# Phase 2: Deep Dive - `models.dart`

## Overview
The `models.dart` file serves as the **Data Layer** of the application. It defines the core entities (`Guard`, `Station`, `ScheduledShift`) used throughout the app. Instead of passing around raw Maps or JSON objects from Firebase, data is parsed into these strongly-typed classes.

## Class Breakdown & OOP Principles

### 1. `Guard` Class
**Purpose:** Represents a single person in the unit.
- **Encapsulation:** Groups related properties (shifts, difficulty score, rest times) into one cohesive unit.
- **Immutability (Partial):** `id` and `name` are marked as `final`. This guarantees that a Guard's core identity cannot be accidentally modified during runtime, preventing bugs.
- **The `copy()` Method (Prototype Pattern concept):** You implemented a `copy()` method to create a new instance with the exact same values. This is crucial for **Simulation/Algorithm safety**. When the scheduler runs, it can modify a "copy" of the guard without corrupting the original state shown in the UI.

### 2. `Station` Class
**Purpose:** Represents a physical guard post.
- **Encapsulation of Logic:** The getter `totalActiveMinutes` encapsulates the business logic for calculating how long a station operates.
- **Why a Getter?** Instead of a regular method `getTotalActiveMinutes()`, using a getter (`get`) treats the calculation as a property. It computes the value on-the-fly, ensuring it's always accurate without requiring extra memory storage.

### 3. `ScheduledShift` Class
**Purpose:** Represents a specific time block assigned to specific people at a specific place.
- **Composition over Inheritance:** This class demonstrates *Composition*. A `ScheduledShift` "has-a" `Station` and "has-a" `List<Guard>`. This is preferred in modern software engineering over deep inheritance trees because it is highly flexible.

## Synchronization & Integration
These models do not fetch data themselves (they are "dumb" data objects, which is a good practice). The synchronization happens in `main.dart`, where Firebase `DocumentSnapshots` are mapped into these Dart objects. This creates a clean separation of concerns: the models only care about structure, not database logic.

---

## NVIDIA Interview Questions & Answers (`models.dart`)

### Q1: Why did you choose to make `id` and `name` in the `Guard` class `final`, but left `totalShifts` mutable?
**Answer:** I used `final` for `id` and `name` because the fundamental identity of a guard should never change after instantiation. Making them immutable prevents accidental state mutation bugs. However, properties like `totalShifts` and `lastShiftEnd` must be mutable because they are constantly updated by the scheduling algorithm as new shifts are assigned.

### Q2: You implemented a `copy()` method in the `Guard` class. What specific problem does this solve?
**Answer:** It solves the problem of side-effects during algorithm execution. When my scheduling algorithm (`scheduler.dart`) tests different shift combinations, it modifies guard metrics (like `totalShifts`). If I passed the original object by reference, a failed scheduling attempt would leave the guard's data corrupted. The `copy()` method allows the algorithm to work on a clone (similar to the Prototype Design Pattern), preserving the original state until the schedule is officially approved.

### Q3: In the `Station` class, you use a getter for `totalActiveMinutes`. Why not just calculate this once in the constructor and store it in a standard variable?
**Answer:** Using a getter calculates the value on-demand. If I calculated it in the constructor, and later the `startHour` or `endHour` of the station was updated dynamically, the stored `totalActiveMinutes` would become stale (out of sync). The getter guarantees that the calculation is always strictly synchronized with the current state of the object, without consuming additional memory for an extra field.

### Q4: In `ScheduledShift`, you hold a `List<Guard> assignedGuards`. If this system scaled to millions of shifts and thousands of guards, what performance issue might this cause, and how would you fix it?
**Answer:** Storing full `Guard` objects inside every `ScheduledShift` in memory could cause memory bloat and redundancy (the same guard object duplicated across hundreds of shifts). To scale, I would change this to `List<String> assignedGuardIds` (Normalization). I would only fetch or link the full `Guard` objects when specifically required for UI rendering, utilizing Lazy Loading to save RAM.

### Q5: How do these Dart models handle the impedance mismatch with Firebase (which uses JSON-like Documents)?
**Answer:** These models act as Data Transfer Objects (DTOs). While Firebase returns raw `Map<String, dynamic>`, my UI and algorithms require strict typing to prevent runtime exceptions (NullPointer exceptions, type mismatches). By mapping Firebase data directly into these Dart classes upon retrieval, I ensure type safety, enable IDE auto-completion, and centralize default values (e.g., `isCommander = false`), keeping my business logic clean and decoupled from Firebase's exact structure.
