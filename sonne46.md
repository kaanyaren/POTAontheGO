# Performance Improvement Suggestions — sonne46

Generated: 2026-03-07  
Scope: `d:\POTAontheGO\pota_on_the_go`

---

## Critical — fix first (highest frame-time cost)

### 1. Break the `_updateCamera → setState → full rebuild` cycle

**File:** `lib/features/parks/presentation/screens/map_screen.dart`  
**Where:** `_updateCamera()`, `_buildMapBody()`, `onPositionChanged` callback

Every pan or pinch-zoom on `FlutterMap` calls `onPositionChanged`, which calls `_updateCamera`, which calls `setState`. That triggers a synchronous rebuild of the entire `MapScreen`. Inside `_buildMapBody`, five expensive derived values are then recomputed from scratch:

```dart
final validParks    = parks.where(...).toList();   // O(n) validity filter
final searchedParks = _applySearch(validParks,...); // O(n×m) string matching
final parkClusters  = _clusterParks(...);           // O(n) grid bucketing
final visibleSpotPoints = _filterVisibleSpotPoints(_buildSpotPoints(...)); // O(n)
final suggestions   = _buildSuggestions(...);       // O(n) string scan
```

**Fix:** Gate `setState` on a minimum change threshold (e.g. zoom change ≥ 0.1 or bounds shift ≥ 5% of screen width). Move camera state into a `StateNotifierProvider` or `ChangeNotifier` and let each derived value recompute only when its inputs change, using `ref.watch` selectors or a `select` guard.

---

### 2. Deduplicate `parkByReference` map construction

**File:** `lib/features/parks/presentation/screens/map_screen.dart`  
**Where:** `_buildSpotPoints()`, `_buildSuggestions()`, `_selectSuggestion()`

All three methods independently build a `Map<String, ParkModel>` from the full parks list on every call, despite being called from the same `_buildMapBody` path. `_selectSuggestion` builds a fourth copy.

**Fix:** Build this map once at the `_buildMapBody` level (or in a provider) and pass it down. If parks >50k entries, this alone cuts three redundant O(n) allocations per frame.

---

### 3. Move all `SpotsScreen.build()` derived data out of `build()`

**File:** `lib/features/spots/presentation/screens/spots_screen.dart`  
**Where:** `build()` body, lines ~110–195

On every rebuild (filter bar expand/collapse, refresh animation, etc.) the screen computes:

- `parkNameByReference` — full `O(n)` map over all parks
- `_dedupeSpots(spots)` — O(n) set scan
- `sortedSpots = [...].sort(...)` — O(n log n) copy + sort
- `_buildOptions(modeOptions)` — O(n) with set dedup and sort
- `_buildOptions(countryOptions)` — same
- `_buildOptions(bandOptions)` — same
- `filteredSpots = sortedSpots.where(...)` — O(n)

None of these depend on pure UI state (filter bar height, animation frame). They only change when `spots` or filter selection changes.

**Fix:** Extract derived spots state into a dedicated provider (or a `ConsumerStatefulWidget`-level cached value computed in `didChangeDependencies`/`_onSpotsUpdated`). Invalidate only when `currentSpotsProvider` or the active filter triple changes. The widget layer should only iterate `filteredSpots`, which is already cheap.

---

## High impact

### 4. Memoize `_clusterParks` against (zoom, bounds, parks.length)

**File:** `lib/features/parks/presentation/screens/map_screen.dart`  
**Where:** `_clusterParks()`, called inside `_buildMapBody()`

Clustering is O(n) and allocates bucket maps and lists. It is invoked on every frame while `_showParks` is true, even when the camera has not moved enough to change the visible cluster grid.

**Fix:** Cache the last `(zoom, boundsKey, parkCount)` input triple alongside the last result. Reuse the cached result if none of the three values changed since last call. A 2-decimal zoom rounding and a hashed bounds value are sufficient keys.

---

### 5. Replace `SharedPreferences` spot cache with a file-backed cache

**File:** `lib/features/spots/data/repositories/spot_repository.dart`  
**Where:** `_getCachedSpots()`, `_saveSpotsToCache()`

