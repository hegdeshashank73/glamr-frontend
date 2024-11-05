import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:glamr/services/search_api.dart';
import 'package:http/http.dart' as http;
import 'package:glamr/screens/ResultsScreen.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  List<CameraDescription>? cameras;
  int _selectedCameraIndex = 0;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> _processAndNavigate() async {
    if (_imageBytes == null) return;
    if (_isProcessing) return;

    // Debounce the function calls
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {});
    setState(() {
      _isProcessing = true;
    });

    try {
      final uploadResponse = await _apiService.getUploadUrl();

      final String uploadUrl = uploadResponse['upload_url'];
      final String s3Key = uploadResponse['key'];

      await _apiService.uploadImageToS3(uploadUrl, _imageBytes!);

      final searchResults = await _apiService.searchOptions(s3Key);

      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            capturedImage: _imageBytes!,
            searchResults: searchResults,
          ),
        ),
      );
    } catch (e) {

      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  Future<void> switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras!.length;

    await _cameraController?.dispose();

    _cameraController = CameraController(
      cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isEmpty) return;

    _cameraController = CameraController(
      cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> captureImage() async {
    if (_cameraController != null) {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      await _cameraController!.dispose();
      _cameraController = null;

      setState(() {
        _imageFile = image;
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = XFile(pickedFile.path);
        _imageBytes = imageBytes;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen camera preview or selected image
          Positioned.fill(
            child: _imageBytes == null
                ? (_cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()))
                : Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), // Semi-transparent overlay
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _imageFile == null
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // Changed to spaceEvenly
                children: [
                  // Gallery button on the left
                  Container(
                    width: 50,
                    margin: const EdgeInsets.only(left: 20),
                    child: GestureDetector(
                      onTap: pickImageFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
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
                  Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 20),
                    child: !kIsWeb && cameras != null && cameras!.length > 1
                        ? GestureDetector(
                      onTap: switchCamera,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    )
                        : const SizedBox(width: 50), // Maintains spacing on web
                  ),

                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.15),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _imageFile = null;
                          _imageBytes = null;
                        });
                        await initializeCamera();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Retake", style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.15),
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text("Search", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
