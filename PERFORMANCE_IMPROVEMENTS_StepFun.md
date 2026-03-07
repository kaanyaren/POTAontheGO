# Performance Improvements Suggestions

*Generated: March 7, 2026*
*Based on analysis of Flutter codebase structure and patterns*

---

## Overview

This document outlines potential performance improvements for the POTAontheGO Flutter application. Issues are prioritized by impact and implementation effort.

---

## 🔴 Critical Priority

### 1. SpotsScreen Park Name Lookup Optimization

**Problem:** Each `_SpotCard` widget independently watches `parkNameProvider(spot.reference)`, causing 100+ simultaneous provider lookups when 100+ spots are displayed. This creates unnecessary rebuilds and database queries.

**Current Code Pattern:**
```dart
// In _SpotCard
final parkNameAsync = ref.watch(parkNameProvider(spot.reference));
```

**Impact:** High - Directly affects scrolling performance and UI responsiveness.

**Solution:**
- Precompute a park name map in the SpotsScreen provider level
- Pass the map down to `_SpotCard` instead of individual provider watches
- Use `ref.watch(parkNameMapProvider)` once in SpotsScreen

**Estimated Effort:** 2-3 hours
**Risk:** Low - Isolated change, easy to test

---

### 2. MapScreen Search Suggestions Computation

**Problem:** `_buildSuggestions` method performs in-memory filtering of all parks and spots on every keystroke. With 1000+ parks, this can cause jank during typing.

**Current Code Pattern:**
```dart
List<Widget> _buildSuggestions(String query) {
  // Filters through all parks/spots on each call
}
```

**Impact:** High - Affects user experience during park search.

**Solution:**
- Move suggestion computation to a separate provider using `FutureProvider` or `Provider`
- Debounce the computation (already has 300ms delay, but computation itself should be async)
- Use `compute()` for heavy filtering operations off the main thread

**Estimated Effort:** 3-4 hours
**Risk:** Low - Can be implemented incrementally

---

### 3. Map Clustering Memoization

**Problem:** `_clusterParks` recalculates on every rebuild, even when zoom level and visible bounds haven't changed. This is expensive with 1000+ parks.

**Current Code Pattern:**
```dart
List<ClusterPark> _clusterParks(List<ParkModel> parks, double zoom) {
  // Recalculates every rebuild
}
```

**Impact:** Medium-High - Affects map rendering performance during pan/zoom.

**Solution:**
- Memoize clustering based on (parks hash, zoom level, bounds)
- Use `useMemoized` pattern or derived provider
- Only recalculate when dependencies actually change

**Estimated Effort:** 2-3 hours
**Risk:** Medium - Requires careful cache invalidation logic

---

## 🟡 Moderate Priority

### 4. Spots Pagination / Infinite Scroll

**Problem:** All spots are loaded into memory at once. With hundreds of spots, this increases memory usage and initial load time.

**Impact:** Medium - Affects memory footprint and initial rendering.

**Solution:**
- Implement pagination (e.g., 50 spots per page)
- Use `ListView.builder` with lazy loading
- Load more on scroll to bottom

**Estimated Effort:** 4-6 hours
**Risk:** Medium - Requires API coordination and state management changes

---

### 5. Gravatar Image Caching

**Problem:** Callsign profile images use `NetworkImage` without specialized caching. While Flutter has basic caching, it's not optimized for repeated avatar loads.

**Current Location:** `features/callsigns/presentation/screens/callsign_info_screen.dart`

**Impact:** Medium - Affects callsign info screen loading and scrolling.

**Solution:**
- Use `cached_network_image` package
- Configure custom cache manager with appropriate size limits
- Add placeholder/error widgets

**Estimated Effort:** 1-2 hours
**Risk:** Low - Standard package integration

---

### 6. SharedPreferences Access Centralization

**Problem:** Multiple repositories read from SharedPreferences independently, causing scattered async I/O operations.

**Impact:** Low-Medium - Minor efficiency gain, better code organization.

**Solution:**
- Create a centralized `PreferencesService` singleton
- Batch reads where possible
- Add in-memory cache for frequently accessed values

