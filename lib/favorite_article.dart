import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:news_app/news_list.dart';

class FavoriteArticle extends StatefulWidget {
  const FavoriteArticle({Key? key}) : super(key: key);

  @override
  State<FavoriteArticle> createState() => _FavoriteArticleState();
}

class _FavoriteArticleState extends State<FavoriteArticle> {
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  Future<QuerySnapshot> getCollections() async {
    return await _firestore.collection("liked_articles").get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('お気に入り'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: getCollections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(doc['title'] ?? 'Unknown Title'),
                      trailing:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(Icons.restore_from_trash),
                          onPressed: () {
                            //ニュースをお気に入りから消す
                            setState(() {
                              FirebaseFirestore.instance
                                  .doc('liked_articles/${doc.id}')
                                  .delete();
                            });
                          },
                        )
                      ]),
                      onTap: () async {
                        final url = Uri.parse(doc['url'] ?? 'Unknown Title');
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
          );
        },
      ),
    );
  }
}
