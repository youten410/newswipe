import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'example_candidate_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:news_app/main.dart';

class ExampleCard extends StatelessWidget {
  final ExampleCandidateModel candidate;
  final int cardIndex;
  final int totalCards;

  const ExampleCard({
    Key? key,
    required this.candidate,
    required this.cardIndex,
    required this.totalCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: themeNotifier.isDarkMode ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3),
          )
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              //カード本体の色
              color: themeNotifier.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 5,
                ),
                Text(
                  candidate.title!,
                  style: TextStyle(
                    color:
                        themeNotifier.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    if (await canLaunch(candidate.link!)) {
                      await launch(candidate.link!);
                    }
                  },
                  child: Text(
                    candidate.link!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                //カード枚数表示
                Center(
                  child: Text(
                    '${cardIndex + 1} / $totalCards',
                    style: TextStyle(
                      color: themeNotifier.isDarkMode
                          ? Colors.white
                          : Colors.black,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
