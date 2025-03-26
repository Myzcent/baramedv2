// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/theme_provider.dart';
import 'provider/font_size_provider.dart';
import 'screen/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ), // ✅ Ensure ThemeProvider is included
        ChangeNotifierProvider(create: (context) => FontSizeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Baramed App',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode:
              themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light, // ✅ Apply ThemeProvider
          home: const HomeScreen(), // ✅ Ensure HomeScreen is the entry point
        );
      },
    );
  }
}
