import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/queue_state.dart';
import '../models/sync_status.dart';
import '../repositories/queue_repository.dart';
import '../services/geolocation_service.dart';
import '../services/sync_service.dart';
import '../storage/local_queue_storage.dart';

class QueueProvider extends ChangeNotifier {
  final QueueRepository _repository;
  final GeolocationService _geolocationService;
  final LocalQueueStorage _storage;
  final SyncService _syncService;

  final List<Client> _clients = [];
  QueueState _state = QueueState.initial;
  String? _errorMessage;

  int _page = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  QueueProvider(
    this._repository,
    this._geolocationService,
    this._storage,
    this._syncService,
  );

  List<Client> get clients => List.unmodifiable(_clients);
  QueueState get state => _state;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInitialQueue() async {
    _state = QueueState.loading;
    _page = 0;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.fetchPage(
        offset: 0,
        limit: _pageSize,
      );
      _clients.clear();
      _clients.addAll(data);
      _state = _clients.isEmpty ? QueueState.empty : QueueState.loaded;
      if (data.length < _pageSize) _hasMore = false;
    } catch (e) {
      // If remote fails, fallback to cached SQLite clients
      try {
        final localData = await _storage.getClients();
        if (localData.isNotEmpty) {
          _clients.clear();
          _clients.addAll(localData.map((m) => Client.fromLocalMap(m)));
          _state = QueueState.loaded;
          _hasMore = false;
        } else {
          _errorMessage = 'Failed to load queue';
          _state = QueueState.error;
        }
      } catch (_) {
        _errorMessage = 'Failed to load queue';
        _state = QueueState.error;
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final newClients = await _repository.fetchPage(
        offset: _page * _pageSize,
        limit: _pageSize,
      );

      final existingIds = _clients.map((c) => c.id).toSet();
      final uniqueNewClients =
          newClients.where((c) => !existingIds.contains(c.id));
      _clients.addAll(uniqueNewClients);

      if (newClients.length < _pageSize) _hasMore = false;
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void handleRealtimeInsert(Client client) {
    final exists = _clients.any((c) => c.id == client.id);
    if (!exists) {
      _clients.insert(0, client);
      if (_state == QueueState.empty || _state == QueueState.initial) {
        _state = QueueState.loaded;
      }
      notifyListeners();
    }
  }

  void handleRealtimeDelete(String id) {
    final index = _clients.indexWhere((c) => c.id == id);
    if (index != -1) {
      _clients.removeAt(index);
      if (_clients.isEmpty) _state = QueueState.empty;
      notifyListeners();
    }
  }

  Future<void> addClient(String name, {bool isOnline = true}) async {
    if (name.trim().isEmpty) return;

    final position = await _geolocationService.getCurrentPosition();

    final client = Client(
      id: const Uuid().v4(),
      name: name.trim(),
      lat: position?.latitude,
      lng: position?.longitude,
      locationAccuracy: position?.accuracy,
      createdAt: DateTime.now(),
      syncStatus: isOnline ? SyncStatus.synced : SyncStatus.pending,
    );

    if (isOnline) {
      try {
        await _repository.registerOnServer(client);
        await _storage.saveClient(client.toLocalMap());
        handleRealtimeInsert(client);
      } catch (_) {
        final pendingClient = Client(
          id: client.id,
          name: client.name,
          lat: client.lat,
          lng: client.lng,
          locationAccuracy: client.locationAccuracy,
          createdAt: client.createdAt,
          syncStatus: SyncStatus.pending,
        );
        await _storage.saveClient(pendingClient.toLocalMap());
        handleRealtimeInsert(pendingClient);
      }
    } else {
      await _storage.saveClient(client.toLocalMap());
      handleRealtimeInsert(client);
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final next = _clients.first;
    try {
      await _repository.deleteClient(next.id);
      await _storage.deleteClient(next.id);
      _clients.removeAt(0);
      if (_clients.isEmpty) _state = QueueState.empty;
      notifyListeners();
    } catch (_) {
      await _storage.deleteClient(next.id);
      _clients.removeAt(0);
      if (_clients.isEmpty) _state = QueueState.empty;
      notifyListeners();
    }
  }

  Future<void> syncPending() async {
    await _syncService.synchronize();
  }
}
