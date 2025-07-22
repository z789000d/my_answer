class NoteTag {
  final int noteId; // 關聯的筆記 ID
  final int tagId; // 關聯的標籤 ID

  NoteTag({
    required this.noteId,
    required this.tagId,
  });

  // 從資料庫的 Map 轉換為 NoteTag 物件
  factory NoteTag.fromMap(Map<String, dynamic> map) {
    return NoteTag(
      noteId: map['note_id'],
      tagId: map['tag_id'],
    );
  }

  // 將 NoteTag 物件轉換為 Map，以便存入資料庫
  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'tag_id': tagId,
    };
  }

  @override
  String toString() {
    return 'NoteTag{noteId: $noteId, tagId: $tagId}';
  }
}