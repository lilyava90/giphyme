import 'dart:io';
import 'package:flutter/material.dart';
import 'package:giphyme/services/face_swap_service.dart';

class FaceSwapProvider extends ChangeNotifier {
  final FaceSwapService _faceSwapService = FaceSwapService();

  File? _selectedGif;
  File? _selectedFaceImage;
  File? _swappedGif;
  bool _isProcessing = false;
  String? _error;
  double _progress = 0.0;
  bool _backendAvailable = false;

  File? get selectedGif => _selectedGif;
  File? get selectedFaceImage => _selectedFaceImage;
  File? get swappedGif => _swappedGif;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  double get progress => _progress;
  bool get backendAvailable => _backendAvailable;

  bool get canSwap => _selectedGif != null && _selectedFaceImage != null;

  void setSelectedGif(File? gif) {
    _selectedGif = gif;
    _error = null;
    notifyListeners();
  }

  void setSelectedFaceImage(File? image) {
    _selectedFaceImage = image;
    _error = null;
    notifyListeners();
  }

  Future<void> checkBackendHealth() async {
    _backendAvailable = await _faceSwapService.checkHealth();
    notifyListeners();
  }

  Future<void> swapFace() async {
    if (_selectedGif == null || _selectedFaceImage == null) {
      _error = 'Please select both GIF and face image';
      notifyListeners();
      return;
    }

    if (!_backendAvailable) {
      _error = 'Backend server not available';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _error = null;
    _progress = 0.0;
    notifyListeners();

    try {
      print('FaceSwapProvider: Starting swapFace service call');

      // Start the actual swap
      File? result;
      final swapFuture = _faceSwapService
          .swapFace(gifFile: _selectedGif!, faceImage: _selectedFaceImage!)
          .then((r) {
            result = r;
            return r;
          });

      // Smooth progress simulation from 0% to 95%
      final stopwatch = Stopwatch()..start();
      const totalSteps = 95; // Progress from 0 to 95%
      const stepDuration = Duration(milliseconds: 800); // Update every 800ms

      for (int step = 0; step <= totalSteps && result == null; step++) {
        _updateProgress(step / 100.0);

        // Wait for step duration, but check if swap completed
        final checkInterval = Duration(milliseconds: 100);
        for (
          int i = 0;
          i < stepDuration.inMilliseconds ~/ checkInterval.inMilliseconds;
          i++
        ) {
          await Future.delayed(checkInterval);
          if (result != null) break;
        }
      }

      // If still processing, wait for completion
      if (result == null) {
        _swappedGif = await swapFuture;
      } else {
        _swappedGif = result;
      }

      print(
        'FaceSwapProvider: Swap completed, result file: ${_swappedGif?.path}',
      );

      // Final progress to 100%
      _updateProgress(1.0);
    } catch (e) {
      print('FaceSwapProvider: Error during swap - $e');
      _error = e.toString();
      _swappedGif = null;
    }

    _isProcessing = false;
    notifyListeners();
  }

  void _updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void clearSelection() {
    _selectedGif = null;
    _selectedFaceImage = null;
    _swappedGif = null;
    _error = null;
    _progress = 0.0;
    notifyListeners();
  }

  void reset() {
    clearSelection();
    _backendAvailable = false;
    notifyListeners();
  }
}
