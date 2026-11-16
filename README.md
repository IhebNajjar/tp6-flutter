# Workshop 6 — Resilient Single-Room Waiting Queue with Flutter & Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.44.8-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Realtime%20%26%20Postgres-3ECF8E?logo=supabase)](https://supabase.com)
[![SQLite](https://img.shields.io/badge/SQLite-Offline%20Persistence-003B57?logo=sqlite)](https://sqlite.org)
[![Tests](https://img.shields.io/badge/Tests-26%2F26%20Passing-brightgreen?logo=checkmarx)](test/)
[![Analysis](https://img.shields.io/badge/Analysis-0%20Issues-brightgreen?logo=dart)](analysis_options.yaml)

A production-grade, distributed, resilient single-room waiting queue management application built for **DSI 31 Cross-Platform Development**.

---

## 🚀 Features

* **📡 Informational Geolocation Integration**:
  * Optional GPS coordinate capture with graceful degradation if permissions are denied or hardware is unavailable.
  * Precise 4-decimal formatting (`lat, lng`) and accuracy in meters.
* **🌐 Network Connectivity Monitoring**:
  * Distinguishes physical network availability (Wi-Fi/Cellular) from remote Supabase backend reachability.
  * 700ms debounce timer preventing false positive state flutters during handover.
  * `OfflineBanner` displaying clear status indicators (`checking`, `offline`, `backendUnavailable`, `online`).
* **💾 Local Persistence with SQLite**:
  * Persistent storage in `waiting_queue.db` (`clients` table).
  * Status-driven offline queue tracking: `pending`, `syncing`, `synced`, `failed`.
* **🔄 Synchronization Engine (`SyncService`)**:
  * Automatically drains pending and failed records when connectivity returns.
  * Prevents duplicate registrations and concurrent sync execution.
  * Interacts with remote PostgreSQL function `register_queue_client` using `ON CONFLICT (id) DO UPDATE`.
* **📄 Pagination & Realtime Reconciliation**:
  * Paginated queue browsing (20 clients per slice) via `fetchPage(offset, limit)`.
  * De-duplicated Supabase Realtime channel stream handling for concurrent inserts and deletes.
* **🎨 Advanced UI & State Management**:
  * Reactive UI states (`initial`, `loading`, `loaded`, `empty`, `refreshing`, `loadingMore`, `error`).
  * Modular widgets: `ClientCard`, `OfflineBanner`, `LoadingWidget`, `QueueEmptyWidget`.

---

## 🏗️ Architecture

```
lib/
├── main.dart
├── models/
│   ├── client.dart
│   ├── sync_status.dart
│   ├── app_connectivity.dart
│   └── queue_state.dart
├── providers/
│   ├── queue_provider.dart
│   └── connectivity_provider.dart
├── services/
│   ├── geolocation_service.dart
│   ├── connectivity_service.dart
│   └── sync_service.dart
├── repositories/
│   └── queue_repository.dart
├── storage/
│   └── local_queue_storage.dart
├── screens/
│   └── queue_screen.dart
└── widgets/
    ├── client_card.dart
    ├── offline_banner.dart
    ├── loading_widget.dart
    └── queue_empty_widget.dart
```

---

## 🧪 Testing & Quality Assurance

Comprehensive Test-Driven Development (TDD) coverage:
* **Models**: `test/models/client_test.dart`
* **Services**: `test/services/geolocation_service_test.dart`, `test/services/sync_service_test.dart`
* **Providers**: `test/providers/connectivity_provider_test.dart`, `test/providers/queue_provider_test.dart`
* **Widgets**: `test/widgets/client_card_test.dart`, `test/widgets/offline_banner_test.dart`

To run tests:
```bash
flutter test
```
Result: **26 tests passing (100% pass rate)**.

To run static analysis:
```bash
flutter analyze
```
Result: **No issues found**.

---

## 📂 Deliverables

* **Technical Documentation**:
  * [`documentation/DOCUMENTATION.md`](documentation/DOCUMENTATION.md)
  * [`documentation/DOCUMENTATION_TP6.docx`](documentation/DOCUMENTATION_TP6.docx)
  * [`documentation/DOCUMENTATION_TP6.pdf`](documentation/DOCUMENTATION_TP6.pdf)
* **AI Assistance Report**:
  * [`compte_rendu_ai/forma.md`](compte_rendu_ai/forma.md)
  * [`compte_rendu_ai/FORMA_TP6.docx`](compte_rendu_ai/FORMA_TP6.docx)
  * [`compte_rendu_ai/FORMA_TP6.pdf`](compte_rendu_ai/FORMA_TP6.pdf)
* **Database Migration**:
  * [`supabase_schema.sql`](supabase_schema.sql)