**Estimated Effort:** 2-3 hours
**Risk:** Low - Refactoring with minimal behavioral change

---

## 🟢 Low Priority / Nice to Have

### 7. Theme Rebuild Optimization

**Problem:** `MyApp` rebuilds entire widget tree on theme mode change. While acceptable, could be optimized.

**Impact:** Low - Theme changes are infrequent.

**Solution:**
- Use `AnimatedTheme` or `Theme` widget with `child` parameter to limit rebuild scope
- Consider `ValueListenableBuilder` for theme mode only

**Estimated Effort:** 1 hour
**Risk:** Low - Cosmetic improvement

---

### 8. String Operations in Loops

**Problem:** Frequent `toUpperCase()`, `trim()`, and string concatenation in loops (especially in filtering/sorting operations).

**Impact:** Low - Micro-optimization, likely negligible in practice.

**Solution:**
- Precompute normalized strings where possible
- Use `StringBuffer` for concatenation in loops
- Profile first to confirm actual impact

**Estimated Effort:** 1-2 hours
**Risk:** Very Low - Code cleanup

---

### 9. Map Tile Error Threshold Configurability

**Problem:** Hardcoded 8 consecutive errors before fallback to OSM tiles.

**Current Location:** `features/parks/presentation/screens/map_screen.dart`

**Impact:** Low - Edge case improvement.

**Solution:**
- Move threshold to configuration or settings
- Make it user-adjustable in Settings screen

**Estimated Effort:** 1 hour
**Risk:** Very Low - Simple parameterization

---

## 📊 Performance Monitoring Recommendations

### Add DevTools Integration

1. **Performance Overlay:** Enable in debug mode to monitor UI jank
   ```dart
   debugPaintSizeEnabled = kDebugMode;
   ```

2. **Widget Rebuild Tracking:** Use `debugPrintStack()` or `RebuildTracker` to identify hot rebuilds

3. **Memory Profiling:** Regularly profile with DevTools Memory tab to catch leaks

4. **Network Monitoring:** Log Dio requests/responses in debug mode to identify redundant calls

### Establish Performance Budgets

Define acceptable thresholds:
- Frame rendering time: < 16ms for 60fps
- Map marker rendering: < 100ms for 500 markers
- Search suggestions: < 50ms response time
- App startup: < 2 seconds to interactive

---

## 🛠️ Implementation Strategy

### Phase 1 (Immediate - 1 week)
1. Fix SpotsScreen park name lookup (Critical #1)
2. Optimize MapScreen search suggestions (Critical #2)
3. Add performance monitoring to identify remaining bottlenecks

### Phase 2 (Short-term - 2-3 weeks)
4. Memoize map clustering (Critical #3)
5. Add cached_network_image for avatars (Moderate #5)
6. Implement spots pagination (Moderate #4)

### Phase 3 (Medium-term - 1 month)
7. Centralize SharedPreferences (Moderate #6)
8. Theme rebuild optimization (Low #7)
9. String operation cleanup (Low #8)

### Phase 4 (Ongoing)
10. Regular performance profiling
11. Establish automated performance regression tests
12. Monitor production performance with analytics

---

## 📈 Expected Improvements

| Issue | Expected Gain | Confidence |
|-------|---------------|------------|
| Spots park lookup | 30-50% smoother scrolling | High |
| Search suggestions | Eliminate typing jank | High |
| Clustering memoization | 20-30% faster map renders | Medium |
| Pagination | 40-60% less memory usage | High |
| Image caching | Faster avatar loading | Medium |

---

## 🔍 Verification Steps

For each improvement:
1. Profile before/after with Flutter DevTools
2. Measure frame times during typical user flows
3. Test with realistic data volumes (1000+ parks, 100+ spots)
4. Verify no regressions in functionality
5. Test on low-end Android devices

---

## 📝 Notes

- All changes should be profiled on actual devices, not just emulators
- Consider adding performance tests to CI/CD pipeline
- Monitor production crash reports for OOM or jank after releases
- Some optimizations may have diminishing returns - always measure before/after

---

*Maintain this document as the codebase evolves. Update with new performance findings and remove resolved items.*