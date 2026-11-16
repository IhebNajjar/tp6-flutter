# Compte Rendu - Assistance Intelligence Artificielle (IA)
## Atelier 6 : File d'Attente Résiliente avec Flutter & Supabase

* **Étudiant** : Iheb Najjar
* **Classe** : DSI 31
* **Matière** : Développement Cross-Platform (Flutter)
* **Outil d'IA utilisé** : Antigravity (Google DeepMind)

---

### Introduction
L'Atelier 6 vise à concevoir une application de file d'attente à salle unique résiliente, modulaire et hautement disponible. Le système intègre la capture contextuelle de géolocalisation, la surveillance fine de la connectivité réseau et applicative avec debouncing, le stockage persistant hors-ligne via SQLite, la synchronisation automatique en arrière-plan vers Supabase, ainsi que la pagination et la réconciliation d'événements Realtime. L'IA a été mobilisée comme architecte logiciel et partenaire de test pour concevoir une architecture en couches propre et conforme aux standards professionnels.

---

### Les 5 Prompts Soumis à l'IA

#### Prompt 1 : Découplage et architecture en couches
> *"Comment structurer proprement les couches UI, Provider, Services, Repository et Storage dans un projet Flutter complexe pour respecter les principes SOLID et faciliter l'injection de dépendances lors des tests ?"*
* **Apport de l'IA** : Définition claire des frontières de responsabilités : l'UI interagit uniquement avec les Providers (`QueueProvider`, `ConnectivityProvider`), les Providers orchestrent les Services techniques (`GeolocationService`, `ConnectivityService`, `SyncService`), tandis que l'accès aux données distantes et locales est centralisé dans le `QueueRepository` et le `LocalQueueStorage` (SQLite).

#### Prompt 2 : Surveillance de connectivité et filtrage des faux positifs (Debouncing)
> *"Les changements d'état réseau de `connectivity_plus` peuvent osciller rapidement lors des transitions Wi-Fi/4G. Comment implémenter un debouncing de 700ms et distinguer une simple connexion Wi-Fi de la réelle disponibilité du backend Supabase ?"*
* **Apport de l'IA** : Implémentation d'une machine à états (`checking`, `online`, `offline`, `backendUnavailable`) dans `ConnectivityProvider` avec un `Timer` de 700ms, complétée par un test de reachability direct (`isSupabaseAvailable()`) avec timeout de 5 secondes et protection anti-réentrance (`_checkingBackend`, `_checkAgain`, `_disposed`).

#### Prompt 3 : Moteur de synchronisation bidirectionnel et fonction RPC Postgres
> *"Comment concevoir un moteur de synchronisation (`SyncService`) capable de traiter les enregistrements en statut `pending` et `failed` sans risquer de créer des doublons d'ordre sur le serveur Supabase ?"*
* **Apport de l'IA** : Conception de l'algorithme de passage d'états (`pending`/`failed` → `syncing` → `synced`/`failed`) et écriture de la fonction PostgreSQL `register_queue_client` avec clause `ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name`, garantissant que Supabase reste l'unique source de vérité pour l'attribution des numéros d'ordre et des horodatages officiels.

#### Prompt 4 : Pagination infinie et réconciliation Supabase Realtime
> *"Lorsqu'on implémente une pagination par tranches de 20 clients et qu'un nouvel utilisateur s'inscrit en temps réel via Supabase Realtime, comment éviter les doublons dans la liste affichée tout en conservant le curseur de pagination cohérent ?"*
* **Apport de l'IA** : Intégration d'une vérification de présence par ID unique (`_clients.any((c) => c.id == client.id)`) avant insertion en tête de liste (`_clients.insert(0, client)`), et filtrage des nouveaux éléments paginés avec `existingIds` pour assurer l'idempotence des flux de données.

#### Prompt 5 : Stratégie TDD (Red-Green-Refactor) et simulation des dépendances
> *"Comment structurer les tests unitaires et widgets avec `mocktail` pour tester les états d'interface (`OfflineBanner`, `ClientCard`, `LoadingWidget`, `QueueEmptyWidget`) et le cycle de vie du provider sans dépendre d'un serveur Supabase physique ou d'un GPS matériel ?"*
* **Apport de l'IA** : Mise en place de mocks spécialisés (`MockQueueRepository`, `MockGeolocationService`, `MockLocalQueueStorage`, `MockConnectivityService`), tests d'états exhaustifs et vérification du comportement nominal et dégradé (26 tests exécutés avec succès et 0 warning d'analyse).

---

### Bilan Personnel
Cet atelier m'a permis de consolider les principes avancés du développement Flutter : la séparation stricte des responsabilités (Clean Architecture), la résilience face aux pannes réseau grâce à SQLite et au debouncing, l'exploitation des transactions PostgreSQL distantes, et la rigueur du Test-Driven Development (TDD). L'assistance de l'IA a accéléré l'identification des cas limites et la structuration industrielle du code.
