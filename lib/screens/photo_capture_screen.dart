import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:giphyme/screens/result_screen.dart';

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _takePicture() async {
    final result = await _imagePicker.pickImage(source: ImageSource.camera);
    if (result != null && mounted) {
      context.read<FaceSwapProvider>().setSelectedFaceImage(File(result.path));
      _processAndNavigate();
    }
  }

  Future<void> _uploadPicture() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null && mounted) {
      context.read<FaceSwapProvider>().setSelectedFaceImage(File(result.path));
      _processAndNavigate();
    }
  }

  void _processAndNavigate() async {
    final provider = context.read<FaceSwapProvider>();

    if (!provider.backendAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backend server is not available. Please check your connection.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate to result screen which will show processing
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Take or Upload Photo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<FaceSwapProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Backend Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: provider.backendAvailable
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      border: Border.all(
                        color: provider.backendAvailable
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.backendAvailable
                              ? Icons.check_circle
                              : Icons.error,
                          color: provider.backendAvailable
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.backendAvailable
                                ? 'Backend connected'
                                : 'Backend not available - Start backend server',
                            style: TextStyle(
                              color: provider.backendAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Instructions
                  Text(
                    'Step 2: Add Your Face',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Take a photo or upload one from your gallery',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Preview selected face
                  if (provider.selectedFaceImage != null)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          provider.selectedFaceImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.face,
                          size: 100,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Take Photo Button
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload Photo Button
                  OutlinedButton.icon(
                    onPressed: _uploadPicture,
                    icon: const Icon(Icons.photo_library, size: 28),
                    label: const Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.yellow[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Tips for Best Results',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Use a clear, well-lit photo'),
                        _buildTip('Face the camera directly'),
                        _buildTip('Show your full face'),
                        _buildTip('Avoid sunglasses or masks'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[300])),
          ),
        ],
      ),
    );
  }
}
