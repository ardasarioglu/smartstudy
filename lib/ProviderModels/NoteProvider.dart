import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:smartstudy/Models/Note.dart';
import 'package:smartstudy/Services/AIService.dart';
import 'package:smartstudy/Services/DatabaseService.dart';
import 'package:smartstudy/Services/FileService.dart';

class NoteProvider extends ChangeNotifier {
  Logger logger = Logger();
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NoteProvider(){
    Future.microtask(() => loadNotes(),);
  }

  void _setLoading(bool value){
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value){
    _errorMessage = value;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    _setError(null);
    _setLoading(true);

    try {
      _notes = await _dbService.getAllNotes();
      notifyListeners();
    } catch (e, stackTrace) {
      _setError("Notlar yüklenirken bir hata oluştu");
      logger.e("leadNotes hatası", error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchNotes(String query) async {
    if (query.isEmpty){
      await loadNotes();
      return;
    }
    _setLoading(true);
    try {
      _notes = await _dbService.filterByTitle(query);
      notifyListeners();
    } catch (e, stackTrace) {
      _setError("Arama sırasında bir hata oluştu");
      logger.e("searchNotes NoteProvider hatası", error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNote(int noteId) async {
    _setLoading(true);
    try{
      await _dbService.deleteNote(noteId);
      await loadNotes();
    } catch (e, stackTrace) {
      logger.e("NoteProvider deleteNote hatası", error: e, stackTrace: stackTrace);
      _setError("Silme sırasında bir hata oluştu");
    } finally {
      _setLoading(false);
    }
  }



}