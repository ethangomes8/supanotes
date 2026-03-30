import 'package:flutter/material.dart';
import '../modele/note.dart';
import '../modele/type.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final NoteType type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Helper to parse color from hex string
    Color _colorFromHex(String hexColor) {
      final hexCode = hexColor.replaceAll('#', '');
      try {
        return Color(int.parse('FF$hexCode', radix: 16));
      } catch (e) {
        return Colors.grey; // Fallback color
      }
    }

    final typeColor = _colorFromHex(type.color);
    final formattedDate = '${note.date.day}/${note.date.month}/${note.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note text
            Text(
              note.text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 12),
            // Bottom row with subtitle and buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subtitle: Chip and Date
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(type.name),
                      backgroundColor: typeColor.withOpacity(0.2),
                      side: BorderSide(color: typeColor, width: 0.5),
                      labelStyle: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Actions: Edit and Delete Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
