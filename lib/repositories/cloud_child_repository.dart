import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';

class CloudChildRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create child in Supabase
  /// Returns the created child cloudId
  Future<String> createChild(Child child) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('children')
        .insert({
          'user_id': user.id,
          'local_id': child.localId,
          'name': child.name,
          'birth_date': child.birthDate.toIso8601String(),
        })
        .select('id')
        .single();

    final cloudId = response['id'] as String;
    return cloudId;
  }

  /// Update child in Supabase
  Future<void> updateChild({
    required String cloudId,
    required Child child,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('children')
      ..update({
        'name': child.name,
        'birth_date': child.birthDate.toIso8601String(),
      })
      ..eq('id', cloudId)
      ..eq('user_id', user.id);
  }

  /// Delete child from Supabase
  Future<void> deleteChild(String cloudId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('children')
        .delete()
        .eq('id', cloudId)
        .eq('user_id', user.id);
  }
}
