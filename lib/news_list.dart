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
import 'package:news_app/custom_bottom_bar.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:news_app/favorite_article.dart';

Set<String> likedItems = {};

//News閲覧ページ
class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {

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

  FirebaseFirestore.instance.collection('liked_articles').snapshots().listen((snapshot) {
    likedItems.clear();
    for (var doc in snapshot.docs) {
      likedItems.add(doc.id);
    }
    setState(() {});
  });
}

  Future<void> _syncLikedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final likedItemsList = prefs.getStringList('likedItems') ?? [];
    setState(() {
      likedItems = likedItemsList.toSet();
    });
  }

  //カテゴリーボタンのウィジェット
  Widget buildCategoryList(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: MenuItemButton(
        onPressed: () {
          //print("${categoryList[index]}が選択されました");
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
        },
        child: Text(
          categoryList[index],
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  //ニュース表示のウィジェット
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: getWheatherInfo(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('エラー: ${snapshot.error}');
            } else {
              return Text('東京 ${snapshot.data}');
            }
          },
        ),
        toolbarHeight: 38,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: 50.0,
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
                              children: [
                                //いいねボタン
                                IconButton(
                                  icon: Icon(
                                    likedItems.contains(itemKey)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: likedItems.contains(itemKey)
                                        ? Colors.red
                                        : null,
                                  ),
                                  iconSize: 20,
                                  onPressed: () async {
                                    itemKey = md5
                                        .convert(
                                            utf8.encode(items[index]['url']))
                                        .toString();

                                    if (likedItems.contains(itemKey)) {
                                      likedItems.remove(itemKey);
                                      await FirebaseFirestore.instance
                                          .doc('liked_articles/$itemKey')
                                          .delete();
                                    } else {
                                      likedItems.add(itemKey);
                                      await FirebaseFirestore.instance
                                          .doc('liked_articles/$itemKey')
                                          .set({
                                        'title': items[index]['title'] ??
                                            'Unknown Title',
                                        'url': items[index]['url'] ??
                                            'Unknown URL',
                                      });
                                    }

                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setStringList(
                                        'likedItems', likedItems.toList());

                                    setState(() {});
                                    //likedItems.clear();
                                    print(likedItems);
                                  },
                                )
                              ],
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
      bottomNavigationBar: CustomBottomAppBar(),
    );
  }
}
