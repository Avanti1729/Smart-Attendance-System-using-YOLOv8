import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';

class MarkAttendanceTab extends StatefulWidget {
  const MarkAttendanceTab({super.key});

  @override
  State<MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<MarkAttendanceTab> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.max);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _captureImage(BuildContext context) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final rawImage = await _controller!.takePicture();

    if (!mounted) return;
    setState(() {
      _capturedImage = rawImage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image Captured Successfully!")),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _capturedImage = pickedFile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image Selected from Gallery!")),
      );
    }
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://smart-attendance-system-using-yolov8.onrender.com//upload"), // update to your backend
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _capturedImage!.path,
          filename: basename(_capturedImage!.path),
        ),
      );

      var response = await request.send();

      setState(() => _isUploading = false);

      final snackMsg = response.statusCode == 200
          ? 'Attendance marked successfully!'
          : 'Upload failed!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMsg)),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _capturedImage == null
              ? CameraPreview(_controller!)
              : Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => _captureImage(context),
              child: const Text('Capture Image'),
            ),
            ElevatedButton(
              onPressed: () => _pickFromGallery(context),
              child: const Text('Upload from Gallery'),
            ),
            ElevatedButton(
              onPressed: _capturedImage == null || _isUploading
                  ? null
                  : () => _uploadImage(context),
              child: _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Mark Attendance'),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
