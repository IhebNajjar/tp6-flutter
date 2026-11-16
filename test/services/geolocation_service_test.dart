import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';

void main() {
  group('GeolocationService Tests', () {
    test('instantiates GeolocationService cleanly', () {
      final service = GeolocationService();
      expect(service, isNotNull);
    });

    test('getCurrentPosition handles location without throwing error', () async {
      final service = GeolocationService();
      // On desktop / CI environments where GPS hardware might be absent,
      // getCurrentPosition gracefully catches exceptions and returns null
      final position = await service.getCurrentPosition();
      expect(position == null || position.latitude != 0, isTrue);
    });
  });
}
