import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'main.dart';

Set<String> likedItems = {};
bool isDarkMode = false;

//News閲覧ページ
class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  late int selectedButtonIndex = 0;
  String weatherInfo = "Loading...";

  List items = [];
  String status = '';

  String itemKey = '';

  List<String> categoryList = ['経済', 'エンタメ', 'ヘルス', '科学', 'スポーツ', 'テクノロジー'];
  String category = 'business';
  int categoryIndex = 0;

  String url = '';

  Future<void> getData(category) async {
    var url =
        'https://newsapi.org/v2/top-headlines?country=jp&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    //print(url);
    var response = await Dio().get(url);
    status = response.data['status'];
    items = response.data['articles'];
    setState(() {});
    //print(status);
  }

  Future<void> _refreshNews() async {
    await getData(category);
  }

  //ユーザー名の取得
  var userName = '';

  Future<String> getUserName() async {
    DocumentSnapshot responseItem =
        await FirebaseFirestore.instance.doc('test/test').get();
    String userName = responseItem.get("userName");
    return userName;
  }

  //天気情報取得
  Future<double> getPrecipitationIntensity(
      String appId, String coordinates) async {
    final url = Uri.https('map.yahooapis.jp', '/weather/V1/place', {
      'appid': appId,
      'coordinates': coordinates,
      'interval': '10',
      'output': 'json',
    });

    final response = await http.get(url);
    final data = json.decode(response.body);
    return data['Feature'][0]['Property']['WeatherList']['Weather'][0]
        ['Rainfall'];
  }

  String judgeWeather(double precipitationIntensity) {
    if (precipitationIntensity == 0) {
      return '☀️';
    } else if (precipitationIntensity < 2) {
      return '☁️';
    } else {
      return '☂️';
    }
  }

  Future<String> getWheatherInfo() async {
    final appId = 'dj00aiZpPURvU0RNSTBwRzd6ViZzPWNvbnN1bWVyc2VjcmV0Jng9ZTc-';
    final coordinates = '139.7616846,35.6046869';

    final precipitationIntensity =
        await getPrecipitationIntensity(appId, coordinates);
    //print('降水強度: $precipitationIntensity');

    final weather = judgeWeather(precipitationIntensity);
    //print('天気: $weather');

    return weather;
  }

  @override
  void initState() {
    super.initState();
    url =
        'https://newsapi.org/v2/top-headlines?country=jp&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    getData(category);
    initWeatherInfo(); // 初期化メソッドを呼び出します。

    FirebaseFirestore.instance
        .collection('liked_articles')
        .snapshots()
        .listen((snapshot) {
      likedItems.clear();
      for (var doc in snapshot.docs) {
        likedItems.add(doc.id);
      }
      setState(() {});
    });
  }

  void initWeatherInfo() async {
    weatherInfo = await getWheatherInfo();
    setState(() {});
  }

  Future<void> _syncLikedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final likedItemsList = prefs.getStringList('likedItems') ?? [];
    setState(() {
      likedItems = likedItemsList.toSet();
    });
  }

  bool isIconChanged = false;

  //カテゴリーボタンのウィジェット
  Widget buildCategoryList(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Container(
        width: 100,
        child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (selectedButtonIndex == index) {
                switch (categoryList[index]) {
                  case '経済':
                    return Colors.black;
                  case 'エンタメ':
                    return Colors.black;
                  case 'ヘルス':
                    return Colors.black;
                  case '科学':
                    return Colors.black;
                  case 'スポーツ':
                    return Colors.black;
                  case 'テクノロジー':
                    return Colors.black;
                  default:
                    return Colors.black;
                }
              }
              return Colors.white54;
            },
          ), foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (selectedButtonIndex == index) {
                return Colors.white;
              }
              return Colors.black;
            },
          )),
          onPressed: () {
            setState(() {
              selectedButtonIndex = index;
              switch (categoryList[index]) {
                case '経済':
                  category = 'business';
                  categoryIndex = 0;
                  break;
                case 'エンタメ':
                  category = 'entertainment';
                  categoryIndex = 1;
                  break;
                case 'ヘルス':
                  category = 'health';
                  categoryIndex = 2;
                  break;
                case '科学':
                  category = 'science';
                  categoryIndex = 3;
                  break;
                case 'スポーツ':
                  category = 'sports';
                  categoryIndex = 4;
                  break;
                case 'テクノロジー':
                  category = 'technology';
                  categoryIndex = 5;
                  break;
              }
              getData(category);
            });
          },
          child: Text(
            categoryList[index],
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  //ニュース表示のウィジェット
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '東京 $weatherInfo',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            themeNotifier.toggleTheme();
          },
          color: Theme.of(context).iconTheme.color,
          iconSize: 20,
          icon: Icon(
            themeNotifier.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
        toolbarHeight: 38,
        backgroundColor: Theme.of(context).appBarTheme.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              //カテゴリボタンの高さ調整
              height: 30.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                itemBuilder: buildCategoryList,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNews,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    // generate unique itemKey for each article
                    String itemKey = md5
                        .convert(utf8.encode(items[index]['url']))
                        .toString();
                    return Card(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title:
                                Text(items[index]['title'] ?? 'Unknown Title'),
                            subtitle: Text(
                                items[index]['author'] ?? 'Unknown Author'),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                            ),
                            onTap: () async {
                              final url = Uri.parse(
                                  items[index]['url'] ?? 'Unknown Title');
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
