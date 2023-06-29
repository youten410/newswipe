import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart'; // you might need to add this package to your pubspec.yaml

class ExampleCandidateModel {
  String? title;
  String? link;

  ExampleCandidateModel({
    this.title,
    this.link,
  });
}

ExampleCandidateModel convertRssItemToCandidateModel(RssItem item) {
  return ExampleCandidateModel(
    title: item.title,
    link: item.link,
  );
}

Future<RssFeed> fetchRssFeed(String category, String country) async {
  print(category);
  var response = await http.get(Uri.parse(
      'https://news.google.com/news/rss/headlines/section/topic/$category.ja_jp/%E3%83%93%E3%82%B8%E3%83%8D%E3%82%B9?$country'));
  var channel = RssFeed.parse(response.body);
  return channel;
}

Future<List<ExampleCandidateModel>> fetchCandidateModels(String category, String country) async {
  RssFeed feed = await fetchRssFeed(category, country);
  List<ExampleCandidateModel> candidateModels = feed.items!.map(convertRssItemToCandidateModel).toList();
  return candidateModels;
}
