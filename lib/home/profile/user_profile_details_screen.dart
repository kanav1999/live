import 'package:carousel_slider/carousel_slider.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/chats/responsive_chat.dart';
import 'package:heyto/home/encounters/match_screen.dart';
import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/ReportModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_logo.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../../app/constants.dart';
import '../../app/setup.dart';

// ignore: must_be_immutable
class UserProfileDetailsScreen extends StatefulWidget {
  static String route = '/profile/user/details';

  UserModel? currentUser, mUser;
  bool? showComponents;

  UserProfileDetailsScreen({this.currentUser, this.mUser, this.showComponents});

  @override
  State<UserProfileDetailsScreen> createState() =>
      _UserProfileDetailsScreenState();
}

class _UserProfileDetailsScreenState extends State<UserProfileDetailsScreen> {

  bool footerVisible = false;

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

  _like(UserModel userModel) async {
    EncountersModel encountersModel = EncountersModel();
    encountersModel.setAuthor = widget.currentUser!;
    encountersModel.setAuthorId = widget.currentUser!.objectId!;

    encountersModel.setReceiver = userModel;
    encountersModel.setReceiverId = userModel.objectId!;

    encountersModel.setSeen = false;
    encountersModel.setLike = true;

    QuickHelp.showLoadingDialog(context);

    var parseResponse = await encountersModel.save();

    if (parseResponse.success) {
      QuickHelp.hideLoadingDialog(context);

      setState(() {
        footerVisible = false;
      });

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
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  _dislike(UserModel userModel) async {
    EncountersModel encountersModel = EncountersModel();
    encountersModel.setAuthor = widget.currentUser!;
    encountersModel.setAuthorId = widget.currentUser!.objectId!;

    encountersModel.setReceiver = userModel;
    encountersModel.setReceiverId = userModel.objectId!;

    encountersModel.setSeen = true;
    encountersModel.setLike = false;
    var parseResponse = await encountersModel.save();

    QuickHelp.showLoadingDialog(context);

    if (parseResponse.success) {
      QuickHelp.hideLoadingDialog(context);

      setState(() {
        footerVisible = false;
      });

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
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  @override
  void initState() {
    //_getUser();
    if(QuickHelp.isMobile()){
      initBannerAd();
    }

    Future.delayed(Duration(seconds: 2), (){

      SendNotifications.sendPush(
        widget.currentUser!,
        widget.mUser!,
        SendNotifications.typeProfileVisit,
      );

    });

    super.initState();
  }

  BannerAd? myBanner;

  initBannerAd() {
    final AdSize adSize = AdSize(width: 316, height: 93);

    myBanner = BannerAd(
      adUnitId: Constants.getAdmobBannerUnit(),
      size: adSize, //AdSize.largeBanner,
      request: AdRequest(),
      listener: BannerAdListener(onAdLoaded: (Ad ad) {
        print("Banner loaded");

        setState(() {
          adWidget = AdWidget(ad: myBanner!);
        });
      }),
    );
  }

  loadAd() {
    myBanner!.load();
  }

  AdWidget? adWidget;

  List<String?> pictures = [];

  bool showReportAndRemoveScreen = true;
  bool showUnblockUserScreen = false;

  final CarouselController _controller = CarouselController();

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.profile_title".tr());

    if(QuickHelp.isMobile()){
      loadAd();
    }

    return ToolBarCenterLogo(
      logoName: 'ic_logo.png',
      logoWidth: 80,
      iconHeight: 20,
      iconWidth: 20,
      leftButtonIcon: widget.showComponents! ? Icons.arrow_back : null,
      leftButtonPress: () {
        if (widget.showComponents!) {
          return QuickHelp.goBackToPreviousPage(context,
              result: widget.currentUser);
        } else {
          return null;
        }
      },
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      rightButtonAsset: widget.showComponents! ?  "chat_config.svg" : null,
      rightButtonPress: () {
        if(!widget.showComponents!){
          return null;
        }else{
          return openSheet();
        }
      },
      child: SafeArea(
        child: Responsive.isMobile(context) || Responsive.isTablet(context) ? getBody() : getBody(),
      ),
    );
  }

   Widget getBody() {
     Size size = MediaQuery.of(context).size;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CarouselSlider.builder(
                      options: CarouselOptions(
                          height: size.height / 2.5,
                          autoPlay: QuickHelp.getPhotosCounter(widget.mUser).length > 1 ? true : false,
                          autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                          enlargeCenterPage: true,
                          viewportFraction: 1,
                          aspectRatio: 4/4,
                          autoPlayCurve: Curves.linearToEaseOut,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          }),
                      carouselController: _controller,
                      itemCount:
                      QuickHelp.getPhotosCounter(widget.mUser).length,
                      itemBuilder: (BuildContext context, int itemIndex,
                          int pageViewIndex) {
                        return ContainerCorner(
                          color: kTransparentColor,
                          width: size.width,
                          height: size.height,
                          marginLeft: 10,
                          marginRight: 10,
                          child: QuickActions.photosWidget(
                            QuickHelp.getPhotosCounter(widget.mUser)[itemIndex], borderRadius: 8,
                          ),
                        );
                      }),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Visibility(
                      visible: QuickHelp.getPhotosCounter(widget.mUser).length > 1 ? true : false,
                      child: QuickHelp.pictureStep(
                          context,
                          QuickHelp.getPhotosCounter(widget.mUser).length,
                          _current),
                    ),
                  ),
                ],
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
                      "${widget.mUser!.getFullName!}",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${getBirthDay(widget.mUser!)}",
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
              info("assets/svg/prof.svg", getWork(widget.mUser!)),
              info("assets/svg/school.svg", widget.mUser!.getSchool!),
              info("assets/svg/sex.svg",
                  QuickHelp.getSexualityListWithName(widget.mUser!)),
              info("assets/svg/country.svg", widget.mUser!.getLocation!),
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
                  widget.mUser!.getAboutYou!,
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
                child: passionsStepWidget(),
              ),
              Center(
                child: Visibility(
                  visible: QuickHelp.isMobile(),
                  child: ContainerCorner(
                    //width: 320,
                    height: 93,
                    marginTop: 20,
                    marginBottom: 30,
                    marginRight: 30,
                    marginLeft: 20,
                    borderRadius: 10,
                    alignment: Alignment.center,
                    color: Colors.transparent,
                    child: adWidget,
                    //width: myBanner!.size.width.toDouble(),
                    //height: myBanner!.size.height.toDouble(),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ),
      Visibility(
        visible: widget.showComponents!,
        child: footer(widget.mUser!),
      ),
    ]);
   }

