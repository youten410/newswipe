import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe Cards Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NewsApp(),
    );
  }
}

class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  List items = [];
  List imageList = [];
  String status = '';

  var url = 'https://newsapi.org/v2/everything?' +
      'q=Apple&' +
      'from=2023-04-16&' +
      'sortBy=popularity&' +
      'apiKey=d29107383eac4c97989831bb265caaaa';

  Future<void> getData() async {
    var response = await Dio().get(url);
    status = response.data['status'];
    imageList = response.data['articles'];
    setState(() {});
    print(status);
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News App'),
      ),
      body: Center(
        child: Text('Status: $status'),
      ),
    );
  }
}
