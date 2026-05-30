import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:smartstudy/Models/Note.dart';
import 'package:smartstudy/Pages/EditNotePage.dart';
import 'package:smartstudy/Pages/FlashcardsPage.dart';
import 'package:smartstudy/ProviderModels/NoteProvider.dart';

class NotePage extends StatelessWidget {
  final Note note;
  const NotePage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    bool isSaving = context.watch<NoteProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        backgroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                note.summaryText ?? "Özet Yok",
                maxLines: null,

              ),
            ),
            Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditNotePage(note: note,),));
                  },
                  child: Text("Düzenle")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardsPage(noteId: note.id!,),));
                  },
                  child: Text("Flashcard'lara git")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    bool? confirmDelete = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Notu Sil"),
                          content: Text("Bu notu kalıcı olarak silmek istediğine emin misin? Bu işlem geri alınamaz"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text("İptal", style: TextStyle(color: Colors.black54),)),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text("Sil"),
                            )
                          ],
                        );
                      },
                    );

                    if(confirmDelete != true) return;
                    if(!context.mounted) return;
                    await context.read<NoteProvider>().deleteNote(note.id!);
                    if(context.mounted){
                      Navigator.pop(context);
                    }

                  },
                  child: Text("Notu Sil!")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
