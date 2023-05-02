import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: loginPage(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログインページ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignInButton(
              Buttons.Google,
              text: "Sign up with Google",
              onPressed: () {},
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
  List<String> menuItem = ['フランス', '米国', '英国', 'ドイツ', '日本', 'イタリア', 'カナダ'];
  String country = 'jp';
  int countryIndex = 4;

  List<String> categoryList = ['経済', 'エンタメ', 'ヘルス', '科学', 'スポーツ', 'テクノロジー'];
  String category = 'business';
  int categoryIndex = 0;

  String url = '';

  Future<void> getData(country, category) async {
    var url =
        'https://newsapi.org/v2/top-headlines?country=$country&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    //print(url);
    var response = await Dio().get(url);
    status = response.data['status'];
    items = response.data['articles'];
    setState(() {});
    //print(status);
  }

  Future<void> _refreshNews() async {
    await getData(country, category);
  }

  @override
  void initState() {
    super.initState();
    url =
        'https://newsapi.org/v2/top-headlines?country=$country&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    getData(country, category);
  }

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
          getData(country, category);
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

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Container(
        width: 150,
        child: Drawer(
          child: ListView.builder(
            itemCount: menuItem.length,
            itemBuilder: (BuildContext context, int index) {
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      menuItem[index],
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    onTap: () {
                      switch (menuItem[index]) {
                        case 'フランス':
                          country = 'fr';
                          countryIndex = 0;
                          break;
                        case '米国':
                          country = 'us';
                          countryIndex = 1;
                          break;
                        case '英国':
                          country = 'gb';
                          countryIndex = 2;
                          break;
                        case 'ドイツ':
                          country = 'de';
                          countryIndex = 3;
                          break;
                        case '日本':
                          country = 'jp';
                          countryIndex = 4;
                          break;
                        case 'イタリア':
                          country = 'it';
                          countryIndex = 5;
                          break;
                        case 'カナダ':
                          country = 'ca';
                          countryIndex = 6;
                          break;
                      }
                      getData(country, category);
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
      ),
      appBar: AppBar(
        title: Text('${menuItem[countryIndex]}のニュース'),
      ),
      body: Column(
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
                          title: Text(items[index]['title'] ?? 'Unknown Title'),
                          subtitle:
                              Text(items[index]['author'] ?? 'Unknown Author'),
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
    );
  }
}
