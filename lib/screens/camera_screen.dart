import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:glamr/screens/ResultsScreen.dart';



class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras![0],
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> captureImage() async {
    if (_cameraController != null) {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes(); // Read image as bytes
      setState(() {
        _imageFile = image;
        _imageBytes = imageBytes; // Store the bytes to display on web
      });
    }
  }

  Future<void> sendImageToApi() async {
    if (_imageFile != null) {
      final uri = Uri.parse('https://yourapiurl.com/upload');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        print("Image uploaded successfully");
      } else {
        print("Failed to upload image");
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Column(
        children: [
          // Container for camera preview with specific padding and alignment
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageBytes == null
                      ? (_cameraController != null && _cameraController!.value.isInitialized
                      ? AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  )
                      : Center(child: CircularProgressIndicator()))
                      : Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),

          // Capture button or action buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _imageFile == null
                ? Center(
              child: GestureDetector(
                onTap: captureImage,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                ),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _imageFile = null; // Clear the image file to reset
                      _imageBytes = null; // Clear the bytes as well
                      initializeCamera(); // Reinitialize camera for new capture
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Retake", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed:  () {
                    if (_imageBytes != null) {
                      // Navigate to the ResultsScreen with the captured image data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultsScreen(capturedImage: _imageBytes!),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Search", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
