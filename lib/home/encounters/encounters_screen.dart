import 'package:carousel_slider/carousel_slider.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/chats/responsive_chat.dart';
import 'package:heyto/home/encounters/find_people_around.dart';
import 'package:heyto/home/encounters/match_screen.dart';
import 'package:heyto/home/encounters/none_around.dart';
import 'package:heyto/home/tickets/tickets_screen.dart';
import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/ReportModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/update_user_provider.dart';
import 'package:heyto/ui/app_bar_center_logo.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_swipecards/flutter_swipecards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:provider/src/provider.dart';

import '../../providers/counter_providers.dart';
import '../../ui/button_rounded_outline.dart';
import '../../ui/rounded_gradient_button.dart';
import '../home_screen.dart';
import '../location/add_city_screen_force.dart';
import '../location/location_settings_screen.dart';

// ignore: must_be_immutable
class EncountersScreen extends StatefulWidget {
  static String route = '/home/encounters';

  UserModel? currentUser;

  EncountersScreen({this.currentUser, Key? key}): super(key: key);

  @override
  _EncountersScreenState createState() => _EncountersScreenState();
}

class _EncountersScreenState extends State<EncountersScreen> {
  //List<String> isSelected = [UserModel.keyGenderMale, UserModel.keyGenderFemale, UserModel.keyGenderBoth];
  List<bool> isSelected = List.generate(3, (index) => false);

  int heightValue = Setup.minDistanceBetweenUsers;
  RangeValues? values;

  String? userId;

  //UserModel? selectedUser;
  List<dynamic> globalUsers = [];
  String? credits;

  CardController cardController = CardController();
  var _future;

  @override
  void initState() {
    _future = loadUser();

    super.initState();
    // _getUser();
  }

  _save() async {
    // Save gender preferences
    if (isSelected[0] == true) {
      widget.currentUser!.setGenderPref = UserModel.keyGenderMale;
    } else if (isSelected[1] == true) {
      widget.currentUser!.setGenderPref = UserModel.keyGenderFemale;
    } else if (isSelected[2] == true) {
      widget.currentUser!.setGenderPref = UserModel.keyGenderBoth;
    }

    // Save Age range
    widget.currentUser!.setPrefMinAge = this.values!.start.round().toInt();
    widget.currentUser!.setPrefMaxAge = this.values!.end.round().toInt();

    // Save Distance
    widget.currentUser!.setPrefDistance = this.heightValue;

    QuickHelp.showLoadingDialog(context);

    ParseResponse parseResponse = await widget.currentUser!.save();
    if (parseResponse.success) {
      widget.currentUser = parseResponse.results!.first;
      widget.currentUser = parseResponse.results!.first;

      QuickHelp.goBackToPreviousPage(context);
      QuickHelp.goBackToPreviousPage(context);

      context.read<UpdateUserProvider>().updateUser(parseResponse.results!.first!);
      context.read<CountersProvider>().setTabIndex(HomeScreen.tabHome);

      setState(() {
        _future = loadUser();
      });
    }
  }

