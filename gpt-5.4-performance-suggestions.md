# GPT-5.4 Performance Suggestions

Generated: 2026-03-07
Scope: `d:\POTAontheGO\pota_on_the_go`

This pass focuses on repo-specific performance opportunities that are visible in the current Flutter code. It does not repeat every idea from the existing root-level audit files.

## Highest-impact suggestions

1. Throttle map camera-driven rebuilds.
   - Files: `pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart:103`, `:143`, `:210`, `:1038`
   - Today, `onPositionChanged` feeds `_updateCamera()`, which calls `setState()` while the map is panning or zooming. That causes the screen to recompute park filtering, spot point building, clustering, suggestions, and marker lists during camera movement.
   - Suggestion: move camera state into a throttled notifier/provider, update heavy derived data only after movement settles, and split map overlays from the rest of the screen so the whole widget tree does not rebuild on every camera tick.

2. Precompute search indexes instead of scanning strings in every map rebuild.
   - Files: `pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart:555`, `:1066`, `:1101`
   - `_buildSuggestions()`, `_applySearch()`, and `_buildSpotPoints()` repeatedly lowercase strings, rebuild lookup maps, and walk large park/spot collections inside `build()`.
   - Suggestion: create derived providers or a search-index service that stores normalized `reference`, `name`, and `activator` values once per data refresh. Then filter against that structure instead of rebuilding indexes on every keystroke and camera update.

3. Move lookup search into the shared network layer and cancel stale requests.
   - Files: `pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart:684`, `pota_on_the_go/lib/core/network/dio_client.dart:3`
   - `_fetchLookupCallsigns()` creates a new `HttpClient`, opens a fresh connection, and decodes JSON on the UI path for every debounced query.
   - Suggestion: move lookup into a repository that uses `DioClient`, add `CancelToken` support for stale queries, and add a short TTL cache for repeated searches.

4. Replace large spot JSON caching in `SharedPreferences`.
   - Files: `pota_on_the_go/lib/features/spots/data/repositories/spot_repository.dart:23`, `:78`, `:93`
   - The repository stores the full spot list as one JSON string in `SharedPreferences`, then `jsonDecode()`s and sorts it on cache reads.
   - Why this matters: `SharedPreferences` is fine for small settings, but it becomes slow and memory-heavy when used as an object store.
   - Suggestion: cache spots in Isar or a file-backed cache, and keep only TTL metadata in `SharedPreferences`.

5. Stop doing spot dedupe, sort, filter-option generation, and filtering inside `build()`.
   - Files: `pota_on_the_go/lib/features/spots/presentation/screens/spots_screen.dart:125`, `:146`, `:149`, `:165`, `:1034`
   - `SpotsScreen` reshapes the full list every time the widget rebuilds, even for local UI events like filter-bar expansion or refresh animation changes.
   - Suggestion: move the expensive list shaping into derived providers keyed by the raw spots list and current filters. Keep the widget layer focused on rendering precomputed view models.

6. Remove fallback per-card park-name lookups.
   - Files: `pota_on_the_go/lib/features/spots/presentation/screens/spots_screen.dart:364`, `:375`, `pota_on_the_go/lib/features/parks/data/repositories/park_lookup_repository.dart:13`
   - `_SpotCard` can still call `parkNameProvider(reference)` if the parent map misses a name. On long lists, that can trigger many small async Isar lookups.
   - Suggestion: build a single `reference -> parkName` map once, or enrich the spot view model before rendering cards. The card itself should not need to query storage.

## Medium-impact suggestions

7. Avoid full park-table loads when the screen only needs a subset.
   - Files: `pota_on_the_go/lib/features/parks/presentation/providers/park_local_provider.dart:7`
   - `localParksProvider` always does `findAll()`. That is convenient, but it pushes the full park table into memory for every consumer.
   - Suggestion: add narrower providers such as `parkNameMapProvider`, `visibleParksProvider(bounds)`, or a lightweight reference/name projection for screens that do not need full park objects.

8. Reduce cold-start blocking and background tab memory.
   - Files: `pota_on_the_go/lib/main.dart:11`, `:197`, `pota_on_the_go/lib/features/home/presentation/screens/home_shell.dart:22`, `:47`
   - The app blocks on Isar init and possible first CSV sync before showing the main shell. After startup, `IndexedStack` keeps all four tabs alive, including the map tab.
   - Suggestion: show the shell earlier, run first sync behind a progress banner, and lazily instantiate non-visible tabs so `FlutterMap` and the spots list are not always resident.

9. Add caching for callsign profiles.
   - Files: `pota_on_the_go/lib/features/callsigns/data/repositories/callsign_repository.dart:16`
   - Callsign profile fetches have no memory or disk cache, so repeated visits for the same activator always hit the network.
   - Suggestion: add a small in-memory cache with TTL, and optionally persist recent profiles locally if the screen becomes a frequent navigation target.

10. Lower peak memory during initial CSV sync.
   - Files: `pota_on_the_go/lib/features/parks/data/repositories/park_sync_repository.dart:56`, `:175`, `:209`
   - The CSV parser already runs in `compute()`, which is good. But it still materializes the full CSV string, a full line list, and a full row-map list before persistence.
   - Suggestion: if park data grows, move to chunked parsing plus chunked persistence so first-run sync has a lower memory spike.

## Suggested order

1. Map camera rebuild throttling
2. Spot cache migration away from `SharedPreferences`
3. Spots list shaping in providers
4. Map search indexing
5. Startup and tab-lifetime changes

## Notes

- The repo already has a few good performance choices in place, especially map tile caching in `MapScreen` and CSV parsing in `compute()` in `ParkSyncRepository`.
- The biggest remaining cost appears to be repeated derived-data work in UI `build()` methods, especially in the map and spots screens.
