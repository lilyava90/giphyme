import 'dart:io';
import 'package:dio/dio.dart';
import 'package:giphyme/config/constants.dart';
import 'package:path_provider/path_provider.dart';

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

      final response = await _dio.post(
        '$BACKEND_URL/swap-face',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;

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
