import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'example_candidate_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:news_app/main.dart';

class ExampleCard extends StatelessWidget {
  final ExampleCandidateModel candidate;

  const ExampleCard({
    Key? key,
    required this.candidate,
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
                Text(
                  candidate.title!,
                  style: TextStyle(
                    color:
                        themeNotifier.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(
                  height: 5,
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
                      color: Colors
                          .blue, // Change the color to indicate that it's a link
                      fontSize: 15,
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
