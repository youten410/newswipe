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

  @override
  void initState() {
    super.initState();
    url =
        'https://newsapi.org/v2/top-headlines?country=jp&category=$category&apiKey=d29107383eac4c97989831bb265caaaa';
    getData(category);
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ニュース'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // ログアウト処理
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return loginPage();
                }),
              );
            },
            child: Text(
              'ログアウト',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
