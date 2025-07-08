import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {//immutable
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {//root
    return MaterialApp(
      title: 'Photo Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PhotoManager(),//first visible screen
    );
  }
}

class PhotoManager extends StatefulWidget {
  const PhotoManager({super.key});

  @override
  State<PhotoManager> createState() => _PhotoManagerState();
}

class _PhotoManagerState extends State<PhotoManager> {
  List<File> _photos = [];//data driving the the grid

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {//-->keeps app responsive while waiting
    final directory = await getApplicationDocumentsDirectory();//-->pause here until we get the app’s document directory.;
    final files = directory.listSync();//returns all files in the app’s photo folder.
    final images = files.whereType<File>().where((file) {
      return file.path.endsWith(".jpg") || file.path.endsWith(".png");
    }).toList();//filter;keep only items that are real Files and end in .jpg or .png, then convert to a list.

    setState(() {//I changed something. Please rebuild the screen.
      _photos = images;
    });
  }




  Future<void> _capturePhoto() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.manageExternalStorage.request();
    //camera and storage permissions
    if (!cameraStatus.isGranted || !storageStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera or storage permission not granted')),
      );
      return;
    }

    final picker = ImagePicker();//lets user capture an image
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    //opens camera and lets user take a photo
    // await-->wait until user takes photo
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImage =
      await File(pickedFile.path).copy('${directory.path}/$fileName.jpg');
      //copies the photo from a temporary folder to a permanent one so the app keeps it after restart.
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
      body: _photos.isEmpty ?
      const Center(child: Text('No photos yet.',style: TextStyle(fontSize: 25,color: Colors.deepPurple),))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              final deleted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoPreviewScreen(
                    photos: List<File>.from(_photos),  // pass a COPY
                    initialIndex: index,
                  ),
                ),
              );

              if (deleted == true) {
                _loadSavedPhotos(); // Refresh grid after deletion
              }
            },

            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photos[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );


        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingActionButton(
            onPressed: _capturePhoto,
            backgroundColor: Colors.deepPurple[200],
            child: const Icon(Icons.camera_alt_rounded,size: 28,),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }
}
class PhotoPreviewScreen extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;

  const PhotoPreviewScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _deletePhoto() async {
    final photoToDelete = widget.photos[_currentIndex];

    await photoToDelete.delete(); // Delete the actual file

    setState(() {
      widget.photos.removeAt(_currentIndex);
      if (_currentIndex >= widget.photos.length) {
        _currentIndex = widget.photos.length - 1;
      }
    });

    if (widget.photos.isEmpty) {
      Navigator.pop(context, true); // Let main screen know something was deleted
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Photo Preview'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePhoto,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.file(widget.photos[index]),
            ),
          );
        },
      ),
    );
  }
}


