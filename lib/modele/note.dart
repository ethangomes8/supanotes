import 'dart:convert';


class Note {
  final int? id;
  String text;
  DateTime date;
  int? typeId;  // ← Ajouter ceci

  Note({
    this.id,
    required this.text,
    required this.date,
    this.typeId,
  });

  Note copyWith({
    int? id,
    String? text,
    DateTime? date,
    int? typeId,
  }) {
    return Note(
      id: id ?? this.id,
      text: text ?? this.text,
      date: date ?? this.date,
      typeId: typeId ?? this.typeId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'text': text,
      'date': date.toIso8601String(),
      if (typeId != null) 'type_id': typeId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final dateValue = map['date'];
    
    if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue).toLocal();
    } else if (dateValue is DateTime) {
      parsedDate = dateValue;
    } else {
      parsedDate = DateTime.now();
    }
    
    return Note(
      id: map['id'] as int?,
      text: map['text'] as String,
      date: parsedDate,
      typeId: map['type_id'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Note(id: $id, text: $text, date: $date)';

  @override
  bool operator ==(covariant Note other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.text == text &&
      other.date == date &&
      other.typeId == typeId;
  }

  @override
  int get hashCode => id.hashCode ^ text.hashCode ^ date.hashCode ^ typeId.hashCode;
}