  _clearAll(StateSetter setState) {
    setState(() {
      if (widget.currentUser!.getGenderPref! == UserModel.keyGenderMale) {
        this.isSelected[0] = true;
        this.isSelected[1] = false;
        this.isSelected[2] = false;
      } else if (widget.currentUser!.getGenderPref! ==
          UserModel.keyGenderFemale) {
        this.isSelected[0] = false;
        this.isSelected[1] = true;
        this.isSelected[2] = false;
      } else if (widget.currentUser!.getGenderPref! ==
          UserModel.keyGenderBoth) {
        this.isSelected[0] = false;
        this.isSelected[1] = false;
        this.isSelected[2] = true;
      }
      this.values = RangeValues(widget.currentUser!.getPrefMinAge!.toDouble(),
          widget.currentUser!.getPrefMaxAge!.toDouble());
      this.heightValue = widget.currentUser!.getPrefDistance!;
    });
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

  bool showReportAndRemoveScreen = true;
  bool showUnblockUserScreen = false;

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.encounters_title".tr());

    setState(() {
      credits = widget.currentUser!.getCredits.toString();
    });

    return ToolBarCenterLogo(
      logoName: 'ic_logo.png',
      logoWidth: 80,
      iconHeight: 20,
      iconWidth: 20,
      leadingWidth: 100,
      rightIconColor: kColorsGrey600,
      afterLogoIconColor: kColorsGrey600,
      leftButtonWidget: ContainerCorner(
        height: 20,
        marginBottom: 10,
        marginTop: 10,
        borderRadius: 20,
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
      rightButtonAsset: "ic_nav_filter.svg",
      rightButtonPress: () {
        _showBottomSheet(context, widget.currentUser!);
      },
      child: widget.currentUser!.getGeoPoint != null ?
      SafeArea(
        child: FutureBuilder(
            future: _future, //loadUser(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                globalUsers = snapshot.data as List<dynamic>;
                return Responsive.isMobile(context) || Responsive.isTablet(context) ? getBody() : webBody();

              } else if (snapshot.hasError) {
                return NoneAround(
                  currentUser: widget.currentUser!,
                );
              } else {

                return FindPeopleAround(
                  currentUser: widget.currentUser!,
                );
              }
            }),
      ) : getLocationScreen(),
    );
  }

  Widget getLocationScreen() {
    var size = MediaQuery.of(context).size;

    return Responsive.isMobile(context)
        ? body()
        : Center(
            child: ContainerCorner(
              width: 400,
              height: size.height,
              borderRadius: 10,
              marginBottom: 20,
              marginTop: 20,
              borderColor: kDisabledGrayColor,
              child: body(),
            ),
          );
  }

  Widget body() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              TextWithTap(
                "ups_".tr(),
                marginTop: 20,
                fontSize: 25,
                marginBottom: 5,
                fontWeight: FontWeight.bold,
              ),
              TextWithTap(
                "permissions.location_needed_for_app"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                marginTop: 0,
                fontSize: 16,
                marginBottom: 5,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
              ),
              TextWithTap(
                "permissions.location_settings"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                marginTop: 10,
                fontSize: 16,
                marginBottom: 5,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
              ),
              Visibility(
                visible: QuickHelp.isMobile(),
                child: ButtonRoundedOutline(
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 30,
                  borderRadius: 60,
                  marginTop: 50,
                  fontSize: 17,
                  textColor: kPrimaryColor,
                  borderColor: kPrimaryColor,
                  borderWidth: 2,
                  text: "permissions.location_settings_open".tr().toUpperCase(),
                  fontWeight: FontWeight.normal,
                  onTap: () async {

                    UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
                        context,
                        LocationSettingsScreen(
                          currentUser: widget.currentUser,
                        ),
                        route: LocationSettingsScreen.route);

                    if(user != null){
                      // Update user now
                      reloadScreen();
                    }
                  },
                ),
              ),
              RoundedGradientButton(
                height: 48,
                marginLeft: 30,
                marginRight: 30,
                marginBottom: 30,
                borderRadius: 60,
                borderRadiusBottomLeft: 15,
                fontSize: 17,
                colors: [kPrimaryColor, kSecondaryColor],
                textColor: Colors.white,
                text: "permissions.location_add_manually".tr().toUpperCase(),
                fontWeight: FontWeight.normal,
                onTap: () async {
                  UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
                      context,
                      AddCityScreenForce(
                        currentUser: widget.currentUser,
                      ),
                      route: AddCityScreenForce.route);

                  if(user != null){
                    // Update user now
                    reloadScreen();
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  reloadScreen(){
    // Reload screen
    context.read<CountersProvider>().setTabIndex(HomeScreen.tabHome);
  }

  String getBirthDay(UserModel currentUser) {
    if (currentUser.getBirthday != null) {
      return ", ${QuickHelp.getAgeFromDate(currentUser.getBirthday!)}";
    } else {
      return "";
    }
  }

  String getWork(UserModel currentUser) {
    List<String> myWork = [];

    if (currentUser.getJobTitle!.isNotEmpty) {
      myWork.add(currentUser.getJobTitle!);
    }

    if (currentUser.getCompanyName!.isNotEmpty) {
      myWork.add(currentUser.getCompanyName!);
    }

    return myWork.join(", ");
  }

  Future<List<dynamic>?> loadUser() async {

    List<String> matchedUserIdList = [];

    print("UsersCount Encounter $userId");

    QueryBuilder<EncountersModel> queryUsersEncounter =
        QueryBuilder<EncountersModel>(EncountersModel());
    queryUsersEncounter.whereEqualTo(
        EncountersModel.keyFromUserId, widget.currentUser!.objectId);
    queryUsersEncounter.setLimit(1000000);

    var encounterResponse = await queryUsersEncounter.query();

    if (encounterResponse.success) {
      if (encounterResponse.results != null &&
          encounterResponse.results!.length > 0) {
        for (EncountersModel currentMatch in encounterResponse.results!) {
          if (!matchedUserIdList.contains(currentMatch.getReceiverId!)) {
            matchedUserIdList.add(currentMatch.getReceiverId!);
          }
        }
      }

      print("UsersCount Encounter: ${matchedUserIdList.length}");

      QueryBuilder<UserModel> users =
          QueryBuilder<UserModel>(UserModel.forQuery());

      //users.whereDoesNotMatchKeyInQuery(UserModel.keyObjectId, EncountersModel.keyFromUserId, queryUsersEncounter);
      users.whereNotEqualTo(
          UserModel.keyObjectId, widget.currentUser!.objectId);
      users.whereValueExists(UserModel.keyGeoPoint, true);
      users.whereValueExists(UserModel.keyAvatar, true);
      users.whereValueExists(UserModel.keyGender, true);
      users.whereNotContainedIn(UserModel.keyObjectId, matchedUserIdList);
      users.whereValueExists(UserModel.keyBirthday, true); // Only show users with birthday
      //users.whereGreaterThanOrEqualsTo(UserModel.keyAge, currentUser!.getPrefMinAge); // Minimum Age
      //users.whereLessThanOrEqualTo(UserModel.keyAge, currentUser!.getPrefMaxAge); // Maximum Age
      users.whereGreaterThanOrEqualsTo(
          UserModel.keyBirthday,
          QuickHelp.getDateFromAge(
              widget.currentUser!.getPrefMaxAge!)); // Minimum Age
      users.whereLessThanOrEqualTo(
          UserModel.keyBirthday,
          QuickHelp.getDateFromAge(
              widget.currentUser!.getPrefMinAge!)); // Maximum Age

      users.whereNotEqualTo(UserModel.keyUserStatus, true);
      users.whereNotEqualTo(UserModel.keyAccountHidden, true);
      users.whereNotEqualTo(UserModel.keyUserAccountDeleted, true);
      users.whereWithinKilometers(
          UserModel.keyGeoPoint,
          widget.currentUser!.getGeoPoint!,
          widget.currentUser!.getPrefDistance!.toDouble());
      users.setLimit(Setup.maxUsersNearToShow);

      if (widget.currentUser!.getGenderPref != UserModel.keyGenderBoth) {
        users.whereEqualTo(
            UserModel.keyGender, widget.currentUser!.getGenderPref);
      }

      //users.whereNotEqualTo(UserModel.PRIVACY_ALMOST_INVISIBLE, true);
      //users.whereNotContainedIn(User.BLOCKED_USERS, userArrayList);

      ParseResponse apiResponse = await users.query();
      if (apiResponse.success) {
        print("UsersCount: ${apiResponse.results!.length}");
        if (apiResponse.results != null) {
          return apiResponse.results;
        } else {
          return AsyncSnapshot.nothing() as List<dynamic>;
        }
      } else {
        return apiResponse.error as dynamic;
      }
    } else {
      return encounterResponse.error as dynamic;
    }
  }

  int _current = 0;

  Widget getBody() {
    var size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.9,
      child: TinderSwapCard(
        cardController: cardController,
        totalNum: globalUsers.length,
        maxWidth: size.width,
        maxHeight: size.height,
        minWidth: size.width * 0.75,
        minHeight: size.height * 0.75,
        cardBuilder: (context, index) {

          UserModel selectedUser = globalUsers[index];

          final CarouselController _controller = CarouselController();

          return ContainerCorner(
            color: Colors.black,
            borderRadius: 20,
            child: Stack(
              children: [
                CarouselSlider.builder(
                  key: Key(selectedUser.objectId!),
                    options: CarouselOptions(
                        autoPlay: true,
                        height: double.maxFinite,
                        autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                        enableInfiniteScroll: true,
                        enlargeCenterPage: QuickHelp.getPhotosCounter(selectedUser).length > 1 ? true : false,
                        viewportFraction: 1,
                        enlargeStrategy: CenterPageEnlargeStrategy.scale,
                        aspectRatio: Responsive.isMobile(context) ? 1 : 1,
                        autoPlayCurve: Curves.linearToEaseOut,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        }),
                    carouselController: _controller,
                    itemCount:
                        QuickHelp.getPhotosCounter(globalUsers[index]!).length,
                    itemBuilder: (BuildContext context, int itemIndex,
                        int pageViewIndex) {
                      return ContainerCorner(
                        color: kTransparentColor,
                        width: size.width,
                        height: size.height,
                        child: QuickActions.photosWidget(
                          QuickHelp.getPhotosCounter(
                              globalUsers[index])[itemIndex],
                          borderRadius: 20,
                        ),
                      );
                    }),
                Container(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Visibility(
                          visible: QuickHelp.getPhotosCounter(selectedUser).length > 1 ? true : false,
                          child: QuickHelp.pictureStep(
                              context,
                              QuickHelp.getPhotosCounter(selectedUser).length,
                              _current),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: ContainerCorner(
                          width: 30,
                          height: 30,
                          marginTop: 40,
                          marginRight: 10,
                          borderRadius: 10,
                          onTap: () => openSheet(selectedUser),
                          color: Colors.black.withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: SvgPicture.asset(
                              "assets/svg/chat_config.svg",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ContainerCorner(
                          width: size.width,
                          radiusBottomLeft: 20,
                          radiusBottomRight: 20,
                          colors: [Colors.black, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          height: size.height / 2,
                          onTap: () {
                            QuickActions.showUserProfile(context, selectedUser);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 15, right: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        selectedUser.getFullName!,
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    TextWithTap(
                                      "${getBirthDay(selectedUser)}",
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      marginRight: 8,
                                    ),
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: SvgPicture.asset(
                                          "assets/svg/ic_verified_account.svg"),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 15, right: 10),
                                child: profileDetails(
                                    context,
                                    selectedUser,
                                    QuickHelp.getPhotosCounter(selectedUser)
                                        .length),
                              ),
                              footer(selectedUser),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        swipeUpdateCallback: (DragUpdateDetails details, Alignment align) {
          /// Get swiping card's alignment
          if (align.x < 0) {
            //Card is LEFT swiping
            //print("Card is LEFT ${align.x}");
            //-1 to -14

          } else if (align.x > 0) {
            //print("Card is RIGHT ${align.x}");

            //1 to 14
            //Card is RIGHT swiping
          }
        },
        swipeCompleteCallback: (CardSwipeOrientation orientation, int index) {
          UserModel selectedUser = globalUsers[index];

          /// Get orientation & index of swiped card!
          if (orientation == CardSwipeOrientation.right) {
            like(selectedUser);
          } else if (orientation == CardSwipeOrientation.left) {
            dislike(selectedUser);
          }
        },
      ),
    );
  }

  Widget webBody() {
    var size = MediaQuery.of(context).size;

    return ContainerCorner(
      height: size.height,
      width: size.width,
      marginLeft: spaces(),
      marginRight: spaces(),
      child: Card(
        elevation: 3.0,
        color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
        child: TinderSwapCard(
          cardController: cardController,
          totalNum: globalUsers.length,
          maxWidth: size.width,
          maxHeight: size.height,
          minWidth: size.width * 0.75,
          minHeight: size.height * 0.75,
          cardBuilder: (context, index) {

            UserModel selectedUser = globalUsers[index];

            final CarouselController _controller = CarouselController();

            return Row(
              children: [
                Flexible(
                  flex: 2,
                  child: ContainerCorner(
                    borderRadius: 0,
                    borderWidth: 0,
                    width: 400,
                    color: Colors.black,
                    child: Stack(
                      children: [
                        CarouselSlider.builder(
                            options: CarouselOptions(
                                autoPlay: true,
                                autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                                enlargeCenterPage: QuickHelp.getPhotosCounter(selectedUser).length > 1 ? true : false,
                                viewportFraction: 1,
                                aspectRatio: 5 / 8,
                                autoPlayCurve: Curves.linearToEaseOut,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _current = index;
                                  });
                                }),
                            carouselController: _controller,
                            itemCount:
                            QuickHelp.getPhotosCounter(globalUsers[index]!).length,
                            itemBuilder: (BuildContext context, int itemIndex,
                                int pageViewIndex) {
                              return ContainerCorner(
                                color: kTransparentColor,
                                width: size.width,
                                height: size.height,
                                child: QuickActions.photosWidget(
                                  QuickHelp.getPhotosCounter(
                                      globalUsers[index])[itemIndex],
                                  borderRadius: 0,
                                ),
                              );
                            }),
                        Container(
                          width: size.width,
                          height: size.height,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Visibility(
                                  visible: QuickHelp.getPhotosCounter(selectedUser).length > 1 ? true : false,
                                  child: QuickHelp.pictureStep(
                                      context,
                                      QuickHelp.getPhotosCounter(selectedUser).length,
                                      _current),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: ContainerCorner(
                                  width: 30,
                                  height: 30,
                                  marginTop: 40,
                                  marginRight: 10,
                                  borderRadius: 10,
                                  onTap: () => openSheet(selectedUser),
                                  color: Colors.black.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: SvgPicture.asset(
                                      "assets/svg/chat_config.svg",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ContainerCorner(
                                  colors: [Colors.black, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  height: size.height / 4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      footer(selectedUser),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                    child: ContainerCorner(
                      color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                            child: Text(
                              "edit_profile.user_information".tr(),
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: 20,
                              top: 20,
                              bottom: 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "${selectedUser.getFullName!}",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "${getBirthDay(selectedUser)}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(
                                  width: 7,
                                ),
                                SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: SvgPicture.asset(
                                        "assets/svg/ic_verified_account.svg"))
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Column(
                              children: [
                                info("assets/svg/prof.svg", getWork(selectedUser)),
                                info("assets/svg/school.svg", selectedUser.getSchool!),
                                info("assets/svg/sex.svg",
                                    QuickHelp.getSexualityListWithName(selectedUser)),
                                info("assets/svg/country.svg", selectedUser.getLocation!),
                              ],
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(left: 20, top: 10),
                            child: Text(
                              "edit_profile.about_".tr(),
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 20, top: 10, right: 8),
                            child: Text(
                              selectedUser.getAboutYou!,
                              style: TextStyle(
                                color: kDisabledGrayColor,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 20, top: 10),
                            child: Text(
                              "edit_profile.passions_section".tr(),
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: 20,
                            ),
                            child: passionsStepWidget(selectedUser),
                          ),
                          SizedBox(
                            height: 15,
                          )
                        ],
                      ),
                    ),
                ),
              ],
            );
          },
          swipeUpdateCallback: (DragUpdateDetails details, Alignment align) {
            /// Get swiping card's alignment
            if (align.x < 0) {
              //Card is LEFT swiping
              //print("Card is LEFT ${align.x}");
              //-1 to -14

            } else if (align.x > 0) {
              //print("Card is RIGHT ${align.x}");

              //1 to 14
              //Card is RIGHT swiping
            }
          },
          swipeCompleteCallback: (CardSwipeOrientation orientation, int index) {
            UserModel selectedUser = globalUsers[index];

            /// Get orientation & index of swiped card!
            if (orientation == CardSwipeOrientation.right) {
              like(selectedUser);
            } else if (orientation == CardSwipeOrientation.left) {
              dislike(selectedUser);
            }
          },
        ),
      ),
    );
  }

  double spaces() {
    var size = MediaQuery.of(context).size.width;
    if(size == 1200) {
      return 100.0;
    }else if(size > 1200){
      return 200.0;
    }else if(size <= 1024){
      return 10;
    }else{
      return 5;
    }
  }

  void openSheet(UserModel mUser) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showReportBottomSheet(mUser);
        });
  }

  void reportAndRemoveMatch(UserModel mUser) async {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_unmatch_user.svg",
      title: "message_screen.remove_match_and_report".tr(),
      message: "message_screen.remove_match_and_report_message"
          .tr(namedArgs: {"name": "${mUser.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        removeMatchedUser(mUser, reportAlso: true);
      },
    );
  }

  removeMatchedUser(UserModel mUser, {bool? reportAlso}) async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.setRemovedMatch = mUser;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;

      QuickHelp.hideLoadingDialog(context);

      if (reportAlso != null && reportAlso) {
        openReportMessage(mUser);
      }
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  void openReportMessage(UserModel mUser) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showReportMessageBottomSheet(mUser);
        });
  }

  Widget _showReportMessageBottomSheet(UserModel mUser) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: ContainerCorner(
                    radiusTopRight: 20.0,
                    radiusTopLeft: 20.0,
                    color: QuickHelp.isDarkMode(context)
                        ? kContentColorLightTheme
                        : Colors.white,
                    child: Column(
                      children: [
                        ContainerCorner(
                          color: kGreyColor1,
                          width: 50,
                          marginTop: 5,
                          borderRadius: 50,
                          marginBottom: 10,
                        ),
                        TextWithTap(
                          "message_screen.report_".tr(),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                        TextWithTap(
                          "message_screen.we_keep_secret".tr(
                            namedArgs: {"name": "${mUser.getFirstName!}"},
                          ),
                          color: kGrayColor,
                          marginBottom: 20,
                        ),
                        Column(
                          children: List.generate(
                              QuickHelp.getReportCodeMessageList().length,
                              (index) {
                            String code =
                                QuickHelp.getReportCodeMessageList()[index];

                            return TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                print("Message: " +
                                    QuickHelp.getReportMessage(code));
                                _confirmReport(QuickHelp.getReportMessage(code),
                                    code, mUser);
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextWithTap(
                                        QuickHelp.getReportMessage(code),
                                        color: kGrayColor,
                                        fontSize: 15,
                                        marginBottom: 5,
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: kGrayColor,
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    height: 1.0,
                                  )
                                ],
                              ),
                            );
                          }),
                        ),
                        ContainerCorner(
                          marginTop: 30,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: TextWithTap(
                              "cancel".tr().toUpperCase(),
                              color: kGrayColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  _confirmReport(String reportReason, String code, UserModel mUser) {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_unmatch_user.svg",
      title: "message_screen.report_reason".tr(),
      message: reportReason,
      confirmButtonText: 'confirm_'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        _saveReport(code, mUser);
      },
    );
  }

  _saveReport(String code, UserModel mUser) async {
    ReportModel reportModel = ReportModel();

    reportModel.setAccuser = widget.currentUser!;
    reportModel.setAccusedId = widget.currentUser!.objectId!;

    reportModel.setAccused = mUser;
    reportModel.setAccusedId = mUser.objectId!;

    reportModel.setMessage = code;

    reportModel.setState = ReportModel.statePending;

    await reportModel.save();
  }

  void removeMatch(UserModel mUser) {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_remove_match.svg",
      title: "message_screen.remove_match".tr(),
      message: "message_screen.remove_match_message"
          .tr(namedArgs: {"name": "${mUser.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        removeMatchedUser(mUser);
      },
    );
  }

  void unblockUser(UserModel mUser) {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_like_swip.svg",
      title: "message_screen.unblock_user".tr(),
      message: "message_screen.unblock_user_message"
          .tr(namedArgs: {"name": "${mUser.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        unblock(mUser);
      },
    );
  }

  unblock(UserModel mUser) async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.unsetRemovedMatch = mUser;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;

      QuickHelp.hideLoadingDialog(context);
      setState(() {
        showReportAndRemoveScreen = true;
        showUnblockUserScreen = false;
      });
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  Widget _showReportBottomSheet(UserModel mUser) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(25.0),
                      topRight: const Radius.circular(25.0),
                    ),
                  ),
                  child: ContainerCorner(
                    radiusTopRight: 20.0,
                    radiusTopLeft: 20.0,
                    color: QuickHelp.isDarkMode(context)
                        ? kContentColorLightTheme
                        : Colors.white,
                    child: Column(
                      children: [
                        ContainerCorner(
                          color: kGreyColor1,
                          width: 50,
                          marginTop: 5,
                          borderRadius: 50,
                        ),
                        Visibility(
                          visible: showReportAndRemoveScreen,
                          child: Column(
                            children: [
                              TextWithTap(
                                "message_screen.report_title".tr(),
                                color: QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                marginTop: 5,
                              ),
                              TextButton(
                                onPressed: () {
                                  QuickHelp.hideLoadingDialog(context);
                                  reportAndRemoveMatch(mUser);
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(right: 15, left: 20),
                                      child: SvgPicture.asset(
                                          "assets/svg/ic_unmatch_user.svg"),
                                    ),
                                    TextWithTap(
                                      "message_screen.report_remove_match".tr(),
                                      color: QuickHelp.isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  QuickHelp.hideLoadingDialog(context);
                                  removeMatch(mUser);
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 10, left: 18),
                                      child: SvgPicture.asset(
                                          "assets/svg/ic_remove_match.svg"),
                                    ),
                                    TextWithTap(
                                      "message_screen.remove_match_only".tr(),
                                      color: QuickHelp.isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: showUnblockUserScreen,
                          child: Column(
                            children: [
                              TextWithTap(
                                "message_screen.report_title".tr(),
                                color: QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                marginTop: 5,
                              ),
                              TextButton(
                                onPressed: () {
                                  QuickHelp.hideLoadingDialog(context);
                                  unblockUser(mUser);
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(right: 15, left: 20),
                                      child: SvgPicture.asset(
                                        "assets/svg/ic_like_swip.svg",
                                      ),
                                    ),
                                    Expanded(
                                      child: TextWithTap(
                                        "message_screen.unblock_user".tr(),
                                        color: QuickHelp.isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget footer(UserModel userModel) {

    return Padding(
      padding: EdgeInsets.only(left: 15, bottom: 20, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => cardController.triggerLeft(),
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: SvgPicture.asset(
                "assets/svg/ic_close_round_encounters.svg",
                height: 51,
                width: 51,
              ),
            ),
          ),
          Row(
            children: [
              ContainerCorner(
                borderRadius: 40,
                colors: [kPrimaryColor, kSecondaryColor],
                height: 51,
                marginTop: 5,
                marginRight: 16,
                onTap: () {
                  if (Responsive.isMobile(context)) {
                    _gotToChat(widget.currentUser!, userModel);
                  } else {
                    QuickHelp.goToNavigatorScreen(context, ResponsiveChat(currentUser: widget.currentUser, mUser: userModel,), route: ResponsiveChat.route);
                  }
                },
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 9, left: 18),
                      child: SvgPicture.asset(
                        "assets/svg/ic_send_encounters.svg",
                        height: 30,
                        width: 30,
                      ),
                    ),
                    TextWithTap(
                      "encounters_screen.hey_".tr(),
                      marginLeft: 10,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      marginRight: 18,
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => cardController.triggerRight(),
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SvgPicture.asset(
                    "assets/svg/ic_like_round_encounters.svg",
                    height: 51,
                    width: 51,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget ticketStep(context, int numberOfSteps, int step) {
    return Container(
      margin: EdgeInsets.only(
        top: 10,
        right: 10,
        left: 10,
        bottom: 10,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: List.generate(numberOfSteps, (index) {
            return GestureDetector(
              onTap: () {},
              child: ContainerCorner(
                borderRadius: 8,
                height: 8,
                width: 8,
                color: index == step ? kPrimaryColor : kGrayColor,
              ),
            );
          }),
        ),
      ),
    );
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickActions.sendMessage(context, currentUser, mUser);
  }

  Widget passionsStepWidget(UserModel userModel) {
    Size size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      margin: EdgeInsets.only(bottom: 25),
      child: Wrap(
        spacing: 10.0, // gap between adjacent chips
        runSpacing: 10.0,
        alignment: WrapAlignment.start,
        //crossAxisAlignment: WrapCrossAlignment.center,
        children: List.generate(userModel.getPassions!.length, (index) {
          return ContainerCorner(
            borderRadius: 70,
            height: 30,
            colors: [Colors.transparent, Colors.transparent],
            borderColor: widget.currentUser!.getPassions!
                    .contains(userModel.getPassions![index])
                ? kPrimaryColor
                : kPhotosGrayColorReverse,
            borderWidth: 1.5,
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: TextWithTap(
                  QuickHelp.getPassions(userModel.getPassions![index]),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  marginLeft: 14,
                  marginRight: 14,
                  textAlign: TextAlign.center,
                  color: widget.currentUser!.getPassions!
                          .contains(userModel.getPassions![index])
                      ? kPrimaryColor
                      : kPhotosGrayColorReverse),
            ),
          );
        }),
      ),
    );
  }

  _showBottomSheet(BuildContext context, UserModel currentUser) {
    values = RangeValues(currentUser.getPrefMinAge!.toDouble(),
        currentUser.getPrefMaxAge!.toDouble());
    heightValue = currentUser.getPrefDistance!;

    if (currentUser.getGenderPref! == UserModel.keyGenderMale) {
      isSelected[0] = true;
    } else if (currentUser.getGenderPref! == UserModel.keyGenderFemale) {
      isSelected[1] = true;
    } else if (currentUser.getGenderPref! == UserModel.keyGenderBoth) {
      isSelected[2] = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          builder: (_, controller) {
            return SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: QuickHelp.isDarkMode(context)
                      ? kContentColorLightTheme
                      : kContentColorDarkTheme,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(25.0),
                    topRight: const Radius.circular(25.0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ContainerCorner(
                              marginTop: 10,
                              marginBottom: 10,
                              color: kPhotosGrayColorReverse,
                              height: 3,
                              width: 60,
                            ),
                            buttonsForFilter(
                                "encounters_screen.filter_".tr(),
                                "encounters_screen.clear_all".tr(),
                                15,
                                18,
                                QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                14,
                                kRedColor1,
                                FontWeight.w600,
                                FontWeight.w500,
                                setState),
                            TextWithTap(
                              "encounters_screen.interested_in".tr(),
                              alignment: Alignment.centerLeft,
                              marginLeft: 15,
                              marginTop: 15,
                              marginBottom: 10,
                              fontWeight: FontWeight.w500,
                              color: QuickHelp.isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            filterSexOption(setState),
                            optionTitles(
                                "encounters_screen.age_range".tr(),
                                this.values!.start.round().toString() +
                                    "-" +
                                    this.values!.end.round().toString(),
                                15,
                                14,
                                QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                14,
                                QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                FontWeight.w500,
                                FontWeight.w500),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 1,
                              ),
                              child: RangeSlider(
                                min: Setup.minimumAgeToRegister.toDouble(),
                                inactiveColor: kPhotosGrayColor,
                                max: Setup.maximumAgeToRegister.toDouble(),
                                values: this.values!,
                                divisions: Setup.maximumAgeToRegister,
                                onChanged: (RangeValues value) {
                                  setState(() {
                                    this.values = value;
                                  });
                                },
                              ),
                            ),
                            optionTitles(
                                "encounters_screen.distance_".tr(namedArgs: {
                                  "unit":
                                      "${currentUser.getDistanceInMiles! ? "mi" : "km"}"
                                }),
                                "${this.heightValue < Setup.maxDistanceBetweenUsers ? "${this.heightValue}" : "encounters_screen.whole_country".tr()}",
                                15,
                                14,
                                QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                14,
                                QuickHelp.isDarkMode(context)
                                    ? Colors.white
                                    : Colors.black,
                                FontWeight.w500,
                                FontWeight.w500),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                overlayColor: kPhotosGrayColor,
                                minThumbSeparation:
                                    Setup.maxDistanceBetweenUsers.toDouble(),
                              ),
                              child: Slider(
                                  value: this.heightValue.toDouble(),
                                  //currentUser.getPrefDistance!.toDouble(),  //heightValue.toDouble(),
                                  min: Setup.minDistanceBetweenUsers.toDouble(),
                                  max: Setup.maxDistanceBetweenUsers.toDouble(),
                                  inactiveColor: kPhotosGrayColor,
                                  activeColor: kPrimaryColor,
                                  onChanged: (double newValue) {
                                    setState(() {
                                      this.heightValue = newValue.round();
                                    });
                                  },
                                  semanticFormatterCallback: (double newValue) {
                                    return '${newValue.round()}';
                                  }),
                            ),
                          ],
                        );
                      },
                    ))
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget optionTitles(
      String? firstTitle,
      String? secondTitle,
      double? marginLeft,
      double? firstTitleFontSize,
      Color? firstTitleColor,
      double? secondTitleFontSize,
      Color? secondTitleColor,
      FontWeight? firstTitleFontWeight,
      FontWeight? secondTitleFontWeight) {
    return ContainerCorner(
      marginLeft: marginLeft!,
      marginRight: 15,
      color: kTransparentColor,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextWithTap(
          firstTitle!,
          fontSize: firstTitleFontSize!,
          color: firstTitleColor!,
          fontWeight: firstTitleFontWeight!,
        ),
        TextWithTap(
          secondTitle!,
          color: secondTitleColor!,
          fontSize: secondTitleFontSize!,
          fontWeight: secondTitleFontWeight!,
        )
      ]),
    );
  }

  Widget buttonsForFilter(
      String? firstTitle,
      String? secondTitle,
      double? marginLeft,
      double? firstTitleFontSize,
      Color? firstTitleColor,
      double? secondTitleFontSize,
      Color? secondTitleColor,
      FontWeight? firstTitleFontWeight,
      FontWeight? secondTitleFontWeight,
      StateSetter setState) {
    return ContainerCorner(
      marginLeft: marginLeft!,
      marginRight: 15,
      color: kTransparentColor,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        TextWithTap(
          "save_".tr(),
          onTap: () => _save(),
          fontSize: 16,
          color: kPrimaryColor,
          fontWeight: FontWeight.normal,
        ),
        TextWithTap(
          firstTitle!,
          fontSize: firstTitleFontSize!,
          color: firstTitleColor!,
          fontWeight: firstTitleFontWeight!,
        ),
        TextWithTap(
          secondTitle!,
          color: secondTitleColor!,
          fontSize: secondTitleFontSize!,
          onTap: () => _clearAll(setState),
          fontWeight: secondTitleFontWeight!,
        )
      ]),
    );
  }

  Widget filterSexOption(StateSetter setState) {
    return ContainerCorner(
      color: kTransparentColor,
      height: 40,
      marginRight: 15,
      marginLeft: 15,
      marginBottom: 20,
      borderColor: kDisabledColor,
      borderRadius: 10,
      marginTop: 15,
      child: Center(
        child: ToggleButtons(
          borderRadius: BorderRadius.circular(10),
          borderColor: Colors.transparent,
          renderBorder: false,
          selectedBorderColor: Colors.transparent,
          splashColor: Colors.transparent,
          selectedColor: Colors.transparent,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < isSelected.length; i++) {
                isSelected[i] = i == index;
              }
            });
          },
          isSelected: isSelected,
          children: [
            sexOption("encounters_screen.men_".tr(), 0),
            sexOption("encounters_screen.women_".tr(), 1),
            sexOption("encounters_screen.both_".tr(), 2),
          ],
        ),
      ),
    );
  }

  Widget sexOption(String? text, int? index) {
    return Container(
      width: (MediaQuery.of(context).size.width / 3) - 11,
      height: 40,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected[index!] ? null : Colors.transparent,
          border: Border.all(
            color: isSelected[index] ? kPrimaryColor : kTransparentColor,
          )),
      child: Center(
        child: Text(
          text!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected[index]
                ? kPrimaryColor
                : QuickHelp.isDarkMode(context)
                    ? Colors.white
                    : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget profileDetails(BuildContext context, UserModel userModel, int step) {
    ParseGeoPoint? userGeoPoint = userModel.getGeoPoint;
    ParseGeoPoint? myGeoPoint = widget.currentUser!.getGeoPoint;

    if (step == 1) {
      return Column(
        children: [
          Visibility(
            visible: getWork(userModel).isNotEmpty,
            child: info("assets/svg/prof.svg", getWork(userModel), top: 7),
          ),
          Visibility(
            visible: userModel.getSchool!.isNotEmpty,
            child: info("assets/svg/school.svg", userModel.getSchool!),
          ),
          Visibility(
            visible: userModel.getCity!.isNotEmpty,
            child: info("assets/svg/country.svg", userModel.getCity!),
          ),
          Visibility(
            visible: userModel.getHasGeoPoint!,
            child: info(
                "assets/svg/ic_pin_fill_encounters.svg",
                "${userModel.getDistanceInMiles! ? "miles_away".tr(namedArgs: {
                        "mi": QuickHelp.distanceInMilesTo(
                                myGeoPoint!, userGeoPoint!)
                            .round()
                            .toString()
                      }) : "kilometers_away".tr(namedArgs: {
                        "km": QuickHelp.distanceInKilometersTo(
                                myGeoPoint!, userGeoPoint!)
                            .round()
                            .toString()
                      })}",
                bottom: 20),
          )
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWithTap(
            userModel.getAboutYou!,
            color: Colors.white,
            fontSize: 13,
            marginBottom: 8,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.start,
          ),
          passionsStepWidget(userModel),
        ],
      );
    }
  }

  Widget info(String icon, String text, {double? top, double? bottom}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ContainerCorner(
            color: kTransparentColor,
            marginRight: 5,
            marginTop: top != null ? top : 0,
            marginBottom: bottom != null ? bottom : 8,
            child: SvgPicture.asset(
              icon,
              height: 20,
              width: 20,
              color: Colors.white,
            )),
        TextWithTap(
          text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          marginTop: top != null ? top : 0,
          marginBottom: bottom != null ? bottom : 8,
        ),
      ],
    );
  }
}

Widget getFreeTicket() {
  return AlertDialog(
    content: ContainerCorner(
      colors: [kPrimaryColor, kSecondaryColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      height: 342,
      width: 268,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Center(
                child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset("assets/images/ticket-star.png")),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ContainerCorner(
                  color: kRedColor1,
                  width: 36,
                  height: 36,
                  borderRadius: 50,
                  child: Text(
                    "3",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          Text(
            "settings.delete_acc_ask".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 35,
          ),
          SizedBox(height: 20),
        ],
      ),
    ),
  );
}
