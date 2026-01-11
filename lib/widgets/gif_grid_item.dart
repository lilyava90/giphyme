import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:giphyme/models/gif_data.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:giphyme/screens/photo_capture_screen.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GifGridItem extends StatelessWidget {
  final GifData gif;

  const GifGridItem({super.key, required this.gif});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _onGifTap(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show original size GIF
            CachedNetworkImage(
              imageUrl: gif.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
            // Subtle hover effect on tap
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _onGifTap(context);
                },
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onGifTap(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading GIF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Download the GIF
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final gifPath =
          '${tempDir.path}/selected_gif_${DateTime.now().millisecondsSinceEpoch}.gif';

      await dio.download(gif.url, gifPath);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Save to provider
      final gifFile = File(gifPath);
      context.read<FaceSwapProvider>().setSelectedGif(gifFile);

      // Navigate to photo capture screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PhotoCaptureScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading GIF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
