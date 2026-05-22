class Flashcard {
  final int? id;
  final int noteId;
  final String question;
  final String answer;

  Flashcard({this.id, required this.noteId, required this.question, required this.answer});

  factory Flashcard.fromMap(Map<String, dynamic> map){
    return Flashcard(
        id: map["id"] as int? ,
        noteId: map["note_id"] as int ,
        question: map["question"] as String,
        answer: map["answer"] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id!=null) 'id': id,
      "note_id": noteId,
      "question": question,
      "answer": answer
    };
  }
}