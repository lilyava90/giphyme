import 'dart:io';
import 'package:dio/dio.dart';
import 'package:giphyme/config/constants.dart';
import 'package:path_provider/path_provider.dart';

class DetectedFace {
  final int index;
  final int x;
  final int y;
  final int width;
  final int height;
  final double confidence;

  DetectedFace({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  factory DetectedFace.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as Map<String, dynamic>;
    return DetectedFace(
      index: (json['index'] as num).toInt(),
      x: (bbox['x'] as num).toInt(),
      y: (bbox['y'] as num).toInt(),
      width: (bbox['width'] as num).toInt(),
      height: (bbox['height'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class FaceSwapService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 180),
      // Large GIFs may be returned; allow large bodies
      maxRedirects: 5,
    ),
  );

  Future<File> swapFace({
    required File gifFile,
    required File faceImage,
  }) async {
    try {
      print('Starting face swap with GIF: ${gifFile.path}');
      print('Face image: ${faceImage.path}');

      final formData = FormData.fromMap({
        'gif_file': await MultipartFile.fromFile(
          gifFile.path,
          filename: 'input.gif',
        ),
        'face_image': await MultipartFile.fromFile(
          faceImage.path,
          filename: 'face.png',
        ),
      });

      print('Sending swap request to: $BACKEND_URL/swap-face');
      final response = await _dio.post(
        '$BACKEND_URL/swap-face',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Face swap response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        print('Received swapped GIF with ${bytes.length} bytes');

        // Get application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final outputPath = '${appDir.path}/giphyme';
        final outputDir = Directory(outputPath);

        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
        }

        final outputFile = File(
          '$outputPath/swapped_${DateTime.now().millisecondsSinceEpoch}.gif',
        );
        await outputFile.writeAsBytes(bytes);
        print('Saved swapped GIF to: ${outputFile.path}');

        // Verify file was written successfully
        final fileSize = await outputFile.length();
        print('Verified file size on disk: $fileSize bytes');

        if (fileSize == 0) {
          throw Exception('File was not written properly');
        }

        return outputFile;
      }

      throw Exception(
        'Face swap failed: ${response.statusCode} - ${response.data}',
      );
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<DetectedFace>> detectFaces({required File faceImage}) async {
    try {
      print('Starting face detection for: ${faceImage.path}');
      print('Backend URL: $BACKEND_URL/detect-faces');

      final formData = FormData.fromMap({
        'face_image': await MultipartFile.fromFile(
          faceImage.path,
          filename: 'face.png',
        ),
      });

      print('Sending face detection request...');
      final response = await _dio.post(
        '$BACKEND_URL/detect-faces',
        data: formData,
        options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Face detection response status: ${response.statusCode}');
      print('Face detection response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final faces = data['faces'] as List<dynamic>;
        final detectedFaces = faces
            .map((f) => DetectedFace.fromJson(f as Map<String, dynamic>))
            .toList();
        print('Successfully detected ${detectedFaces.length} face(s)');
        return detectedFaces;
      }

      final errorMsg =
          'Face detection failed: ${response.statusCode} - ${response.data}';
      print('Error: $errorMsg');
      throw Exception(errorMsg);
    } on DioException catch (e) {
      print('DioException in face detection: ${e.message}');
      print('DioException type: ${e.type}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Face detection error details: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Error detecting faces: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '$BACKEND_URL/health',
        options: Options(validateStatus: (status) => status! < 500),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