  Widget webBody() {
    var size = MediaQuery.of(context).size;
    final CarouselController _controller = CarouselController();

    return ContainerCorner(
      height: size.height,
      width: size.width,
      marginLeft: spaces(),
      marginRight: spaces(),
      marginBottom: 30,
      child: Card(
        elevation: 3.0,
        color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Stack(
                children: [
                  CarouselSlider.builder(
                      options: CarouselOptions(
                          height: size.height,
                          autoPlay: QuickHelp.getPhotosCounter(widget.mUser).length > 1 ? true : false,
                          autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                          enlargeCenterPage: true,
                          viewportFraction: 1,
                          aspectRatio: 4/12,
                          autoPlayCurve: Curves.linearToEaseOut,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          }),
                      carouselController: _controller,
                      itemCount:
                      QuickHelp.getPhotosCounter(widget.mUser).length,
                      itemBuilder: (BuildContext context, int itemIndex,
                          int pageViewIndex) {
                        return ContainerCorner(
                          color: kTransparentColor,
                          width: size.width,
                          height: size.height,
                          marginLeft: 10,
                          marginRight: 10,
                          child: QuickActions.photosWidget(
                            QuickHelp.getPhotosCounter(widget.mUser)[itemIndex], borderRadius: 8, fit: BoxFit.cover,
                          ),
                        );
                      }),

                  Align(
                    alignment: Alignment.topCenter,
                    child: Visibility(
                      visible: QuickHelp.getPhotosCounter(widget.mUser).length > 1 ? true : false,
                      child: QuickHelp.pictureStep(
                          context,
                          QuickHelp.getPhotosCounter(widget.mUser).length,
                          _current),
                    ),
                  ),
                ],
              ),),
            Flexible(
              flex: 2,
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
                          "${widget.mUser!.getFullName!}",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "${getBirthDay(widget.mUser!)}",
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
                        info("assets/svg/prof.svg", getWork(widget.mUser!)),
                        info("assets/svg/school.svg", widget.mUser!.getSchool!),
                        info("assets/svg/sex.svg",
                            QuickHelp.getSexualityListWithName(widget.mUser!)),
                        info("assets/svg/country.svg", widget.mUser!.getLocation!),
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
                      widget.mUser!.getAboutYou!,
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
                    child: passionsStepWidget(),
                  ),
                  SizedBox(
                    height: 15,
                  )
                ],
              ),
            )
          ],
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

  Widget footer(UserModel userModel) {

    return Padding(
      padding: EdgeInsets.only(left: 15, bottom: 20, right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: SvgPicture.asset(
                "assets/svg/ic_close_round_encounters.svg",
                height: 51,
                width: 51,
              ),
            ),
            onTap: () => _dislike(widget.mUser!),
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
                    //context.read<CountersProvider>().setTabIndex(HomeScreen.tabChat);
                    QuickHelp.goToNavigatorScreen(context, ResponsiveChat(currentUser: widget.currentUser, mUser: widget.mUser,), route: ResponsiveChat.route);
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
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SvgPicture.asset(
                    "assets/svg/ic_like_round_encounters.svg",
                    height: 51,
                    width: 51,
                  ),
                ),
                onTap: () => _like(widget.mUser!),
              ),
            ],
          )
        ],
      ),
    );
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickActions.sendMessage(context, currentUser, mUser);
  }

  Padding info(String icon, String text) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 7,
          ),
          SizedBox(width: 15, height: 15, child: SvgPicture.asset(icon)),
          SizedBox(
            width: 7,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF879099),
            ),
          ),
        ],
      ),
    );
  }

  void openSheet() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showReportBottomSheet();
        });
  }

  void reportAndRemoveMatch() async {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_unmatch_user.svg",
      title: "message_screen.remove_match_and_report".tr(),
      message: "message_screen.remove_match_and_report_message"
          .tr(namedArgs: {"name": "${widget.mUser!.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        removeMatchedUser(reportAlso: true);
      },
    );
  }

  removeMatchedUser({bool? reportAlso}) async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.setRemovedMatch = widget.mUser!;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;

      QuickHelp.hideLoadingDialog(context);

      if (reportAlso != null && reportAlso) {
        openReportMessage();
      }
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  void openReportMessage() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showReportMessageBottomSheet();
        });
  }

  Widget _showReportMessageBottomSheet() {
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
                            namedArgs: {
                              "name": "${widget.mUser!.getFirstName!}"
                            },
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
                                _confirmReport(
                                    QuickHelp.getReportMessage(code), code);
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

  _confirmReport(String reportReason, String code) {
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
        _saveReport(code);
      },
    );
  }

  _saveReport(String code) async {
    ReportModel reportModel = ReportModel();

    reportModel.setAccuser = widget.currentUser!;
    reportModel.setAccusedId = widget.currentUser!.objectId!;

    reportModel.setAccused = widget.mUser!;
    reportModel.setAccusedId = widget.mUser!.objectId!;

    reportModel.setMessage = code;

    reportModel.setState = ReportModel.statePending;

    await reportModel.save();
  }

  void removeMatch() {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_remove_match.svg",
      title: "message_screen.remove_match".tr(),
      message: "message_screen.remove_match_message"
          .tr(namedArgs: {"name": "${widget.mUser!.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        removeMatchedUser();
      },
    );
  }

  void unblockUser() {
    QuickHelp.showDialogHeyto(
      context: context,
      isRow: false,
      svgAsset: "assets/svg/ic_like_swip.svg",
      title: "message_screen.unblock_user".tr(),
      message: "message_screen.unblock_user_message"
          .tr(namedArgs: {"name": "${widget.mUser!.getFullName}"}),
      confirmButtonText: 'yes'.tr(),
      cancelButtonText: 'cancel'.tr(),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        unblock();
      },
    );
  }

  unblock() async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.unsetRemovedMatch = widget.mUser!;
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

  Widget _showReportBottomSheet() {
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
                                  reportAndRemoveMatch();
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
                                  removeMatch();
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
                                  unblockUser();
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

  Widget passionsStepWidget() {
    return Container(
      margin: EdgeInsets.only(top: 25),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          //crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(widget.mUser!.getPassions!.length, (index) {
            return ContainerCorner(
              borderRadius: 70,
              height: 32,
              colors: [kPrimaryColor, kSecondaryColor],
              borderColor: kPrimaryColor,
              borderWidth: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: TextWithTap(
                    QuickHelp.getPassions(widget.mUser!.getPassions![index]),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    marginLeft: 14,
                    marginRight: 14,
                    textAlign: TextAlign.center,
                    color: Colors.white),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget cards(context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(
        top: 10,
        right: 10,
        left: 10,
        bottom: 10,
      ),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          //crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(8, (index) {
            return ContainerCorner(
              borderRadius: 8,
              height: 80,
              width: (size.width / 4) - 20,
              color: kGreyColor1.withOpacity(0.3),
            );
          }),
        ),
      ),
    );
  }
}
