import 'dart:convert';

String weatherDescription(jsonData) {
  var data = json.decode(jsonData);

  List<int> weatherCodes = List<int>.from(data['hourly']['weathercode']);
  
  Map<int, String> weatherDictionary = {
    0: "晴れ",
    1: "晴れ",
    2: "晴れがかり",
    3: "曇りがかり",
    4: "曇り",
    5: "曇り",
    6: "曇り",
    7: "霧",
    8: "雨または雪",
    51: "霧雨",  // SYNOPコードには存在しないため仮に追加
  };

  int morningWeatherCode = weatherCodes[8];  // 8:00の天気
  int afternoonWeatherCode = weatherCodes[14];  // 14:00の天気
  int eveningWeatherCode = weatherCodes[20];  // 20:00の天気

  String morningWeather = weatherDictionary[morningWeatherCode] ?? "不明";
  String afternoonWeather = weatherDictionary[afternoonWeatherCode] ?? "不明";
  String eveningWeather = weatherDictionary[eveningWeatherCode] ?? "不明";

  return "今日の天気は、午前中は${morningWeather}、午後は${afternoonWeather}、そして夕方は${eveningWeather}と予想されます。";
}
