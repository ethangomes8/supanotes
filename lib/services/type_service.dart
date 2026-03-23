import 'package:supabase_flutter/supabase_flutter.dart';
import '../modele/type.dart';

class TypeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'types';

  Future<List<NoteType>> getAllTypes() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select();
      
      return (response as List)
          .map((type) => NoteType.fromMap(type as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur getAllTypes: $e');
      return [];
    }
  }
}
