import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String status = '';
  List menuItem = ['フランス','米国','英国','ドイツ','日本','イタリア','カナダ'];
  String country = 'jp';
  String url = '';

  Future<void> getData(country) async {
    var url = 'https://newsapi.org/v2/top-headlines?country=$country&apiKey=d29107383eac4c97989831bb265caaaa';
    print(url);
    var response = await Dio().get(url);
    status = response.data['status'];
    items = response.data['articles'];
    setState(() {});
    print(status);
  }

  Future<void> _refreshNews() async {
    await getData(country);
  }

  @override
  void initState() {
    super.initState();
    url = 'https://newsapi.org/v2/top-headlines?country=$country&apiKey=d29107383eac4c97989831bb265caaaa';
    getData(country);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView.builder(
          itemCount: menuItem.length,
          itemBuilder: (BuildContext context, int index) {
            return Column(
              //センターにしたい
              children: [
                ListTile(
                  title: Text(
                    menuItem[index],
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                  onTap: () {
                    print(menuItem[index]);
                    if (menuItem[index] == "日本") {
                      getData("jp");
                    }else{
                      getData("us");
                    }
                  },
                ),
                const Divider(
                  color: Color.fromARGB(255, 159, 152, 152),
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Text('Status: $status'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        child: ListView.separated(
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(items[index]['title'] ?? 'Unknown Title'),
                    subtitle: Text(items[index]['author'] ?? 'Unknown Author'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () async {
                      final url =
                          Uri.parse(items[index]['url'] ?? 'Unknown Title');
                      // ignore: deprecated_member_use
                      if (await canLaunch(url.toString())) {
                        // ignore: deprecated_member_use
                        await launch(url.toString());
                      } else {
                        print("Can't launch url");
                      }
                    },
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider();
          },
        ),
      ),
    );
  }
}
