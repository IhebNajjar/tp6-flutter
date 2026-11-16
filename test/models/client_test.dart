import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/sync_status.dart';

void main() {
  group('Client Model Tests', () {
    test('client without location reports hasLocation as false', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        createdAt: DateTime.now(),
      );

      expect(client.hasLocation, isFalse);
      expect(client.locationText, equals('Location not captured'));
    });

    test('toLocalMap preserves accuracy and syncStatus', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        lat: 36.8065,
        lng: 10.1815,
        locationAccuracy: 5.5,
        createdAt: DateTime(2026, 1, 1),
        syncStatus: SyncStatus.pending,
      );

      final map = client.toLocalMap();
      expect(map['location_accuracy_m'], equals(5.5));
      expect(map['sync_status'], equals('pending'));
    });

    test('toSupabaseMap excludes local sync_status', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      final map = client.toSupabaseMap();
      expect(map.containsKey('sync_status'), isFalse);
    });

    test('fromSupabaseMap deserializes correctly', () {
      final map = {
        'id': 'abc-123',
        'name': 'Sarah Connor',
        'lat': 36.8065,
        'lng': 10.1815,
        'location_accuracy_m': 4.2,
        'created_at': '2026-01-01T12:00:00.000Z',
      };

      final client = Client.fromSupabaseMap(map);
      expect(client.id, 'abc-123');
      expect(client.name, 'Sarah Connor');
      expect(client.lat, 36.8065);
      expect(client.lng, 10.1815);
      expect(client.locationAccuracy, 4.2);
      expect(client.syncStatus, SyncStatus.synced);
      expect(client.hasLocation, isTrue);
      expect(client.locationText, '36.8065, 10.1815');
    });

    test('fromLocalMap deserializes correctly with custom sync status', () {
      final map = {
        'id': 'local-999',
        'name': 'John Doe',
        'lat': null,
        'lng': null,
        'location_accuracy_m': null,
        'created_at': '2026-01-01T12:00:00.000Z',
        'sync_status': 'failed',
      };

      final client = Client.fromLocalMap(map);
      expect(client.id, 'local-999');
      expect(client.name, 'John Doe');
      expect(client.syncStatus, SyncStatus.failed);
      expect(client.hasLocation, isFalse);
    });
  });
}
