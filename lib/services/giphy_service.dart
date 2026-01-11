import 'package:giphy_get/giphy_get.dart';
import 'package:giphyme/models/gif_data.dart';
import 'package:giphyme/config/constants.dart';

class GiphyService {
  late final GiphyClient _client;

  GiphyService() {
    _client = GiphyClient(apiKey: GIPHY_API_KEY, randomId: 'giphyme_app');
  }

  Future<List<GifData>> searchGifs(String query) async {
    try {
      final collection = await _client.search(
        query,
        limit: 20,
        rating: GiphyRating.g,
        lang: GiphyLanguage.english,
      );

      return collection.data
          .map(
            (gif) => GifData(
              id: gif.id ?? '',
              title: gif.title ?? '',
              url: gif.images?.original?.url ?? '',
              previewUrl:
                  gif.images?.fixedWidth?.url ??
                  gif.images?.fixedWidthSmall?.url ??
                  '',
              width:
                  double.tryParse(gif.images?.original?.width ?? '200') ?? 200,
              height:
                  double.tryParse(gif.images?.original?.height ?? '200') ?? 200,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search GIFs: ${e.toString()}');
    }
  }

  Future<List<GifData>> getTrendingGifs() async {
    try {
      final collection = await _client.trending(
        limit: 20,
        rating: GiphyRating.g,
      );

      return collection.data
          .map(
            (gif) => GifData(
              id: gif.id ?? '',
              title: gif.title ?? '',
              url: gif.images?.original?.url ?? '',
              previewUrl:
                  gif.images?.fixedWidth?.url ??
                  gif.images?.fixedWidthSmall?.url ??
                  '',
              width:
                  double.tryParse(gif.images?.original?.width ?? '200') ?? 200,
              height:
                  double.tryParse(gif.images?.original?.height ?? '200') ?? 200,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load trending GIFs: ${e.toString()}');
    }
  }
}
