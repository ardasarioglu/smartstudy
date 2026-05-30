import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:smartstudy/Pages/AddNotePage.dart';
import 'package:smartstudy/Pages/NotePage.dart';
import 'package:smartstudy/ProviderModels/NoteProvider.dart';
import 'package:smartstudy/Services/AIService.dart';
import 'package:smartstudy/Services/PickerService.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => NoteProvider(),)
    ], child: const MyApp(),)
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45),
        child: AppBar(
          backgroundColor: Colors.grey,
          title: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: .circular(20),
            ),
            child: Center(
              child: TextField(
                onChanged: (value) {
                  context.read<NoteProvider>().searchNotes(value);
                },
                cursorColor: Colors.black,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Ara",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    context.read<NoteProvider>().searchNotes("");
                  }, icon: Icon(Icons.clear))
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SafeArea(
          child: Consumer<NoteProvider>(
            builder: (context, provider, child) {
              if(provider.isLoading){
                return Center(child: CircularProgressIndicator(),);
              }
              if(provider.notes.isNotEmpty){
                return ListView.builder(
                  itemCount: provider.notes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NotePage(note: provider.notes[index],),));
                      },
                      title: Text(provider.notes[index].title,),
                      subtitle: Text(
                        provider.notes[index].summaryText ?? "Özet Yok",
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    );
                  },
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Center(
                    child: Text("Henüz bir notun yok, yapay zeka ile ilk flashcard'ını oluşturmak için + butonuna bas"),
                  ),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Addnotepage(),)),
        child: Icon(Icons.add),
      ),
    );
  }
}
