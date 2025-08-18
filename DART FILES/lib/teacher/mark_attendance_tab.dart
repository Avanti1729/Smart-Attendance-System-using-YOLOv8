import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _capturedImage = await _controller!.takePicture();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (_capturedImage == null) return;

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "http://10.201.12.211:5000/upload", // replace with your backend
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _capturedImage!.path,
          filename: basename(_capturedImage!.path),
        ),
      );

      var response = await request.send();

      if (!mounted) return;
      setState(() => _isUploading = false);

      final snackMsg = response.statusCode == 200
          ? 'Attendance marked successfully!'
          : 'Upload failed!';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snackMsg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        Expanded(child: CameraPreview(_controller!)),
        if (_capturedImage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(File(_capturedImage!.path), height: 150),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture Image'),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _uploadImage(context),
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
      ],
    );
  }
}
