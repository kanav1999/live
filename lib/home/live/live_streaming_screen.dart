import 'dart:async';

import 'package:blur/blur.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/coins/coins_payment_web_widget.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/app/config.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_cloud.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/coins/coins_payment_widget.dart';
import 'package:heyto/models/GiftsModel.dart';
import 'package:heyto/models/LiveMessagesModel.dart';
import 'package:heyto/models/LiveStreamingModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/button_rounded.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

// ignore: must_be_immutable
class LiveStreamingScreen extends StatefulWidget {
  final String? channelName;
  final bool? isBroadcaster;
  UserModel? currentUser;
  UserModel? mUser;
  LiveStreamingModel? mLiveStreamingModel;

  static String route = "/home/live/streaming";

  LiveStreamingScreen({
    Key? key,
    this.channelName,
    this.isBroadcaster,
    this.currentUser,
    this.mUser,
    this.mLiveStreamingModel,
  }) : super(key: key);

  @override
  _LiveStreamingScreenState createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with TickerProviderStateMixin {
  final _users = <int>[];
  final usersInLiveBeforePrivate = <UserModel>[];
  final joinedLiveUsers = [];
  final usersToInvite = [];
  late RtcEngine _engine;
  bool muted = false;
  bool liveMessageSent = false;
  late int streamId;
  bool liveEnded = false;
  bool following = false;
  bool liveJoined = false;
  LiveQuery liveQuery = LiveQuery();
  Subscription? subscription;
  String liveCounter = "0";
  String diamondsCounter = "0";
  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;
  int bottomSheetCurrentIndexGift = 0;

  bool warningShows = false;
  bool isPrivateLive = false;
  bool initGift = false;

  String mUserDiamonds = "";

  TextEditingController textEditingController = TextEditingController();

  late FocusNode? chatTextFieldFocusNode;
  GiftsModel? selectedGif;

  void initializeSelectedGif(GiftsModel gift) {
    setState(() {
      selectedGif = gift;
    });
  }

  _getDefaultGiftPrice() async {
    QueryBuilder<GiftsModel> queryGift = QueryBuilder<GiftsModel>(GiftsModel());
    queryGift.whereEqualTo(
        GiftsModel.keyGiftCategories, GiftsModel.giftCategoryTypeClassic);
    queryGift.setLimit(1);

    ParseResponse response = await queryGift.query();
    if (response.success) {
      initializeSelectedGif(response.results as GiftsModel);
      setState(() {
        selectedGif = response.results as GiftsModel;
        print("Selected gif by default");
      });
    } else {
      print("deu errado");
    }
  }

  startTimerToEndLive(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (!isLiveJoined()) {
        if (widget.isBroadcaster!) {
          QuickHelp.showDialogLivEend(
            context: context,
            dismiss: false,
            title: 'live_streaming.cannot_stream'.tr(),
            confirmButtonText: 'live_streaming.finish_live'.tr(),
            message: 'live_streaming.cannot_stream_ask'.tr(),
            onPressed: () {
              //QuickHelp.goToPageWithClear(context, HomePage(currentUser: currentUser));
              QuickHelp.goBackToPreviousPage(context);
              QuickHelp.goBackToPreviousPage(context);
              //_onCallEnd(context),
            },
          );
        } else {
          setState(() {
            liveEnded = true;
          });

          widget.mLiveStreamingModel!.setStreaming = false;
          widget.mLiveStreamingModel!.save();
        }
      }
    });
  }

  startTimerToConnectLive(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (!liveJoined) {
        QuickHelp.showAppNotification(
            context: context, title: "can_not_try".tr());
        QuickHelp.goBackToPreviousPage(context);
      }
    });
  }

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk and leave channel
    _engine.stopPreview();
    _engine.destroy();

    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    textEditingController.dispose();

    //_secureScreen(false);
    super.dispose();
  }

  @override
  void initState() {
    // initialize agora sdk

    initializeAgora();

    chatTextFieldFocusNode = FocusNode();

    _animationController = AnimationController.unbounded(vsync: this);

    if(!widget.isBroadcaster!){
      setState(() {
        mUserDiamonds = widget.mUser!.getDiamondsTotal.toString();
      });
    }

    super.initState();
  }

  bool _showChat = false;
  bool _hideSendButton = false;

  void showChatState() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  void toggleSendButton(bool active) {
    setState(() {
      _hideSendButton = active;
    });
  }

  Future<void> initializeAgora() async {
    print("AgoraLive initializeAgora channel");

    if (QuickHelp.isMobile()) {
      startTimerToConnectLive(context, 15);
    }

    await _initAgoraRtcEngine();

    if (!widget.isBroadcaster!) {
      if (widget.currentUser!.getFollowing!.contains(widget.mUser!.objectId)) {
        following = true;
      }
    }

    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          if (QuickHelp.isWebPlatform()) {
            if (widget.isBroadcaster! && uid == widget.currentUser!.getUid) {
              if (widget.isBroadcaster! && !liveJoined) {
                createLive(widget.mLiveStreamingModel!);

                setState(() {
                  //_users.add(uid);
                  liveJoined = true;
                });
              }
            }
          } else {
            startTimerToEndLive(context, 5);
          }

          print('AgoraLive isBroadcaster: $channel, uid: $uid,  elapsed '
              '$elapsed');
        });
      },
      firstLocalVideoFrame: (width, height, elapsed) {
        print(
            'AgoraLive firstLocalVideoFrame: $width, $height, time: $elapsed');

        if (widget.isBroadcaster! && !liveJoined) {
          createLive(widget.mLiveStreamingModel!);

          setState(() {
            liveJoined = true;
          });
        }
      },
      error: (ErrorCode errorCode) {
        print('AgoraLive error $errorCode');

        // JoinChannelRejected
        if (errorCode == ErrorCode.JoinChannelRejected) {
          _engine.leaveChannel();
          QuickHelp.goToNavigatorScreen(
              context, HomeScreen(currentUser: widget.currentUser!),
              route: HomeScreen.route);
        }
      },
      leaveChannel: (stats) {
        setState(() {
          print('AgoraLive onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          _users.add(uid);
          usersInLiveBeforePrivate.add(widget.mUser!);
          liveJoined = true;
          joinedLiveUsers.add(uid);
        });

        print('AgoraLive userJoined: $uid');
        updateViewers(uid, widget.currentUser!.objectId!);
      },
      userOffline: (uid, elapsed) {
        if (!widget.isBroadcaster!) {
          setState(() {
            print('AgoraLive userOffline: $uid');
            _users.remove(uid);

            if (uid == widget.mUser!.getUid) {
              liveEnded = true;
              liveJoined = false;
            }
          });
        }
      },
    ));

    print("AgoraLive before init channel");
    await _engine.joinChannel(null, widget.channelName!,
        widget.currentUser!.objectId, widget.currentUser!.getUid!);

    print("AgoraLive init channel");
  }

  Future<void> _initAgoraRtcEngine() async {
    print("AgoraLive start _initAgoraRtcEngine");

    // Create RTC client instance
    RtcEngineContext context = RtcEngineContext(Config.agoraAppId);
    _engine = await RtcEngine.createWithContext(context);

    if (widget.isBroadcaster! && QuickHelp.isMobile()) {
      //streamId = (await _engine.createDataStream(true, false))!;
    }

    _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster!) {
      _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      _engine.setClientRole(ClientRole.Audience);
    }
    _engine.enableVideo();
    _engine.startPreview();
  }

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    if (isPrivateLive) {
      if (widget.mLiveStreamingModel!.getAuthorId !=
          widget.currentUser!.objectId) {
        openPayPrivateLiveSheet(widget.mLiveStreamingModel!);
      }
    }

    return WillPopScope(
      onWillPop: () => closeAlert(),
      child: GestureDetector(
        onTap: () {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
            showChatState();
          }
        },
        child: ToolBar(
          centerTitle: true,
          titleChild: widget.isBroadcaster!
              ? Visibility(
                  visible: isLiveJoined() && !liveEnded,
                  child: ContainerCorner(
                    height: 30,
                    width: 60,
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: 40,
                    child: TextWithTap(
                      "live_streaming.live_".tr(),
                      color: Colors.white,
                      fontSize: 17,
                      textAlign: TextAlign.center,
                      alignment: Alignment.center,
                    ),
                  ),
                )
              : Visibility(
                  visible: !liveEnded && isLiveJoined(),
                  child: ContainerCorner(
                    width: 100,
                    height: 30,
                    borderRadius: 30,
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_small_viewers.svg",
                          height: 18,
                          color: Colors.white,
                        ),
                        TextWithTap(
                          liveCounter,
                          color: Colors.white,
                          fontSize: 15,
                          marginRight: 15,
                          marginLeft: 5,
                        ),
                      ],
                    ),
                  ),
                ),
          extendBodyBehindAppBar: true,
          backgroundColor: isLiveJoined()
              ? Colors.black.withOpacity(0.2)
              : kTransparentColor,
          //leftButtonWidget: widget.isBroadcaster! ? QuickActions.avatarWidget(widget.currentUser!,) : QuickHelp.isIOSPlatform() ? Icon(Icons.arrow_back_ios) : Icon(Icons.arrow_back),
          leftButtonWidget: QuickActions.avatarWidget(widget.isBroadcaster! ? widget.currentUser! : widget.mUser!,),
          //onLeftButtonTap: !widget.isBroadcaster! ? () => closeAlert() : null,
          iconColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          rightButtonIcon: Icons.close,
          //rightButtonIcon: widget.isBroadcaster! ? Icons.close : null,
          //rightButtonIcon: widget.isBroadcaster!? Icons.close : !liveEnded ? Icons.add_photo_alternate_outlined : null,
          rightIconColor: !liveEnded && isLiveJoined() ? Colors.white : null,
          //rightButtonPress:  widget.isBroadcaster! ? () => closeAlert() : () => requestLive(),
          //rightButtonPress: widget.isBroadcaster! ? () => closeAlert() : () => null,
          rightButtonPress: () => closeAlert() ,
          child: !Responsive.isWebOrDeskTop(context) ? getBody() : webBody(),
        ),
      ),
    );
  }

  Widget webBody() {

    var size = MediaQuery.of(context).size;
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Blur(
            blurColor: Colors.black,
            blur: 60,
            child: QuickActions.photosWidget(
                widget.mLiveStreamingModel!.getImage!.url!)
        ),
        Row(
          children: [
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.only(
                        right: Responsive.isTablet(context) ? 5 : 50),
                    child: _bottomBar(),
                  )),
                  if (!widget.isBroadcaster!) chatInputField(),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: ContainerCorner(
                height: size.height,
                child: Stack(
                  children: [
                    _getRenderViews(),
                    Visibility(
                      visible: !isLiveJoined(),
                      child: getLoadingScreen(),
                    ),
                    if (!widget.isBroadcaster!)
                      Positioned(
                        bottom: 1,
                        child: ContainerCorner(
                          marginLeft: 10,
                          marginRight: 10,
                          marginBottom: 20,
                          borderRadius: 50,
                          width: size.width / 3.3,
                          color: Colors.black.withOpacity(0.3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                children: [
                                  ContainerCorner(
                                    marginRight: 10,
                                    marginLeft: 6,
                                    color: Colors.black.withOpacity(0.5),
                                    child: QuickActions.avatarWidget(
                                      widget.mUser!,
                                    ),
                                    borderRadius: 50,
                                    height: 60,
                                    width: 60,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextWithTap(
                                        widget.mUser!.getFullName!,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SvgPicture.asset(
                                            "assets/svg/dolar_diamond.svg",
                                            height: 25,
                                          ),
                                          TextWithTap(
                                            widget.mUser!.getDiamondsTotal!
                                                .toString(),
                                            color: Colors.white,
                                            fontSize: 14,
                                            marginLeft: 3,
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                              ContainerCorner(
                                marginLeft: 10,
                                marginRight: 6,
                                colors: [
                                  following ? kColorsIndigo500 : kPrimaryColor,
                                  following ? kColorsIndigo500 : kPrimaryColor
                                ],
                                child: ContainerCorner(
                                    color: kTransparentColor,
                                    marginAll: 5,
                                    height: 50,
                                    width: 50,
                                    child: Center(
                                      child: Icon(
                                        following ? Icons.done : Icons.add,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    )),
                                borderRadius: 50,
                                height: 40,
                                width: 40,
                                onTap: () {
                                  if (!following) {
                                    followOrUnfollow();
                                    sendMessage(
                                        LiveMessagesModel.messageTypeFollow,
                                        "",
                                        widget.currentUser!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
            if (!Responsive.isTablet(context))
              Flexible(
                flex: 2,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 50, right: 10, bottom: 10),
                  child: widget.isBroadcaster!
                      ? broadCasterTools()
                      : CoinsFlowWidget(
                          currentUser: widget.currentUser!,
                    onGiftSelected: (gift) => sendMessage(
                        LiveMessagesModel.messageTypeGift,
                        LiveMessagesModel.messageTypeGift,
                        widget.currentUser!,
                      giftsModel: gift
                    ),
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget broadCasterTools() {
    var size = MediaQuery.of(context).size;
    return ContainerCorner(
      radiusTopLeft: 25,
      radiusTopRight: 25,
      height: size.height,
      marginTop: 200,
      color: Colors.black.withOpacity(0.4),
      child: Column(
        children: [
          TextWithTap(
            "live_streaming.tools_".tr(),
            color: Colors.white,
            fontSize: 20,
            marginTop: 15,
          ),
          Expanded(
            child: GridView.count(
              childAspectRatio: 1.7,
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  child: TextButton(
                    onPressed: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_small_viewers.svg",
                          height: 30,
                          color: kColorsBlue100,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextWithTap(
                              "live_streaming.views_".tr(),
                              color: Colors.white,
                              marginLeft: 10,
                              fontSize: 14,
                            ),
                            if (verifyNumber(liveCounter))
                              ContainerCorner(
                                width: 35,
                                child: FittedBox(
                                  child: TextWithTap(
                                    liveCounter,
                                    color: Colors.white,
                                    marginLeft: 3,
                                  ),
                                ),
                              ),
                            if (!verifyNumber(liveCounter))
                              TextWithTap(
                                liveCounter,
                                color: Colors.white,
                                marginLeft: 3,
                              )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  child: TextButton(
                    onPressed: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/dolar_diamond.svg",
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextWithTap(
                              "live_streaming.diamonds_".tr(),
                              color: Colors.white,
                              marginLeft: 2,
                              marginBottom: 1,
                            ),
                            if (verifyNumber(diamondsCounter))
                              ContainerCorner(
                                width: 35,
                                child: FittedBox(
                                  child: TextWithTap(
                                    diamondsCounter,
                                    color: Colors.white,
                                    marginLeft: 3,
                                    marginBottom: 1,
                                  ),
                                ),
                              ),
                            if (!verifyNumber(diamondsCounter))
                              TextWithTap(
                                diamondsCounter,
                                color: Colors.white,
                                marginLeft: 3,
                                marginBottom: 1,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  child: TextButton(
                    onPressed: () => _onToggleMute(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          muted ? Icons.mic : Icons.mic_off_rounded,
                          color: muted ? kPrimaryColor : Colors.red,
                          size: 30,
                        ),
                        TextWithTap(
                          "live_streaming.toggle_audio".tr(),
                          color: Colors.white,
                          marginLeft: 10,
                        )
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
  }

  bool verifyNumber(String number) {
    int nmr = int.parse(number);
    if (nmr > 99) {
      return true;
    } else {
      return false;
    }
  }

  Widget getBody() {
    return Center(
      child: Stack(
        children: [
          Stack(
            children: [
              _getRenderViews(),
              Visibility(
                visible: !isLiveJoined(),
                child: getLoadingScreen(),
              ),
            ],
          ),
          Visibility(
            visible: visibleToolbar() && isLiveJoined(),
            child: _toolbar(),
          ),
          Visibility(
              visible: !liveEnded && isLiveJoined(),
              child: SafeArea(
                  child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _bottomBar(),
              ))),
        ],
      ),
    );
  }

  bool isLiveJoined() {
    if (liveJoined) {
      return true;
    } else {
      return false;
    }
  }

  bool visibleToolbar() {
    if (widget.isBroadcaster!) {
      return true;
    } else if (!widget.isBroadcaster! && liveEnded) {
      return false;
    } else {
      return false;
    }
  }

  requestLive() {
    sendMessage(LiveMessagesModel.messageTypeCoHost, "", widget.currentUser!);
  }

  closeAlert() {
    if (!widget.isBroadcaster!) {
      saveLiveUpdate();
    } else {
      if (liveJoined == false && liveEnded == true) {
        QuickHelp.goToNavigatorScreen(
            context, HomeScreen(currentUser: widget.currentUser!),
            route: HomeScreen.route);
      } else {
        QuickHelp.showDialogLivEend(
          context: context,
          title: 'live_streaming.live_'.tr(),
          confirmButtonText: 'live_streaming.finish_live'.tr(),
          message: 'live_streaming.finish_live_ask'.tr(),
          onPressed: () {
            QuickHelp.goBackToPreviousPage(context);
            _onCallEnd(context);
          },
        );
      }
    }
  }

  Widget _toolbar() {
    return Container(
        margin: EdgeInsets.only(top: 50),
        alignment: Alignment.topLeft,
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SvgPicture.asset(
                      "assets/svg/ic_small_viewers.svg",
                      height: 16,
                    ),
                    SvgPicture.asset(
                      "assets/svg/dolar_diamond.svg",
                      height: 25,
                    ),
                  ],
                ),
                Column(
                  children: [
                    TextWithTap(
                      liveCounter.toString(),
                      color: Colors.white,
                      fontSize: 16,
                      marginLeft: 10,
                    ),
                    TextWithTap(
                      diamondsCounter,
                      color: Colors.white,
                      fontSize: 16,
                      marginLeft: 9,
                      marginBottom: 7,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  Widget _bottomBar() {
    return widget.isBroadcaster! ? streamerBottom() : audianceBottom();
  }

  Widget _getRenderViews() {
    if (widget.isBroadcaster!) {
      return RtcLocalView.SurfaceView();
    } else {
      return RtcRemoteView.SurfaceView(
        uid: widget.mUser!.getUid!,
        channelId: widget.channelName!,
      );
    }
  }

  Widget showLiveEnded() {
    return Container(
      child: Stack(
        children: [
          Container(
            color: QuickHelp.isDarkMode(context)
                ? kContentColorDarkTheme
                : kContentColorLightTheme,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWithTap(
                "live_streaming.live_ended".tr().toUpperCase(),
                marginBottom: 20,
                fontSize: 16,
                color: QuickHelp.isDarkMode(context)
                    ? kContentColorLightTheme
                    : kContentColorDarkTheme,
              ),
              Container(
                margin: EdgeInsets.only(bottom: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/svg/ic_small_viewers.svg",
                      height: 18,
                      color: QuickHelp.isDarkMode(context)
                          ? kContentColorLightTheme
                          : kContentColorDarkTheme,
                    ),
                    TextWithTap(
                      widget.mLiveStreamingModel!.getViewers!.length.toString(),
                      color: QuickHelp.isDarkMode(context)
                          ? kContentColorLightTheme
                          : kContentColorDarkTheme,
                      fontSize: 15,
                      marginRight: 15,
                      marginLeft: 5,
                    ),
                    SvgPicture.asset(
                      "assets/svg/dolar_diamond.svg",
                      height: 28,
                    ),
                    TextWithTap(
                      diamondsCounter,
                      color: QuickHelp.isDarkMode(context)
                          ? kContentColorLightTheme
                          : kContentColorDarkTheme,
                      fontSize: 15,
                      marginLeft: 3,
                    ),
                  ],
                ),
              ),
              QuickActions.avatarBorder(
                widget.mUser!,
                width: 110,
                height: 110,
                borderWidth: 2,
                borderColor: QuickHelp.isDarkMode(context)
                    ? kPrimaryColor
                    : kContentColorDarkTheme,
              ),
              TextWithTap(
                widget.mUser!.getFullName!,
                marginTop: 15,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: QuickHelp.isDarkMode(context)
                    ? kContentColorLightTheme
                    : kContentColorDarkTheme,
              ),
              Visibility(
                visible: !following,
                child: ButtonRounded(
                  text: "live_streaming.live_follow".tr(),
                  fontSize: 17,
                  borderRadius: 20,
                  width: 120,
                  textAlign: TextAlign.center,
                  marginTop: 40,
                  color: kPrimaryColor,
                  textColor: Colors.white,
                  onTap: () => followOrUnfollow(),
                ),
              ),
              Visibility(
                visible: following,
                child: ContainerCorner(
                  height: 30,
                  marginLeft: 40,
                  marginRight: 40,
                  colors: [kWarninngColor, kPrimaryColor],
                  child: TextWithTap(
                    "live_streaming.you_follow".tr(),
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      //color: Colors.blue,
    );
  }

  Widget getLoadingScreen() {
    if (liveEnded) {
      return Container(
        child: Stack(
          children: [
            Container(
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : kContentColorDarkTheme,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextWithTap(
                  "live_streaming.live_ended".tr().toUpperCase(),
                  marginBottom: 20,
                  fontSize: 16,
                  color: !QuickHelp.isDarkMode(context)
                      ? kContentColorLightTheme
                      : kContentColorDarkTheme,
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_small_viewers.svg",
                        height: 18,
                        color: !QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : kContentColorDarkTheme,
                      ),
                      TextWithTap(
                        widget.mLiveStreamingModel!.getViewers!.length.toString(),
                        color: !QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : kContentColorDarkTheme,
                        fontSize: 15,
                        marginRight: 15,
                        marginLeft: 5,
                      ),
                      SvgPicture.asset(
                        "assets/svg/dolar_diamond.svg",
                        height: 28,
                      ),
                      TextWithTap(
                        diamondsCounter,
                        color: !QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : kContentColorDarkTheme,
                        fontSize: 15,
                        marginLeft: 3,
                      ),
                    ],
                  ),
                ),
                QuickActions.avatarBorder(
                  widget.isBroadcaster! ? widget.currentUser! : widget.mUser!,
                  width: 110,
                  height: 110,
                  borderWidth: 2,
                  borderColor: QuickHelp.isDarkMode(context)
                      ? kPrimaryColor
                      : kContentColorDarkTheme,
                ),
                TextWithTap(
                  widget.isBroadcaster!
                      ? widget.currentUser!.getFullName!
                      : widget.mUser!.getFullName!,
                  marginTop: 15,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: QuickHelp.isDarkMode(context)
                      ? Colors.white
                      : Colors.black,
                ),
                Visibility(
                  visible: !widget.isBroadcaster!,
                  child: Column(
                    children: [
                      Visibility(
                        visible: !following,
                        child: ButtonRounded(
                          text: "live_streaming.live_follow".tr(),
                          fontSize: 17,
                          borderRadius: 20,
                          marginLeft: 50,
                          marginRight: 50,
                          width: 120,
                          textAlign: TextAlign.center,
                          marginTop: 40,
                          color: kPrimaryColor,
                          textColor: Colors.white,
                          onTap: () {
                            followOrUnfollow();
                          },
                        ),
                      ),
                      Visibility(
                        visible: following,
                        child: ContainerCorner(
                          marginRight: 50,
                          marginLeft: 50,
                          borderRadius: 50,
                          height: 30,
                          marginTop: 15,
                          colors: [kWarninngColor, kPrimaryColor],
                          child: Center(
                              child: TextWithTap(
                                "live_streaming.you_follow".tr(),
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        //color: Colors.blue,
      );
    } else {
      return Container(
        child: Stack(
          children: [
            QuickActions.photosWidget(
                widget.mLiveStreamingModel!.getImage!.url!),
            Center(
              child: QuickActions.avatarBorder(
                  widget.isBroadcaster! ? widget.currentUser! : widget.mUser!,
                  width: 140,
                  height: 140,
                  borderWidth: 2,
                  borderColor: kPrimaryColor),
            ),
          ],
        ),
        //color: Colors.blue,
      );
    }
  }

  void followOrUnfollow() async {
    if (widget.currentUser!.getFollowing!.contains(widget.mUser!.objectId)) {
      widget.currentUser!.removeFollowing = widget.mUser!.objectId!;

      setState(() {
        following = false;
      });
    } else {
      widget.currentUser!.setFollowing = widget.mUser!.objectId!;

      setState(() {
        following = true;
      });
    }

    await widget.currentUser!.save();

    ParseResponse parseResponse = await QuickCloudCode.followUser(
        isFollowing: false,
        author: widget.currentUser!,
        receiver: widget.mUser!);
    if (parseResponse.success) {}
  }

  void _onCallEnd(BuildContext context) {
    saveLiveUpdate();
    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    if (mounted) {
      setState(() {
        liveEnded = true;
        liveJoined = false;
      });
    }
  }

  void saveLiveUpdate() async {
    if (widget.isBroadcaster!) {
      widget.mLiveStreamingModel!.setStreaming = false;
      await widget.mLiveStreamingModel!.save();
      _engine.leaveChannel();
      if (subscription != null) {
        liveQuery.client.unSubscribe(subscription!);
      }
    } else {
      if (liveJoined) {
        widget.mLiveStreamingModel!.removeViewersCount = 1;
        await widget.mLiveStreamingModel!.save();
      }
      _engine.leaveChannel();
      if (subscription != null) {
        liveQuery.client.unSubscribe(subscription!);
      }

      QuickHelp.goToNavigatorScreen(
          context, HomeScreen(currentUser: widget.currentUser!),
          route: HomeScreen.route);
    }
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    //_engine.sendStreamMessage(streamId, "mute user blet");
    _engine.switchCamera();
  }

  updateViewers(int uid, String objectId) async {
    widget.mLiveStreamingModel!.addViewersCount = 1;
    widget.mLiveStreamingModel!.setViewersId = objectId;
    widget.mLiveStreamingModel!.setViewers = uid;

    if (widget.mLiveStreamingModel!.getPrivate!) {
      widget.mLiveStreamingModel!.setPrivateViewersId = objectId;
    }

    ParseResponse parseResponse = await widget.mLiveStreamingModel!.save();
    if (parseResponse.success) {
      this.setState(() {
        liveCounter = widget.mLiveStreamingModel!.getViewersCount.toString();
        diamondsCounter = widget.mLiveStreamingModel!.getDiamonds.toString();
      });

      sendMessage(LiveMessagesModel.messageTypeJoin, "", widget.currentUser!);

      setupCounterLive(widget.mLiveStreamingModel!.objectId!);
      setupCounterLiveUser();
    }
  }

  createLive(LiveStreamingModel liveStreamingModel) async {
    liveStreamingModel.setStreaming = true;

    ParseResponse parseResponse = await liveStreamingModel.save();
    if (parseResponse.success) {
      setupCounterLiveUser();
      setupCounterLive(liveStreamingModel.objectId!);
    }
  }

  Future<List<dynamic>?> inviteFriends() async {
    QueryBuilder<LiveStreamingModel> queryLive =
        QueryBuilder(LiveStreamingModel());
    queryLive.whereEqualTo(
        LiveStreamingModel.keyObjectId, widget.mLiveStreamingModel!.objectId);
    ParseResponse response1 = await queryLive.query();
    if (response1.success) {
      QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());
      query.whereNotEqualTo(
          UserModel.keyObjectId, widget.currentUser!.objectId);
      query.whereContainedIn(UserModel.keyObjectId,
          response1.results!.first[LiveStreamingModel.keyViewersId]);

      ParseResponse response = await query.query();

      if (response.success) {
        if (response.results != null) {
          return response.results;
        } else {
          return AsyncSnapshot.nothing() as dynamic;
        }
      } else {
        return response.error as dynamic;
      }
    } else {
      return response1.error as dynamic;
    }
  }

  void openPeopleToBeInvitedSheet() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showListOfPeopleToBeInvited();
        });
  }

  Widget _showListOfPeopleToBeInvited() {
    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());
    query.whereContainedIn(UserModel.keyObjectId,
        widget.mLiveStreamingModel!.getViewersId as List<dynamic>);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    backgroundColor: kTransparentColor,
                    appBar: AppBar(
                      backgroundColor: kTransparentColor,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                        ),
                      ),
                      actions: [
                        ContainerCorner(
                          height: 20,
                          width: 100,
                          borderRadius: 10,
                          marginRight: 20,
                          marginTop: 10,
                          marginBottom: 10,
                          onTap: () {
                            _privatizeLive(selectedGif!,
                                viewersInLiveId: usersToInvite);
                          },
                          child: Center(
                              child: TextWithTap(
                            "live_streaming.go_live".tr(),
                            color: Colors.white,
                            fontSize: 15,
                          )),
                          colors: [kWarninngColor, kPrimaryColor],
                        ),
                      ],
                      automaticallyImplyLeading: false,
                    ),
                    body: ParseLiveListWidget<UserModel>(
                      query: query,
                      reverse: false,
                      lazyLoading: false,
                      shrinkWrap: true,
                      duration: Duration(seconds: 0),
                      childBuilder: (BuildContext context,
                          ParseLiveListElementSnapshot<UserModel> snapshot) {
                        if (snapshot.hasData) {
                          UserModel user = snapshot.loadedData as UserModel;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (usersToInvite.contains(user.objectId)) {
                                  usersToInvite.remove(user.objectId);
                                } else {
                                  usersToInvite.add(user.objectId);
                                }
                              });
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: ContainerCorner(
                                    child: Row(
                                      children: [
                                        QuickActions.avatarWidget(
                                          user,
                                          width: 50,
                                          height: 50,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWithTap(
                                              user.getFullName!,
                                              marginLeft: 15,
                                              color: Colors.white,
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ContainerCorner(
                                                    marginRight: 10,
                                                    child: Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          "assets/svg/dolar_diamond.svg",
                                                          height: 24,
                                                        ),
                                                        TextWithTap(
                                                          mUserDiamonds,
                                                          fontSize: 14,
                                                          marginLeft: 3,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                usersToInvite.contains(user.objectId)
                                    ? Icon(
                                        Icons.check_circle,
                                        color: kPrimaryColor,
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked,
                                        color: kPrimaryColor,
                                      ),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                      queryEmptyElement: Center(
                        child: QuickActions.noContentFound(
                            "No one found",
                            "No watcher was found in this live",
                            "assets/svg/ic_tab_live_selected.svg"),
                      ),
                      listLoadingElement: Center(
                        child: CircularProgressIndicator(),
                      ),
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

  setupCounterLiveUser() async {

    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());

    if(widget.isBroadcaster!){
      query.whereEqualTo(UserModel.keyObjectId, widget.currentUser!.objectId);
    } else {
      query.whereEqualTo(UserModel.keyObjectId, widget.mUser!.objectId);
    }


    subscription = await liveQuery.client.subscribe(query);

    subscription!.on(LiveQueryEvent.update, (user) async {
      print('*** UPDATE ***');

      if(widget.isBroadcaster!){
        widget.currentUser = user as UserModel;
      } else {
        widget.mUser = user as UserModel;
      }

      setState(() {
        mUserDiamonds = widget.currentUser!.getDiamondsTotal!.toString();
      });

    });

    subscription!.on(LiveQueryEvent.enter, (user) {
      print('*** ENTER ***');

      if(widget.isBroadcaster!){
        widget.currentUser = user as UserModel;
      } else {
        widget.mUser = user as UserModel;
      }

      setState(() {
        mUserDiamonds = widget.currentUser!.getDiamondsTotal!.toString();
      });
    });

  }

  setupCounterLive(String objectId) async {
    QueryBuilder<LiveStreamingModel> query =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
    query.whereEqualTo(LiveStreamingModel.keyObjectId, objectId);

    subscription = await liveQuery.client.subscribe(query);

    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel live) {
      print('*** UPDATE ***');
      widget.mLiveStreamingModel! == live;

      this.setState(() {
        liveCounter = live.getViewersCount.toString();
        diamondsCounter = live.getDiamonds.toString();
      });

      /*LiveStreamingModel updatedLive = response.results!.first as LiveStreamingModel;
      if(updatedLive.getPrivate == true && !widget.isBroadcaster!){
        print('*** UPDATE *** is Private: ${value.getPrivate}');
        if(!updatedLive.getPrivateViewersId!.contains(widget.currentUser!.objectId)){
          openPayPrivateLiveSheet(updatedLive);
        }*/
    });

    subscription!.on(LiveQueryEvent.enter, (LiveStreamingModel value) {
      print('*** ENTER ***');

      widget.mLiveStreamingModel = value;

      this.setState(() {
        liveCounter = widget.mLiveStreamingModel!.getViewersCount.toString();
        diamondsCounter = widget.mLiveStreamingModel!.getDiamonds.toString();
      });
    });
  }

  void openSettingSheet() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showSettingsBottomSheet();
        });
  }

  Widget streamerBottom() {
    //return Container(color: Colors.green,);
    return Container(
      //color: kRedColor1,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            liveMessages(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!Responsive.isWebOrDeskTop(context))
                  ContainerCorner(
                    marginRight: 10,
                    marginLeft: 10,
                    color: Colors.black.withOpacity(0.5),
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginAll: 8,
                      height: 30,
                      width: 30,
                      child: Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    borderRadius: 50,
                    height: 50,
                    width: 50,
                    onTap: () => openSettingSheet(),
                  ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: Responsive.isWebOrDeskTop(context) ? 15 : 1,
                        bottom: Responsive.isWebOrDeskTop(context) ? 20 : 1),
                    //height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: TextField(
                                controller: textEditingController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: kGreyColor1.withOpacity(0.5),
                                  ),
                                  hintText:
                                      "live_streaming.live_tape_here".tr(),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ContainerCorner(
                  marginLeft: 10,
                  marginRight: 10,
                  marginBottom: Responsive.isWebOrDeskTop(context) ? 20 : 1,
                  color: Colors.black.withOpacity(0.5),
                  child: ContainerCorner(
                    color: kTransparentColor,
                    marginAll: 8,
                    height: 30,
                    width: 30,
                    child: SvgPicture.asset(
                      "assets/svg/ic_send_message.svg",
                      color: Colors.white,
                      height: 10,
                      width: 30,
                    ),
                  ),
                  borderRadius: 50,
                  height: 50,
                  width: 50,
                  onTap: () {
                    if (textEditingController.text.isNotEmpty) {
                      sendMessage(LiveMessagesModel.messageTypeComment,
                          textEditingController.text, widget.currentUser!);
                      textEditingController.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget audianceBottom() {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                liveMessages(),
                if (_showChat && !Responsive.isWebOrDeskTop(context))
                  chatInputField(),
              ],
            ),
            if (!Responsive.isWebOrDeskTop(context))
              Visibility(
                visible: !_showChat,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ContainerCorner(
                      marginAll: 5,
                      color: Colors.black.withOpacity(0.5),
                      child: ContainerCorner(
                        color: kTransparentColor,
                        marginAll: 8,
                        height: 30,
                        width: 30,
                        child: SvgPicture.asset(
                          "assets/svg/ic_tab_chat_default.svg",
                          color: Colors.white,
                          height: 10,
                          width: 30,
                        ),
                      ),
                      borderRadius: 50,
                      height: 50,
                      width: 50,
                      onTap: () {
                        chatTextFieldFocusNode!.requestFocus();
                        showChatState();
                      },
                    ),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        ContainerCorner(
                                          marginRight: 10,
                                          marginLeft: 6,
                                          color: Colors.black.withOpacity(0.5),
                                          child: QuickActions.avatarWidget(
                                            widget.mUser!,
                                          ),
                                          borderRadius: 50,
                                          height: 40,
                                          width: 40,
                                          onTap: () {},
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TextWithTap(
                                              widget.mUser!.getFullName!,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svg/dolar_diamond.svg",
                                                  height: 20,
                                                ),
                                                TextWithTap(
                                                  mUserDiamonds,
                                                  color: QuickHelp.isDarkMode(
                                                          context)
                                                      ? kContentColorLightTheme
                                                      : kContentColorDarkTheme,
                                                  fontSize: 13,
                                                  marginLeft: 3,
                                                ),
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    ContainerCorner(
                                      marginLeft: 10,
                                      marginRight: 6,
                                      colors: [
                                        following
                                            ? kColorsIndigo500
                                            : kPrimaryColor,
                                        following
                                            ? kColorsIndigo500
                                            : kPrimaryColor
                                      ],
                                      child: ContainerCorner(
                                          color: kTransparentColor,
                                          marginAll: 5,
                                          height: 30,
                                          width: 30,
                                          child: Icon(
                                            following ? Icons.done : Icons.add,
                                            color: Colors.white,
                                            size: 24,
                                          )),
                                      borderRadius: 50,
                                      height: 40,
                                      width: 40,
                                      onTap: () {
                                        if (!following) {
                                          followOrUnfollow();
                                          sendMessage(
                                              LiveMessagesModel
                                                  .messageTypeFollow,
                                              "",
                                              widget.currentUser!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //if(!QuickHelp.isWebPlatform())
                    ContainerCorner(
                      marginAll: 5,
                      color: Colors.white,
                      child: ContainerCorner(
                        color: kTransparentColor,
                        marginAll: 8,
                        height: 30,
                        width: 30,
                        child: SvgPicture.asset(
                          "assets/svg/ic_menu_gifters.svg",
                          color: Colors.black,
                          height: 10,
                          width: 30,
                        ),
                      ),
                      borderRadius: 50,
                      height: 50,
                      width: 50,
                      onTap: () {
                        if (QuickHelp.isWebPlatform()) {
                          CoinsFlowPaymentWeb(
                            context: context,
                            currentUser: widget.currentUser!,
                            showOnlyCoinsPurchase: false,
                            onCoinsPurchased: (coins) {
                              print(
                                  "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");
                            },
                            onGiftSelected: (gift) {
                              print("onGiftSelected called ${gift.getTickets}");
                              updateCurrentUser(gift);
                            },
                          );
                        } else {
                          CoinsFlowPayment(
                            context: context,
                            currentUser: widget.currentUser!,
                            onCoinsPurchased: (coins) {
                              print(
                                  "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");
                            },
                            onGiftSelected: (gift) {
                              print("onGiftSelected called ${gift.getTickets}");
                              updateCurrentUser(gift);
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void openSelectPrice() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showGiftToBePaidOnPremiumBottomSheet();
        });
  }

  Widget getGiftsPrices(StateSetter setState) {
    QueryBuilder<GiftsModel> giftQuery = QueryBuilder<GiftsModel>(GiftsModel());
    giftQuery.whereValueExists(GiftsModel.keyGiftCategories, true);
    giftQuery.whereEqualTo(
        GiftsModel.keyGiftCategories, GiftsModel.giftCategoryTypeClassic);

    return ContainerCorner(
      color: kTransparentColor,
      child: ParseLiveGridWidget<GiftsModel>(
        query: giftQuery,
        crossAxisCount: 4,
        reverse: false,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        lazyLoading: false,
        //childAspectRatio: 1.0,
        shrinkWrap: true,
        listenOnAllSubItems: true,
        listeningIncludes: [
          LiveStreamingModel.keyAuthor,
          LiveStreamingModel.keyAuthorInvited,
        ],
        duration: Duration(seconds: 0),
        animationController: _animationController,
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<GiftsModel> snapshot) {
          GiftsModel gift = snapshot.loadedData!;

          if (initGift) {
            setState(() {
              selectedGif = gift;
            });
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedGif = gift;
              });
            },
            child: Column(
              children: [
                Lottie.network(gift.getFile!.url!,
                    width: 60, height: 60, animate: true, repeat: true),
                ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_coin_with_star.svg",
                        width: 18,
                        height: 18,
                      ),
                      TextWithTap(
                        gift.getTickets.toString(),
                        color: Colors.white,
                        fontSize: 14,
                        marginLeft: 5,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        queryEmptyElement: Padding(
          padding: EdgeInsets.all(8.0),
          child: QuickActions.noContentFound(
              "live_streaming.no_gift_title".tr(),
              "live_streaming.no_gift_explain".tr(),
              "assets/svg/ic_menu_gifters.svg",
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center),
        ),
        gridLoadingElement: Container(
          margin: EdgeInsets.only(top: 50),
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _showGiftToBePaidOnPremiumBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Column(
                  children: [
                    ContainerCorner(
                      borderRadius: 10,
                      width: 170,
                      height: 250,
                      marginBottom: 20,
                      colors: [kPrimaryColor, kWarninngColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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
                              "live_streaming.premium_price".tr(),
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              marginBottom: 15,
                            )),
                            Center(
                              child: TextWithTap(
                                "live_streaming.premium_price_explain".tr(),
                                color: Colors.white,
                                fontSize: 12,
                                marginLeft: 10,
                              ),
                            ),
                            if (selectedGif != null)
                              Lottie.network(selectedGif!.getFile!.url!,
                                  width: 90,
                                  height: 97,
                                  animate: true,
                                  repeat: true),
                            Expanded(
                              child: ContainerCorner(
                                borderRadius: 10,
                                height: 30,
                                width: 100,
                                color: kPrimaryColor,
                                onTap: () {
                                  if (selectedGif != null) {
                                    if (widget.mLiveStreamingModel!
                                            .getViewersCount! >
                                        0) {
                                      Navigator.pop(context);
                                      openPeopleToBeInvitedSheet();
                                    } else {
                                      _privatizeLive(selectedGif!);
                                    }
                                  } else {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svg/sad.svg",
                                                  height: 70,
                                                  width: 70,
                                                ),
                                                TextWithTap(
                                                  "live_streaming.select_price"
                                                      .tr(),
                                                  textAlign: TextAlign.center,
                                                  color: Colors.red,
                                                  marginTop: 20,
                                                ),
                                                SizedBox(
                                                  height: 35,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    ContainerCorner(
                                                      child: TextButton(
                                                        child: TextWithTap(
                                                          "cancel"
                                                              .tr()
                                                              .toUpperCase(),
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                      color: kRedColor1,
                                                      borderRadius: 10,
                                                      marginLeft: 5,
                                                      width: 125,
                                                    ),
                                                    Expanded(
                                                      child: ContainerCorner(
                                                        child: TextButton(
                                                          child: TextWithTap(
                                                            "get_money.try_again"
                                                                .tr()
                                                                .toUpperCase(),
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                        ),
                                                        color: kGreenColor,
                                                        borderRadius: 10,
                                                        marginRight: 5,
                                                        width: 125,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          );
                                        });
                                  }
                                },
                                marginTop: 15,
                                marginBottom: 5,
                                child: Center(
                                  child: TextWithTap(
                                    "live_streaming.premium_btn".tr(),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ContainerCorner(
                        color: Colors.black.withOpacity(0.5),
                        radiusTopLeft: 25.0,
                        radiusTopRight: 25.0,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 3,
                        child: Scaffold(
                          appBar: AppBar(
                            backgroundColor: kTransparentColor,
                            elevation: 0,
                            automaticallyImplyLeading: false,
                            title: TextWithTap(
                              "live_streaming.gif_prices".tr(),
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            centerTitle: true,
                          ),
                          backgroundColor: kTransparentColor,
                          body: getGiftsPrices(
                              setState), //getClassicGifts(setState)
                        ),
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ),
    );
  }

  _privatizeLive(GiftsModel gift, {List? viewersInLiveId}) async {
    QuickHelp.showLoadingDialog(context);

    widget.mLiveStreamingModel!.setPrivate = true;
    widget.mLiveStreamingModel!.setPrivateLivePrice = gift;

    if (viewersInLiveId != null) {
      if (viewersInLiveId.length > 0) {
        widget.mLiveStreamingModel!.setPrivateListViewersId = viewersInLiveId;
      }
    }

    ParseResponse response = await widget.mLiveStreamingModel!.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      Navigator.pop(context);

      /*if(liveStreamingModel.getPrivate!){
        openPayPrivateLiveSheet(liveStreamingModel);
      }*/

      setState(() {
        isPrivateLive = true;
      });
    }
  }

  _unPrivatizeLive(GiftsModel gift) async {
    QuickHelp.showLoadingDialog(context);

    widget.mLiveStreamingModel!.setPrivate = false;
    //widget.mLiveStreamingModel!.removePrice = widget.mLiveStreamingModel!.getPrivateLivePrice!;

    ParseResponse response = await widget.mLiveStreamingModel!.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      setState(() {
        isPrivateLive = false;
      });
    }
  }

  Widget _showSettingsBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
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
                  child: Column(
                    children: [
                      ContainerCorner(
                        color: kGrayColor,
                        width: 50,
                        borderRadius: 20,
                        height: 5,
                        marginTop: 5,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 20),
                        child: TextButton(
                          onPressed: () => _onSwitchCamera(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.camera_front_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              TextWithTap(
                                "live_streaming.switch_camera".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: TextButton(
                          onPressed: () => _onToggleMute(),
                          child: Row(
                            children: [
                              Icon(
                                muted ? Icons.mic : Icons.mic_off_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              TextWithTap(
                                "live_streaming.toggle_audio".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                        visible: false,
                        //visible: !isPrivateLive,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, top: 5),
                          child: TextButton(
                            onPressed: () {
                              _getDefaultGiftPrice();
                              Navigator.of(context).pop();
                              openSelectPrice();
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.vpn_key_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                TextWithTap(
                                  "live_streaming.privatize_live".tr(),
                                  color: Colors.white,
                                  marginLeft: 10,
                                  fontSize: 18,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: false,//visible: isPrivateLive,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, top: 5),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _unPrivatizeLive(selectedGif!);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                TextWithTap(
                                  "live_streaming.unset_private_live".tr(),
                                  color: Colors.white,
                                  marginLeft: 10,
                                  fontSize: 18,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Tab gefTab(String name, String image) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            color: Colors.white.withOpacity(0.7),
            width: 20,
            height: 20,
          ),
          TextWithTap(
            name,
            fontSize: 12,
            marginTop: 5,
          ),
        ],
      ),
    );
  }

  Widget chatInputField() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 20 / 2,
      ),
      decoration: BoxDecoration(
        color: kTransparentColor,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 32,
            color: Color(0xFF087949).withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      onChanged: (text) {
                        if (text.isNotEmpty) {
                          toggleSendButton(true);
                        } else {
                          toggleSendButton(false);
                        }
                      },
                      focusNode: chatTextFieldFocusNode,
                      maxLines: 2,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: "comment_post.leave_comment".tr(),
                        hintStyle: TextStyle(color: Colors.white),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hideSendButton && !Responsive.isWebOrDeskTop(context))
            ContainerCorner(
              marginLeft: 10,
              color: kBlueColor1,
              child: ContainerCorner(
                color: kTransparentColor,
                marginAll: 5,
                height: 30,
                width: 30,
                child: SvgPicture.asset(
                  "assets/svg/ic_send_message.svg",
                  color: Colors.white,
                  height: 10,
                  width: 30,
                ),
              ),
              borderRadius: 50,
              height: 45,
              width: 45,
              onTap: () {
                if (textEditingController.text.isNotEmpty) {
                  sendMessage(LiveMessagesModel.messageTypeComment,
                      textEditingController.text, widget.currentUser!);
                  setState(() {
                    textEditingController.text = "";
                  });
                  toggleSendButton(false);
                }
              },
            ),
          if (Responsive.isWebOrDeskTop(context))
            ContainerCorner(
              marginLeft: 10,
              color: kBlueColor1,
              child: ContainerCorner(
                color: kTransparentColor,
                marginAll: 5,
                height: 30,
                width: 30,
                child: SvgPicture.asset(
                  "assets/svg/ic_send_message.svg",
                  color: Colors.white,
                  height: 10,
                  width: 30,
                ),
              ),
              borderRadius: 50,
              height: 45,
              width: 45,
              onTap: () {
                if (textEditingController.text.isNotEmpty) {
                  sendMessage(LiveMessagesModel.messageTypeComment,
                      textEditingController.text, widget.currentUser!);
                  setState(() {
                    textEditingController.text = "";
                  });
                  toggleSendButton(false);
                }
              },
            ),
        ],
      ),
    );
  }

  sendMessage(
    String messageType,
    String message,
    UserModel author, {
    GiftsModel? giftsModel,
  }) async {
    if (messageType == LiveMessagesModel.messageTypeGift) {
      if (!Responsive.isWebOrDeskTop(context)) {
        QuickHelp.goBackToPreviousPage(context);
      }

      widget.currentUser!.removeCredit = giftsModel!.getTickets!;
      await widget.currentUser!.save();

      widget.mLiveStreamingModel!.addDiamonds = QuickHelp.getDiamondsForReceiver(giftsModel.getTickets!);
      await widget.mLiveStreamingModel!.save();

      await QuickCloudCode.sendGift(authorId: widget.mUser!.objectId!, credits: giftsModel.getTickets!);
    }

    LiveMessagesModel liveMessagesModel = new LiveMessagesModel();
    liveMessagesModel.setAuthor = author;
    liveMessagesModel.setAuthorId = author.objectId!;

    liveMessagesModel.setLiveStreaming = widget.mLiveStreamingModel!;
    liveMessagesModel.setLiveStreamingId =
        widget.mLiveStreamingModel!.objectId!;

    if (giftsModel != null) {
      liveMessagesModel.setGift = giftsModel;
      liveMessagesModel.setGiftId = giftsModel.objectId!;
    }

    if (messageType == LiveMessagesModel.messageTypeCoHost) {
      liveMessagesModel.setCoHostAuthor = widget.currentUser!;
      liveMessagesModel.setCoHostAuthorUid = widget.currentUser!.getUid!;
      liveMessagesModel.setCoHostAvailable = false;
    }

    liveMessagesModel.setMessage = message;
    liveMessagesModel.setMessageType = messageType;
    await liveMessagesModel.save();
  }

  Widget liveMessages() {
    if (widget.isBroadcaster! && liveMessageSent == false) {
      SendNotifications.sendPush(
          widget.currentUser!, widget.currentUser!, SendNotifications.typeLive,
          objectId: widget.mLiveStreamingModel!.objectId!);
      sendMessage(
          LiveMessagesModel.messageTypeSystem,
          "live_streaming.live_streaming_created_message".tr(),
          widget.currentUser!);
      liveMessageSent = true;
    }

    QueryBuilder<LiveMessagesModel> queryBuilder =
        QueryBuilder<LiveMessagesModel>(LiveMessagesModel());
    queryBuilder.whereEqualTo(LiveMessagesModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId);
    queryBuilder.includeObject([
      LiveMessagesModel.keySenderAuthor,
      LiveMessagesModel.keyLiveStreaming,
      LiveMessagesModel.keyGift
    ]);
    queryBuilder.orderByDescending(LiveMessagesModel.keyCreatedAt);

    var size = MediaQuery.of(context).size;
    return ContainerCorner(
      color: kTransparentColor,
      marginLeft: 10,
      marginRight: 10,
      height: Responsive.isMobile(context) || Responsive.isTablet(context)
          ? 300
          : size.height - 200,
      width: size.width / 1.3,
      marginBottom: 15,
      //color: kTransparentColor,
      child: ParseLiveListWidget<LiveMessagesModel>(
        query: queryBuilder,
        reverse: true,
        duration: Duration(microseconds: 500),
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<LiveMessagesModel> snapshot) {
          if (snapshot.failed) {
            return Text('not_connected'.tr());
          } else if (snapshot.hasData) {
            LiveMessagesModel liveMessage = snapshot.loadedData!;

            bool isMe =
                liveMessage.getAuthorId == widget.currentUser!.objectId &&
                    liveMessage.getLiveStreaming!.getAuthorId! ==
                        widget.currentUser!.objectId;

            return getMessages(liveMessage, isMe);
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget getMessages(LiveMessagesModel liveMessages, bool isMe) {
    if (isMe) {
      return messageAvatar(
          "live_streaming.you_".tr(),
          liveMessages.getMessageType == LiveMessagesModel.messageTypeSystem
              ? "live_streaming.live_streaming_created_message".tr()
              : liveMessages.getMessage!,
          liveMessages.getAuthor!.getAvatar!.url!);
    } else {
      if (liveMessages.getMessageType == LiveMessagesModel.messageTypeSystem) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "live_streaming.live_streaming_created_message".tr(),
            liveMessages.getAuthor!.getAvatar!.url!);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeJoin) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "live_streaming.live_streaming_watching".tr(),
            liveMessages.getAuthor!.getAvatar!.url!);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeComment) {
        return messageNoAvatar(
            nameOrYou(liveMessages), liveMessages.getMessage!);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeFollow) {
        return messageNoAvatar(
            nameOrYou(liveMessages), "live_streaming.new_follower".tr());
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeGift) {
        return messageGift(
            nameOrYou(liveMessages),
            "live_streaming.new_gift".tr(),
            liveMessages.getGift!.getFile!.url!,
            liveMessages.getAuthor!.getAvatar!.url!);
      }
      /*else if(liveMessages.getMessageType == LiveMessagesModel.messageTypeCoHost){
        return messageCoHost(nameOrYou(liveMessages), "live_streaming.ask_permition".tr(), liveMessages.getAuthor!, liveMessages, liveMessages.getAuthor!.getAvatar!.url!);

      }*/
      else {
        return messageNoAvatar(
            nameOrYou(liveMessages), liveMessages.getMessage!);
      }
    }
  }

  String nameOrYou(LiveMessagesModel liveMessage) {
    if (liveMessage.getAuthorId == widget.currentUser!.objectId) {
      return "live_streaming.you_".tr();
    } else {
      return liveMessage.getAuthor!.getFullName!;
    }
  }

  Widget messageAvatar(String title, String message, avatarUrl) {
    return ContainerCorner(
      borderRadius: 50,
      marginBottom: 5,
      colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.02)],
      child: Row(
        children: [
          ContainerCorner(
            width: 30,
            height: 30,
            color: kRedColor1,
            borderRadius: 50,
            marginRight: 10,
            child: QuickActions.photosWidgetCircle(avatarUrl,
                width: 10, height: 10, boxShape: BoxShape.circle),
          ),
          Flexible(
            child: Column(
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: kWarninngColor,
                    ),
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messageNoAvatar(String title, String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: RichText(
          text: TextSpan(children: [
        TextSpan(
          text: title,
          style: TextStyle(
            color: kWarninngColor,
          ),
        ),
        TextSpan(text: " "),
        TextSpan(
          text: message,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ])),
    );
  }

  Widget messageGift(String title, String message, String giftUrl, avatarUrl) {
    return ContainerCorner(
      borderRadius: 50,
      marginBottom: 5,
      colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.02)],
      child: Row(
        children: [
          ContainerCorner(
            width: 40,
            height: 40,
            color: kRedColor1,
            borderRadius: 50,
            marginRight: 10,
            marginLeft: 10,
            child: QuickActions.photosWidgetCircle(avatarUrl,
                width: 10, height: 10, boxShape: BoxShape.circle),
          ),
          Flexible(
            child: Column(
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: kWarninngColor,
                    ),
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ])),
              ],
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Container(
              width: 50,
              height: 50,
              child: Lottie.network(giftUrl,
                  width: 30, height: 30, animate: true, repeat: true)),
        ],
      ),
    );
  }

  String hostButton(UserModel author, LiveMessagesModel message) {
    if (widget.isBroadcaster!) {
      if (message.getCoHostAuthorAvailable!) {
        return "live_streaming.accepted_btn".tr();
      } else {
        return "live_streaming.accept_btn".tr();
      }
    } else if (message.getAuthor!.objectId! == widget.currentUser!.objectId) {
      if (message.getCoHostAuthorAvailable!) {
        return "live_streaming.join_now_btn".tr();
      } else {
        return "live_streaming.pending_btn".tr();
      }
    } else {
      return "";
    }
  }

  bool hostButtonCondition(UserModel author, LiveMessagesModel message) {
    if (widget.isBroadcaster!) {
      return true;
    } else if (message.getAuthor!.objectId! == widget.currentUser!.objectId) {
      return true;
    } else {
      return false;
    }
  }

  updateCurrentUser(GiftsModel giftsModel) async {
    QuickHelp.showLoadingDialog(context);

    widget.currentUser!.removeCredit = giftsModel.getTickets!;
    ParseResponse response = await widget.currentUser!.save();
    if (response.success) {
      widget.currentUser = response.results!.first as UserModel;
      sendMessage(LiveMessagesModel.messageTypeGift, "", widget.currentUser!,
          giftsModel: giftsModel);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: response.error!.message,
          user: widget.currentUser!);
    }
  }

  void openPayPrivateLiveSheet(LiveStreamingModel live) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        isDismissible: false,
        builder: (context) {
          return _showPayPrivateLiveBottomSheet(live);
        });
  }

  Widget _showPayPrivateLiveBottomSheet(LiveStreamingModel live) {
    return Container(
      color: Color.fromRGBO(0, 0, 0, 0.001),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.89,
          minChildSize: 0.1,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return StatefulBuilder(builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
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
                          onPressed: () {
                            Navigator.of(context).pop();
                            closeAlert();
                          },
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
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 15.0),
                                          child: CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.white,
                                            child: SvgPicture.asset(
                                              "assets/svg/sad.svg",
                                              color: kRedColor1,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "live_streaming.not_enough_coins"
                                              .tr(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 35,
                                        ),
                                        ButtonWithGradient(
                                          borderRadius: 100,
                                          text: "live_streaming.get_credit_btn"
                                              .tr(),
                                          marginLeft: 15,
                                          marginRight: 15,
                                          height: 50,
                                          beginColor: kWarninngColor,
                                          endColor: kPrimaryColor,
                                          onTap: () {
                                            Navigator.pop(context);
                                            //Navigator.pop(context);
                                            CoinsFlowPayment(
                                              context: context,
                                              currentUser: widget.currentUser!,
                                              showOnlyCoinsPurchase: true,
                                              onCoinsPurchased: (coins) {
                                                print(
                                                    "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");
                                                Navigator.pop(context);
                                              },
                                              onGiftSelected: (gift) {
                                                print(
                                                    "onGiftSelected called ${gift.getTickets}");
                                              },
                                            );
                                            //Navigator.pop(context);
                                            //Navigator.pop(context);
                                          },
                                        ),
                                        SizedBox(height: 20),
                                      ],
                                    ),
                                  );
                                });
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
    );
  }

  _payForPrivateLive(LiveStreamingModel live) async {
    QuickHelp.showLoadingDialog(context);

    updateCurrentUser(live.getPrivateGift!);
    live.setPrivateViewersId = widget.currentUser!.objectId!;
    ParseResponse response = await live.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      Navigator.pop(context);
    } else {
      QuickHelp.hideLoadingDialog(context);
      Navigator.pop(context);
    }
  }
}
