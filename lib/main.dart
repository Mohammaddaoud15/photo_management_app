import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PhotoManager(),
    );
  }
}

class PhotoManager extends StatefulWidget {
  const PhotoManager({super.key});

  @override
  State<PhotoManager> createState() => _PhotoManagerState();
}

class _PhotoManagerState extends State<PhotoManager> {
  List<File> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final images = files.whereType<File>().where((file) {
      return file.path.endsWith(".jpg") || file.path.endsWith(".png");
    }).toList();

    setState(() {
      _photos = images;
    });
  }

  Future<void> _capturePhoto() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.manageExternalStorage.request();

    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera or storage permission not granted')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImage =
      await File(pickedFile.path).copy('${directory.path}/$fileName.jpg');

      setState(() {
        _photos.add(savedImage);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Photo Manager',style: TextStyle(fontSize: 30),),
        backgroundColor: Colors.deepPurple,
      ),
      body: _photos.isEmpty
          ? const Center(child: Text('No photos yet.',style: TextStyle(fontSize: 25,color: Colors.deepPurple),))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return Image.file(
            _photos[index],
            fit: BoxFit.cover,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
