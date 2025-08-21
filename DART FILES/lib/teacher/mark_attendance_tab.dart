import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:image/image.dart' as img;

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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image Captured Successfully!")),
    );
  }

  Future<void> _uploadImage(BuildContext context) async {
    if (_capturedImage == null) return;

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "http://10.201.12.211:5000/upload",
        ), //remember to change link here else no work
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackMsg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _retakeImage() {
    setState(() {
      _capturedImage = null; // clear last image
    });
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
            if (_capturedImage == null)
              ElevatedButton(
                onPressed: () => _captureImage(context),
                child: const Text('Capture Image'),
              )
            else
              ElevatedButton(
                onPressed: _retakeImage,
                child: const Text('Retake'),
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
