import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giphyme/providers/giphy_provider.dart';
import 'package:giphyme/providers/face_swap_provider.dart';
import 'package:giphyme/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GiphyProvider()),
        ChangeNotifierProvider(create: (_) => FaceSwapProvider()),
      ],
      child: MaterialApp(
        title: 'GiphyMe - Face Swap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
