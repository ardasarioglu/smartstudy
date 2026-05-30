import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstudy/Models/FlashCard.dart';
import 'package:smartstudy/ProviderModels/NoteProvider.dart';

class FlashcardsPage extends StatefulWidget {
  final int noteId;

  const FlashcardsPage({super.key, required this.noteId});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    // Provider üzerinden sadece bu nota ait kartları çekiyoruz
    final cards = await context.read<NoteProvider>().fetchFlashcardsForNote(widget.noteId);
    setState(() {
      _flashcards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Kartların öne çıkması için hafif gri arka plan
      appBar: AppBar(
        backgroundColor: Colors.grey,
        title: const Text("Çalışma Kartları"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
          ? const Center(
        child: Text("Bu not için henüz bir çalışma kartı oluşturulmamış.", textAlign: TextAlign.center),
      )
          : Column(
        children: [
          // --- ÜST BİLGİ ALANI (Kart 1 / 5) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Kart ${_currentIndex + 1} / ${_flashcards.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // --- KART KAYDIRMA ALANI ---
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _flashcards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final card = _flashcards[index];
                // Kendi yazdığımız 3D FlipCard Widget'ını çağırıyoruz
                return CustomFlipCard(
                  frontText: card.question,
                  backText: card.answer,
                );
              },
            ),
          ),

          // --- ALT İLERLEME ÇUBUĞU (Opsiyonel ama çok şık) ---
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _flashcards.length,
            backgroundColor: Colors.grey[300],
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}

// --- MÜHENDİSLİK SİHRİ: 3D DÖNEN KART WIDGET'I ---
class CustomFlipCard extends StatefulWidget {
  final String frontText;
  final String backText;

  const CustomFlipCard({super.key, required this.frontText, required this.backText});

  @override
  State<CustomFlipCard> createState() => _CustomFlipCardState();
}

class _CustomFlipCardState extends State<CustomFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    // Animasyonun hızını (300 milisaniye) belirliyoruz
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    // Animasyon değeri 0.5'i geçince arka yüzü göstereceğiz
    bool isUnderHalf = _animation.value < 0.5;

    return GestureDetector(
      onTap: _flipCard,
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          // 3D perspektif efekti için Matrix4 sihirli dokunuşu (0.001)
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_animation.value * pi),
          child: isUnderHalf
              ? _buildCardSide(widget.frontText, Colors.white, Colors.black, "Soru")
              : Transform(
            // Arka yüzün ters (ayna) görünmemesi için tekrar X ekseninde çeviriyoruz
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(pi),
            child: _buildCardSide(widget.backText, Colors.black87, Colors.white, "Cevap"),
          ),
        ),
      ),
    );
  }

  // Kartın ön ve arka yüzünün UI tasarımı
  Widget _buildCardSide(String text, Color bgColor, Color textColor, String label) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.5,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}