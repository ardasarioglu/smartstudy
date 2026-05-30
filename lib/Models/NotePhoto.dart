class NotePhoto {
  final int? id;
  final int noteId;
  final String imagePath;

  NotePhoto({this.id, required this.noteId, required this.imagePath});

  factory NotePhoto.fromMap(Map<String, dynamic> map){
    return NotePhoto(
        id: map["id"] as int?,
        noteId: map["note_id"] as int,
        imagePath: map["image_path"] as String
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if(id!=null) "id" : id,
      "note_id": noteId,
      "image_path": imagePath
    };
  }
}