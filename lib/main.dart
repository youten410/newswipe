import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:news_app/news_list.dart';
import 'package:provider/provider.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
      ),
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
      ),
      home: NewsApp(),
    );
  }
}
