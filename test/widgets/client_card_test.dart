import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/widgets/client_card.dart';

void main() {
  group('ClientCard Widget Tests', () {
    testWidgets('renders client with location correctly', (tester) async {
      final client = Client(
        id: '1',
        name: 'Ali Ben Salah',
        lat: 36.8065,
        lng: 10.1815,
        locationAccuracy: 5.0,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientCard(client: client),
          ),
        ),
      );

      expect(find.text('Ali Ben Salah'), findsOneWidget);
      expect(
        find.text('Location available (36.8065, 10.1815)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('renders client without location correctly', (tester) async {
      final client = Client(
        id: '2',
        name: 'Youssef Trabelsi',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientCard(client: client),
          ),
        ),
      );

      expect(find.text('Youssef Trabelsi'), findsOneWidget);
      expect(find.text('Location not captured'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });
  });
}
