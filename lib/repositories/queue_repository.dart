import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client.dart';

class QueueRepository {
  final SupabaseClient? _supabase;
  RealtimeChannel? _channel;

  QueueRepository({SupabaseClient? supabase})
      : _supabase = supabase ??
            (Supabase.instance.client);

  /// Registers a client on Supabase using RPC or upsert
  Future<Client> registerOnServer(Client client) async {
    if (_supabase == null) {
      throw Exception('Supabase client not initialized');
    }

    try {
      // Attempt to invoke the authoritative RPC function
      final response = await _supabase!.rpc(
        'register_queue_client',
        params: {
          'p_id': client.id,
          'p_name': client.name,
          'p_lat': client.lat,
          'p_lng': client.lng,
          'p_accuracy': client.locationAccuracy,
          'p_created_at': client.createdAt.toIso8601String(),
        },
      );

      if (response is List && response.isNotEmpty) {
        return Client.fromSupabaseMap(Map<String, dynamic>.from(response.first));
      } else if (response is Map) {
        return Client.fromSupabaseMap(Map<String, dynamic>.from(response));
      }
      return client;
    } catch (e) {
      debugPrint('RPC register_queue_client failed, falling back to direct upsert: $e');
      final data = await _supabase!
          .from('clients')
          .upsert(client.toSupabaseMap())
          .select()
          .single();
      return Client.fromSupabaseMap(Map<String, dynamic>.from(data));
    }
  }

  /// Fetches a paginated slice of the waiting queue
  Future<List<Client>> fetchPage({
    required int offset,
    required int limit,
  }) async {
    if (_supabase == null) return [];

    final fromIndex = offset;
    final toIndex = offset + limit - 1;

    final response = await _supabase!
        .from('clients')
        .select()
        .order('created_at', ascending: true)
        .range(fromIndex, toIndex);

    final List<dynamic> list = response as List<dynamic>;
    return list
        .map((item) => Client.fromSupabaseMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Deletes a client from the waiting queue
  Future<void> deleteClient(String id) async {
    if (_supabase == null) return;
    await _supabase!.from('clients').delete().eq('id', id);
  }

  /// Subscribes to Supabase Realtime changes on 'clients' table
  void subscribeToRealtime({
    required void Function(Client) onInsert,
    required void Function(String) onDelete,
  }) {
    if (_supabase == null) return;

    _channel = _supabase!
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final client = Client.fromSupabaseMap(
                Map<String, dynamic>.from(newRecord),
              );
              onInsert(client);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final oldRecord = payload.oldRecord;
            final id = oldRecord['id']?.toString();
            if (id != null) {
              onDelete(id);
            }
          },
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    if (_channel != null && _supabase != null) {
      _supabase!.removeChannel(_channel!);
      _channel = null;
    }
  }
}
