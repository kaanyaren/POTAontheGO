# Performance suggestions (automated scan)

Summary
-------
- Quick scan of the Flutter app under `pota_on_the_go/lib` (main entry at `main.dart`). Found several frequent UI state updates and a few JSON/network parsing spots that could be optimized.

High-level recommendations
------------------------
- Favor immutable/const widgets where possible (use `const` constructors).
- Replace broad `setState(() { })` usage with more granular state management (Riverpod providers, `ValueNotifier`, `StateNotifier`, or local `ChangeNotifier`) so rebuilds affect minimal subtree.
- Debounce rapid user input (search boxes) to avoid repeated rebuilds and excessive API calls.
- Offload heavy parsing (large JSON/CSV) to isolates (use `compute` or a dedicated isolate) instead of running on the UI thread.
- Use lazy lists and optimizations: `ListView.builder`, provide `itemCount`, set `itemExtent` when known, and use `RepaintBoundary` for expensive list children.
- Cache network assets and API responses (e.g., `cached_network_image`, HTTP caching or local DB) and minimize repeated network fetches.
- Reduce widget allocation inside `build()` (avoid creating many objects each frame).
- Profile with Dart DevTools (CPU + raster + memory) and measure before/after each change.

Repository-specific findings & suggestions
----------------------------------------
- Map screen: [pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart](pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart#L319-L1325)
  - Many `setState` calls across the file (search, refresh, selection, UI toggles). Refactor to:
    - Use Riverpod providers / `StateNotifier` for non-UI state (search query, lookups, selected point).
    - Use `ValueListenableBuilder` / scoped consumers to update only the widgets that need it.
    - Replace empty `setState(() { })` patterns with targeted updates or provider invalidation.
  - `jsonDecode(responseBody)` appears in this file — move heavy decoding to `compute` if payloads can be large.
  - The map may render many markers; consider clustering or canvas-based rendering for large sets.

- Spots screen: [pota_on_the_go/lib/features/spots/presentation/screens/spots_screen.dart](pota_on_the_go/lib/features/spots/presentation/screens/spots_screen.dart#L1-L300)
  - Multiple small `setState` usages for UI toggles and refresh flags. Similar refactor: local `StateNotifier` or finer-grained widgets to avoid full rebuilds.

- Park sync / parsing: [pota_on_the_go/lib/features/parks/data/repositories/park_sync_repository.dart](pota_on_the_go/lib/features/parks/data/repositories/park_sync_repository.dart#L1-L120)
  - This repo already uses `compute` for parsing (good). Verify streaming or chunked parsing if CSVs are very large to reduce peak memory.

- JSON decoding in data layer: [pota_on_the_go/lib/features/spots/data/repositories/spot_repository.dart](pota_on_the_go/lib/features/spots/data/repositories/spot_repository.dart#L1-L120)
  - `jsonDecode` is used; for large responses offload to `compute`.

- Lists: Instances of `ListView` found in screens such as callsign, settings and park detail screens. Ensure they use `ListView.builder` with `itemCount` and `itemExtent` where possible:
  - [map_screen.dart ListView.separated](pota_on_the_go/lib/features/parks/presentation/screens/map_screen.dart#L518)
  - [park_detail_screen.dart ListView](pota_on_the_go/lib/features/parks/presentation/screens/park_detail_screen.dart#L28)

- App bootstrap: [pota_on_the_go/lib/main.dart](pota_on_the_go/lib/main.dart)
  - App performs DB init and may sync CSVs at startup (`appBootstrapProvider`). Keep heavy work off the immediate UI thread and show progress; if initial sync is required only once, consider incremental background sync to speed first-render.

- Network / Map tiles
  - Verify Android manifest includes `INTERNET` permission for release builds (release networking failures are common without it).

Priority list (short)
---------------------
1. Refactor large, multi-purpose widgets (map_screen) to reduce `setState` blast radius.
2. Offload JSON/CSV parsing to `compute` or isolates where not already done.
3. Use `ListView.builder` + `itemExtent` and `RepaintBoundary` where lists show complex children.
4. Add caching for network/mapping tiles and API responses.
5. Run CPU and raster profiles with DevTools and address the top-3 hotspots.

Quick validation steps
----------------------
- Use `flutter run --profile` and open DevTools → CPU + Timeline; capture a startup/profile trace and look for long frames and main-thread tasks.
- Measure before/after (frame build times, memory, bundle size) for each change.

Next steps I can take
---------------------
- Create focused PRs for `map_screen.dart` to replace `setState` with Riverpod-driven state and add debouncing to search.
- Move JSON decode calls into `compute` where appropriate and add tests for parse/stream correctness.
- Add profiling notes (DevTools trace) and a short benchmark script if you want me to run local profiling next.

If you want, I can implement one targeted change now (pick: map_screen state refactor, offload jsonDecode to `compute`, or add cached image support). 
