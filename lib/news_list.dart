import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marquee/marquee.dart';
import 'package:news_app/weather.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert' as convert;
import 'package:webfeed/webfeed.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:news_app/example_candidate_model.dart';
import 'package:news_app/example_card.dart';

Set<String> likedItems = {};
bool isDarkMode = false;

//News閲覧ページ
class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  final AppinioSwiperController controller = AppinioSwiperController();
  late int selectedButtonIndex = 0;
  String weatherInfo = "Loading...";
  String presentLocationName = 'Loading...';

  String splitedAdress = '';

  List items = [];
  String status = '';

  String itemKey = '';

  //drawerに表示するメニュー
  List language = ['Japan', 'US'];

  //カテゴリタブ
  String currentLanguage = '日本語';

  Map<String, List<String>> categoryList = {
    '日本語': ['経済', 'エンタメ', 'ヘルス', '科学', 'スポーツ', 'テクノロジー'],
    'English': [
      'Economy',
      'Entertainment',
      'Health',
      'Science',
      'Technology' 'Sports'
    ]
  };

//カテゴリーボタンのウィジェット
  Widget buildCategoryList(BuildContext context, int index) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Container(
        width: 120,
        child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              //カテゴリボタンのボックスの色　クリックされた時　ダーク/ライト
              if (selectedButtonIndex == index) {
                switch (category) {
                  case '経済':
                  case 'Busiess':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'エンタメ':
                  case 'Entertainment':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'ヘルス':
                  case 'Health':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'サイエンス':
                  case 'Science':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'スポーツ':
                  case 'Sports':
                    return themeNotifier.isDarkMode
                        ? Colors.white
                        : Colors.black;
                  case 'テクノロジー':
                  case 'Technology':
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
            print(
                "${categoryList[currentLanguage]![index].toString()}が選択されました");
            selectedButtonIndex = index;
            switch (categoryList[currentLanguage]![index].toString()) {
              case '経済':
              case 'Busiess':
                category = 'BUSINESS';
                break;
              case 'エンタメ':
              case 'Entertainment':
                category = 'ENTERTAINMENT';
                break;
              case 'ヘルス':
              case 'Health':
                category = 'HEALTH';
                break;
              case 'サイエンス':
              case 'Science':
                category = 'SCIENCE';
                break;
              case 'スポーツ':
              case 'Sports':
                category = 'SPORTS';
                break;
              case 'テクノロジー':
              case 'Technology':
                category = 'TECHNOLOGY';
                break;
            }
            rssFeed = fetchRssFeed(category, country);
            setState(() {});
          },
          child: Text(
            categoryList[currentLanguage]![index].toString(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  String category = 'BUSINESS';
  int categoryIndex = 0;

  String country = 'hl=ja&gl=JP&ceid=JP:ja';
  int countryIndex = 0;

  //記事URL？
  String url = '';

  //ニュースAPIリクエスト
  Future<RssFeed> fetchRssFeed(category, country) async {
    print(category);
    var response = await http.get(Uri.parse(
        'https://news.google.com/news/rss/headlines/section/topic/$category.ja_jp/%E3%83%93%E3%82%B8%E3%83%8D%E3%82%B9?$country'));
    var channel = RssFeed.parse(response.body);
    return channel;
  }

  Future<void> _refreshNews() async {
    await fetchRssFeed(category, country);
  }

  //位置情報取得
  Future<String> getLocation() async {
    try {
      print('位置情報取得開始');
      //アクセス許可要求
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // ユーザーが許可を拒否した場合の処理
          print("Location permissions denied");
          return "Permission denied"; // エラーメッセージを返す
        }
      }

      // ユーザーが許可したら位置情報を取得
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      var location = extractCoordinates(position.toString());
      var keido = location[1];
      var ido = location[0];
      var coordinates = keido.toString() + ',' + ido.toString();

      final googleAPIKey = 'AIzaSyCe5jXTKg2WbntQzK4oO3doAEJS0b5W93o';
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$ido,$keido&key=$googleAPIKey&language=ja'));
      var decodedResponse = json.decode(response.body);

      String address = decodedResponse['plus_code']['compound_code'];

      int separatorIndex = address.lastIndexOf('、');
      splitedAdress = address.substring(separatorIndex + 1);

      print('splitedAdress : $splitedAdress');

      var cityName = decodedResponse['results'][0]['address_components'][3]
              ['long_name']
          .toString();
      var prefectureName = decodedResponse['results'][0]['address_components']
              [2]['long_name']
          .toString();
      presentLocationName = prefectureName + cityName;
      print('場所:$splitedAdress');

      setState(() {});

      print('coordinates : $coordinates');
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
    print(coordinates);
    var latitude = coordinates.split(',')[1];
    var longitude = coordinates.split(',')[0];
    var url =
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&hourly=apparent_temperature,weathercode&forecast_days=1';
    var response = await http.get(Uri.parse(url));
    //天気予報の結果に応じた絵文字のunicodeを受け取る
    var emoji = weatherDescription(response.body);
    return emoji;
  }

  void initWeatherInfo() async {
    print('getLocationの呼び出し');
    String coordinates = await getLocation();
    print('getWheatherInfoの呼び出し');
    print('取得する天気の座標$coordinates');
    weatherInfo = await getWheatherInfo(coordinates);
    setState(() {});
  }

  bool isIconChanged = false;

  bool showMarquee = false;

  late Future<RssFeed> rssFeed;

  @override
  void initState() {
    super.initState();
    getLocation();
    initWeatherInfo();
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        showMarquee = true;
      });
    });
    rssFeed = fetchRssFeed(category, country);
  }

  //ニュース表示のウィジェット
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: showMarquee
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: Marquee(
                  text: '$splitedAdress   $weatherInfo',
                  style: TextStyle(
                      color: themeNotifier.isDarkMode
                          ? Colors.white
                          : Colors.black),
                  velocity: 40,
                  blankSpace: 50,
                ),
              )
            : null,
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
        actions: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                color: Theme.of(context).iconTheme.color,
                iconSize: 20,
                icon: Icon(
                  themeNotifier.isDarkMode
                      ? Icons.language_outlined
                      : Icons.language_outlined,
                  color: themeNotifier.isDarkMode ? Colors.white : Colors.black,
                ),
              );
            },
          ),
        ],
        toolbarHeight: 38,
        titleTextStyle: Theme.of(context).primaryTextTheme.headline6,
      ),
      endDrawer: Drawer(
          backgroundColor:
              themeNotifier.isDarkMode ? Colors.black : Colors.white,
          child: ListView.builder(
            itemCount: language.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      language[index],
                      style: TextStyle(
                        fontSize: 18,
                        color: themeNotifier.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    onTap: () {
                      switch (language[index]) {
                        case 'Japan':
                          country = 'hl=ja&gl=JP&ceid=JP:ja';
                          currentLanguage = '日本語';
                          break;
                        case 'US':
                          country = 'hl=en-US&gl=US&ceid=US:en';
                          currentLanguage = 'English';
                          break;
                      }
                      rssFeed = fetchRssFeed(category, country);
                      print('国:$country カテゴリ:$category');
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  Divider(
                    color: Colors.grey.shade400,
                  ),
                ],
              );
            },
          )),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              //カテゴリボタンの高さ調整
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: buildCategoryList,
                padding: EdgeInsets.only(bottom: 5),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ExampleCandidateModel>>(
                future: fetchCandidateModels(category,country),
                builder: (BuildContext context,
                    AsyncSnapshot<List<ExampleCandidateModel>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child:
                            CircularProgressIndicator()); // ダイアログ表示
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error: ${snapshot.error}')); // エラー表示
                  } else {
                    var candidates = snapshot.data;
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.50,
                      child: AppinioSwiper(
                        backgroundCardsCount: 2,
                        swipeOptions: const AppinioSwipeOptions.all(),
                        unlimitedUnswipe: true,
                        controller: controller,
                        onSwiping: (AppinioSwiperDirection direction) {
                          debugPrint(direction.toString());
                        },
                        padding: const EdgeInsets.only(
                          left: 25,
                          right: 25,
                          top: 50,
                          bottom: 40,
                        ),
                        cardsCount: candidates!.length,
                        cardsBuilder: (BuildContext context, int index) {
                          return ExampleCard(candidate: candidates[index]);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
