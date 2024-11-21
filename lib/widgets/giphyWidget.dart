import 'dart:convert';

import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/app/colors.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GiphyWidget extends StatelessWidget {
  final String? search;
  final String apiKey;
  final int? limit;
  final int offset;
  final Function? onTap;
  GiphyWidget({
    this.search = "",
    this.limit = 10,
    this.offset = 0,
    this.onTap,
    required this.apiKey,
  });

  Future<Map> _getGifs({String? search}) async {

    String giphyUrlTrending = "https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=$limit&rating=g";
    String giphyUrlSearch = "https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=";
    String giphyUrlSearchParams = "&limit=$limit&offset=$offset&rating=g&lang=en";

    http.Response response;
    if (search!.isEmpty) {
      response = await http.get(Uri.parse(giphyUrlTrending));
    } else {
      response = await http.get(Uri.parse(
          "${giphyUrlSearch}$search${giphyUrlSearchParams}"));
    }
    return json.decode(response.body);
  }

  Widget showGif(BuildContext context, {String? search}) {

    return ContainerCorner(
      shadowColor: QuickHelp.isDarkMode(context) ? kContentColorGhostTheme : kGreyColor3,
      color: QuickHelp.isDarkMode(context)
          ? kContentColorLightTheme
          : Colors.white,
      height: 97,
      marginLeft: 10,
      marginRight: 10,
      marginTop: 10,
      borderRadius: 10,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(limit!, (index) {
            return FutureBuilder(
                future: _getGifs(search: search),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {

                    return ContainerCorner(
                      color: kTransparentColor,
                      marginTop: 5,
                      marginLeft: 5,
                      height: 80,
                      width: 120,
                      onTap: ()=> onTap!= null ? onTap!(snapshot.data["data"][index]["images"]["fixed_height"]["url"]) as void Function()? : null,
                      borderRadius: 20,
                      child: QuickActions.gifWidget(
                        snapshot.data["data"][index]["images"]
                        ["fixed_height"]["url"],
                        fit: BoxFit.cover,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return ContainerCorner(
                      color: kTransparentColor,
                      marginTop: 5,
                      marginLeft: 5,
                      child: Column(
                        children: [
                          FadeShimmer(
                            height: 80,
                            width: 80,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                            millisecondsDelay: 0,
                          ),
                        ],
                      ),
                    ); //Icon(Icons.error_outline)  freeWidget(thereLikes: true);
                  } else {
                    return ContainerCorner(
                      color: kTransparentColor,
                      marginTop: 5,
                      marginLeft: 5,
                      child: Column(
                        children: [
                          FadeShimmer(
                            height: 80,
                            width: 80,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                            millisecondsDelay: 0,
                          ),
                        ],
                      ),
                    );
                  }
                });
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return showGif(context, search: search);
  }
}
