import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:blur/blur.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class MatchScreen extends StatefulWidget {
  UserModel? currentUser, mUser;

  MatchScreen({this.currentUser, this.mUser});
  static  String route = '/encounters/match';

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          Blur(
            blurColor: Colors.transparent,
            blur: 20,
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: QuickActions.photosWidget(widget.mUser!.getAvatar!.url!, borderRadius: 10),
            ),
          ),
          Positioned(
            bottom: 10,
              left: 2,
              right: 2,
              child: Center(
                child: Column(
                  children: [
                    TextWithTap(
                      "encounters_screen.it_is_a_match".tr(),
                      color: kSecondaryColor,
                      fontWeight: FontWeight.w700,
                      textItalic: true,
                      fontSize: 45,
                    ),
                    TextWithTap(
                      "encounters_screen.you_and_her".tr(namedArgs: {"name" : widget.mUser!.getFirstName!}),
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      marginBottom: 80,
                    ),
                    matchedPictures(),
                    ContainerCorner(
                      width: MediaQuery.of(context).size.width,
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      height: 300,
                      borderWidth: 0.0,
                      colors: [Colors.black, Colors.transparent],
                      child: Column(
                        children: [
                          ButtonWithGradient(
                            marginBottom: 25,
                            marginTop: 90,
                            borderRadius: 100,
                            text: "encounters_screen.send_message".tr(),
                            fontSize: 17,
                            marginLeft: 15,
                            marginRight: 15,
                            height: 50,
                            beginColor: kPrimaryColor,
                            endColor: kSecondaryColor,
                            onTap: () => QuickActions.sendMessage(context, widget.currentUser, widget.mUser),
                          ),
                          TextWithTap(
                            "encounters_screen.keep_playing".tr(),
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            onTap: () => QuickHelp.goBackToPreviousPage(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ),],
      ),
    );
  }

  Widget matchedPictures() {
    return Center(
      child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: AlwaysStoppedAnimation(-3.97 / 360),
                  //origin: Offset.infinite,
                  child: Container(
                    height: 213,
                    width: 143,
                    child: QuickActions.photosWidget(widget.currentUser!.getAvatar!.url!, borderRadius: 20),
                  ),
                ),
                RotationTransition(
                  turns: AlwaysStoppedAnimation(6.15 / 360),
                  child: Container(
                    height: 213,
                    width: 143,
                    child: QuickActions.photosWidget(widget.mUser!.getAvatar!.url!, borderRadius: 20),
                  ),
                )
              ],
            ),
            Positioned(
              bottom: 40,
              right: 20,
              left: 20,
              child: SvgPicture.asset("assets/svg/ic_match_heart_encounters.svg"),
            )
            ,]
      ),
    );
  }
}
