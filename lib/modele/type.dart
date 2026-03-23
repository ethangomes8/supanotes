class NoteType {
  final int? id;
  final String name;
  final String color;

  NoteType({
    this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'color': color,
    };
  }

  factory NoteType.fromMap(Map<String, dynamic> map) {
    return NoteType(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String,
    );
  }

  @override
  String toString() => 'NoteType(id: $id, name: $name, color: $color)';
}



