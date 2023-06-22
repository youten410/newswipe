import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  getData('business');
}

Future<void> getData(category) async {
  print('start');
  //print(url);
  final response = await http.get(Uri.parse(
      'https://newsapi.org/v2/top-headlines?country=jp&category=$category&apiKey=d29107383eac4c97989831bb265caaaa'));
  var newsData = json.decode(response.body);
  //print(newsData);

  var status = newsData['status'];
  var items = newsData['articles'];
  print(status);
  print(items);
  print('finish');
}
