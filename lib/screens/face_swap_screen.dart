import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FaceSwapScreen extends StatefulWidget {
  const FaceSwapScreen({super.key});

  @override
  State<FaceSwapScreen> createState() => _FaceSwapScreenState();
}

class _FaceSwapScreenState extends State<FaceSwapScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickGif() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      if (mounted) {
        context.read<FaceSwapProvider>().setSelectedGif(File(result.path));
      }
    }
  }

  Future<void> _pickFaceImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      if (mounted) {
        context.read<FaceSwapProvider>().setSelectedFaceImage(
          File(result.path),
        );
      }
    }
  }

  Future<void> _swapFace() async {
    final provider = context.read<FaceSwapProvider>();
    if (!provider.backendAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backend server is not available. Check your connection.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await provider.swapFace();

    if (mounted && provider.error == null && provider.swappedGif != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face swap completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceSwapProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Backend Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.backendAvailable
                        ? Colors.green[50]
                        : Colors.red[50],
                    border: Border.all(
                      color: provider.backendAvailable
                          ? Colors.green
                          : Colors.red,
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
                              : 'Backend not available',
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
                const SizedBox(height: 32),
                // GIF Selection
                const Text(
                  'Step 1: Select GIF',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickGif,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: provider.selectedGif != null
                        ? Stack(
                            children: [
                              // Show GIF thumbnail if possible
                              Container(
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'GIF Selected',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      provider.selectedGif!.path
                                          .split('/')
                                          .last,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    provider.setSelectedGif(null);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select GIF',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // Face Image Selection
                const Text(
                  'Step 2: Select Face Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickFaceImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: provider.selectedFaceImage != null
                        ? Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  provider.selectedFaceImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    provider.setSelectedFaceImage(null);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.face,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select face image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // Swap Button
                ElevatedButton(
                  onPressed:
                      provider.canSwap &&
                          !provider.isProcessing &&
                          provider.backendAvailable
                      ? _swapFace
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: provider.isProcessing
                      ? SpinKitRing(color: Colors.white, lineWidth: 3, size: 24)
                      : const Text(
                          'Swap Face',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                if (provider.isProcessing)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: provider.progress,
                        minHeight: 4,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Processing... ${(provider.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                // Error Message
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Success Message and Download
                if (provider.swappedGif != null && provider.error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Success!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Saved at: ${provider.swappedGif!.path}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Start Over'),
                                  onPressed: () {
                                    provider.clearSelection();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
