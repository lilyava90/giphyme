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
      // Simulate progress updates
      _progress = 0.1;
      notifyListeners();

      _swappedGif = await _faceSwapService.swapFace(
        gifFile: _selectedGif!,
        faceImage: _selectedFaceImage!,
      );

      _progress = 1.0;
    } catch (e) {
      _error = e.toString();
      _swappedGif = null;
    }

    _isProcessing = false;
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
