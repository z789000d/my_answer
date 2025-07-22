
class Note {
  final int? id;
  final String userId; 
  final String title;
  final String? content;
  final int isDeleted;
  final String createdAt;
  final String? updatedAt;

  Note({
    this.id,
    required this.userId,
    required this.title,
    this.content,
    this.isDeleted = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      content: map['content'],
      isDeleted: map['is_deleted'],
      createdAt: map['create_at'],
      updatedAt: map['update_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'is_deleted': isDeleted,
      'create_at': createdAt,
      'update_at': updatedAt,
    };
  }
}