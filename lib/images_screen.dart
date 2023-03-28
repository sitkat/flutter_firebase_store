import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseFirestore fireStore = FirebaseFirestore.instance;
QuerySnapshot? querySnapshot;
List<Map<String, dynamic>> userList = [];
CollectionReference usersImage =
    FirebaseFirestore.instance.collection('images');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ImagesScreen());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImagesScreen(),
    );
  }
}

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
      GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController _nameController = new TextEditingController();
  int _counter = 0;

  void _incrementCounter() async {
    
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Выбор файла',
    );
    if (result != null) {
      final size = result.files.first.size;
      final file = io.File(result.files.single.path!);
      final fileExtensions = result.files.first.extension!;
      print("размер:$size file:${file.path} fileExtensions:${fileExtensions}");
      String names = getRandomString(5);
      await FirebaseStorage.instance.ref().child(names).putFile(file);

      final urlFile =
          await FirebaseStorage.instance.ref().child(names).getDownloadURL();
      final imagesAdd = fireStore.collection('images');
      imagesAdd
          .add(
            {
              'nameFile': names,
              'size': result.files.first.size,
              'url': urlFile,
            },
          )
          .then((value) => print('Add image'))
          .catchError((error) => print('Faild add: $error'));
    } else {}
    initImage();
  }

  Future<void> DeleteImage() async {
    await FirebaseStorage.instance.ref("/" + fullname).delete();
    if (link != '') {
      querySnapshot = await FirebaseFirestore.instance
          .collection('images')
          .where('url', isEqualTo: link)
          .get();
      fullpath.clear();

      querySnapshot?.docs.forEach((doc) async {
        await usersImage.doc(doc.id).delete();
      });
    }
    initImage();
  }

  String link = '';
  String fullname = '';
  List<ModelTest> fullpath = [];

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rand = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rand.nextInt(_chars.length))));

  Future<void> initImage() async {
    querySnapshot = await FirebaseFirestore.instance
        .collection('images')
        .get();
    fullpath.clear();

    final storageReference = querySnapshot!.docs.toList();
    final list = await storageReference;
    list.forEach((element) async {
      final url = await element.get('url');
      final nameFile = await element.get('nameFile');
      final size = await element.get('size');
      fullpath.add(ModelTest(url, nameFile, size));
      setState(() {
        link = '';
        _nameController.text = '';
      });
    });
  }

  @override
  void initState() {
    initImage().then(
      (value) {},
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          foregroundColor: Colors.green,
          title: Text(
            'Картинки',
            style: TextStyle(color: Colors.white),
          ),
        actions: [
          IconButton(
              onPressed: () async {
                await initImage();
              },
              icon: Icon(Icons.refresh, color: Colors.black,)),
        ],
            centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: fullpath.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      onLongPress: () async {
                        link = fullpath[index].url;
                        fullname = fullpath[index].nameFile;
                        await DeleteImage();
                      },
                      onTap: () {
                        setState(() {
                          link = fullpath[index].url;
                          _nameController.text = fullpath[index].nameFile;
                        });
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Image.network(
                            fullpath[index].url,
                            errorBuilder: (context, error, stackTrace) {
                              return Text('');
                            },
                          ),
                        ),
                        title: Text("Название: " + fullpath[index].nameFile),
                        subtitle: Text("Размер: " +
                            fullpath[index].size.toString() +
                            "Ссылка: " +
                            fullpath[index].url),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Название файла:',
                        ),
                      ),
                    ),
                    Image.network(
                      link,
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return Text('Картинка не выбрана');
                      },
                    ),
                  ],
                ))
          ],
        ),
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ModelTest {
  final String url;
  final String nameFile;
  final int size;

  ModelTest(this.url, this.nameFile, this.size);
}