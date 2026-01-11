import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:async';

// Custom GIF display widget that ensures continuous looping animation
class AnimatedGifDisplay extends StatefulWidget {
  final File gifFile;
  final double height;
  final BoxFit fit;

  const AnimatedGifDisplay({
    super.key,
    required this.gifFile,
    this.height = 350,
    this.fit = BoxFit.contain,
  });

  @override
  State<AnimatedGifDisplay> createState() => _AnimatedGifDisplayState();
}

class _AnimatedGifDisplayState extends State<AnimatedGifDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _resetTimer;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();

    // Force refresh every 3 seconds to restart GIF animation
    _resetTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.file(
      widget.gifFile,
      key: ValueKey(_refreshKey),
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showSaveSnackbar = false;

  @override
  void initState() {
    super.initState();
    // Start processing immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    await context.read<FaceSwapProvider>().swapFace();
  }

  Future<void> _saveToGallery() async {
    final provider = context.read<FaceSwapProvider>();
    if (provider.swappedGif == null) return;

    try {
      final result = await ImageGallerySaver.saveFile(
        provider.swappedGif!.path,
        name: 'giphyme_${DateTime.now().millisecondsSinceEpoch}',
        isReturnPathOfIOS: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ GIF saved to Camera Roll!'),
            backgroundColor: Colors.green[400],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _shareGif() async {
    final provider = context.read<FaceSwapProvider>();
    if (provider.swappedGif == null) return;

    try {
      await Share.shareXFiles([
        XFile(provider.swappedGif!.path),
      ], text: 'Check out my awesome face-swapped GIF! 🎬✨');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Processing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            context.read<FaceSwapProvider>().clearSelection();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          tooltip: 'Back to Home',
        ),
      ),
      body: Consumer<FaceSwapProvider>(
        builder: (context, provider, _) {
          if (provider.isProcessing) {
            return _buildProcessingView(provider);
          } else if (provider.error != null) {
            return _buildErrorView(provider);
          } else if (provider.swappedGif != null) {
            return _buildSuccessView(provider);
          } else {
            return _buildProcessingView(provider);
          }
        },
      ),
    );
  }

  Widget _buildProcessingView(FaceSwapProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitRing(color: Colors.white, size: 80, lineWidth: 8),
            const SizedBox(height: 32),
            Text(
              'Creating Your Face-Swapped GIF',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This may take 30-120 seconds...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              value: provider.progress > 0 ? provider.progress : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey[800],
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            if (provider.progress > 0)
              Text(
                '${(provider.progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Our AI is:\n• Detecting faces in the GIF\n• Swapping your face frame-by-frame\n• Creating the final result',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(FaceSwapProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            Text(
              'Oops! Something Went Wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                provider.clearSelection();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text(
                'Start Over',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(FaceSwapProvider provider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
              const SizedBox(height: 24),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your face-swapped GIF is ready!',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Show result GIF with animation
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green[400]!, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedGifDisplay(
                    gifFile: provider.swappedGif!,
                    height: 350,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save and Share Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Save to Camera Roll Button
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[600],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _saveToGallery,
                            borderRadius: BorderRadius.circular(50),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.save_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Share Button
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purple[600],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _shareGif,
                            borderRadius: BorderRadius.circular(50),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.save_alt, color: Colors.green[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Saved to:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.swappedGif!.path,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () {
                  provider.clearSelection();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Create Another',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