The full spot list is stored as one JSON string in `SharedPreferences`. `_getCachedSpots` calls `jsonDecode(rawJson)` and `sort()` every time it runs, including on startup TTL checks. `SharedPreferences` is synchronous-blocking on Android (reads from in-memory once loaded, but the initial load is synchronous disk I/O).

**Fix:** Write the sorted JSON to a regular file in the app's cache directory using `path_provider`. Keep only the `updated_at` timestamp in `SharedPreferences`. This separates large blob I/O from the fast settings store and avoids re-sorting on every cache read (write once sorted, read as-is).

---

### 6. Replace `_fetchLookupCallsigns` raw `HttpClient` with `DioClient`

**File:** `lib/features/parks/presentation/screens/map_screen.dart`  
**Where:** `_fetchLookupCallsigns()`

A new `HttpClient` is created, used, and force-closed for every debounced search keystroke. This bypasses Dio's connection pool and retry interceptors, and creates a connection cold-start on each query.

The stale-request guard via `_lookupRequestSerial` is correct, but cancellation only happens after the response arrives — the in-flight TCP connection is not cancelled.

**Fix:** Move lookup calls into the `DioClient` singleton, add a `CancelToken` per query, and call `cancelToken.cancel()` when a new query arrives before the old one finishes. Add a short in-memory TTL cache (e.g. `Map<String, List<_LookupCallsign>>` with 60 s expiry) to avoid repeated identical queries.

---

### 7. Add a memory cache to `CallsignRepository`

**File:** `lib/features/callsigns/data/repositories/callsign_repository.dart`  
**Where:** `getCallsignProfile()`

Every visit to a callsign's profile screen triggers a network round-trip. There is no in-memory or disk cache. Repeated visits for recently-looked-up callsigns (common for active activators) always pay full latency.

**Fix:** Add a `Map<String, CallsignProfileModel>` with a time-stamped entry and a TTL of ~10 minutes. On cache hit, return instantly. This is especially noticeable on the spots screen where the same activator appears on multiple spots.

---

### 8. Avoid full `findAll()` in `localParksProvider`

**File:** `lib/features/parks/presentation/providers/park_local_provider.dart`

`localParksProvider` loads the entire parks collection into a Dart `List<ParkModel>` on every consumer subscription. With the global parks CSV (~50k+ entries), this is a multi-hundred-millisecond Isar read that holds all park objects in memory simultaneously.

**Fix:** Add a complementary `parkNameMapProvider` that projects only `reference` and `name` into a `Map<String, String>`. Consumers that only need park names (e.g. `SpotsScreen`) should use that narrower provider. `localParksProvider` (full objects) should only be consumed by `MapScreen`.

---

## Medium impact

### 9. Lazy-load non-active tabs; stop `IndexedStack` from keeping all four screens alive

**File:** `lib/features/home/presentation/screens/home_shell.dart`  
**Where:** `_pages` list, `IndexedStack`

`IndexedStack` keeps all four screens mounted even when not visible:

```dart
static const _pages = [
  MapScreen(),      // FlutterMap + full parks + tile provider  
  SpotsScreen(),    // live network poll  
  HfConditionsScreen(),
  SettingsScreen(),
];
```

`FlutterMap` allocates a tile cache of up to 350 MB and establishes its own rendering pipeline. `SpotsScreen` also watches `currentSpotsProvider` which may trigger background fetches.

**Fix:** Replace `IndexedStack` with a custom `PageView` or conditional mounting — only keep the previously-visited tab alive if it has state worth preserving (map position). For `SettingsScreen` and `HfConditionsScreen` there is no meaningful state to preserve; they can be safely recreated on tab switch.

---

### 10. Defer first-run CSV sync behind a progress banner

**File:** `lib/main.dart`  
**Where:** `appBootstrapProvider`, `_AppBootstrapGate`

On first install (empty Isar), the app blocks on Isar init + full CSV download + full `compute` parse + batched Isar writes before showing any UI. This can exceed 5 s on a slow connection.

**Fix:** Show the `HomeShell` immediately after `IsarHelper.init()`. Show an inline progress banner if the park count is zero. Trigger `syncParksFromCsv()` in the background and update the UI with a pre-existing `SyncStatusProvider`. This mirrors how most apps handle first-run data loading.

