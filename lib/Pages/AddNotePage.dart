import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smartstudy/ProviderModels/NoteProvider.dart';
import 'package:smartstudy/Services/AIService.dart';
import 'package:smartstudy/Services/PickerService.dart';

class Addnotepage extends StatefulWidget {
  const Addnotepage({super.key});

  @override
  State<Addnotepage> createState() => _AddnotepageState();
}

class _AddnotepageState extends State<Addnotepage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  final PickerService _pickerService = PickerService();
  final AIService _aiService = AIService();

  final List<XFile> _selectedPhotos = [];
  bool _isOcrRunning = false;
  bool _isAIRunning = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    List<XFile> photos = await _pickerService.pickMultiImageFromGallery();
    if (photos.isNotEmpty){
      setState(() {
        _selectedPhotos.addAll(photos);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    XFile? photo = await _pickerService.pickImageFromCamera();
    if(photo != null){
      setState(() {
        _selectedPhotos.add(photo);
      });
    }
  }

  Future<void> _runOcr() async {
    if(_selectedPhotos.isEmpty) return;
    setState(() => _isOcrRunning = true);

    String extractedText = await _aiService.ocrWithAI(_selectedPhotos);

    setState(() {
      _textController.text += "\n$extractedText";
      _isOcrRunning = false;
    });
  }

  Future<void> _runAI() async {
    setState(() {
      _isAIRunning = true;
    });
    String summary = await _aiService.generateSummary(_textController.text);
    setState(() {
      _summaryController.text = summary;
      _isAIRunning = false;
    });
  }

  Future<void> _saveNote() async {
    if(_titleController.text.trim().isEmpty || _textController.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen başlık ve içerik giriniz"))
      );
      return;
    }

    bool success = await context.read<NoteProvider>().saveNoteAndGenerateCards(
        title: _titleController.text.trim(),
        originalText: _textController.text.trim(),
        tempPhotos: _selectedPhotos,
        summaryText: _summaryController.text.isNotEmpty ? _summaryController.text : null
    );
    if(success && mounted){
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isSaving = context.watch<NoteProvider>().isLoading;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45),
        child: AppBar(
          backgroundColor: Colors.grey,
          actions: [
            isSaving
            ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,)
              ),
            )
            : IconButton(
              onPressed: () {
                _saveNote();
              },
              icon: Icon(Icons.check))
          ],
        )
      ),
      body: AbsorbPointer(
        absorbing: isSaving || _isOcrRunning || _isAIRunning,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 8),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(fontWeight: .bold, fontSize: 24),
                  textAlign: .center,
                  decoration: InputDecoration(
                      hintText: "Not Başlığı",
                      border: InputBorder.none
                  ),
                ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: .spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => _pickPhotos(),
                    icon: Icon(Icons.photo_library),
                    tooltip: "Galeri",
                  ),
                  IconButton(
                    onPressed: () => _pickFromCamera(),
                    icon: Icon(Icons.camera_alt),
                    tooltip: "Kamera",
                  ),
                  if (_selectedPhotos.isNotEmpty)...[
                    SizedBox(width: 10,),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white
                      ),
                      icon: _isOcrRunning ? SizedBox(width: 12, height: 12,child: CircularProgressIndicator(strokeWidth: 2,)) : Icon(Icons.document_scanner),
                      label: Text("Yazıya çevir"),
                      onPressed: _runOcr,
                    )

                  ]
                ],
              ),

              if(_selectedPhotos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: .circular(8),
                          child: Stack(
                            children: [
                              Image.file(File(_selectedPhotos[index].path), width: 100, fit: BoxFit.cover,),
                              Positioned(
                                right: -8,
                                top: -8,
                                child: IconButton(onPressed: () {
                                  setState(() {
                                    _selectedPhotos.removeAt(index);
                                  });
                                },
                                icon: Icon(Icons.delete_forever)),
                              ),
                            ]
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    bool hasContent = value.text.trim().isNotEmpty;
                    if (!hasContent) return const SizedBox.shrink();
                    return Row(
                      mainAxisAlignment: .spaceAround,
                      children: [
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white
                            ),
                            onPressed: () => _runAI(),
                            label: Text("Özet Oluştur"),
                            icon: _isAIRunning ? SizedBox(width: 12, height: 12,child: CircularProgressIndicator(strokeWidth: 2,)) : Icon(Icons.document_scanner),

                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white
                            ),
                            onPressed: _textController.clear,
                            child: Text("Metni Temizle")
                        ),
                      ],
                    );
                  },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Notunuzu buraya yazın veya fotoğraftan tarayın...",
                    border: InputBorder.none
                  ),
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    bool hasContent = value.text.trim().isNotEmpty;
                    if (!hasContent) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Divider(),
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Align(alignment: .centerLeft, child: Text("Özet:", style: TextStyle(fontWeight: .bold, fontSize: 24),),),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            decoration: InputDecoration(
                              border: .none
                            ),
                            controller: _summaryController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                        SizedBox(height: 50,)
                      ],
                    );
                  },
              )
            ],
          ),
        ),
      ),
    );
  }
}
