import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  String presentLocationName = 'Loading...';

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

  //天気情報取得
  Future<double> getPrecipitationIntensity(
      String appId, String coordinates) async {
    print('coordinates : $coordinates');
    final url = Uri.https('map.yahooapis.jp', '/weather/V1/place', {
      'appid': appId,
      'coordinates': coordinates,
      'interval': '10',
      'output': 'json',
    });

    final response = await http.get(url);
    final data = json.decode(response.body);
    print(data);
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

  //位置情報取得
  Future<String> getLocation() async {
    try {
      print('位置情報取得開始');
      //アクセス許可要求
      // LocationPermission permission = await Geolocator.checkPermission();
      // if (permission == LocationPermission.denied) {
      //   permission = await Geolocator.requestPermission();
      //   if (permission == LocationPermission.denied) {
      //     // ユーザーが許可を拒否した場合の処理
      //     print("Location permissions denied");
      //     return "Permission denied"; // エラーメッセージを返す
      //   }
      // }

      // ユーザーが許可したら位置情報を取得
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      var location = extractCoordinates(position.toString());
      var keido = '133.6137351299371'; //location[1];
      var ido = '33.535685882374985'; //location[0];
      var coordinates = keido + ',' + ido;

      print(coordinates);

      final googleAPIKey = 'AIzaSyCe5jXTKg2WbntQzK4oO3doAEJS0b5W93o';
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$ido,$keido&key=$googleAPIKey&language=ja'));
      var decodedResponse = json.decode(response.body);
      var cityName = decodedResponse['results'][0]['address_components'][1]
              ['long_name']
          .toString();
      var prefectureName = decodedResponse['results'][0]['address_components']
              [2]['long_name']
          .toString();
      presentLocationName = prefectureName + cityName;

      print('場所:$presentLocationName');

      return coordinates;
    } catch (e) {
      print(e);
      return "Error: $e";
    }
  }

  //正規表現で緯度、軽度を抽出
  List<String> extractCoordinates(String location) {
    RegExp latExp = RegExp(r'Latitude: (\d+\.\d+)', multiLine: true);
    RegExp lonExp = RegExp(r'Longitude: (\d+\.\d+)', multiLine: true);

    Match? latMatch = latExp.firstMatch(location);
    Match? lonMatch = lonExp.firstMatch(location);

    String? lat = latMatch?.group(1);
    String? lon = lonMatch?.group(1);

    if (lat == null || lon == null) {
      throw Exception('Failed to extract coordinates');
    }

    return [lat, lon];
  }

  //天気情報取得パラメータ
  Future<String> getWheatherInfo(String coordinates) async {
    print('天気情報取得開始');
    final appId = 'dj00aiZpPURvU0RNSTBwRzd6ViZzPWNvbnN1bWVyc2VjcmV0Jng9ZTc-';
    final precipitationIntensity =
        await getPrecipitationIntensity(appId, coordinates);
    print('降水強度: $precipitationIntensity');

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
    getLocation();
    initWeatherInfo();
  }

  void initWeatherInfo() async {
    print('getLocationの呼び出し');
    String coordinates = await getLocation();
    print('getWheatherInfoの呼び出し');
    weatherInfo = await getWheatherInfo(coordinates);
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
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
                    //カテゴリボタンのボックスの色　クリックされた時　ダーク/ライト
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'エンタメ':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'ヘルス':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case '科学':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'スポーツ':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'テクノロジー':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  default:
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                }
              }
              //カテゴリボタンのボックスの色　クリックされていない時　ダーク/ライト
              return themeNotifier.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.white;
            },
          ), foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (selectedButtonIndex == index) {
                //カテゴリボタンのクリックされた時の色　ライト/ダーク
                return themeNotifier.isDarkMode ? Colors.black : Colors.white;
              }
              //カテゴリボタンのクリックされていない時の色　ライト/ダーク
              return themeNotifier.isDarkMode ? Colors.white : Colors.black;
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
        elevation: 0.0,
        title: Text(
          //天気アイコンのサイズ変更
          '$presentLocationName $weatherInfo',
          style: TextStyle(
              color: themeNotifier.isDarkMode ? Colors.white : Colors.black),
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
            color: themeNotifier.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        toolbarHeight: 38,
        titleTextStyle: Theme.of(context).primaryTextTheme.headline6,
        //backgroundColor: Theme.of(context).appBarTheme.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              //カテゴリボタンの高さ調整
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                itemBuilder: buildCategoryList,
                padding: EdgeInsets.only(bottom: 5),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNews,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    // generate unique itemKey for each article
                    String itemKey = md5
                        .convert(utf8.encode(items[index]['url']))
                        .toString();
                    return Card(
                      color: themeNotifier.isDarkMode
                          ? Colors.grey.shade800
                          : Colors.white,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              items[index]['title'] ?? 'Unknown Title',
                              style: TextStyle(
                                  color: themeNotifier.isDarkMode
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            subtitle: Text(
                                items[index]['author'] ?? 'Unknown Author'),
                            textColor: themeNotifier.isDarkMode
                                ? Colors.white
                                : Colors.black,
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
