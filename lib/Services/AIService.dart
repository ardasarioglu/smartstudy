import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class AIService {

  var logger = Logger();
  final model = FirebaseAI.googleAI().generativeModel(
    model: "gemini-3.1-flash-lite",
    generationConfig: GenerationConfig(responseModalities: [ResponseModalities.text, ResponseModalities.image]),
  );


  Future<String> sendText(String message) async {
    if (message.isEmpty) {
      print("Boş metin gönderilemez.");
      return "";
    }
    try {
      final response = await model.generateContent([Content.text(message)]);
      return response.text ?? "Modelden boş yanıt döndü.";
    } catch (e, stackTrace) {
      logger.e("AIService sendText", error: e, stackTrace: stackTrace);
      return "";
    }
  }

  Future<String> sendMassageAndPhotos(String message, List<XFile> photos) async {
    if (message.trim().isEmpty && photos.isEmpty){
      print("Boş metin veya fotoğraf gönderilemez");
      return "";
    }

    try {
      List<Part> parts = [];
      if(message.trim().isNotEmpty){
        parts.add(TextPart(message));
      }
      for(var photo in photos){
        final bytes = await photo.readAsBytes();
        final mimeType = photo.mimeType ?? "image/jpeg";
        parts.add(InlineDataPart(mimeType, bytes));
      }
      final content = Content.multi(parts);
      final response = await model.generateContent([content]) ;
      return response.text ?? "";
    } catch (e, stackTrace) {
      logger.e("AIService sendMessageAndPhotos", error: e, stackTrace: stackTrace);
      return "";
    }
  }

  Future<String> ocrWithAI(List<XFile> photos) async {
    return await sendMassageAndPhotos("Bu fotoğraflardaki tüm metinleri tam olarak görüldüğü gibi, harfi harfine çıkar. Hiçbir ek açıklama, yorum, bağlam, özet, giriş veya çıkış cümlesi ekleme. Fotoğraftaki yazım veya noktalama hatalarını düzeltme. Sadece ve sadece fotoğrafta okuduğun metni çıktı olarak ver.", photos);
  }

  Future<String> generateFlashCards(String text) async {
    String prompt = """
      Aşağıdaki metni analiz et ve en önemli bilgilerden çalışma kartları (flashcards) oluştur.
      Çıktıyı KESİNLİKLE sadece aşağıdaki JSON formatında ver, başka hiçbir açıklama yazma:
      [
        {"question": "Soru 1", "answer": "Cevap 1"},
        {"question": "Soru 2", "answer": "Cevap 2"}
      ]
      Metin: $text
    """;
    return await sendText(prompt);
  }

  Future<String> generateSummary(String text) async {
    String prompt = """
      Aşağıdaki metni analiz et ve en önemli noktaları vurgulayan, kısa ve anlaşılır bir özet çıkar.
      Sadece özeti yaz, başka hiçbir açıklama veya giriş cümlesi ekleme.
      Metin: $text
    """;
    return await sendText(prompt);
  }

}