import 'package:blur/blur.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/coins/web_subscriptions.dart';
import 'package:heyto/home/encounters/match_screen.dart';
import 'package:heyto/home/tickets/tickets_screen.dart';
import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_logo.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

// ignore: must_be_immutable
class LikesScreen extends StatefulWidget {
  static String route = '/home/likes';
  UserModel? currentUser;

  LikesScreen({this.currentUser});

  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  String? credits;
  List<dynamic> globalUsers = [];

  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>?> loadUser() async {
    QueryBuilder<EncountersModel> encountersQuery =
        QueryBuilder<EncountersModel>(EncountersModel());
    encountersQuery.whereEqualTo(EncountersModel.keyToUser, widget.currentUser);
    encountersQuery.whereEqualTo(EncountersModel.keySeen, false);
    encountersQuery.whereEqualTo(EncountersModel.keyLiked, true);
    encountersQuery.includeObject(
        [EncountersModel.keyFromUser, EncountersModel.keyToUser]);

    ParseResponse apiResponse = await encountersQuery.query();
    if (apiResponse.success) {
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as List<dynamic>;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.likes_title".tr());

    setState(() {
      credits = widget.currentUser!.getCredits.toString();
    });

    return ToolBarCenterLogo(
      logoName: 'ic_logo.png',
      logoWidth: 80,
      iconHeight: 24,
      iconWidth: 24,
      leadingWidth: 100,
      leftButtonWidget: ContainerCorner(
        marginBottom: 10,
        marginTop: 10,
        borderRadius: 50,
        width: 150,
        marginLeft: 10,
        color: Colors.black,
        onTap: () async {
          if (Setup.isPaymentsDisabledOnWeb) return;
          UserModel result = await QuickHelp.goToNavigatorScreenForResult(
              context,
              TicketsScreen(
                currentUser: widget.currentUser,
              ),
              route: TicketsScreen.route);

          //result as UserModel
          print("result: ${result.objectId}");

          widget.currentUser = result;

          setState(() {
            credits = widget.currentUser!.getCredits.toString();
          });
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, top: 10, bottom: 10, right: 3),
              child: SvgPicture.asset(
                "assets/svg/ticket_icon.svg",
                height: 24,
                width: 24,
              ),
            ),
            Expanded(
                child: TextWithTap(
              credits!,
              color: Colors.white,
            )),
          ],
        ),
      ),
      leftButtonPress: () {
        if (Setup.isPaymentsDisabledOnWeb) return;
        QuickHelp.goToNavigatorScreen(
            context,
            TicketsScreen(
              currentUser: widget.currentUser,
            ),
            route: TicketsScreen.route);
      },
      child: Responsive.isWebOrDeskTop(context) ? webBody() : gridOfLikes(),
    );
  }

  Widget webBody() {
    return ContainerCorner(
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: WebSubscriptions(
              currentUser: widget.currentUser,
            ),
          ),
          Flexible(
            flex: 8,
            child: gridOfLikes(),
          ),
        ],
      ),
    );
  }

  Widget gridOfLikes() {
    return FutureBuilder(
        future: loadUser(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            globalUsers = snapshot.data as List<dynamic>;
            return Padding(
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Column(
                children: [
                  chooserWidget(),
                  Expanded(
                    child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          //maxCrossAxisExtent: size.width /2,
                          childAspectRatio:
                              Responsive.isWebOrDeskTop(context) ? 0.8 : 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          crossAxisCount: Responsive.isWebOrDeskTop(context)
                              ? 4
                              : Responsive.isTablet(context)
                                  ? 3
                                  : 2,
                        ),
                        itemCount: globalUsers.length,
                        itemBuilder: (BuildContext ctx, index) {
                          return Column(
                            children: [
                              Flexible(
                                flex: 2,
                                child: Stack(
                                  children: [
                                    if (widget.currentUser!.isPremium!)
                                      ContainerCorner(
                                        radiusBottomLeft: 10,
                                        radiusBottomRight: 10,
                                        radiusTopRight: 10,
                                        radiusTopLeft: 10,
                                        child: QuickActions.photosWidget(
                                            globalUsers[index]
                                                .getAuthor!
                                                .getAvatar!
                                                .url!,
                                            borderRadius: 10),
                                        onTap: () =>
                                            QuickActions.showUserProfile(
                                                context,
                                                globalUsers[index].getAuthor),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () {
                                          if (Setup.isPaymentsDisabledOnWeb)
                                            return;
                                          QuickHelp.goToNavigatorScreen(
                                              context,
                                              TicketsScreen(
                                                currentUser: widget.currentUser,
                                              ),
                                              route: TicketsScreen.route);
                                        },
                                        child: Blur(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          blurColor: Colors.transparent,
                                          blur: 10,
                                          child: ContainerCorner(
                                            child: QuickActions.photosWidget(
                                                globalUsers[index]
                                                    .getAuthor!
                                                    .getAvatar!
                                                    .url!,
                                                borderRadius: 10),
                                          ),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: ContainerCorner(
                                        radiusTopRight: 10,
                                        radiusTopLeft: 10,
                                        radiusBottomRight: 10,
                                        radiusBottomLeft: 10,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        height: 70,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            QuickHelp.isUserOnline(
                                                    globalUsers[index]
                                                        .getAuthor)
                                                ? Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Row(children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              kTicketBlueColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                          widget.currentUser!
                                                                  .isPremium!
                                                              ? globalUsers[
                                                                      index]
                                                                  .getAuthor!
                                                                  .getFirstName!
                                                              : "likes_screen.recently_active"
                                                                  .tr(),
                                                          style: TextStyle(
                                                            fontSize: 14.0,
                                                            color: Colors.white,
                                                          )),
                                                    ]),
                                                  )
                                                : Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Row(children: [
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      Text(
                                                          widget.currentUser!
                                                                  .isPremium!
                                                              ? globalUsers[
                                                                      index]
                                                                  .getAuthor!
                                                                  .getFirstName!
                                                              : "",
                                                          style: TextStyle(
                                                            fontSize: 14.0,
                                                            color: Colors.white,
                                                          )),
                                                    ]),
                                                  )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
                child:
                    noLikes()); //Icon(Icons.error_outline)  freeWidget(thereLikes: true);
          } else {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.count(
                crossAxisCount: Responsive.isWebOrDeskTop(context)
                    ? 4
                    : Responsive.isTablet(context)
                        ? 3
                        : 2,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio:
                    Responsive.isWebOrDeskTop(context) ? 0.7 : 0.8,
                children: List.generate(
                    16,
                    (index) => FadeShimmer(
                          height: 100,
                          width: 100,
                          radius: 10,
                          millisecondsDelay: 0,
                          fadeTheme: QuickHelp.isDarkMode(context)
                              ? FadeTheme.dark
                              : FadeTheme.light,
                        )),
              ),
            );
          }
        });
  }

  Widget chooserWidget() {
    if (widget.currentUser!.isPremium!) {
      return premiumWidget();
    } else {
      return freeWidget();
    }
  }

  like(UserModel userModel) async {
    EncountersModel encountersModel = EncountersModel();
    encountersModel.setAuthor = widget.currentUser!;
    encountersModel.setAuthorId = widget.currentUser!.objectId!;

    encountersModel.setReceiver = userModel;
    encountersModel.setReceiverId = userModel.objectId!;

    encountersModel.setSeen = false;
    encountersModel.setLike = true;

    var parseResponse = await encountersModel.save();

    if (parseResponse.success) {
      SendNotifications.sendPush(
        widget.currentUser!,
        userModel,
        SendNotifications.typeLiked,
      );

      QueryBuilder<EncountersModel> encountersQueryBuilder =
          QueryBuilder<EncountersModel>(EncountersModel());
      encountersQueryBuilder.whereEqualTo(
          EncountersModel.keyFromUser, userModel);
      encountersQueryBuilder.whereEqualTo(
          EncountersModel.keyToUser, widget.currentUser);
      encountersQueryBuilder.whereEqualTo(EncountersModel.keyLiked, true);

      var encounterResponse = await encountersQueryBuilder.query();
      if (encounterResponse.success && encounterResponse.results != null) {
        var user = encounterResponse.results!.first;

        if (user != null) {
          user.setSeen = true;
          var userResult = await user.save();

          if (userResult.success) {
            encountersModel.setSeen = true;
            encountersModel.save();

            SendNotifications.sendPush(
              widget.currentUser!,
              userModel,
              SendNotifications.typeMatch,
            );

            QuickHelp.goToNavigatorScreen(
                context,
                MatchScreen(
                  currentUser: widget.currentUser,
                  mUser: userModel,
                ),
                route: MatchScreen.route);
          }
        }
      }
    }
  }

  dislike(UserModel userModel) async {
    EncountersModel encountersModel = EncountersModel();
    encountersModel.setAuthor = widget.currentUser!;
    encountersModel.setAuthorId = widget.currentUser!.objectId!;

    encountersModel.setReceiver = userModel;
    encountersModel.setReceiverId = userModel.objectId!;

    encountersModel.setSeen = true;
    encountersModel.setLike = false;
    var parseResponse = await encountersModel.save();

    if (parseResponse.success) {
      QueryBuilder<EncountersModel> encountersQueryBuilder =
          QueryBuilder<EncountersModel>(EncountersModel());
      encountersQueryBuilder.whereEqualTo(
          EncountersModel.keyFromUser, userModel);
      encountersQueryBuilder.whereEqualTo(
          EncountersModel.keyToUser, widget.currentUser);

      var encounterResponse = await encountersQueryBuilder.query();
      if (encounterResponse.success && encounterResponse.results != null) {
        var user = encounterResponse.results!.first;

        if (user != null) {
          user.setSeen = true;
          user.save();
        }
      }
    }
  }

  Widget premiumWidget() {
    return TextWithTap(
      "likes_screen.likes_counter"
          .tr(namedArgs: {"likes": globalUsers.length.toString()}),
      color: kDisabledGrayColor,
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      alignment: Alignment.topLeft,
      marginBottom: 17,
      marginLeft: 5,
    );
  }

  Widget freeWidget() {
    return Column(
      children: [
        widget.currentUser!.isPremium!
            ? Text('')
            : TextWithTap(
                "likes_screen.starts_upgrade"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                marginTop: 15,
                marginBottom: 10,
                fontSize: 14,
                alignment: Alignment.center,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: QuickHelp.isDarkModeNoContext()
                    ? Colors.white
                    : Colors.black,
              ),
        widget.currentUser!.isPremium!
            ? Text('')
            : ContainerCorner(
                height: 46,
                marginBottom: 17,
                marginTop: 5,
                marginLeft: 20,
                marginRight: 20,
                borderRadius: 70,
                width: Responsive.isWebOrDeskTop(context) ? 350 : null,
                colors: [kPrimaryColor, kSecondaryColor],
                shadowColor: QuickHelp.isDarkMode(context)
                    ? kContentColorGhostTheme
                    : kGrayColor.withOpacity(0.5),
                setShadowToBottom: false,
                alignment: Alignment.center,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                blurRadius: 5,
                spreadRadius: 0.5,
                child: TextWithTap(
                  "likes_screen.who_likes_you".tr(),
                  fontSize: 17,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                onTap: () {
                  if (Setup.isPaymentsDisabledOnWeb) return;
                  QuickHelp.goToNavigatorScreen(
                      context,
                      TicketsScreen(
                        currentUser: widget.currentUser,
                      ),
                      route: TicketsScreen.route);
                },
              ),
        TextWithTap(
          "likes_screen.likes_counter"
              .tr(namedArgs: {"likes": globalUsers.length.toString()}),
          marginBottom: 17,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
        widget.currentUser!.isPremium!
            ? TextWithTap(
                "likes_screen.people_who_you_like".tr(),
                marginBottom: 17,
                marginTop: 20,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kGreyColor1,
              )
            : Text(''),
      ],
    );
  }

  Widget noLikes() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ContainerCorner(
          height: 91,
          width: 91,
          marginBottom: 20,
          color: kTransparentColor,
          child: SvgPicture.asset("assets/svg/favorite.svg"),
        ),
        TextWithTap(
          "likes_screen.likes_counter"
              .tr(namedArgs: {"likes": globalUsers.length.toString()}),
          marginBottom: 17,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
        TextWithTap(
          "likes_screen.people_who_you_like".tr(),
          marginBottom: 17,
          marginTop: 20,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kGreyColor1,
        )
      ],
    );
  }
}
