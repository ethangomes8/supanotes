import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'modele/note.dart';
import 'modele/type.dart';
import 'widgets/note_card.dart';
import 'services/note_service.dart';
import 'services/type_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Note> _notes = [];
  List<NoteType> _types = [];
  final NoteService _noteService = NoteService();
  final TypeService _typeService = TypeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTypes();
    loadNotes();
  }

  Future<void> loadTypes() async {
    _types = await _typeService.getAllTypes();
  }

  Future<void> loadNotes() async {
    setState(() => _isLoading = true);
    try {
      _notes = await _noteService.getAllNotes();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Erreur lors du chargement des notes');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> saveNote(String noteText, int typeId) async {
    final note = await _noteService.addNote(noteText, typeId);
    if (note != null) {
      await loadNotes();
    } else {
      if (!mounted) return;
      _showErrorSnackbar('Erreur lors de l\'enregistrement');
    }
  }

  Future<void> updateNote(int id, String newText, int typeId) async {
    final success = await _noteService.updateNote(id, newText, typeId);
    if (success) {
      await loadNotes();
    } else {
      if (!mounted) return;
      _showErrorSnackbar('Erreur lors de la modification');
    }
  }

  Future<void> deleteNote(int id) async {
    final success = await _noteService.deleteNote(id);
    if (success) {
      await loadNotes();
    } else {
      if (!mounted) return;
      _showErrorSnackbar('Erreur lors de la suppression');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> confirmDeleteNote(int noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: const Text('Supprimer cette note ??'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteNote(noteId);
      if (mounted) {
        _showSuccessSnackbar('Note supprimée');
      }
    }
  }

  Future<void> showNoteDialog({String initialText = '', int? editId, int? initialTypeId}) async {
    final controller = TextEditingController(text: initialText);
    int selectedTypeId = initialTypeId ?? (_types.isNotEmpty ? _types[0].id! : 1);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editId == null ? 'Ajouter une note' : 'Modifier la note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Écris ta note ici',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedTypeId,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id!,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedTypeId = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.pop(context);
                if (mounted) {
                  _showErrorSnackbar('La note ne peut pas être vide');
                }
                return;
              }
              Navigator.pop(context);
              
              if (editId == null) {
                await saveNote(text, selectedTypeId);
                if (mounted) {
                  _showSuccessSnackbar('Note enregistrée');
                }
              } else {
                await updateNote(editId, text, selectedTypeId);
                if (mounted) {
                  _showSuccessSnackbar('Note modifiée');
                }
              }
              
              controller.dispose();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'lib/assets/img/supanotes.png',
              height: 25,
              width: 25,
            ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'Ajouter une note',
            onPressed: () => showNoteDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('Aucune note enregistrée'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final noteType = _types.firstWhere(
                      (type) => type.id == note.typeId,
                      orElse: () => _types.isNotEmpty ? _types[0] : NoteType(id: 1, name: 'basic', color: '#FFFFFF'),
                    );
                    return NoteCard(
                      note: note,
                      type: noteType,
                      onEdit: () => showNoteDialog(
                        initialText: note.text,
                        editId: note.id,
                        initialTypeId: note.typeId,
                      ),
                      onDelete: () => confirmDeleteNote(note.id!),
                    );
                  },
                ),
    );
  }
}
