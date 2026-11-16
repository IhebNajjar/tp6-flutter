# Workshop 6 — Resilient Single-Room Waiting Queue with Flutter & Supabase

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Realtime%20%26%20Postgres-3ECF8E?logo=supabase)](https://supabase.com)
[![SQLite](https://img.shields.io/badge/SQLite-Offline%20Persistence-003B57?logo=sqlite)](https://sqlite.org)

## 📌 Context & Overview
Extending the Flutter single-room waiting queue application to build a resilient, production-ready system with:
1. **Device Geolocation Integration:** Informational, optional GPS capture with graceful fallback.
2. **Network Connectivity Monitoring:** Distinguishes device connectivity (Wi-Fi/Cellular) from Supabase backend reachability with 700ms debouncing.
3. **Local SQLite Persistence:** Offline registrations cached locally in `waiting_queue.db`.
4. **Synchronization Engine (`SyncService`):** Automatic background queue synchronization upon network restoration with duplicate prevention.
5. **Advanced UI States:** Reactive queue states (`loading`, `empty`, `loaded`, `refreshing`, `loadingMore`, `error`).
6. **Pagination & Realtime Reconciliation:** Offset/limit page loading and de-duplicated Supabase Realtime channel event handling.
7. **TDD Methodology:** Red → Green → Refactor coverage across models, services, providers, and widgets.

---
*Created as part of DSI 31 Cross-Platform Mobile Development Curriculum.*
