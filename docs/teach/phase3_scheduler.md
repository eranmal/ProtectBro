# Phase 3: The Core Engine - `scheduler.dart` & `simulation.dart`

## Overview
This is the absolute heart of **ProtectBro**. While the UI and database are important, the actual engineering value lies in the automated scheduling algorithm. You have implemented a **Greedy Algorithm** to solve a complex resource-allocation problem (Guard Duty Scheduling).

## The Algorithm Breakdown (`generateAdvancedSchedule`)

### 1. The Priority Mechanism (`stationClocks`)
Instead of iterating minute-by-minute (which is extremely inefficient), you implemented an event-driven approach. 
- You maintain a map of `stationClocks` which tracks the *next time* each station needs a guard.
- In each iteration, the algorithm finds the station with the earliest clock. This mimics a **Priority Queue (Min-Heap)** behavior.

### 2. Dynamic Shift Durations
Instead of hardcoding shift lengths, the algorithm calculates them dynamically:
```dart
int dur = (currentlyAvail.length == 0) ? 60 : _roundUp5(nextStation.totalActiveMinutes ~/ (currentlyAvail.length ~/ nextStation.guardsNeeded).clamp(1, 100));
```
This is a robust edge-case handler: if there are fewer guards available, shift durations automatically stretch to compensate, up to the station's `maxShiftMinutes`.

### 3. The Sacred Sorting Law (`_getAvail`)
At the core of the Greedy approach is how you pick the "best" guard for the current shift. You sort available guards based on three strict rules:
1.  **Total Shifts (`totalShifts`):** Ensures absolute fairness in the quantity of work.
2.  **Rest Time (`lastShiftEnd`):** If shifts are equal, the person who rested the longest gets picked.
3.  **Difficulty (`totalDifficultyScore`):** If both above are equal, the person who has had "easier" stations so far gets the harder assignment.

## Algorithm Complexity Analysis (NVIDIA Expected)
*   **Time Complexity:** Let $G$ be the number of guards and $S$ be the total number of shifts generated. In the worst case, for every shift, you filter and sort the guards. Sorting takes $O(G \log G)$. Furthermore, your `isBusy` check scans existing shifts ($O(S)$). Overall time complexity is roughly **$O(S \cdot G \log G + S^2)$**. 
*   **Space Complexity:** **$O(G + S)$**. You create a temporary deep copy of the guards array and a new list to hold the generated shifts.

---

## NVIDIA Interview Questions & Answers (`scheduler.dart`)

### Q1: You used a "Greedy Algorithm" here. What are the pros and cons of this approach compared to Backtracking or Dynamic Programming?
**Answer:** The primary advantage of the Greedy approach is **Performance and Simplicity**. For a mobile app, an $O(N \log N)$ greedy algorithm runs in milliseconds. The disadvantage is that Greedy algorithms do not always yield the *globally optimal* solution. It might make a locally optimal choice early in the day that leads to a sub-optimal assignment later (e.g., running out of rested guards at 3 AM). However, for tactical guard scheduling, "fair enough and fast" is far better than "mathematically perfect but slow/crashing".

### Q2: Inside `_getAvail`, you filter out busy guards by scanning the entire `shifts` list. How does this affect performance, and how would you optimize it?
**Answer:** Currently, `isBusy` scans the entire generated `shifts` list repeatedly, leading to an $O(S)$ check inside an $O(G)$ loop, making that specific block $O(S \cdot G)$. To optimize this, I would add a `DateTime? currentlyBusyUntil` property to the `Guard` model itself. When I assign a guard to a shift, I update this property. Then, checking if a guard is busy becomes an $O(1)$ operation (just `guard.currentlyBusyUntil.isAfter(currentTime)`), drastically reducing the CPU cycles.

### Q3: Dart is single-threaded. `List.sort()` is $O(N \log N)$. If a battalion has 1,000 guards, running this algorithm might cause the Flutter UI to freeze (Jank). How do you solve this?
**Answer:** CPU-intensive tasks on the main thread block Flutter's rendering pipeline. To solve this, I would move the `generateAdvancedSchedule` function to a separate **Isolate**. By using Dart's `compute()` function, the algorithm runs on a background thread. It will do the heavy lifting and sorting, and then pass the final `List<ScheduledShift>` back to the main thread, keeping the UI running at a smooth 60/120 FPS.

### Q4: Your `stationClocks` mechanism iterates over all stations to find the minimum time ($O(K)$ where $K$ is stations). What abstract data structure would make this more efficient?
**Answer:** A **Priority Queue (specifically a Min-Heap)**. Instead of iterating over all stations every loop, I could insert the stations into a Min-Heap keyed by their next required start time. Popping the earliest station would be $O(\log K)$, and inserting its next required time would also be $O(\log K)$. This is a classic optimization for simulation engines.

### Q5: What happens in your code if there is an extreme edge case where there are simply zero available guards to fill a required station?
**Answer:** The algorithm is designed not to crash or infinite-loop. If `selected.length` is less than `guardsNeeded` (meaning not enough guards were found), the `else` block triggers: `stationClocks[nextStation.id] = sStart.add(const Duration(minutes: 15));`. This means the algorithm skips forward by 15 minutes and tries again later. Essentially, the station remains unmanned for a 15-minute gap, which is the most realistic fallback behavior in a real-world shortage scenario.
