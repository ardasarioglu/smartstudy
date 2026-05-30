import 'package:path/path.dart';
import 'package:smartstudy/Models/FlashCard.dart';
import 'package:smartstudy/Models/Note.dart';
import 'package:smartstudy/Models/NotePhoto.dart';
import 'package:smartstudy/Services/FileService.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if(_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    var databasePath = await getDatabasesPath();
    var path = join(databasePath, "database.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure
    );

  }
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        original_text TEXT NOT NULL,
        summary_text TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE Flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES Notes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE NotePhotos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        image_path TEXT NOT NULL, 
        FOREIGN KEY (note_id) REFERENCES Notes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
  }

  Future<int> deleteNote(int id) async {
    final db = await database;

    List<NotePhoto> photos = await getNotePhotos(id);

    for(var photo in photos){
      String path = photo.imagePath;
      await FileService.deleteImageFromLocalStorage(path);
    }

    return await db.delete("Notes", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteFlashCard(int id) async {
    final db = await database;
    return await db.delete("Flashcards", where: "id = ?", whereArgs: [id]);
  }

  Future<int> deleteNotePhoto(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query("NotePhotos", where: "id = ?", whereArgs: [id]);

    List<NotePhoto> photos = List.generate(result.length, (index) => NotePhoto.fromMap(result[index]),);

    for (var photo in photos){
      await FileService.deleteImageFromLocalStorage(photo.imagePath);
    }

    return await db.delete("NotePhotos", where: "id = ?", whereArgs: [id]);
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    int insertedNoteID = await db.insert("Notes", note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return insertedNoteID;
  }

  Future<int> insertFlashCard(Flashcard flashcard) async {
    final db = await database;
    int insertedFlashCardID = await db.insert("Flashcards", flashcard.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return insertedFlashCardID;
  }

  Future<void> insertNotePhoto(List<NotePhoto> notePhotos) async {
    final db = await database;
    Batch batch = db.batch();
    for(var notePhoto in notePhotos){
      batch.insert(
          "NotePhotos",
          notePhoto.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    var result = await db.query("Notes", orderBy: "id DESC");
    return List.generate(result.length, (index) => Note.fromMap(result[index]),);
  }

  Future<List<Note>> filterByTitle(String searchText) async {
    final db = await database;
    var result = await db.query("Notes", where: "title LIKE ?", whereArgs: ['%$searchText%'], orderBy: "id DESC");
    return List.generate(result.length, (index) => Note.fromMap(result[index]),);
  }

  Future<void> updateNote(int id, String newTitle, String? newSummaryText, String newOriginalText) async {
    final db = await database;
    await db.update("Notes", {"title": newTitle, "summary_text": newSummaryText, "original_text": newOriginalText}, where: "id = ?", whereArgs: [id]);
  }

  Future<List<NotePhoto>> getNotePhotos(int id) async {
    final db = await database;
    var result = await db.query("NotePhotos", where: "note_id = ?", whereArgs: [id]);
    return List.generate(result.length, (index) => NotePhoto.fromMap(result[index]),);
  }

  Future<List<Flashcard>> getFlashCards(int id) async {
    final db = await database;
    var result = await db.query("Flashcards", where: "note_id = ?", whereArgs: [id]);
    return List.generate(result.length, (index) => Flashcard.fromMap(result[index]),);

  }

  Future<Note?> getNoteById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query("Notes", where: "id = ?", whereArgs: [id]);
    if(result.isNotEmpty){
      return Note.fromMap(result.first);
    }
    return null;
  }

  Future<void> updateFlashCard(int id, String newQuestion, String newAnswer) async {
    final db = await database;
    await db.update("Flashcards", {"question": newQuestion, "answer": newAnswer}, where: "id = ?", whereArgs: [id]);
  }

}