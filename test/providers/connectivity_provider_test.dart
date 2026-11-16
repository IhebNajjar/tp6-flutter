import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waiting_room_app/models/app_connectivity.dart';
import 'package:waiting_room_app/providers/connectivity_provider.dart';
import 'package:waiting_room_app/services/connectivity_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('ConnectivityProvider Tests', () {
    late MockConnectivityService mockService;
    late StreamController<bool> networkStreamController;

    setUp(() {
      mockService = MockConnectivityService();
      networkStreamController = StreamController<bool>.broadcast();

      when(() => mockService.networkChanges)
          .thenAnswer((_) => networkStreamController.stream);
    });

    tearDown(() {
      networkStreamController.close();
    });

    test('initial status is checking', () {
      final provider = ConnectivityProvider(mockService);
      expect(provider.status, AppConnectivity.checking);
      expect(provider.isOnline, isFalse);
    });

    test('handles offline state when network is disconnected', () async {
      when(() => mockService.hasNetwork()).thenAnswer((_) async => false);

      final provider = ConnectivityProvider(mockService);
      await provider.initialize();

      expect(provider.status, AppConnectivity.offline);
      expect(provider.isOnline, isFalse);
    });

    test('transitions to online when backend is available', () async {
      when(() => mockService.hasNetwork()).thenAnswer((_) async => true);
      when(() => mockService.isSupabaseAvailable())
          .thenAnswer((_) async => true);

      final provider = ConnectivityProvider(mockService);
      await provider.initialize();

      // Allow debounce timer (700ms) to fire
      await Future.delayed(const Duration(milliseconds: 750));

      expect(provider.status, AppConnectivity.online);
      expect(provider.isOnline, isTrue);
    });

    test('transitions to backendUnavailable when network is up but backend fails',
        () async {
      when(() => mockService.hasNetwork()).thenAnswer((_) async => true);
      when(() => mockService.isSupabaseAvailable())
          .thenAnswer((_) async => false);

      final provider = ConnectivityProvider(mockService);
      await provider.initialize();

      await Future.delayed(const Duration(milliseconds: 750));

      expect(provider.status, AppConnectivity.backendUnavailable);
      expect(provider.isOnline, isFalse);
    });
  });
}
