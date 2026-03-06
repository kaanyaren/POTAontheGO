# POTA on the GO - Hand-off Document for Next AI Agent

**Project Status**: Modules 1 to 4 of `IMPLEMENTASYON_PLANI.md` have been fully completed. The Flutter initialization, package integrations, local database setup, and all API endpoints are done. Module 5 (UI/UX) is the remaining pending part.

## 1. Project Overview
Project is a cross-platform (Android/iOS) map application for Parks on the Air (POTA) ham radio operators.
It is built using **Flutter**, **Dio** for network, **Riverpod** for state management, and **Isar** for a fast local NoSQL database.
The architecture is based on **Clean Architecture** patterns, divided into features (`parks`, `spots`, `activations`).

## 2. Completed Modules & Features

### Module 1: Core Setup
- **Flutter Initialization:** The `pota_on_the_go` project has been created.
- **Dependencies Installed:** `flutter_riverpod`, `dio`, `isar`, `isar_flutter_libs`, `path_provider`, `flutter_map`, `latlong2`, `csv`.
  - *Note:* Also added `build_runner` and `isar_generator` as `dev_dependencies`. Added dependency overrides for `matcher` and `test_api` in `pubspec.yaml` due to null-safety constraints in the current Flutter version.
- **Clean Architecture Folders:** Standard lib structure with `core/` and `features/` (`parks`, `spots`, `activations`) directories successfully implemented.
- **Dio Client:** Setup in `lib/core/network/dio_client.dart` configured to hit `https://api.pota.app/`.

### Module 2 & 3: Local Database & CSV Parsing (Parks)
- **Isar Database Initialization:** `lib/core/database/isar_helper.dart` handles the application document directory setup and opening the Isar database.
- **Models & Code Gen:** We have `@collection` models for `ParkModel` and `SpotModel`. All `.g.dart` mappings have been successfully generated to support indexing and Isar auto-increment parameters via `build_runner`.
- **Sync Agent:** Implemented `ParkSyncRepository` to handle fetching the `https://pota.app/all_parks_ext.csv`. Because the CSV file has thousands of rows, the Isar logic operates offline-first. It processes the text parsing, parses headers like "reference", "name", "latitude", "longitude", and executes a batch insert (`putAll`) inside an `isar.writeTxn`.
- **Riverpod Initializer:** Integrated in `lib/main.dart` such that `main()` runs `WidgetsFlutterBinding.ensureInitialized()` and `IsarHelper.init()`. The `_MyHomePageState` (now wrapped in Riverpod `ConsumerState` or reading container directly with `ProviderScope.containerOf`) automatically fires the CSV sync logic on startup if the database is mostly empty (`count < 1000`). It shows a `CircularProgressIndicator` during insertion.

### Module 4: API Integrations
All real-time endpoints have been structured with their own `FutureProvider` utilizing Riverpod.
- **Spots API:** `SpotRepository` in `lib/features/spots/data/repositories/spot_repository.dart` handles `GET /spot/` fetching real-time on-air operators. Available via Riverpod `currentSpotsProvider`. Uses `SpotModel`.
- **Park Activations API:** `ActivationRepository` in `lib/features/activations/data/repositories/activation_repository.dart` handles the history of prior activations based on park reference. `GET /park/activations/{reference}`. Available via Riverpod `parkActivationsProvider`. Uses `ActivationModel`.

## 3. Pending Tasks (Module 5 & Next Steps)
The next AI Agent should focus immediately on **Modül 5: UI ve Harita Geliştirimi (UI/UX Agent)** according to the `IMPLEMENTASYON_PLANI.md`. Since the raw data, endpoints, and providers are available, the frontend development should proceed exactly as planned:
- Building out the core BottomNavigationBar screens (Map, Live Spots, Settings).
- Integrating `flutter_map` using local `ParkModel` Isar queries to drop coordinate pins.
- Hooking the Live Spots screen up to the live `spotRepositoryProvider`.
- Creating a detailed Park View using the `activationRepositoryProvider` to show history details when you click a park list/pin.

## 4. Current State & Known Behaviors
- The repository was recently cleared of `flutter analyze` errors and committed/pushed to the remote `POTAontheGO` GitHub branch.
- Dart Version: 3.11.0 / Flutter Version: 3.41.1
- Isar DB requires the `build.yaml` file (already present) to instruct it dynamically on `.g.dart` mapping paths.
- The `main.dart` contains test logic for checking sync state but needs to be rewritten fully by the UI/UX Agent.
