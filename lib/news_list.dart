import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:news_app/custom_bottom_bar.dart';
import 'dart:math';

//News閲覧ページ
class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  Set<int> likedItems = {};

  List items = [];
  String status = '';

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
    print('降水強度: $precipitationIntensity');

    final weather = judgeWeather(precipitationIntensity);
    print('天気: $weather');

    return weather;
  }

  @override
  void initState() {
    super.initState();
    url =
        'https://newsapi.org/v2/top-headlines?country=jp&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    getData(category);
  }

  //カテゴリーボタンのウィジェット
  Widget buildCategoryList(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: MenuItemButton(
        onPressed: () {
          print("${categoryList[index]}が選択されました");
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
                                    likedItems.contains(index)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: likedItems.contains(index)
                                        ? Colors.red
                                        : null,
                                  ),
                                  iconSize: 20,
                                  onPressed: () {
                                    //ボタンの表示・非表示
                                    setState(() {
                                      int likedIndex = likedItems.firstWhere(
                                          (element) => element == index,
                                          orElse: () => -1);
                                      if (likedIndex != -1) {
                                        String articleId = 'article_' +
                                            likedIndex
                                                .toString()
                                                .padLeft(3, '0');
                                        likedItems.remove(likedIndex);
                                        FirebaseFirestore.instance
                                            .doc('liked_articles/$articleId')
                                            .delete();
                                      } else {
                                        String articleId = 'article_' +
                                            index.toString().padLeft(3, '0');
                                        likedItems.add(index);
                                        FirebaseFirestore.instance
                                            .doc('liked_articles/$articleId')
                                            .set({
                                          'title': items[index]['title'] ??
                                              'Unknown Title',
                                          'url': items[index]['url'] ??
                                              'Unknown URL',
                                        });
                                      }
                                    });
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
