class Note{
  final int? id;
  final String title;
  final String originalText;
  final String? summaryText;
  final DateTime createdAt;

  Note({this.id, required this.title, required this.originalText, this.summaryText, required this.createdAt});
  factory Note.fromMap(Map<String, dynamic> map){
    return Note(
      id: map["id"] as int?,
      title: map["title"] as String,
      originalText: map["original_text"] as String,
      summaryText: map["summary_text"] as String?,
      createdAt: DateTime.parse(map["created_at"]),
    );
  }

  Map<String, dynamic> toMap() {
    return{
      if(id != null) "id": id,
      "title": title,
      "original_text": originalText,
      "summary_text": summaryText,
      "created_at": createdAt.toIso8601String()
    };
  }

}