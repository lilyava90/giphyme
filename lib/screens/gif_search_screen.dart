import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/giphy_provider.dart';
import 'package:giphyme/widgets/gif_grid_item.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GifSearchScreen extends StatefulWidget {
  const GifSearchScreen({super.key});

  @override
  State<GifSearchScreen> createState() => _GifSearchScreenState();
}

class _GifSearchScreenState extends State<GifSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Load trending GIFs on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiphyProvider>().getTrendingGifs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select a GIF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search GIFs...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          context.read<GiphyProvider>().clearGifs();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  context.read<GiphyProvider>().searchGifs(value);
                }
              },
            ),
          ),
          // GIF Grid
          Expanded(
            child: Consumer<GiphyProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                    child: SpinKitCircle(
                      color: Theme.of(context).colorScheme.primary,
                      size: 50.0,
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.getTrendingGifs();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.gifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No GIFs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_searchController.text.isEmpty)
                          ElevatedButton(
                            onPressed: () {
                              provider.getTrendingGifs();
                            },
                            child: const Text('Load Trending GIFs'),
                          ),
                      ],
                    ),
                  );
                }

                return MasonryGridView.count(
                  padding: const EdgeInsets.all(8),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: provider.gifs.length,
                  itemBuilder: (context, index) {
                    final gif = provider.gifs[index];
                    // Calculate height based on aspect ratio for masonry effect
                    final itemHeight = 200 / gif.aspectRatio;
                    return SizedBox(
                      height: itemHeight.clamp(150.0, 400.0),
                      child: GifGridItem(gif: gif),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
