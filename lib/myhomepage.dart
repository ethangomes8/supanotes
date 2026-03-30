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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _types = await _typeService.getAllTypes();
      _notes = await _noteService.getAllNotes();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur de connexion. Impossible de charger les données.';
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    int selectedTypeId = initialTypeId ?? (_types.isNotEmpty ? _types.first.id ?? 1 : 1);

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
                value: selectedTypeId,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.where((type) => type.id != null).map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id!,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedTypeId = value;
                  }
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
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Réessayer'),
            )
          ],
        ),
      );
    } else if (_notes.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cliquez sur le bouton + pour en créer une.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(8.0),
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
            onDelete: () {
              if (note.id != null) {
                confirmDeleteNote(note.id!);
              }
            },
          );
        },
      );
    }

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
            icon: const Icon(Icons.note_add_outlined),
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
      body: body,
    );
  }
}
