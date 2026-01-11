import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:giphyme/screens/gif_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check backend health on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceSwapProvider>().checkBackendHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Directly show the GIF search screen as the home screen
    return const GifSearchScreen();
  }
}
