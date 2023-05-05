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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NewsApp(),
    );
  }
}

//ログインページ
class loginPage extends StatefulWidget {
  const loginPage({super.key});
  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  // Googleを使ってサインイン
  Future<User> signInWithGoogle() async {
    // 認証フローのトリガー
    final googleUser = await GoogleSignIn(scopes: [
      'email',
    ]).signIn();
    // リクエストから、認証情報を取得
    final googleAuth = await googleUser!.authentication;
    // クレデンシャルを新しく作成
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // サインインしたら、Userを返す
    return (await FirebaseAuth.instance.signInWithCredential(credential)).user!;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ログイン',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignInButton(
              Buttons.Google,
              onPressed: () async {
                try {
                  final user = await signInWithGoogle();
                  print('ユーザー名: ${user.displayName}');
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) {
                      return NewsApp();
                    }),
                  );
                } on FirebaseAuthException catch (e) {
                  print('FirebaseAuthException');
                  print('${e.code}');
                } on Exception catch (e) {
                  print('Exception');
                  print('${e.toString()}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

//News閲覧ページ
class NewsApp extends StatefulWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  State<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
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
                            trailing: Icon(Icons.arrow_forward),
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
      bottomNavigationBar: _BottomAppBar(),
    );
  }
}

class _BottomAppBar extends StatelessWidget {
  const _BottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;

  static final List<FloatingActionButtonLocation> centerLocations =
      <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
      color: Colors.blue,
      // ignore: sort_child_properties_last
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Open navigation menu',
              icon: const Icon(Icons.menu),
              onPressed: () {
                //menu
              },
            ),
            if (centerLocations.contains(fabLocation)) const Spacer(),
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              tooltip: 'Favorite',
              icon: const Icon(Icons.favorite),
              onPressed: () {
              },
            ),
          ],
        ),
      ),
      height: 60,
    );
  }
}
