import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

class ExampleCandidateModel {
  String? title;
  String? link;
  String? img;

  ExampleCandidateModel({
    this.title,
    this.link,
    this.img
  });
}

ExampleCandidateModel convertRssItemToCandidateModel(RssItem item) {
  return ExampleCandidateModel(
    title: item.title,
    link: item.link,
  );
}

Future<RssFeed> fetchRssFeed(String category) async {
  print('URL : https://news.mynavi.jp/rss/$category');
  var response = await http.get(Uri.parse(
      'https://news.mynavi.jp/rss/$category'));
  var channel = RssFeed.parse(response.body);
  return channel;
}

Future<List<ExampleCandidateModel>> fetchCandidateModels(String category, String country) async {
  RssFeed feed = await fetchRssFeed(category);
  List<ExampleCandidateModel> candidateModels = feed.items!.map(convertRssItemToCandidateModel).toList();
  return candidateModels;
}
