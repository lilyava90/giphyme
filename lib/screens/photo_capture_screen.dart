import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:giphyme/screens/result_screen.dart';
import 'package:giphyme/services/face_swap_service.dart';
import 'package:image/image.dart' as img;

class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FaceSwapService _faceSwapService = FaceSwapService();

  File? _capturedImage;
  List<DetectedFace>? _detectedFaces;
  bool _isDetectingFaces = false;

  Future<void> _takePicture() async {
    final result = await _imagePicker.pickImage(source: ImageSource.camera);
    if (result != null && mounted) {
      await _handleImageSelection(File(result.path));
    }
  }

  Future<void> _uploadPicture() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null && mounted) {
      await _handleImageSelection(File(result.path));
    }
  }

  Future<void> _handleImageSelection(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _detectedFaces = null;
      _isDetectingFaces = true;
    });

    try {
      print('PhotoCaptureScreen: Detecting faces...');
      final faces = await _faceSwapService.detectFaces(faceImage: imageFile);
      print('PhotoCaptureScreen: Detected ${faces.length} face(s)');

      if (!mounted) return;

      if (faces.isEmpty) {
        // No faces detected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No faces detected in the image. Please try another photo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _capturedImage = null;
          _isDetectingFaces = false;
        });
      } else if (faces.length == 1) {
        // Only one face, proceed directly with cropped face
        if (mounted) {
          _selectFace(faces[0]);
        }
      } else {
        // Multiple faces detected, show selection UI
        setState(() {
          _detectedFaces = faces;
          _isDetectingFaces = false;
        });
      }
    } catch (e) {
      print('PhotoCaptureScreen: Error during face detection: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error detecting faces: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _capturedImage = null;
        _isDetectingFaces = false;
      });
    }
  }

  void _selectFace(DetectedFace face) async {
    if (_capturedImage == null) return;

    try {
      // Crop the selected face and save it as a temporary file
      final imageBytes = _capturedImage!.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop coordinates with generous padding for face detection
      // Using 50% of face dimensions as padding to ensure proper face detection
      final paddingX = (face.width * 0.5).toInt();
      final paddingY = (face.height * 0.5).toInt();
      final x = (face.x - paddingX).clamp(0, decodedImage.width);
      final y = (face.y - paddingY).clamp(0, decodedImage.height);
      final width = (face.width + paddingX * 2).clamp(
        0,
        decodedImage.width - x,
      );
      final height = (face.height + paddingY * 2).clamp(
        0,
        decodedImage.height - y,
      );

      // Crop the face region
      final croppedImage = img.copyCrop(
        decodedImage,
        x: x.toInt(),
        y: y.toInt(),
        width: width.toInt(),
        height: height.toInt(),
      );

      print(
        'Cropped face image size: ${croppedImage.width}x${croppedImage.height}',
      );

      // Encode to PNG
      final croppedBytes = img.encodePng(croppedImage);

      // Save to temporary file
      final tempDir = await Directory.systemTemp.createTemp('giphyme_face');
      final croppedFile = File('${tempDir.path}/selected_face.png');
      await croppedFile.writeAsBytes(croppedBytes);

      print('Cropped face saved to: ${croppedFile.path}');
      print('File size: ${croppedFile.lengthSync()} bytes');

      // Set the cropped face image
      if (mounted) {
        context.read<FaceSwapProvider>().setSelectedFaceImage(croppedFile);
        _processAndNavigate();
      }
    } catch (e) {
      print('Error cropping selected face: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting face: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelFaceSelection() {
    setState(() {
      _capturedImage = null;
      _detectedFaces = null;
    });
  }

  Widget _buildFaceThumbnail(DetectedFace face) {
    try {
      // Decode the image
      final imageBytes = _capturedImage!.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop coordinates with some padding
      final padding = 10;
      final x = (face.x - padding).clamp(0, decodedImage.width);
      final y = (face.y - padding).clamp(0, decodedImage.height);
      final width = (face.width + padding * 2).clamp(0, decodedImage.width - x);
      final height = (face.height + padding * 2).clamp(
        0,
        decodedImage.height - y,
      );

      // Crop the face region
      final croppedImage = img.copyCrop(
        decodedImage,
        x: x.toInt(),
        y: y.toInt(),
        width: width.toInt(),
        height: height.toInt(),
      );

      // Encode back to PNG
      final croppedBytes = img.encodePng(croppedImage);

      // Display the cropped face
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(croppedBytes, fit: BoxFit.cover),
        ),
      );
    } catch (e) {
      print('Error building face thumbnail: $e');
      // Fallback to icon display
      return Container(
        color: Colors.grey[700],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.face, color: Colors.white, size: 40),
              const SizedBox(height: 4),
              Text(
                '${(face.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      );
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
    // If multiple faces detected, show face selection UI
    if (_detectedFaces != null && _detectedFaces!.length > 1) {
      return _buildFaceSelectionUI();
    }

    // Otherwise show the normal capture UI
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

                  // Preview selected face or loading indicator
                  if (_isDetectingFaces)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Detecting faces...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_capturedImage != null)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_capturedImage!, fit: BoxFit.cover),
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
                    onPressed: _isDetectingFaces ? null : _takePicture,
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
                    onPressed: _isDetectingFaces ? null : _uploadPicture,
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

  Widget _buildFaceSelectionUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select a Face',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelFaceSelection,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Multiple faces detected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap on the face you want to use for the swap',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Display image with face boxes overlay
              if (_capturedImage != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedImage!,
                      fit: BoxFit.contain,
                      height: 300,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Show cropped face thumbnails
              if (_detectedFaces != null && _detectedFaces!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Faces:',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _detectedFaces!.length,
                        itemBuilder: (context, index) {
                          final face = _detectedFaces![index];
                          return GestureDetector(
                            onTap: () => _selectFace(face),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[800],
                                    ),
                                    child: _buildFaceThumbnail(face),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Face ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // List of detected faces
              ...List.generate(_detectedFaces!.length, (index) {
                final face = _detectedFaces![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    onPressed: () => _selectFace(face),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.face, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Face ${index + 1} (${(face.confidence * 100).toStringAsFixed(0)}% confidence)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: _cancelFaceSelection,
                child: const Text(
                  'Cancel and try another photo',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw face boxes
class FaceBoxPainter extends CustomPainter {
  final List<DetectedFace> faces;
  final File imageFile;
  final Function(DetectedFace) onFaceTap;

  FaceBoxPainter({
    required this.faces,
    required this.imageFile,
    required this.onFaceTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print(
      'FaceBoxPainter: Drawing ${faces.length} faces on canvas size: $size',
    );

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
    ];

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final color = colors[i % colors.length];

      print(
        'Face $i: x=${face.x}, y=${face.y}, w=${face.width}, h=${face.height}',
      );

      // Draw rectangle around face
      final boxPaint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      final rect = Rect.fromLTWH(
        face.x.toDouble(),
        face.y.toDouble(),
        face.width.toDouble(),
        face.height.toDouble(),
      );

      canvas.drawRect(rect, boxPaint);

      // Draw filled background for label
      final labelPaint = Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      final labelRect = Rect.fromLTWH(
        face.x.toDouble(),
        (face.y - 35).toDouble().clamp(0, double.infinity),
        80,
        30,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
        labelPaint,
      );

      // Draw text label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Face ${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (face.x + 10).toDouble(),
          (face.y - 28).toDouble().clamp(0, double.infinity),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
