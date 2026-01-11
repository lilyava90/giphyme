class GifData {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final double width;
  final double height;

  GifData({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
  });

  double get aspectRatio => height > 0 ? width / height : 1.0;

  factory GifData.fromJson(Map<String, dynamic> json) {
    final originalImages = json['images']?['original'];
    final fixedWidth = json['images']?['fixed_width'];

    return GifData(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      url: json['url'] as String? ?? originalImages?['url'] ?? '',
      previewUrl:
          json['images']?['preview_gif']?['url'] ?? fixedWidth?['url'] ?? '',
      width:
          double.tryParse(originalImages?['width']?.toString() ?? '200') ?? 200,
      height:
          double.tryParse(originalImages?['height']?.toString() ?? '200') ??
          200,
    );
  }
}
