import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/queue_state.dart';
import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';
import 'package:waiting_room_app/services/sync_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

class MockGeolocationService extends Mock implements GeolocationService {}

class MockLocalQueueStorage extends Mock implements LocalQueueStorage {}

class MockSyncService extends Mock implements SyncService {}

class FakeClient extends Fake implements Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeClient());
  });

  group('QueueProvider Tests', () {
    late MockQueueRepository mockRepository;
    late MockGeolocationService mockGeoService;
    late MockLocalQueueStorage mockStorage;
    late MockSyncService mockSyncService;
    late QueueProvider provider;

    setUp(() {
      mockRepository = MockQueueRepository();
      mockGeoService = MockGeolocationService();
      mockStorage = MockLocalQueueStorage();
      mockSyncService = MockSyncService();

      provider = QueueProvider(
        mockRepository,
        mockGeoService,
        mockStorage,
        mockSyncService,
      );
    });

    test('initial state is QueueState.initial', () {
      expect(provider.state, QueueState.initial);
      expect(provider.clients, isEmpty);
      expect(provider.hasMore, isTrue);
      expect(provider.isLoadingMore, isFalse);
    });

    test('fetchInitialQueue transitions to empty when 0 clients returned',
        () async {
      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => []);

      await provider.fetchInitialQueue();

      expect(provider.state, QueueState.empty);
      expect(provider.clients, isEmpty);
      expect(provider.hasMore, isFalse);
    });

    test('fetchInitialQueue loads clients and transitions to loaded', () async {
      final sampleClients = List.generate(
        5,
        (i) => Client(
          id: 'id-$i',
          name: 'Client $i',
          createdAt: DateTime.now(),
        ),
      );

      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => sampleClients);

      await provider.fetchInitialQueue();

      expect(provider.state, QueueState.loaded);
      expect(provider.clients.length, 5);
      expect(provider.hasMore, isFalse); // < 20 means no more pages
    });

    test('loadMore appends unique clients without duplicates', () async {
      // Create 20 initial clients so that _hasMore remains true
      final initialClients = List.generate(
        20,
        (i) => Client(id: 'client-$i', name: 'User $i', createdAt: DateTime.now()),
      );

      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => initialClients);

      await provider.fetchInitialQueue();
      expect(provider.hasMore, isTrue);

      final nextPageClients = [
        Client(id: 'client-19', name: 'Duplicate User', createdAt: DateTime.now()),
        Client(id: 'client-20', name: 'User 20', createdAt: DateTime.now()),
      ];

      when(() => mockRepository.fetchPage(offset: 20, limit: 20))
          .thenAnswer((_) async => nextPageClients);

      await provider.loadMore();

      expect(provider.clients.length, 21); // 20 + 1 unique new client
      expect(provider.clients.any((c) => c.id == 'client-20'), isTrue);
    });

    test('handleRealtimeInsert prepends client and prevents duplicates', () {
      final c1 = Client(id: '100', name: 'Realtime Client', createdAt: DateTime.now());

      provider.handleRealtimeInsert(c1);
      expect(provider.clients.length, 1);
      expect(provider.clients.first.id, '100');
      expect(provider.state, QueueState.loaded);

      // Inserting duplicate must not add again
      provider.handleRealtimeInsert(c1);
      expect(provider.clients.length, 1);
    });

    test('handleRealtimeDelete removes client and transitions to empty if last',
        () {
      final c1 = Client(id: '200', name: 'Client to delete', createdAt: DateTime.now());
      provider.handleRealtimeInsert(c1);
      expect(provider.clients.length, 1);

      provider.handleRealtimeDelete('200');
      expect(provider.clients, isEmpty);
      expect(provider.state, QueueState.empty);
    });
  });
}
