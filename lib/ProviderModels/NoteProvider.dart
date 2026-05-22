import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:smartstudy/Models/FlashCard.dart';
import 'package:smartstudy/Models/Note.dart';
import 'package:smartstudy/Models/NotePhoto.dart';
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
      logger.e("loadNotes hatası", error: e, stackTrace: stackTrace);
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

  Future<bool> saveNoteAndGenerateCards({
    required String title,
    required String originalText,
    required List<XFile> tempPhotos,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      String summary = await _aiService.generateSummary(originalText);


      Note note = Note(
          title: title,
          originalText: originalText,
          createdAt: DateTime.now(),
          summaryText: summary
      );

      int noteId = await _dbService.insertNote(note);

      if(tempPhotos.isNotEmpty) {
        List<Notephoto> photoModels = [];
        for (XFile tempFile in tempPhotos){
          String permanentPath = await FileService.saveImageToLocalStorage(tempFile);
          photoModels.add(Notephoto(noteId: noteId, imagePath: permanentPath));
        }
        await _dbService.insertNotePhoto(photoModels);
      }
      String aiResponse = await _aiService.generateFlashCards(originalText);
      if (aiResponse.isNotEmpty){
        String cleanJson = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        try {
          List<dynamic> jsonList = jsonDecode(cleanJson);
          for (var item in jsonList) {
            Flashcard flashcard = Flashcard(noteId: noteId, question: item["question"] ?? "Soru anlaşılamadı", answer: item["answer"] ?? "Cevap anlaşılamadı");
            await _dbService.insertFlashCard(flashcard);
          }
        } catch (jsonError) {
          logger.w("Yapay zeka JSON formatını bozdu $jsonError");
        }
      }
      await loadNotes();
      return true;
    } catch (e, stackTrace) {
      _setError("Not kaydedilirken beklenmedik bir hata oluştu.");
      logger.e("saveNoteAndGenerateCards hatası", error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Flashcard>> fetchFlashcardsForNote(int noteId) async {
    try {
      return await _dbService.getFlashCards(noteId);
    } catch (e) {
      logger.e("Flashcard çekme hatası", error: e);
      return [];
    }
  }

  Future<List<Notephoto>> fetchNotephotosForNote(int noteId) async {
    try {
      return await _dbService.getNotePhotos(noteId);
    } catch (e) {
      logger.e("Notephotos çekme hatası", error: e);
      return [];
    }
  }

  Future<void> editFlashcard(int cardId, String newQuestion, String newAnswer) async {
    try {
      await _dbService.updateFlashCard(cardId, newQuestion, newAnswer);
      notifyListeners();
    } catch (e) {
      logger.e("Flashcard güncellenemedi", error: e);
    }
  }

  Future<void> editNote(int noteId, String newTitle, String newOriginalText, String? newSummary) async {
    _setLoading(true);
    try {
      await _dbService.updateNote(noteId, newTitle, newSummary, newOriginalText);
      await loadNotes();
    } catch (e) {
      _setError("Not güncellenemedi");
      logger.e("Edit Note hatası", error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFlashcard(int cardId) async {
    try {
      await _dbService.deleteFlashCard(cardId);
      notifyListeners();
    } catch (e) {
      _setError("Flashcard silinemedi");
      logger.e("Flashcard silme hatası", error: e);
    }
  }

  Future<void> addManualFlashCard(int noteId, String question, String answer) async {
    try {
      Flashcard flashcard = Flashcard(noteId: noteId, question: question, answer: answer);
      await _dbService.insertFlashCard(flashcard);
      notifyListeners();
    } catch (e) {
      _setError("Manuel flashcard ekleme hatası");
      logger.e("Flashcard eklenirken hata meydana geldi", error: e);
    }
  }

  Future<void> deleteSpecificPhoto(int photoId) async {
    try {
      await _dbService.deleteNotePhoto(photoId);
      notifyListeners();
    } catch (e) {
      logger.e("Fotoğraf silinemedi", error: e);
    }
  }
}