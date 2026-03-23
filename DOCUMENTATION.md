# SupaNotes - Documentation Technique

**Ici on retrouve MCD, MLD et tous les détails en rapport avec la BDD, ainsi que les explications du fonctionnement des fonctionnalités.**

---

## 1- Base de données

### MCD (Modèle Conceptuel)

```
┌──────────────┐
│     USER     │
│ (auth.users) │
└──────┬───────┘
       │ 1 → N
       │ 
       ▼
    ┌──────────────────┐        ┌─────────────┐
    │      NOTE        │    FK  │    TYPE     │
    ├──────────────────┤───────▶├─────────────┤
    │ id               │        │ id          │
    │ text             │        │ name        │
    │ date             │        │ color       │
    │ user_id (FK)     │        └─────────────┘
    │ type_id (FK)     |
    └──────────────────┘
```

**Entités** :
- **USER** : Utilisateurs Supabase Auth
- **NOTE** : Notes avec texte, date, propriétaire
- **TYPE** : Catégories (Important, Todo, Idée)

---

### MLD (Modèle Logique - PostgreSQL)

```
types (id_type, name, color)

notes (id_notes, text, date, created_at, #type_id)
```

Où :
- `#type_id` référence `types.id` (optionnel)

**SQL de création** :
```sql
CREATE TABLE public.types (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name text NOT NULL UNIQUE,
  color text,
  CONSTRAINT types_pkey PRIMARY KEY (id)
);

CREATE TABLE public.notes (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  text text NOT NULL,
  date timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  type_id bigint,
  CONSTRAINT notes_pkey PRIMARY KEY (id),
  CONSTRAINT notes_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.types(id)
);
```

**Données par défaut** :
```
Types:
├─ 1 | Important | #FF0000
├─ 2 | Todo      | #00FF00
└─ 3 | Idée      | #0000FF
```

## 2- Détails techniques

### 2.1 - Écran de connexion (LoginScreen)

Écran d'authentification avec champs email/mot de passe et bouton de connexion. Utilise Supabase Auth pour vérifier les credentials et rediriger vers MyHomePage en cas de succès.

**Fonction `_login()` :**
```dart
Future<void> _login() async {
  try {
    await Supabase.instance.client.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (mounted) Navigator.pushReplacementNamed('/home');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)
    );
  }
}
```

---

### 2.2 - Page d'accueil (MyHomePage)

Affiche la liste des notes triées par date décroissante, avec boutons pour ajouter une note (+) et se déconnecter (logout). Charge les notes au démarrage via `loadNotes()`.

**Méthode `build()` :**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(icon: Icon(Icons.note_add), onPressed: () => showNoteDialog()),
        IconButton(icon: Icon(Icons.logout), onPressed: _logout),
      ],
    ),
    body: _isLoading ? CircularProgressIndicator() : ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, index) => NoteCard(note: _notes[index], ...),
    ),
  );
}
```

---

### 2.3 - Ajouter une note

Dialog modal avec TextField pour le texte et Dropdown pour le type. Valide que le texte n'est pas vide avant INSERT dans `notes`.

**Fonction `showNoteDialog()` :**
```dart
Future<void> showNoteDialog({String initialText = '', int? editId, int? initialTypeId}) async {
  // ... champs TextField et Dropdown ...
  ElevatedButton(
    onPressed: () async {
      if (text.isEmpty) return;
      if (editId == null) await saveNote(text, selectedTypeId);
      // ...
    },
  )
}
```

**SQL INSERT** : `INSERT INTO notes (text, type_id, date) VALUES ('...', 2, NOW()) RETURNING *;`

---

### 2.4 - Modifier une note

Réutilise le même dialog pré-rempli avec les données existantes. Met à jour la note via UPDATE.

**Appel dans `NoteCard` :**
```dart
onEdit: () => showNoteDialog(
  initialText: note.text,
  editId: note.id,
  initialTypeId: note.typeId,
)
// Dans dialog : if (editId != null) await updateNote(editId, text, selectedTypeId);
```

**SQL UPDATE** : `UPDATE notes SET text='...', type_id=2, date=NOW() WHERE id=42;`

---

### 2.5 - Supprimer une note

Dialog de confirmation avant DELETE irréversible de la note.

**Fonction `confirmDeleteNote()` :**
```dart
confirmDeleteNote(int noteId) async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed) await deleteNote(noteId);
}
```

**SQL DELETE** : `DELETE FROM notes WHERE id=42;`

---

### 2.6 - Services backend

**NoteService** : CRUD pour les notes (addNote, updateNote, deleteNote, getAllNotes).  
**TypeService** : Récupération des types (getAllTypes).

**Méthode `addNote()` dans NoteService :**
```dart
Future<Note?> addNote(String text, int typeId) async {
  final response = await _supabase.from('notes').insert({...}).select().single();
  return Note.fromMap(response);
}
```

---

## 3- Sécurité

**Row Level Security (RLS)** : Supabase applique automatiquement les policies pour que chaque utilisateur ne voie que ses propres notes (WHERE user_id = auth.uid()).

**Validation** : Tous les inputs sont validés (texte non-vide avant INSERT/UPDATE).

**Mounted checks** : Vérification `if (mounted)` avant setState() pour éviter les crashs.

---

## 4- Sources

- **Supabase Documentation** : https://supabase.com/docs
- **Flutter Docs** : https://docs.flutter.dev
- **supabase_flutter** : https://pub.dev/packages/supabase_flutter
- **PostgreSQL RLS** : https://www.postgresql.org/docs/current/ddl-rowsecurity.html