---

### 11. Fix `_normalizedSpaceGroteskTextTheme` getter — it creates a new object on every call

**File:** `lib/main.dart`  
**Where:** `_normalizedSpaceGroteskTextTheme` (top-level getter)

The getter calls `_cachedTextTheme.copyWith(...)` with 15 arguments on every invocation. It is called inside `_buildTheme()`, which itself is called on every `MyApp` rebuild. The `copyWith` allocates a new `TextTheme` and 15 `TextStyle` wrappers each time.

**Fix:** Change from a getter to a top-level `final` variable initialized once:

```dart
final _normalizedSpaceGroteskTextTheme = _cachedTextTheme.copyWith(...);
```

Since `_cachedTextTheme` is already a top-level `final`, this is safe and requires no structural change.

---

### 12. Remove the unused `google_fonts` dependency

**File:** `pubspec.yaml`

`google_fonts: ^6.3.2` is listed as a dependency, but no Dart file in `lib/` imports it. The app uses a locally bundled `SpaceGrotesk-Variable.ttf` font asset declared in `pubspec.yaml`. The `google_fonts` package still adds ~150 KB of compiled bytecode and triggers a font cache directory lookup at startup.

**Fix:** Remove the line `google_fonts: ^6.2.0` from `pubspec.yaml` and run `flutter pub get`.

---

### 13. Avoid re-sorting spots on every `_getCachedSpots` read

**File:** `lib/features/spots/data/repositories/spot_repository.dart`  
**Where:** `_getCachedSpots()`, `_saveSpotsToCache()`

`_getCachedSpots` decodes the full JSON and sorts the list on every call, including calls from `getRecentSpots` that only want to check freshness. `_saveSpotsToCache` writes spots in network order, leaving sorting to the reader.

**Fix:** Sort the list once in `_saveSpotsToCache` before encoding. `_getCachedSpots` can then skip the sort, reducing an O(n log n) sort that currently happens on every startup, every tab switch that triggers a provider rebuild, and every cache miss check.

---

## Suggested implementation order

| Priority | Item | Effort | Expected gain |
|---|---|---|---|
| 1 | Throttle `_updateCamera` → `setState` (item 1) | Medium | Eliminates most dropped frames during map pan |
| 2 | Share `parkByReference` map (item 2) | Low | ~3× reduction in allocations per map frame |
| 3 | Move `SpotsScreen` derived data to providers (item 3) | Medium | Spots tab no longer recomputes 7 lists on UI events |
| 4 | Cache `_clusterParks` result (item 4) | Low | Clustering runs only on visible-area change |
| 5 | Spot cache to file-backed store, write pre-sorted (items 5, 13) | Low | Removes sort + full JSONDecode per startup |
| 6 | `DioClient`-based lookup with `CancelToken` (item 6) | Medium | Faster typeahead, no dangling TCP connections |
| 7 | Callsign profile cache (item 7) | Low | Instant repeated callsign lookups |
| 8 | `parkNameMapProvider` narrow projection (item 8) | Low | Halves memory for screens that only need names |
| 9 | Fix `_normalizedSpaceGroteskTextTheme` getter (item 11) | Trivial | Removes 15-TextStyle alloc per rebuild |
| 10 | Remove `google_fonts` (item 12) | Trivial | Smaller APK, no font-cache I/O at startup |
| 11 | Deferred tab loading (item 9) | High | ~350 MB peak memory reduction |
| 12 | Deferred first-run sync (item 10) | Medium | First-launch visible UI ≤ 200 ms |

---

## Notes

- Items already done well: tile caching in `NetworkTileProvider` (350 MB budget, 14-day TTL), CSV parsing in `compute()`, batched Isar writes at 2000 rows, stale-request serial guarding in `_fetchLookupCallsigns`, and the `ParkLookupRepository` in-memory `_cache`.
- The dominant cost visible in a Dart DevTools timeline is likely the `_buildMapBody` batch rebuild on every camera tick. Items 1–4 above all reduce pressure on that same path.
