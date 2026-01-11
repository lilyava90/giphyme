import 'package:flutter/material.dart';
import 'package:giphyme/models/gif_data.dart';
import 'package:giphyme/services/giphy_service.dart';

class GiphyProvider extends ChangeNotifier {
  final GiphyService _giphyService = GiphyService();

  List<GifData> _gifs = [];
  bool _isLoading = false;
  String? _error;

  List<GifData> get gifs => _gifs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchGifs(String query) async {
    if (query.isEmpty) {
      _gifs = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gifs = await _giphyService.searchGifs(query);
    } catch (e) {
      _error = e.toString();
      _gifs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getTrendingGifs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _gifs = await _giphyService.getTrendingGifs();
    } catch (e) {
      _error = e.toString();
      _gifs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearGifs() {
    _gifs = [];
    _error = null;
    notifyListeners();
  }
}
