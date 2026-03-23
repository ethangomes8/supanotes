import 'package:supabase_flutter/supabase_flutter.dart';
import '../modele/note.dart';

class NoteService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'notes';

  Future<List<Note>> getAllNotes() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('date', ascending: false);
      
      if (response.isEmpty) {
        return [];
      }
      
      return (response as List)
          .map((note) {
            try {
              return Note.fromMap(note as Map<String, dynamic>);
            } catch (e) {
              print('Erreur parsing: $e');
              return null;
            }
          })
          .whereType<Note>()
          .toList();
    } catch (e) {
      print('Erreur getAllNotes: $e');
      return [];
    }
  }

  Future<Note?> addNote(String text, int typeId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert({
            'text': text,
            'type_id': typeId,
            'date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return Note.fromMap(response);
    } catch (e) {
      print('Erreur addNote: $e');
      return null;
    }
  }

  Future<bool> updateNote(int id, String text, int typeId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'text': text,
            'type_id': typeId,
            'date': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Erreur updateNote: $e');
      return false;
    }
  }

  Future<bool> deleteNote(int id) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      print('Erreur deleteNote: $e');
      return false;
    }
  }
}
