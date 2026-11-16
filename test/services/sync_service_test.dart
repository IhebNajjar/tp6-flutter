import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/sync_status.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/sync_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

class MockLocalQueueStorage extends Mock implements LocalQueueStorage {}

class MockQueueRepository extends Mock implements QueueRepository {}

class FakeClient extends Fake implements Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeClient());
    registerFallbackValue(SyncStatus.pending);
  });

  group('SyncService Tests', () {
    late MockLocalQueueStorage mockStorage;
    late MockQueueRepository mockRepository;
    late SyncService syncService;

    setUp(() {
      mockStorage = MockLocalQueueStorage();
      mockRepository = MockQueueRepository();
      syncService = SyncService(mockStorage, mockRepository);
    });

    test('synchronizes pending records successfully to synced status',
        () async {
      final sampleRecord = {
        'id': 'uuid-1',
        'name': 'Sarah Connor',
        'lat': 36.8065,
        'lng': 10.1815,
        'location_accuracy_m': 4.5,
        'created_at': '2026-01-01T10:00:00.000Z',
        'sync_status': 'pending',
      };

      when(() => mockStorage.getPendingClients())
          .thenAnswer((_) async => [sampleRecord]);
      when(() => mockStorage.updateSyncStatus(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.registerOnServer(any()))
          .thenAnswer((invocation) async => invocation.positionalArguments.first as Client);

      await syncService.synchronize();

      verify(() => mockStorage.updateSyncStatus('uuid-1', SyncStatus.syncing))
          .called(1);
      verify(() => mockRepository.registerOnServer(any())).called(1);
      verify(() => mockStorage.updateSyncStatus('uuid-1', SyncStatus.synced))
          .called(1);
    });

    test('marks record as failed when server registration throws exception',
        () async {
      final sampleRecord = {
        'id': 'uuid-2',
        'name': 'Failing Client',
        'lat': null,
        'lng': null,
        'location_accuracy_m': null,
        'created_at': '2026-01-01T10:00:00.000Z',
        'sync_status': 'pending',
      };

      when(() => mockStorage.getPendingClients())
          .thenAnswer((_) async => [sampleRecord]);
      when(() => mockStorage.updateSyncStatus(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.registerOnServer(any()))
          .thenThrow(Exception('Network error'));

      await syncService.synchronize();

      verify(() => mockStorage.updateSyncStatus('uuid-2', SyncStatus.syncing))
          .called(1);
      verify(() => mockStorage.updateSyncStatus('uuid-2', SyncStatus.failed))
          .called(1);
    });

    test('does not execute twice when already syncing', () async {
      when(() => mockStorage.getPendingClients()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return [];
      });

      final future1 = syncService.synchronize();
      final future2 = syncService.synchronize();

      await Future.wait([future1, future2]);

      verify(() => mockStorage.getPendingClients()).called(1);
    });
  });
}
