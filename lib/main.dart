import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_connectivity.dart';
import 'providers/connectivity_provider.dart';
import 'providers/queue_provider.dart';
import 'repositories/queue_repository.dart';
import 'screens/queue_screen.dart';
import 'services/connectivity_service.dart';
import 'services/geolocation_service.dart';
import 'services/sync_service.dart';
import 'storage/local_queue_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  SupabaseClient? supabaseClient;
  if (supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id')) {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
    supabaseClient = Supabase.instance.client;

    // Optional anonymous sign-in
    try {
      await supabaseClient.auth.signInAnonymously();
    } catch (_) {}
  }

  // 2. Initialize Layered Architecture Services & Repositories
  final geolocationService = GeolocationService();
  final connectivityService = ConnectivityService(supabaseClient);
  final localStorage = LocalQueueStorage();
  final queueRepository = QueueRepository(supabase: supabaseClient);
  final syncService = SyncService(localStorage, queueRepository);

  // 3. Initialize Providers
  final connectivityProvider = ConnectivityProvider(connectivityService);
  await connectivityProvider.initialize();

  final queueProvider = QueueProvider(
    queueRepository,
    geolocationService,
    localStorage,
    syncService,
  );

  // 4. Set up automatic sync when connectivity returns online
  connectivityProvider.addListener(() {
    if (connectivityProvider.status == AppConnectivity.online) {
      debugPrint('[AutoSync] Online connection detected, triggering sync...');
      syncService.synchronize();
    }
  });

  // 5. Connect Realtime Stream
  queueRepository.subscribeToRealtime(
    onInsert: (client) => queueProvider.handleRealtimeInsert(client),
    onDelete: (id) => queueProvider.handleRealtimeDelete(id),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider.value(value: queueProvider),
      ],
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resilient Waiting Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const QueueScreen(),
    );
  }
}
