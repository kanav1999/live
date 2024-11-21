import 'dart:math';

import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FindPeopleAround extends StatefulWidget {
  final UserModel? currentUser;

  FindPeopleAround({Key? key, this.currentUser}) : super(key: key);

  @override
  _FindPeopleAroundState createState() => _FindPeopleAroundState();
}

class _FindPeopleAroundState extends State<FindPeopleAround>
    with TickerProviderStateMixin {
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(duration: Duration(seconds: 3), vsync: this)
          ..repeat();
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween(begin: 0, end: 2 * pi).animate(controller!);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(alignment: AlignmentDirectional.center, children: [
            AnimatedBuilder(
                animation: animation,
                child: ContainerCorner(
                  height: 325,
                  width: 325,
                  marginRight: 15,
                  marginLeft: 15,
                  color: kTransparentColor,
                  child: Image.asset("assets/images/ic_radar_encounters.png"),
                ),
                builder: (BuildContext context, Widget? child) {
                  return Transform.rotate(
                    angle: controller!.value * 2.0 * pi,
                    child: child,
                  );
                }),
            Container(
              width: 120,
              height: 120,
              child: QuickActions.avatarWidget(widget.currentUser!),
            ),
            Positioned(
              left: 30,
              child: ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 50,
                  marginRight: 100,
                  marginBottom: 10,
                  child: SvgPicture.asset(
                    "assets/svg/ic_fill_heart.svg",
                    width: 15,
                    height: 15,)
              ),
            ),
            Positioned(
              right: 20,
              bottom: 10,
              child: ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 50,
                  marginRight: 100,
                  marginBottom: 10,
                  child: SvgPicture.asset(
                    "assets/svg/ic_fill_heart.svg",
                    width: 20,
                    height: 20,)
              ),
            ),
            Positioned(
              top: -20,
              right: 10,
              child: ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 50,
                  marginRight: 100,
                  marginBottom: 10,
                  child: SvgPicture.asset(
                    "assets/svg/ic_fill_heart.svg",
                    width: 30,
                    height: 30,)
              ),
            ),
          ]),
          TextWithTap(
            "encounters_screen.finding_people".tr(),
            marginTop: 20,
            color: kGreyColor1,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          )
        ],
      ),
    );
  }
}
