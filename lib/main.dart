import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera & Gallery Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;  // Controller to manage camera
  List<CameraDescription>? cameras;  // List to hold available cameras
  final ImagePicker _picker = ImagePicker();  // ImagePicker instance to handle gallery picking
  bool _isCameraInitialized = false;  // Check if camera is initialized

  @override
  void initState() {
    super.initState();
    _initCamera();  // Initialize the camera when the app starts
  }

  // Initialize the camera
  _initCamera() async {
    cameras = await availableCameras();  // Get the list of available cameras
    _controller = CameraController(cameras![0], ResolutionPreset.medium);  // Set up a camera controller for the first camera
    await _controller?.initialize();  // Initialize the controller
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);  // Pick image from the gallery
    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();  // Convert image to bytes

      // Send the image bytes to a server
      var response = await http.post(
        Uri.parse('http://your-fastapi-endpoint/process'),  // Your server endpoint
        headers: {'Content-Type': 'application/json'},  // Send the image as bytes
        body: imageBytes,
      );

      print(response.body);  // Print server response
    }
  }

  // Function to capture an image using the camera
  Future<void> captureImage() async {
    if (_controller != null && _controller!.value.isInitialized) {
      XFile picture = await _controller!.takePicture();  // Capture the image

      Uint8List imageBytes = await picture.readAsBytes();  // Convert image to bytes

      // Since you don't want the image saved, we won't call picture.saveTo() or similar methods.

      // Send the image bytes to a server
      var response = await http.post(
        Uri.parse('http://your-fastapi-endpoint/process'),  // Your server endpoint
        headers: {'Content-Type': 'application/json'},
        body: imageBytes,
      );

      print(response.body);  // Print server response
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aplicativo de OCR"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isCameraInitialized && _controller != null)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),  // Display the camera preview
              )
            else
              const CircularProgressIndicator(),  // Show loading spinner while initializing

            const SizedBox(height: 20),  // Add some space between elements

            ElevatedButton(
              onPressed: () {
                captureImage();  // Call the camera capture function
              },
              child: const Text("Capturar Imagem"),
            ),

            const SizedBox(height: 20),  // Add some space between buttons

            ElevatedButton(
              onPressed: () {
                pickImageFromGallery();  // Call the function to pick an image from the gallery
              },
              child: const Text("Abrir Galeria"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();  // Dispose of the controller when the widget is destroyed
    super.dispose();
  }
}
