import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/coins/web_subscriptions.dart';
import 'package:heyto/home/profile/profile_screen.dart';
import 'package:heyto/home/settings/get_money_screen.dart';
import 'package:heyto/models/GiftsModel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/live/live_preview_screen.dart';
import 'package:heyto/home/live/live_streaming_screen.dart';
import 'package:heyto/models/LiveMessagesModel.dart';
import 'package:heyto/models/LiveStreamingModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import '../../app/setup.dart';
import '../../helpers/quick_cloud.dart';
import '../coins/coins_payment_widget.dart';

// ignore: must_be_immutable
class AllLivesPage extends StatefulWidget {
  UserModel? currentUser;

  AllLivesPage({this.currentUser});

  static String route = "/home/live";

  @override
  _AllLivesPageState createState() => _AllLivesPageState();
}

class _AllLivesPageState extends State<AllLivesPage>
    with TickerProviderStateMixin {
  int tabsLength = 4;

  int tabLive = 0;
  int tabChat = 1;
  int tabMatching = 2;
  int tabCommunity = 3;

  late TabController _tabController;
  AnimationController? _animationController;
  int tabIndex = 0;

  int numberOfColumns = 2;



  @override
  void initState() {
    super.initState();

    _animationController = AnimationController.unbounded(vsync: this);
    _tabController = TabController(vsync: this, length: tabsLength)
      ..addListener(() {
        setState(() {
          tabIndex = _tabController.index;
        });
      });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: ContainerCorner(
          height: 40,
          marginBottom: 10,
          marginTop: 10,
          borderRadius: 20,
          marginLeft: 10,
          marginRight: 10,
          color: QuickHelp.isDarkMode(context) ? kContentColorGhostTheme : Colors.black,
          onTap: () => QuickHelp.goToNavigatorScreen(context, GetMoneyScreen(currentUser: widget.currentUser,), route: GetMoneyScreen.route),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: SvgPicture.asset("assets/svg/dolar_diamond.svg", height: 20, width: 20,),
              ),
              SizedBox(child:
              SizedBox(
                child: TextWithTap("${QuickHelp.convertDiamondsToMoney(widget.currentUser!.getDiamonds!).toStringAsFixed(1)} ${Setup.withdrawCurrent}",
                  color: Colors.white,
                  marginRight: 5,
                  marginLeft: 5,
                  fontSize: 15,),
              )),
            ],
          ),
        ),
        leadingWidth: 110,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            "assets/images/ic_logo.png",
            height: 100,
            width: 100,
          ),
        ),
        backgroundColor: kTransparentColor,
        actions: [
          Visibility(
            visible: false,
            child: TextButton(
                onPressed: () {},
                child: Icon(
                  Icons.search,
                  color: kGrayColor,
                  size: 30,
                )),
          ),
          Visibility(
            //visible: !QuickHelp.isWebPlatform(),
            visible: true,
            child: TextButton(
              onPressed: () {
                if (widget.currentUser!.getAvatar == null) {
                  QuickHelp.showAppNotificationAdvanced(
                    title: "live_streaming.no_avatar_found_title".tr(),
                    message: "live_streaming.no_avatar_found_explain".tr(),
                    context: context,
                    isError: true,
                  );
                } else {
                  checkPermission(true);
                }
              },
              child: Icon(
                Icons.videocam,
                color: kPrimaryColor,
                size: 30,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Responsive.isWebOrDeskTop(context)
                  ? webBody()
                  : gridOfLives(),
            ),
          ),
        ],
      ),
    );
  }

  Widget webBody() {

    return ContainerCorner(
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: WebSubscriptions(currentUser: widget.currentUser,),
          ),
          Flexible(
            flex: 8,
            child: gridOfLives(),
          ),
        ],
      ),
    );
  }

  Widget gridOfLives() {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift
    ]);
    //queryBuilder.whereEqualTo(LiveStreamingModel.keyStreamingPrivate, false);
    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    //queryBuilder.whereNotContainedIn(LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);

    return ParseLiveGridWidget<LiveStreamingModel>(
      query: queryBuilder,
      crossAxisCount: Responsive.isWebOrDeskTop(context)
          ? 5
          : Responsive.isTablet(context)
              ? 3
              : 2,
      reverse: false,
      crossAxisSpacing: Responsive.isWebOrDeskTop(context) ? 15 : 2,
      mainAxisSpacing: Responsive.isWebOrDeskTop(context) ? 15 : 2,
      lazyLoading: false,
      childAspectRatio: Responsive.isWebOrDeskTop(context) ? 0.8 : 0.6,
      primary: true,
      shrinkWrap: true,
      listenOnAllSubItems: true,
      listeningIncludes: [
        LiveStreamingModel.keyAuthor,
        LiveStreamingModel.keyAuthorInvited,
      ],
      duration: Duration(seconds: 0),
      animationController: _animationController,
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<LiveStreamingModel> snapshot) {
        if (snapshot.hasData) {
          LiveStreamingModel liveStreaming = snapshot.loadedData!;

          return GestureDetector(
            onTap: () {
              checkPermission(false,
                  channel: liveStreaming.getStreamingChannel,
                  liveStreamingModel: liveStreaming);
            },
            child: Column(
              children: [
                ContainerCorner(
                  height: 200,
                  width: 200,
                  color: kTransparentColor,
                  child: QuickActions.photosWidget(liveStreaming.getImage!.url!,
                      borderRadius: 10),
                ),
                ContainerCorner(
                  marginLeft: 3,
                  marginTop: 5,
                  child: Row(
                    children: [
                      QuickActions.avatarWidget(
                        liveStreaming.getAuthor!,
                        height: 47,
                        width: 47,
                        margin: EdgeInsets.only(right: 5),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ContainerCorner(
                            width: 100,
                            child: TextWithTap(
                              liveStreaming.getAuthor!.getFirstName!,
                              color: QuickHelp.isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                              marginRight: 10,
                              marginLeft: 5,
                              fontSize: 16,
                            ),
                          ),
                          Row(children: [
                            SvgPicture.asset(
                              "assets/svg/dolar_diamond.svg",
                              height: 15,
                              width: 15,
                            ),
                            TextWithTap(
                              liveStreaming.getDiamonds.toString(),
                              color: QuickHelp.isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                              marginRight: 10,
                              marginLeft: 5,
                            ),
                            SvgPicture.asset(
                              "assets/svg/ic_small_viewers.svg",
                              color: kColorsBlue100,
                              height: 15,
                              width: 15,
                            ),
                            TextWithTap(
                              liveStreaming.getViewersCount!.toString(),
                              color: QuickHelp.isDarkMode(context)
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w500,
                              marginRight: 10,
                              marginLeft: 5,
                            ),
                          ]),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.count(
              crossAxisCount: Responsive.isWebOrDeskTop(context)
                  ? 5
                  : Responsive.isTablet(context)
                      ? 3
                      : 2,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: Responsive.isWebOrDeskTop(context) ? 0.8 : 0.8,
              children: List.generate(
                  24,
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
      },
      queryEmptyElement: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: QuickActions.noContentFound(
              "live_streaming.no_live_title".tr(),
              "live_streaming.no_live_explain".tr(),
              "assets/svg/ic_tab_live_selected.svg",
              color: kDisabledColor),
        ),
      ),
      gridLoadingElement: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: Responsive.isWebOrDeskTop(context)
              ? 5
              : Responsive.isTablet(context)
                  ? 3
                  : 2,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: Responsive.isWebOrDeskTop(context) ? 0.8 : 0.8,
          children: List.generate(
              24,
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
      ),
    );
  }

  Widget initQuery() {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift
    ]);
    //queryBuilder.whereEqualTo(LiveStreamingModel.keyStreamingPrivate, false);
    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, false);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);

    return Padding(
      padding: EdgeInsets.only(right: 2, left: 2),
      child: ParseLiveGridWidget<LiveStreamingModel>(
        query: queryBuilder,
        crossAxisCount: 2,
        reverse: false,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        lazyLoading: false,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        listenOnAllSubItems: true,
        scrollController: ScrollController(keepScrollOffset: false),
        listeningIncludes: [
          LiveStreamingModel.keyAuthor,
          LiveStreamingModel.keyAuthorInvited,
        ],
        duration: Duration(seconds: 0),
        animationController: _animationController,
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<LiveStreamingModel> snapshot) {
          if (snapshot.hasData) {
            LiveStreamingModel liveStreaming = snapshot.loadedData!;

            return GestureDetector(
              onTap: () {
                checkPermission(false,
                    channel: liveStreaming.getStreamingChannel,
                    liveStreamingModel: liveStreaming);
              },
              child: Container(),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        queryEmptyElement: Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: QuickActions.noContentFound(
              "live_streaming.no_live_title".tr(),
              "live_streaming.no_live_explain".tr(),
              "assets/svg/ic_tab_live_default.svg",
            ),
          ),
        ),
        gridLoadingElement: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget tabsRows(
    String title,
    int position,
  ) {
    return Text(
      title.tr(),
    );
  }

  Widget tabsFilters(
    String icon,
    String title,
    int position,
  ) {
    return ContainerCorner(
      borderRadius: 10,
      color: kGreyColor0,
      child: Padding(
        padding: EdgeInsets.all(3.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon),
            TextWithTap(
              title.tr(),
              fontSize: 12,
              marginLeft: 5,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkPermission(bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) async {
    if (QuickHelp.isAndroidPlatform()) {
      PermissionStatus status = await Permission.storage.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission android');

      checkStatus(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else if (QuickHelp.isIOSPlatform()) {
      PermissionStatus status = await Permission.photos.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission ios');

      checkStatus(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else if (QuickHelp.isWebPlatform()) {

      _gotoLiveScreen(isBroadcaster, channel: channel, liveStreamingModel: liveStreamingModel);

      print('Permission Web');
    } else {
      print('Permission other device');
      _gotoLiveScreen(isBroadcaster, channel: channel, liveStreamingModel: liveStreamingModel);
    }
  }

  void checkStatus(PermissionStatus status, PermissionStatus status2,
      PermissionStatus status3, bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) {
    if (status.isDenied || status2.isDenied || status3.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.

      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access".tr(),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          message: "permissions.photo_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);

            //if (await Permission.camera.request().isGranted) {
            // Either the permission was already granted before or the user just granted it.
            //}

            // You can request multiple permissions at once.
            Map<Permission, PermissionStatus> statuses = await [
              Permission.camera,
              Permission.photos,
              Permission.storage,
              Permission.microphone,
            ].request();

            if (statuses[Permission.camera]!.isGranted &&
                    statuses[Permission.photos]!.isGranted ||
                statuses[Permission.storage]!.isGranted ||
                statuses[Permission.microphone]!.isGranted) {
              _gotoLiveScreen(isBroadcaster,
                  channel: channel, liveStreamingModel: liveStreamingModel);
            }
          });
    } else if (status.isPermanentlyDenied ||
        status2.isPermanentlyDenied ||
        status3.isPermanentlyDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access_denied".tr(),
          confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
          message: "permissions.photo_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () {
            QuickHelp.hideLoadingDialog(context);

            openAppSettings();
          });
    } else if (status.isGranted && status2.isGranted && status3.isGranted) {
      //_uploadPhotos(ImageSource.gallery);
      _gotoLiveScreen(isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    }

    print('Permission $status');
    print('Permission $status2');
    print('Permission $status3');
  }

  _gotoLiveScreen(bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) async {
    if (widget.currentUser!.getAvatar == null) {
      QuickHelp.showDialogLivEend(
        context: context,
        dismiss: true,
        title: 'live_streaming.photo_needed'.tr(),
        confirmButtonText: 'live_streaming.add_photo'.tr(),
        message: 'live_streaming.photo_needed_explain'.tr(),
        onPressed: () {
          QuickHelp.goBackToPreviousPage(context);
          ProfileScreen(
            currentUser: widget.currentUser,
          );
        },
      );
    } else {
      if (isBroadcaster) {
        QuickHelp.goToNavigatorScreen(
            context, LivePreviewScreen(currentUser: widget.currentUser!),
            route: LivePreviewScreen.route);
      } else {
        if (liveStreamingModel!.getPrivate!) {
          if (!liveStreamingModel.getPrivateViewersId!
              .contains(widget.currentUser!.objectId!)) {
            openPayPrivateLiveSheet(liveStreamingModel);
          } else {
            QuickHelp.goToNavigatorScreen(
                context,
                LiveStreamingScreen(
                  channelName: channel!,
                  isBroadcaster: false,
                  currentUser: widget.currentUser!,
                  mUser: liveStreamingModel.getAuthor,
                  mLiveStreamingModel: liveStreamingModel,
                ),
                route: LiveStreamingScreen.route);
          }
        } else {
          QuickHelp.goToNavigatorScreen(
              context,
              LiveStreamingScreen(
                channelName: channel!,
                isBroadcaster: false,
                currentUser: widget.currentUser!,
                mUser: liveStreamingModel.getAuthor,
                mLiveStreamingModel: liveStreamingModel,
              ),
              route: LiveStreamingScreen.route);
        }
      }
    }
  }

  showPermissionDenied(bool isCamera) {
    QuickHelp.showAppNotificationAdvanced(
      context: context,
      title: "permissions.live_access_denied".tr(),
      message: "permissions.live_access_denied_explain".tr(),
    );
  }

  void openPayPrivateLiveSheet(LiveStreamingModel live) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showPayPrivateLiveBottomSheet(live);
        });
  }

  Widget _showPayPrivateLiveBottomSheet(LiveStreamingModel live) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
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
                  child: Scaffold(
                    appBar: AppBar(
                      toolbarHeight: 35.0,
                      backgroundColor: kTransparentColor,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      actions: [
                        IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close)),
                      ],
                    ),
                    backgroundColor: kTransparentColor,
                    body: Column(
                      children: [
                        Center(
                            child: TextWithTap(
                          "live_streaming.private_live".tr(),
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                          marginBottom: 15,
                        )),
                        Center(
                          child: TextWithTap(
                            "live_streaming.private_live_explain".tr(),
                            color: Colors.white,
                            fontSize: 16,
                            marginLeft: 20,
                            marginRight: 20,
                            marginTop: 20,
                          ),
                        ),
                        Expanded(
                            child: Lottie.network(
                                live.getPrivateGift!.getFile!.url!,
                                width: 150,
                                height: 150,
                                animate: true,
                                repeat: true)),
                        ContainerCorner(
                          color: kTransparentColor,
                          marginTop: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/svg/ic_coin_with_star.svg",
                                width: 24,
                                height: 24,
                              ),
                              TextWithTap(
                                live.getPrivateGift!.getTickets.toString(),
                                color: Colors.white,
                                fontSize: 18,
                                marginLeft: 5,
                              )
                            ],
                          ),
                        ),
                        ContainerCorner(
                          borderRadius: 10,
                          height: 50,
                          width: 150,
                          color: kPrimaryColor,
                          onTap: () {
                            if (widget.currentUser!.getCredits! >=
                                live.getPrivateGift!.getTickets!) {
                              _payForPrivateLive(live);
                            } else {
                              CoinsFlowPayment(
                                context: context,
                                currentUser: widget.currentUser!,
                                showOnlyCoinsPurchase: true,
                                onCoinsPurchased: (coins) {
                                  print(
                                      "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");

                                  if (widget.currentUser!.getCredits! >=
                                      live.getPrivateGift!.getTickets!) {
                                    _payForPrivateLive(live);
                                    //sendGift(live);
                                  }
                                },
                              );
                            }
                          },
                          marginTop: 15,
                          marginBottom: 40,
                          child: Center(
                            child: TextWithTap(
                              "live_streaming.pay_for_live".tr(),
                              color: Colors.white,
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

  _payForPrivateLive(LiveStreamingModel live) async {
    QuickHelp.showLoadingDialog(context);

    ParseResponse response = await QuickCloudCode.sendGift(
        authorId: live.getAuthor!.objectId!,
        credits: live.getPrivateGift!.getTickets!);

    if (response.success) {
      updateCurrentUserCredit(
          live.getPrivateGift!.getTickets!, live, live.getPrivateGift!);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  updateCurrentUserCredit(
      int coins, LiveStreamingModel live, GiftsModel giftsModel) async {
    widget.currentUser!.removeCredit = coins;
    ParseResponse userResponse = await widget.currentUser!.save();
    if (userResponse.success) {
      widget.currentUser = userResponse.results!.first as UserModel;

      sendMessage(live, giftsModel);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  sendMessage(LiveStreamingModel live, GiftsModel giftsModel) async {
    live.addDiamonds = QuickHelp.getDiamondsForReceiver(live.getPrivateGift!.getTickets!);
    await live.save();

    LiveMessagesModel liveMessagesModel = new LiveMessagesModel();
    liveMessagesModel.setAuthor = widget.currentUser!;
    liveMessagesModel.setAuthorId = widget.currentUser!.objectId!;

    liveMessagesModel.setLiveStreaming = live;
    liveMessagesModel.setLiveStreamingId = live.objectId!;

    liveMessagesModel.setGift = giftsModel;
    liveMessagesModel.setGiftId = giftsModel.objectId!;

    liveMessagesModel.setMessage = "";
    liveMessagesModel.setMessageType = LiveMessagesModel.messageTypeGift;

    ParseResponse response = await liveMessagesModel.save();
    if (response.success) {
      QuickHelp.goToNavigatorScreen(
          context,
          LiveStreamingScreen(
            channelName: live.getStreamingChannel!,
            isBroadcaster: false,
            currentUser: widget.currentUser!,
            mUser: live.getAuthor,
            mLiveStreamingModel: live,
          ),
          route: LiveStreamingScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }
}
