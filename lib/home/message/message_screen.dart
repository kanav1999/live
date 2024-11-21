import 'dart:async';
import 'dart:io';

import 'package:heyto/app/config.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/animation/bounce.dart';
import 'package:heyto/home/calls/video_call_screen.dart';
import 'package:heyto/home/calls/voice_call_screen.dart';
import 'package:heyto/home/coins/coins_payment_widget.dart';
import 'package:heyto/models/MessagesModel.dart';
import 'package:heyto/models/ReportModel.dart';
import 'package:heyto/modules/showcase/src/showcase.dart';
import 'package:heyto/modules/showcase/src/showcase_widget.dart';
import 'package:heyto/utils/utilsConstants.dart';
import 'package:heyto/widgets/giphyWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/MessageListModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '../../ui/app_bar_chat.dart';

// ignore: must_be_immutable
class MessageScreen extends StatefulWidget {
  UserModel? currentUser, mUser;

  MessageScreen({Key? key, this.currentUser, this.mUser}) : super(key: key);

  static String route = '/messages/chat';

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController messageController = TextEditingController();
  TextEditingController gifController = TextEditingController();

  String callDuration = "00:00";

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  GlobalKey _one = GlobalKey();

  /*     =========Audio stuff==========     */

  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
  FlutterSound flutterSound = FlutterSound();

  String _myPath = "";

  ParseFileBase? audioFile;
  String? globalVoiceUrl;
  String? globalVoiceDuration;

  checkMicPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      startRecording();
    } else {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.microphone_access".tr(),
          message: "permissions.microphone_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);
            requestMicrophonePermission();
          });
    }
  }

  Future<void> startRecording() async {
    Initialized.fullyInitialized;

    var tempDir = await getTemporaryDirectory();
    _myPath = '${tempDir.path}/flutter_sound.aac';

    await _myRecorder.startRecorder(
      toFile: _myPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      showVoiceRecorderArea = true;
      showTextMessageInput = false;
      showGifMessageInput = false;
    });

    _stopWatchTimer.onExecute.add(StopWatchExecute.start);
  }

  Future<void> stopRecording() async {
    await _myRecorder.stopRecorder();
  }

  Future<void> saveVoiceMessage({MessageModel? repliedMessage}) async {
    stopRecording();

    if (QuickHelp.isWebPlatform()) {
      //Seems weird, but this lets you get the data from the selected file as an Uint8List very easily.
      ParseWebFile file = ParseWebFile(null, name: "voice.aac", url: _myPath);
      await file.download();
      audioFile = ParseWebFile(file.file, name: file.name);
    } else {
      audioFile = ParseFile(File(_myPath), name: "voice.aac");
    }

    //DurationFormatUtils.formatDuration(millis, "**H:mm:ss**", true);
    Duration? duration = await flutterSoundHelper.duration(_myPath);
    if (duration != null && audioFile != null) {
      String durationAllowed =
          QuickHelp.getDurationInMinutes(duration: duration);

      if (durationAllowed == "00:00" || durationAllowed == "00:01") {
        /*setState(() {
          recordInfo = "message_screen.record_info".tr();
        });*/

      } else {
        _saveMessage(
          "voice",
          messageType: MessageModel.messageTypeVoice,
          voiceMessage: audioFile,
          voiceDuration: QuickHelp.getDurationInMinutes(duration: duration),
          replyMessage: repliedMessage != null ? repliedMessage : null,
        );
      }
    }
  }

  _payAndPause(String voiceUrl) {
    if (globalVoiceUrl != null) {
      if (voiceUrl == globalVoiceUrl) {
        pausePlayer(voiceUrl);
      } else {
        setState(() {
          globalVoiceUrl = voiceUrl;
          globalVoiceDuration = "Playing";
        });
        play(voiceUrl);
      }
    } else {
      setState(() {
        globalVoiceUrl = voiceUrl;
        globalVoiceDuration = "Playing";
      });
      play(voiceUrl);
    }
  }

  void play(String voiceUrl) async {
    await _myPlayer.startPlayer(
      fromURI: voiceUrl,
      codec: Codec.aacADTS,
      whenFinished: () {
        setState(() {
          globalVoiceUrl = "";
          globalVoiceDuration = "Finished";
        });
      },
    );
  }

  Future<void> pausePlayer(String voiceUrl) async {
    if (_myPlayer.isPlaying) {
      await _myPlayer.pausePlayer();
      setState(() {
        globalVoiceUrl = "";
        globalVoiceDuration = "Pause";
      });
    } else if (_myPlayer.isPaused) {
      await _myPlayer.resumePlayer();
      setState(() {
        globalVoiceUrl = "";
        globalVoiceDuration = "Resume";
      });
    } else {
      play(voiceUrl);
    }
  }

  Future<void> stopPlayer() async {
    setState(() {
      globalVoiceUrl = "";
      globalVoiceDuration = "";
    });
    await _myPlayer.stopPlayer();
  }

  Future<void> requestMicrophonePermission() async {
    var asked = await Permission.microphone.request();

    if (asked.isGranted) {
      startRecording();
    } else if (asked.isDenied) {
      QuickHelp.showAppNotification(
          context: context,
          title: "permissions.microphone_access_denied".tr(),
          isError: true);
    } else if (asked.isPermanentlyDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.microphone_access_denied".tr(),
          confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
          message: "permissions.microphone_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () {
            QuickHelp.hideLoadingDialog(context);
            openAppSettings();
          });
    }
  }

  /*     ======Audio stuff ends here======     */

  int _start = 10;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
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

  final LiveQuery liveQuery = LiveQuery();
  Subscription? subscription;

  List<dynamic> results = <dynamic>[];
  late QueryBuilder<MessageModel> queryBuilder;

  bool isFavorite = false;

  _likeAndDislike(MessageModel chatMessage) async {
    chatMessage.setIsLikedMessage = !chatMessage.isLikedMessage!;
    ParseResponse response = await chatMessage.save();
    if (response.success) {
      setState(() {});
    }
  }

  GroupedItemScrollController listScrollController =
      GroupedItemScrollController();

  Future<List<dynamic>?> loadMessages() async {
    QueryBuilder<MessageModel> queryFrom =
        QueryBuilder<MessageModel>(MessageModel());

    queryFrom.whereEqualTo(MessageModel.keyAuthor, widget.currentUser!);

    queryFrom.whereEqualTo(MessageModel.keyReceiver, widget.mUser!);

    QueryBuilder<MessageModel> queryTo =
        QueryBuilder<MessageModel>(MessageModel());
    queryTo.whereEqualTo(MessageModel.keyAuthor, widget.mUser!);
    queryTo.whereEqualTo(MessageModel.keyReceiver, widget.currentUser!);

    queryBuilder = QueryBuilder.or(MessageModel(), [queryFrom, queryTo]);
    queryBuilder.orderByDescending(MessageModel.keyCreatedAt);

    queryBuilder.includeObject([
      MessageModel.keyCall,
      MessageModel.keyAuthor,
      MessageModel.keyReceiver,
      MessageModel.keyListMessage,
    ]);

    setupLiveQuery();

    ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      //print("Messages count: ${apiResponse.results!.length}");
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as List<dynamic>;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  String? sendButtonIcon = "assets/svg/send.svg";
  Color sendButtonBackground = kColorsBlue400;

  String voiceMessageButtonIcon = "assets/svg/send.svg";

  bool showReplyText = false;
  bool showReplyGif = false;
  bool showReplyVoice = false;

  String gifReplyUrl = "";

  bool showMicrophoneButton = QuickHelp.isMobile();

  String name = "";
  String textToBeReplied = "";
  late FocusNode? messageTextFieldFocusNode;

  MessageModel? repliedMessage;

  String _search = "";

  _searchGift(String text) {
    setState(() {
      _search = text;
    });
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

  bool isEmailVerified = false;

  @override
  void initState() {
    _canMakeCalls();

    super.initState();

    messageTextFieldFocusNode = FocusNode();

    //Open audio session
    _myPlayer.openAudioSession().then((value) {
      setState(() {
        Initialized.fullyInitialized;
      });
    });

    if (QuickHelp.isMobile()) {
      _myRecorder.openAudioSession().then((value) {
        setState(() {
          Initialized.fullyInitialized;
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    messageController.dispose();

    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    _stopWatchTimer.dispose();

    //close audion session
    _myRecorder.closeAudioSession();
    _myPlayer.closeAudioSession();
    //_myPlayer = null;
  }

  bool showTextMessageInput = true;
  bool showGifMessageInput = false;
  bool showVoiceRecorderArea = false;
  bool disableMessageWays = false;

  bool showReportAndRemoveScreen = true;
  bool showUnblockUserScreen = false;
  bool disableCalls = false;

  updateComponentsOnMatchRemoved() {
    setState(() {
      showTextMessageInput = false;
      showGifMessageInput = false;
      showVoiceRecorderArea = false;
      disableMessageWays = true;
      disableCalls = true;
    });
  }

  _canMakeCalls() {
    setState(() {
      if (_verifyMatch()) {
        disableCalls = true;
      } else {
        disableCalls = false;
      }
    });
  }

  @override
  Widget build(BuildContext mContext) {
    isEmailVerified = widget.mUser!.getEmailVerified!;

    if (widget.currentUser!.getFavoritesUsers != null &&
        widget.currentUser!.getFavoritesUsers!
            .contains(widget.mUser!.objectId)) {
      setState(() {
        isFavorite = true;
      });
    } else {
      setState(() {
        isFavorite = false;
      });
    }

    if (_verifyMatch()) {
      setState(() {
        showTextMessageInput = false;
        showGifMessageInput = false;
        showVoiceRecorderArea = false;
        disableMessageWays = true;
      });

      if (hideAndShowTookKit()) {
        showReportAndRemoveScreen = false;
        showUnblockUserScreen = true;
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScopeNode focusScopeNode = FocusScope.of(mContext);
        if (!focusScopeNode.hasPrimaryFocus &&
            focusScopeNode.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: ToolBarChatWidget(
        elevation: 0,
        leftSideWidth: 28.0,
        centerTitle: false,
        leftButtonIcon: Responsive.isMobile(context) ? Icons.arrow_back : null,
        leftIconColor: Responsive.isMobile(context) ? kGrayColor : null,
        leftButtonPress: () {
          if (Responsive.isMobile(context)) {
            return QuickHelp.goBackToPreviousPage(mContext);
          } else {
            return null;
          }
        },
        centerWidget: Row(
          children: [
            GestureDetector(
              child: QuickActions.avatarWidget(widget.mUser!,
                  width: 40, height: 40),
              onTap: () => !Responsive.isWebOrDeskTop(context)
                  ? QuickActions.showUserProfile(context, widget.mUser!)
                  : null,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TextWithTap(
                          widget.mUser!.getFirstName!,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: QuickHelp.isDarkMode(mContext)
                              ? Colors.white
                              : Colors.black,
                          marginLeft: 10,
                          marginRight: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Visibility(
                        visible: isEmailVerified,
                        child: Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: SvgPicture.asset(
                            "assets/svg/ic_verified_account.svg",
                            height: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextWithTap(
                    QuickHelp.isUserOnlineChat(widget.mUser!),
                    fontSize: 12,
                    color: QuickHelp.isDarkMode(mContext)
                        ? Colors.white
                        : kBlueColor1,
                    marginLeft: 10,
                    marginRight: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        rightButtonWidget: Row(
          children: [
            Visibility(
              visible: !QuickHelp.isWebPlatform() && !disableCalls,
              child: ContainerCorner(
                width: 24,
                height: 24,
                marginRight: 10,
                marginLeft: 10,
                onTap: () => _showVideoAndVoiceCallsButtons(),
                child: Icon(
                  Icons.call,
                  color: kFeatureSpotLightColor,
                  size: 24,
                ),
              ),
            ),
            ContainerCorner(
              width: 24,
              height: 24,
              marginRight: 10,
              marginLeft: 10,
              onTap: () => updateFavoriteStatus(),
              child: SvgPicture.asset(
                isFavorite
                    ? "assets/svg/ic_badge_feature_favourites.svg"
                    : "assets/svg/star.svg",
              ),
            ),
            ContainerCorner(
                marginRight: 10,
                marginLeft: 10,
                width: 24,
                onTap: () => openSheet(),
                child: SvgPicture.asset(
                  "assets/svg/ic_message_repost.svg",
                  color: QuickHelp.isDarkMode(mContext)
                      ? Colors.white
                      : Colors.black,
                )),
          ],
        ),
        child: SafeArea(
          child: ShowCaseWidget(
            builder: Builder(builder: (context) {
              mContext = context;
              return messageSpace(context);
            }),
          ),
        ),
      ),
    );
  }

  checkPermission(bool isVideoCall) async {
    QuickHelp.goBackToPreviousPage(context);

    if (await Permission.camera.isGranted &&
        await Permission.microphone.isGranted) {
      startCall(isVideoCall);
    } else if (await Permission.camera.isDenied ||
        await Permission.microphone.isDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.call_access".tr(),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          message: "permissions.call_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);

            // You can request multiple permissions at once.
            Map<Permission, PermissionStatus> statuses = await [
              Permission.camera,
              Permission.microphone,
            ].request();

            if (statuses[Permission.camera]!.isGranted &&
                statuses[Permission.microphone]!.isGranted) {
              startCall(isVideoCall);
            } else {
              QuickHelp.showAppNotificationAdvanced(
                  title: "permissions.call_access_denied".tr(),
                  message: "permissions.call_access_denied_explain"
                      .tr(namedArgs: {"app_name": Setup.appName}),
                  context: context,
                  isError: true);
            }
          });
    } else if (await Permission.camera.isPermanentlyDenied ||
        await Permission.microphone.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  startCall(bool isVideoCall) {
    if (isVideoCall) {
      if (widget.currentUser!.getCredits! >=
          Setup.coinsNeededForVideoCallPerMinute) {
        QuickHelp.showDialogWithButtonCustom(
            context: context,
            title: "video_call.video_call_price".tr(),
            message: "video_call.video_explain".tr(namedArgs: {
              "coins": Setup.coinsNeededForVideoCallPerMinute.toString(),
              "name": widget.mUser!.getFirstName!
            }),
            cancelButtonText: "cancel".tr(),
            confirmButtonText: "continue".tr(),
            onPressed: () {
              QuickHelp.hideLoadingDialog(context);
              QuickHelp.goToNavigatorScreen(
                  context,
                  VideoCallScreen(
                    currentUser: widget.currentUser,
                    mUser: widget.mUser,
                    channel: widget.currentUser!.objectId,
                    isCaller: true,
                  ),
                  route: VideoCallScreen.route);
            });
      } else {
        QuickHelp.showAppNotificationAdvanced(
            title: "video_call.no_coins".tr(),
            message: "video_call.no_coins_video".tr(namedArgs: {
              "coins": Setup.coinsNeededForVideoCallPerMinute.toString()
            }),
            context: context,
            isError: true);

        CoinsFlowPayment(
            context: context,
            currentUser: widget.currentUser!,
            showOnlyCoinsPurchase: true,
            onCoinsPurchased: (coins) {
              print(
                  "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");
              startCall(true);
            });
      }
    } else {
      if (widget.currentUser!.getCredits! >=
          Setup.coinsNeededForVoiceCallPerMinute) {
        QuickHelp.showDialogWithButtonCustom(
            context: context,
            title: "video_call.voice_call_price".tr(),
            message: "video_call.voice_explain".tr(namedArgs: {
              "coins": Setup.coinsNeededForVoiceCallPerMinute.toString(),
              "name": widget.mUser!.getFirstName!
            }),
            cancelButtonText: "cancel".tr(),
            confirmButtonText: "continue".tr(),
            onPressed: () {
              QuickHelp.hideLoadingDialog(context);
              QuickHelp.goToNavigatorScreen(
                  context,
                  VoiceCallScreen(
                    mUser: widget.mUser,
                    currentUser: widget.currentUser,
                    channel: widget.currentUser!.objectId,
                    isCaller: true,
                  ),
                  route: VoiceCallScreen.route);
            });
      } else {
        QuickHelp.showAppNotificationAdvanced(
            title: "video_call.no_coins".tr(),
            message: "video_call.no_coins_voice".tr(namedArgs: {
              "coins": Setup.coinsNeededForVoiceCallPerMinute.toString()
            }),
            context: context,
            isError: true);

        CoinsFlowPayment(
            context: context,
            currentUser: widget.currentUser!,
            showOnlyCoinsPurchase: true,
            onCoinsPurchased: (coins) {
              print(
                  "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");
              startCall(false);
            });
      }
    }
  }

  Widget callMessage(MessageModel messageModel, bool isMe) {
    bool author = messageModel.getCall != null &&
        messageModel.getAuthorId! == widget.currentUser!.objectId!;

    bool accepted = messageModel.getCall!.getAccepted!;

    return Column(
      children: [
        ContainerCorner(
          color: kTransparentColor,
          borderRadius: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ContainerCorner(
                marginRight: 50,
                marginLeft: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Visibility(
                      visible: !accepted && !author,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_received,
                            color: isMe ? Colors.white : Colors.red,
                          ),
                          TextWithTap(
                            "message_screen.missed_call".tr(),
                            color: isMe ? Colors.white : Colors.red,
                            marginLeft: 10,
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: !accepted && author,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_made,
                            color: isMe ? Colors.white : Colors.red,
                          ),
                          TextWithTap(
                            "message_screen.missed_call".tr(),
                            color: isMe ? Colors.white : Colors.red,
                            marginLeft: 10,
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: accepted && author,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_made,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                          TextWithTap(
                            "message_screen.out_going_call".tr(),
                            color: Colors.white,
                            marginLeft: 10,
                          )
                        ],
                      ),
                    ),
                    Visibility(
                      visible: accepted && !author,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_received,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                          TextWithTap(
                            "message_screen.incoming_call".tr(),
                            color: isMe ? Colors.white : Colors.black,
                            marginLeft: 10,
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        TextWithTap(
                          QuickHelp.getMessageTime(messageModel.createdAt!,
                              time: true),
                          marginRight: 10,
                          color: isMe ? Colors.white : Colors.black,
                        ),
                        Visibility(
                          visible: messageModel.getCall!.getAccepted!,
                          child: TextWithTap(
                            messageModel.getCall!.getDuration!,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: isMe ? kPrimaryLightColor : kDisabledGrayColor,
                height: 50,
                marginBottom: 5,
                marginRight: 2,
                marginTop: 5,
                borderRadius: 70,
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    messageModel.getCall!.getIsVoiceCall!
                        ? Icons.phone
                        : Icons.videocam,
                    color: isMe ? kPrimaryColor : Colors.white,
                    size: 25,
                  ),
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget callInfo(bool appear, IconData icon, String text) {
    return Visibility(
      visible: appear,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.red,
          ),
          TextWithTap(
            text,
            color: Colors.red,
            marginLeft: 10,
          )
        ],
      ),
    );
  }

  saveUserUnFavorite() async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.removeFavoriteUser = widget.mUser!;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;
      widget.currentUser = response.results!.first;

      setState(() {
        isFavorite = false;
      });

      QuickHelp.hideLoadingDialog(context);
    } else {
      setState(() {
        isFavorite = true;
      });

      QuickHelp.hideLoadingDialog(context);
    }
  }

  _showVideoAndVoiceCallsButtons() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: kTransparentColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: kTransparentColor,
              actions: [
                IconButton(
                    onPressed: () => QuickHelp.goBackToPreviousPage(context),
                    icon: Icon(
                      Icons.close,
                      size: 35,
                    ))
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                QuickActions.avatarWidget(
                  widget.mUser!,
                  height: 170,
                  width: 170,
                  margin: EdgeInsets.only(top: 20),
                ),
                BounceInDown(
                  child: TextWithTap(
                    "message_screen.call_type".tr(),
                    color: kGreyColor0,
                    marginTop: 30,
                    fontSize: 18,
                  ),
                ),
                Expanded(
                  child: ContainerCorner(
                    marginTop: 50,
                    marginLeft: 30,
                    marginRight: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BounceInUp(
                          child: ContainerCorner(
                            setShadowToBottom: true,
                            shadowColor: kGreyColor0,
                            shadowColorOpacity: 0.2,
                            height: 70,
                            width: 70,
                            color: kGreyColor0,
                            marginLeft: 20,
                            borderRadius: 50,
                            child: Icon(
                              Icons.call,
                              color: kPrimaryColor,
                              size: 40,
                            ),
                            onTap: () => checkPermission(false),
                          ),
                        ),
                        BounceInRight(
                          child: ContainerCorner(
                            setShadowToBottom: true,
                            shadowColor: kGreyColor0,
                            shadowColorOpacity: 0.2,
                            height: 70,
                            width: 70,
                            color: kPrimaryLightColor,
                            marginRight: 20,
                            borderRadius: 50,
                            child: Icon(
                              Icons.videocam,
                              color: kPrimaryColor,
                              size: 40,
                            ),
                            onTap: () => checkPermission(true),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  void updateFavoriteStatus() async {
    if (isFavorite) {
      QuickHelp.showDialogHeyto(
        context: context,
        isRow: false,
        svgAsset: "assets/svg/ic_badge_feature_favourites.svg",
        title: "message_screen.remove_favorite".tr(),
        message: "message_screen.remove_favorite"
            .tr(namedArgs: {"name": "${widget.mUser!.getFullName}"}),
        confirmButtonText: 'yes'.tr(),
        cancelButtonText: 'cancel'.tr(),
        onPressed: () {
          QuickHelp.goBackToPreviousPage(context);
          saveUserUnFavorite();
        },
      );
    } else {
      QuickHelp.showLoadingDialog(this.context, useLogo: true);

      widget.currentUser!.setFavoritesUser = widget.mUser!;
      ParseResponse response = await widget.currentUser!.save();

      if (response.success) {
        widget.currentUser = response.results!.first;
        widget.currentUser = response.results!.first;

        setState(() {
          isFavorite = true;
        });

        SendNotifications.sendPush(
          widget.currentUser!,
          widget.mUser!,
          SendNotifications.typeFavorite,
        );

        QuickHelp.hideLoadingDialog(context);
      } else {
        setState(() {
          isFavorite = false;
        });

        QuickHelp.hideLoadingDialog(context);
      }
    }
  }

  String getPlayOrPauseIcon(String? voiceUrl) {
    if (voiceUrl != null && voiceUrl == globalVoiceUrl) {
      return "assets/svg/ic_pause_audio.svg";
    } else {
      return "assets/svg/ic_play_audio.svg";
    }
  }

  String getPlayOrPauseDuration(MessageModel message, String? voiceUrl) {
    if (voiceUrl != null && voiceUrl == globalVoiceUrl) {
      return globalVoiceDuration!;
    } else {
      return message.getVoiceDuration!;
    }
  }

  scrollToBottom(
      {required int position,
      bool? animated = false,
      int? duration = 3,
      Curve? curve = Curves.easeOut}) {
    if (listScrollController.isAttached) {
      if (animated = true) {
        listScrollController.scrollTo(
            index: position,
            duration: Duration(seconds: duration!),
            curve: curve!);
      } else {
        listScrollController.jumpTo(index: position, automaticAlignment: false);
      }
    }
  }

  Widget messageSpace(BuildContext showContext) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: FutureBuilder<List<dynamic>?>(
                future: loadMessages(), //_future, //loadUser(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    results = snapshot.data as List<dynamic>;
                    var reversedList = results.reversed.toList();

                    return StickyGroupedListView<dynamic, DateTime>(
                      elements: reversedList,
                      reverse: true,
                      order: StickyGroupedListOrder.DESC,
                      // Check first
                      groupBy: (dynamic message) {
                        if (message.createdAt != null) {
                          return DateTime(message.createdAt!.year,
                              message.createdAt!.month, message.createdAt!.day);
                        } else {
                          return DateTime(DateTime.now().year,
                              DateTime.now().month, DateTime.now().day);
                        }
                      },
                      floatingHeader: true,
                      groupComparator: (DateTime value1, DateTime value2) {
                        return value1.compareTo(value2);
                      },
                      itemComparator: (dynamic element1, dynamic element2) {
                        if (element1.createdAt != null &&
                            element2.createdAt != null) {
                          return element1.createdAt!
                              .compareTo(element2.createdAt!);
                        } else if (element1.createdAt == null &&
                            element2.createdAt != null) {
                          return DateTime.now().compareTo(element2.createdAt!);
                        } else if (element1.createdAt != null &&
                            element2.createdAt == null) {
                          return element1.createdAt!.compareTo(DateTime.now());
                        } else {
                          return DateTime.now().compareTo(DateTime.now());
                        }
                      },
                      groupSeparatorBuilder: (dynamic element) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 0, top: 3),
                          child: TextWithTap(
                            QuickHelp.getMessageTime(element.createdAt != null
                                ? element.createdAt!
                                : DateTime.now()),
                            textAlign: TextAlign.center,
                            color: kGreyColor1,
                            fontSize: 12,
                          ),
                        );
                      },
                      itemBuilder: (context, dynamic chatMessage) {
                        bool isMe = chatMessage.getAuthorId! ==
                                widget.currentUser!.objectId!
                            ? true
                            : false;
                        if (!isMe && !chatMessage.isRead!) {
                          _updateMessageStatus(chatMessage);
                        }

                        if (chatMessage.getMessageList != null &&
                            chatMessage.getMessageList!.getAuthorId ==
                                widget.mUser!.objectId) {
                          MessageListModel chatList =
                              chatMessage.getMessageList as MessageListModel;

                          if (!chatList.isRead! &&
                              chatList.objectId ==
                                  chatMessage.getMessageListId) {
                            _updateMessageList(chatMessage.getMessageList!);
                          }
                        }

                        return Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Container(
                            padding: EdgeInsets.only(top: 20),
                            child: isMe
                                ? mySentMessage(chatMessage)
                                : receivedMessage(chatMessage),
                          ),
                        );
                      },
                      // optional
                      itemScrollController: listScrollController, // optional
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: QuickActions.noContentFound(
                          "message_screen.no_chat_title".tr(),
                          "message_screen.no_chat_explain".tr(),
                          "assets/svg/ic_tab_message.svg"),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
        ),
        Visibility(
          visible: showVoiceRecorderArea,
          child: voiceRecorderArea(),
        ),
        Visibility(visible: showGifMessageInput, child: gifInputField()),
        Visibility(
            visible: showTextMessageInput, child: chatInputField(showContext)),
        Visibility(
          visible: disableMessageWays,
          child: ContainerCorner(
            borderColor: kGreyColor1.withOpacity(0.3),
            radiusTopLeft: 20,
            radiusTopRight: 20,
            marginLeft: 5,
            marginRight: 5,
            height: 50,
            marginTop: 20,
            color: QuickHelp.isDarkMode(context)
                ? kContentColorLightTheme
                : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 20),
                  child: SvgPicture.asset("assets/svg/ic_unmatch_user.svg"),
                ),
                TextWithTap(
                  "message_screen.removed_from_matches".tr(),
                  color: kBlueColor1,
                  fontWeight: FontWeight.bold,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: SvgPicture.asset("assets/svg/ic_unmatch_user.svg"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget showHeartOnLikedMessage(MessageModel chatMessage) {
    return Visibility(
      visible: chatMessage.isLikedMessage!,
      child: Positioned(
        right: chatMessage.getAuthorId == widget.currentUser!.objectId
            ? null
            : -10,
        left: chatMessage.getAuthorId == widget.currentUser!.objectId
            ? -10
            : null,
        bottom: -10,
        child: ContainerCorner(
          borderRadius: 50,
          color: kGreyColor0,
          width: 40,
          height: 30,
          borderWidth: 3,
          borderColor: Colors.white,
          child: ContainerCorner(
            color: kTransparentColor,
            marginTop: 1,
            marginLeft: 2,
            marginRight: 2,
            marginBottom: 1,
            child: SvgPicture.asset(
              "assets/svg/ic_match_heart_encounters.svg",
              color: Colors.red,
            ),
            width: 40,
          ),
        ),
      ),
    );
  }

  // Save the message
  _saveMessage(String messageText,
      {MessageModel? replyMessage,
      String? gifMessage,
      ParseFileBase? voiceMessage,
      String? voiceDuration,
      required String messageType}) async {
    setState(() {
      if (QuickHelp.isMobile()) {
        showMicrophoneButton = true;
      } else {
        showMicrophoneButton = false;
      }
    });

    if (messageText.isNotEmpty) {
      MessageModel message = MessageModel();
      message.setAuthor = widget.currentUser!;
      message.setAuthorId = widget.currentUser!.objectId!;

      message.setMessageType = messageType;

      message.setReceiver = widget.mUser!;
      message.setReceiverId = widget.mUser!.objectId!;

      if (messageText.isNotEmpty) {
        message.setText = messageText;
      }

      message.setIsMessageFile = false;

      message.setIsRead = false;

      if (replyMessage != null) {
        message.setReplyMessage = replyMessage;
      }

      if (gifMessage != null) {
        message.setGifMessage = gifMessage;
      }

      if (voiceMessage != null) {
        message.setVoiceMessage = voiceMessage;
      }

      if (voiceDuration != null) {
        message.setVoiceDuration = voiceDuration;
      }

      message.setIsLikedMessage = false;

      setState(() {
        results.add(message as dynamic);
      });

      ParseResponse response = await message.save();
      if (response.success) {
        if (messageType != MessageModel.messageTypeCall) {
          SendNotifications.sendPush(
            widget.currentUser!,
            widget.mUser!,
            SendNotifications.typeMessage,
          );
        }
        _saveList(message);
      }
    }
  }

  _saveList(MessageModel messageModel) async {
    QueryBuilder<MessageListModel> queryFrom =
        QueryBuilder<MessageListModel>(MessageListModel());
    queryFrom.whereEqualTo(MessageListModel.keyListId,
        widget.currentUser!.objectId! + widget.mUser!.objectId!);

    QueryBuilder<MessageListModel> queryTo =
        QueryBuilder<MessageListModel>(MessageListModel());
    queryTo.whereEqualTo(MessageListModel.keyListId,
        widget.mUser!.objectId! + widget.currentUser!.objectId!);

    QueryBuilder<MessageListModel> queryBuilder =
        QueryBuilder.or(MessageListModel(), [queryFrom, queryTo]);

    ParseResponse parseResponse = await queryBuilder.query();

    if (parseResponse.success) {
      if (parseResponse.results != null) {
        MessageListModel messageListModel = parseResponse.results!.first;

        messageListModel.setAuthor = widget.currentUser!;
        messageListModel.setAuthorId = widget.currentUser!.objectId!;

        messageListModel.setReceiver = widget.mUser!;
        messageListModel.setReceiverId = widget.mUser!.objectId!;

        messageListModel.setMessage = messageModel;
        messageListModel.setMessageId = messageModel.objectId!;
        messageListModel.setText = messageModel.getText!;
        messageListModel.setIsMessageFile = false;

        messageListModel.setIsRead = false;
        messageListModel.setListId =
            widget.currentUser!.objectId! + widget.mUser!.objectId!;

        messageListModel.setMessageType = messageModel.getMessageType!;

        messageListModel.setIsOnline =
            QuickHelp.isUserOnlineStatusBool(widget.mUser!);
        messageListModel.setIsFavorite = widget.currentUser!.getFavoritesUsers!
            .contains(widget.mUser!.objectId!);

        messageListModel.incrementCounter = 1;
        await messageListModel.save();

        messageModel.setMessageList = messageListModel;
        messageModel.setMessageListId = messageListModel.objectId!;

        await messageModel.save();
      } else {
        MessageListModel messageListModel = MessageListModel();

        messageListModel.setAuthor = widget.currentUser!;
        messageListModel.setAuthorId = widget.currentUser!.objectId!;

        messageListModel.setReceiver = widget.mUser!;
        messageListModel.setReceiverId = widget.mUser!.objectId!;

        messageListModel.setMessage = messageModel;
        messageListModel.setMessageId = messageModel.objectId!;
        messageListModel.setText = messageModel.getText!;
        messageListModel.setIsMessageFile = false;

        messageListModel.setListId =
            widget.currentUser!.objectId! + widget.mUser!.objectId!;
        messageListModel.setIsRead = false;

        messageListModel.setMessageType = messageModel.getMessageType!;

        messageListModel.setIsOnline =
            QuickHelp.isUserOnlineStatusBool(widget.mUser!);
        messageListModel.setIsFavorite = widget.currentUser!.getFavoritesUsers!
            .contains(widget.mUser!.objectId!);

        messageListModel.incrementCounter = 1;
        await messageListModel.save();

        messageModel.setMessageList = messageListModel;
        messageModel.setMessageListId = messageListModel.objectId!;
        await messageModel.save();
      }
    }
  }

  _updateMessageList(MessageListModel messageListModel) async {
    messageListModel.setIsRead = true;
    messageListModel.setCounter = 0;
    await messageListModel.save();
  }

  _updateMessageStatus(MessageModel messageModel) async {
    messageModel.setIsRead = true;
    await messageModel.save();
  }

  Future<void> _objectUpdated(MessageModel object) async {
    for (int i = 0; i < results.length; i++) {
      if (results[i].get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        if (UtilsConstant.after(results[i], object) == null) {
          setState(() {
            // ignore: invalid_use_of_protected_member
            results[i] = object.clone(object.toJson(full: true));
          });
        }
        break;
      }
    }
  }

  setupLiveQuery() async {
    if (subscription == null) {
      subscription = await liveQuery.client.subscribe(queryBuilder);
    }

    subscription!.on(LiveQueryEvent.create, (MessageModel message) {
      if (message.getAuthorId == widget.mUser!.objectId) {
        setState(() {
          results.add(message);
        });
      } else {
        setState(() {});
      }
    });

    subscription!.on(LiveQueryEvent.update, (MessageModel message) {
      _objectUpdated(message);
    });
  }

  String getReplayAuthorName(MessageModel message, UserModel user) {
    if (message.getAuthor!.objectId == user.objectId) {
      return "you_".tr();
    } else {
      return message.getAuthor!.getFirstName!;
    }
  }

  /* ============Report And Remove Match Stuffs==============*/
  /* ============Report And Remove Match Stuffs==============*/
  /* ============Report And Remove Match Stuffs==============*/

  /* ============Widgets==============*/
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

  Widget _showReportBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: SafeArea(
        child: ContainerCorner(
          radiusTopRight: 20.0,
          radiusTopLeft: 20.0,
          color: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                            padding: EdgeInsets.only(right: 15, left: 20),
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
                            padding:
                                const EdgeInsets.only(right: 10, left: 18),
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
                            padding: EdgeInsets.only(right: 15, left: 20),
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
      ),
    );
  }

  /* ============Functions==============*/
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

  bool _verifyMatch() {
    List<String> mUserRemovedMatches = widget.mUser!.getRemovedMatch!;
    List<String> currentUserRemovedMatches =
        widget.currentUser!.getRemovedMatch!;
    bool response = false;

    if (mUserRemovedMatches.contains(widget.currentUser!.objectId!) ||
        currentUserRemovedMatches.contains(widget.mUser!.objectId!)) {
      response = true;
    }
    return response;
  }

  bool hideAndShowTookKit() {
    List<String> currentUserRemovedMatches =
        widget.currentUser!.getRemovedMatch!;
    bool response = false;

    if (currentUserRemovedMatches.contains(widget.mUser!.objectId!)) {
      response = true;
    }
    return response;
  }

  unblock() async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.unsetRemovedMatch = widget.mUser!;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;
      widget.currentUser = response.results!.first;

      QuickHelp.hideLoadingDialog(context);
      setState(() {
        showTextMessageInput = true;
        disableMessageWays = false;
        showReportAndRemoveScreen = true;
        showUnblockUserScreen = false;
        disableCalls = false;
      });
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  removeMatchedUser({bool? reportAlso}) async {
    QuickHelp.showLoadingDialog(this.context, useLogo: true);

    widget.currentUser!.setRemovedMatch = widget.mUser!;
    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first;
      widget.currentUser = response.results!.first;

      QuickHelp.hideLoadingDialog(context);
      updateComponentsOnMatchRemoved();

      if (reportAlso != null && reportAlso) {
        openReportMessage();
      }
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
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

  /* ========================End============================= */
  /* ========================End============================= */
  /* ========================End============================= */

  /* ============Replied messages: Voice, Gif, Text==============*/
  /* ============Replied messages: Voice, Gif, Text==============*/
  /* ============Replied messages: Voice, Gif, Text==============*/
  Widget showRepliedMessage(MessageModel chatMessage) {
    return Visibility(
      visible: chatMessage.getReplyMessage != null ? true : false,
      child: Column(
        children: [
          if (chatMessage.getReplyMessage != null &&
              chatMessage.getReplyMessage!.getVoiceMessage != null)
            voiceRepliedMessage(chatMessage),
          if (chatMessage.getReplyMessage != null &&
              chatMessage.getReplyMessage!.getMessageType! ==
                  MessageModel.messageTypeText)
            texRepliedMessage(chatMessage),
          if (chatMessage.getReplyMessage != null &&
              chatMessage.getReplyMessage!.getGifMessage != null)
            gifRepliedMessage(chatMessage),
        ],
      ),
    );
  }

  Widget gifRepliedMessage(MessageModel chatMessage) {
    return ContainerCorner(
      color: kGrayColor.withOpacity(0.5),
      radiusTopRight: 20,
      radiusTopLeft: 20,
      marginTop: 10,
      marginLeft: 10,
      marginRight: 10,
      height: 150,
      width: 150,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ContainerCorner(
              color: kTransparentColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                    chatMessage.getReplyMessage != null
                        ? getReplayAuthorName(
                            chatMessage.getReplyMessage!, widget.currentUser!)
                        : "",
                    marginLeft: 10,
                    marginBottom: 1,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  Expanded(
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginBottom: 5,
                      marginLeft: 10,
                      height: 70,
                      width: 150,
                      child: QuickActions.gifWidget(
                          chatMessage.getReplyMessage!.getGifMessage!),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget voiceRepliedMessage(MessageModel chatMessage) {
    return ContainerCorner(
      color: kGrayColor.withOpacity(0.5),
      radiusTopRight: 20,
      radiusTopLeft: 20,
      marginTop: 10,
      marginLeft: 10,
      marginRight: 10,
      height: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ContainerCorner(
              color: kTransparentColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                    chatMessage.getReplyMessage != null
                        ? getReplayAuthorName(
                            chatMessage.getReplyMessage!, widget.currentUser!)
                        : "",
                    marginLeft: 10,
                    marginBottom: 1,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  Expanded(
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginBottom: 5,
                      marginLeft: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/svg/ic_audio_wave.svg"),
                          TextWithTap(
                            "Audio: ${chatMessage.getReplyMessage!.getVoiceDuration!}",
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget texRepliedMessage(MessageModel chatMessage) {
    return ContainerCorner(
      color: kGrayColor.withOpacity(0.5),
      radiusTopRight: 20,
      radiusTopLeft: 20,
      marginTop: 10,
      marginLeft: 10,
      marginRight: 10,
      height: 70,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ContainerCorner(
              color: kTransparentColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                    chatMessage.getReplyMessage != null
                        ? getReplayAuthorName(
                            chatMessage.getReplyMessage!, widget.currentUser!)
                        : "",
                    marginLeft: 10,
                    marginBottom: 1,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  ContainerCorner(
                    color: kTransparentColor,
                    width: MediaQuery.of(context).size.width - 100,
                    child: TextWithTap(
                      chatMessage.getReplyMessage != null
                          ? chatMessage.getReplyMessage!.getText!
                          : "",
                      marginLeft: 10,
                      color: Colors.black.withOpacity(0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ========================End============================= */
  /* ========================End============================= */
  /* ========================End============================= */

  /* ============Types of messages: Voice, Gif, Text==============*/
  /* ============Types of messages: Voice, Gif, Text==============*/
  /* ============Types of messages: Voice, Gif, Text==============*/

  Widget gifMessage(String url, MessageModel? chatMessage) {
    return Column(
      children: [
        if (chatMessage!.getReplyMessage != null)
          ContainerCorner(
            colors: [
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kPrimaryColor
                  : kGreyColor1,
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kPrimaryColor
                  : kGreyColor1,
            ],
            borderRadius: 20,
            child: Column(
              children: [
                showRepliedMessage(chatMessage),
                ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 5,
                  marginLeft: 5,
                  marginRight: 5,
                  height: 120,
                  width: 120,
                  marginBottom: 5,
                  borderRadius: 20,
                  child: QuickActions.gifWidget(
                    url,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        if (chatMessage.getReplyMessage == null)
          ContainerCorner(
            color: kTransparentColor,
            borderRadius: 20,
            child: Column(
              children: [
                showRepliedMessage(chatMessage),
                ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 5,
                  marginLeft: 5,
                  marginRight: 5,
                  height: 120,
                  width: 120,
                  marginBottom: 5,
                  borderRadius: 20,
                  child: QuickActions.gifWidget(
                    url,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget voiceMessage(MessageModel? chatMessage) {
    return Column(
      children: [
        if (chatMessage!.getReplyMessage != null)
          ContainerCorner(
            colors: [
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kPrimaryColor
                  : kGreyColor1,
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kPrimaryColor
                  : kGreyColor1,
            ],
            borderRadius: 20,
            child: Column(
              children: [
                ContainerCorner(
                  width: 215,
                  colors: [
                    chatMessage.getAuthorId == widget.currentUser!.objectId!
                        ? kPrimaryColor
                        : kGreyColor1,
                    chatMessage.getAuthorId == widget.currentUser!.objectId!
                        ? kSecondaryColor
                        : kGreyColor1,
                  ],
                  marginLeft: 5,
                  radiusTopLeft: 10.0,
                  radiusTopRight: 10.0,
                  radiusBottomRight:
                      chatMessage.getAuthorId == widget.currentUser!.objectId!
                          ? 0
                          : 10.0,
                  radiusBottomLeft:
                      chatMessage.getAuthorId == widget.currentUser!.objectId!
                          ? 10.0
                          : 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      showRepliedMessage(chatMessage),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _payAndPause(chatMessage.getVoiceMessage!.url!);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                getPlayOrPauseIcon(
                                    chatMessage.getVoiceMessage!.url != null
                                        ? chatMessage.getVoiceMessage!.url!
                                        : null),
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SvgPicture.asset(
                                "assets/svg/ic_audio_wave.svg"),
                          )
                        ],
                      ),
                      Row(
                        //mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWithTap(
                            getPlayOrPauseDuration(
                                chatMessage,
                                chatMessage.getVoiceMessage!.url != null
                                    ? chatMessage.getVoiceMessage!.url!
                                    : null),
                            color: Colors.white,
                            marginLeft: 15,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextWithTap(
                                chatMessage.createdAt != null
                                    ? QuickHelp.getMessageTime(
                                        chatMessage.createdAt!,
                                        time: true)
                                    : "sending_".tr(),
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                marginRight: 10,
                                marginLeft: 10,
                              ),
                              Visibility(
                                visible: chatMessage.getAuthorId ==
                                        widget.currentUser!.objectId!
                                    ? true
                                    : false,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(
                                    chatMessage.createdAt != null
                                        ? Icons.done_all
                                        : Icons.access_time_outlined,
                                    color: chatMessage.isRead!
                                        ? kBlueColor1
                                        : Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        if (chatMessage.getReplyMessage == null)
          ContainerCorner(
            width: 215,
            colors: [
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kPrimaryColor
                  : kGreyColor1,
              chatMessage.getAuthorId == widget.currentUser!.objectId!
                  ? kSecondaryColor
                  : kGreyColor1,
            ],
            marginLeft: 5,
            radiusTopLeft: 10.0,
            radiusTopRight: 10.0,
            radiusBottomRight:
                chatMessage.getAuthorId == widget.currentUser!.objectId!
                    ? 0
                    : 10.0,
            radiusBottomLeft:
                chatMessage.getAuthorId == widget.currentUser!.objectId!
                    ? 10.0
                    : 0.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _payAndPause(chatMessage.getVoiceMessage!.url!);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset(
                          getPlayOrPauseIcon(
                              chatMessage.getVoiceMessage!.url != null
                                  ? chatMessage.getVoiceMessage!.url!
                                  : null),
                          height: 24,
                          width: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SvgPicture.asset("assets/svg/ic_audio_wave.svg"),
                    )
                  ],
                ),
                Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWithTap(
                      getPlayOrPauseDuration(
                          chatMessage,
                          chatMessage.getVoiceMessage!.url != null
                              ? chatMessage.getVoiceMessage!.url!
                              : null),
                      color: Colors.white,
                      marginLeft: 15,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextWithTap(
                          chatMessage.createdAt != null
                              ? QuickHelp.getMessageTime(chatMessage.createdAt!,
                                  time: true)
                              : "sending_".tr(),
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          marginRight: 10,
                          marginLeft: 10,
                        ),
                        Visibility(
                          visible: chatMessage.getAuthorId ==
                                  widget.currentUser!.objectId!
                              ? true
                              : false,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              chatMessage.createdAt != null
                                  ? Icons.done_all
                                  : Icons.access_time_outlined,
                              color: chatMessage.isRead!
                                  ? kBlueColor1
                                  : Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /* ========================End============================= */
  /* ========================End============================= */
  /* ========================End============================= */

  /* ============Show message sent and received: Voice, Gif, Text==============*/
  /* ============Show message sent and received: Voice, Gif, Text==============*/
  /* ============Show message sent and received: Voice, Gif, Text==============*/

  Widget mySentMessage(MessageModel chatMessage) {
    return Align(
      alignment: (Alignment.topRight),
      child: Stack(clipBehavior: Clip.none, children: [
        if (chatMessage.getMessageType == MessageModel.messageTypeCall)
          ContainerCorner(
            radiusBottomLeft: 10,
            radiusTopLeft: 10,
            radiusTopRight: 10,
            marginTop: 10,
            marginBottom: 10,
            colors: [kPrimaryColor, kSecondaryColor],
            child: callMessage(chatMessage, true),
          ),
        if (MessageModel.messageTypeText == chatMessage.getMessageType)
          GestureDetector(
            child: ContainerCorner(
              radiusBottomLeft: 20,
              radiusTopLeft: 20,
              radiusTopRight: 20,
              colors: [kPrimaryColor, kSecondaryColor],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  showRepliedMessage(chatMessage),
                  TextWithTap(
                    chatMessage.getText!,
                    marginBottom: 5,
                    marginTop: 10,
                    color: Colors.white,
                    marginLeft: 10,
                    marginRight: 10,
                    fontSize: 14,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextWithTap(
                        chatMessage.createdAt != null
                            ? QuickHelp.getMessageTime(chatMessage.createdAt!,
                                time: true)
                            : "sending_".tr(),
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        marginRight: 10,
                        marginLeft: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(
                          chatMessage.createdAt != null
                              ? Icons.done_all
                              : Icons.access_time_outlined,
                          color:
                              chatMessage.isRead! ? kBlueColor1 : Colors.white,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onDoubleTap: () {
              print(chatMessage.objectId);
              _likeAndDislike(chatMessage);
            },
          ),
        if (MessageModel.messageTypeGif == chatMessage.getMessageType)
          GestureDetector(
            child: gifMessage(chatMessage.getGifMessage!, chatMessage),
            onDoubleTap: () {
              print(chatMessage.objectId);
              _likeAndDislike(chatMessage);
            },
          ),
        if (MessageModel.messageTypeVoice == chatMessage.getMessageType)
          GestureDetector(
            child: voiceMessage(chatMessage),
            onDoubleTap: () {
              print(chatMessage.objectId);
              _likeAndDislike(chatMessage);
            },
          ),
        showHeartOnLikedMessage(chatMessage),
      ]),
    );
  }

  Widget receivedMessage(MessageModel chatMessage) {
    return Align(
      alignment: (Alignment.topLeft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActions.avatarWidget(widget.mUser!, width: 25, height: 25),
          Flexible(
            child: GestureDetector(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (chatMessage.getMessageType ==
                      MessageModel.messageTypeCall)
                    ContainerCorner(
                      radiusBottomLeft: 10,
                      radiusTopLeft: 10,
                      radiusTopRight: 10,
                      marginTop: 10,
                      marginBottom: 10,
                      color: kGreyColor0,
                      child: callMessage(chatMessage, false),
                    ),
                  if (MessageModel.messageTypeText ==
                      chatMessage.getMessageType)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContainerCorner(
                          radiusTopLeft: 20,
                          radiusTopRight: 20,
                          radiusBottomRight: 20,
                          marginRight: 10,
                          marginLeft: 5,
                          color: kGreyColor0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Visibility(
                                visible: chatMessage.getReplyMessage != null
                                    ? true
                                    : false,
                                child: ContainerCorner(
                                  color: kGreyColor3,
                                  radiusTopRight: 20,
                                  radiusTopLeft: 20,
                                  marginTop: 10,
                                  marginLeft: 10,
                                  marginRight: 10,
                                  height: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: ContainerCorner(
                                          color: kTransparentColor,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextWithTap(
                                                chatMessage.getReplyMessage !=
                                                        null
                                                    ? getReplayAuthorName(
                                                        chatMessage
                                                            .getReplyMessage!,
                                                        widget.currentUser!)
                                                    : "",
                                                marginLeft: 10,
                                                marginBottom: 1,
                                                color: Colors.black
                                                    .withOpacity(0.4),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                              ContainerCorner(
                                                color: kTransparentColor,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    100,
                                                child: TextWithTap(
                                                  chatMessage.getReplyMessage !=
                                                          null
                                                      ? chatMessage
                                                          .getReplyMessage!
                                                          .getText!
                                                      : "",
                                                  marginLeft: 10,
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextWithTap(
                                chatMessage.getText!,
                                marginBottom: 10,
                                marginTop: 10,
                                color: Colors.black,
                                marginLeft: 10,
                                marginRight: 10,
                                fontSize: 14,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextWithTap(
                                    chatMessage.createdAt != null
                                        ? QuickHelp.getMessageTime(
                                            chatMessage.createdAt!,
                                            time: true)
                                        : "sending_".tr(),
                                    color: kGreyColor4,
                                    fontSize: 12,
                                    marginRight: 10,
                                    marginLeft: 10,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (MessageModel.messageTypeGif == chatMessage.getMessageType)
                    GestureDetector(
                      child:
                          gifMessage(chatMessage.getGifMessage!, chatMessage),
                      onDoubleTap: () {
                        print(chatMessage.objectId);
                        _likeAndDislike(chatMessage);
                      },
                    ),
                  if (MessageModel.messageTypeVoice ==
                      chatMessage.getMessageType)
                    GestureDetector(
                      child: voiceMessage(chatMessage),
                      onDoubleTap: () {
                        print(chatMessage.objectId);
                        _likeAndDislike(chatMessage);
                      },
                    ),
                  showHeartOnLikedMessage(chatMessage),
                ],
              ),
              onDoubleTap: () {
                print(chatMessage.objectId);
                _likeAndDislike(chatMessage);
              },
            ),
          ),
        ],
      ),
    );
  }

  /* ========================End============================= */
  /* ========================End============================= */
  /* ========================End============================= */

  /* ============Show message to be replied above messages inputs: Voice, Gif, Text==============*/
  /* ============Show message to be replied above messages inputs: Voice, Gif, Text==============*/
  /* ============Show message to be replied above messages inputs: Voice, Gif, Text==============*/

  Widget replyTextEditing() {
    return Visibility(
      visible: showReplyText,
      child: ContainerCorner(
        color: kGrayColor.withOpacity(0.5),
        radiusTopRight: 20,
        radiusTopLeft: 20,
        marginTop: 10,
        height: 100,
        child: Stack(children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ContainerCorner(
                color: kBlueColor1.withOpacity(0.5),
                width: 5,
                height: 60,
                marginLeft: 30,
                borderRadius: 20,
              ),
              Expanded(
                child: ContainerCorner(
                  color: kTransparentColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWithTap(
                        name,
                        marginLeft: 10,
                        marginBottom: 15,
                        color: Colors.black.withOpacity(0.4),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      ContainerCorner(
                        color: kTransparentColor,
                        width: MediaQuery.of(context).size.width - 20,
                        child: TextWithTap(
                          textToBeReplied,
                          marginLeft: 10,
                          color: Colors.black.withOpacity(0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    showReplyText = false;
                    textToBeReplied = "";
                    name = "";
                    repliedMessage = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: kBlueColor1,
                )),
          )
        ]),
      ),
    );
  }

  Widget replyGifEditing() {
    return Visibility(
      visible: showReplyGif,
      child: ContainerCorner(
        color: kGrayColor.withOpacity(0.5),
        radiusTopRight: 20,
        radiusTopLeft: 20,
        marginTop: 10,
        height: 100,
        child: Stack(children: [
          Row(
            //mainAxisSize: MainAxisSize.min,
            children: [
              ContainerCorner(
                color: kBlueColor1.withOpacity(0.5),
                width: 5,
                height: 60,
                marginLeft: 30,
                borderRadius: 20,
                marginTop: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                    name,
                    marginLeft: 10,
                    marginBottom: 3,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  Expanded(
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginBottom: 5,
                      marginLeft: 10,
                      height: 70,
                      width: 150,
                      child: QuickActions.gifWidget(gifReplyUrl),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    showReplyGif = false;
                    gifReplyUrl = "";
                    name = "";
                    repliedMessage = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: kBlueColor1,
                )),
          )
        ]),
      ),
    );
  }

  Widget replyVoiceEditing() {
    return Visibility(
      visible: showReplyVoice,
      child: ContainerCorner(
        color: kGrayColor.withOpacity(0.5),
        radiusTopRight: 20,
        radiusTopLeft: 20,
        marginTop: 10,
        height: 100,
        child: Stack(children: [
          Row(
            //mainAxisSize: MainAxisSize.min,
            children: [
              ContainerCorner(
                color: kBlueColor1.withOpacity(0.5),
                width: 5,
                height: 60,
                marginLeft: 30,
                borderRadius: 20,
                marginTop: 20,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                    name,
                    marginLeft: 10,
                    marginBottom: 3,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  Expanded(
                    child: ContainerCorner(
                      color: kTransparentColor,
                      //marginBottom: 5,
                      marginTop: 10,
                      marginLeft: 10,
                      height: 70,
                      width: 150,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset("assets/svg/ic_audio_wave.svg"),
                          TextWithTap(
                            "Audio: $textToBeReplied",
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    showReplyVoice = false;
                    name = "";
                    repliedMessage = null;
                  });
                },
                child: Icon(
                  Icons.close,
                  color: kBlueColor1,
                )),
          )
        ]),
      ),
    );
  }

  /* ========================End============================= */
  /* ========================End============================= */
  /* ========================End============================= */

  /* ================Messages Inputs: Voice Recorder, Gif, Text==============*/
  /*=================Messages Inputs: Voice Recorder, Gif, Text==============*/
  /*=================Messages Inputs: Voice Recorder, Gif, Text==============*/

  Widget gifInputField() {
    return Column(
      children: [
        Column(
          children: [
            replyTextEditing(),
            replyGifEditing(),
            replyVoiceEditing(),
            GiphyWidget(
                apiKey: Config.giphyApiKey,
                search: _search,
                onTap: (url) {
                  if (_verifyMatch()) {
                    disableMessageWays = true;
                    showTextMessageInput = false;
                    showGifMessageInput = false;
                    showVoiceRecorderArea = false;
                  } else {
                    _saveMessage(
                      "gif",
                      gifMessage: url,
                      replyMessage:
                          repliedMessage != null ? repliedMessage : null,
                      messageType: MessageModel.messageTypeGif,
                    );
                    setState(() {
                      messageController.clear();
                      showReplyText = false;
                      textToBeReplied = "";
                      name = "";
                      repliedMessage = null;
                      showReplyGif = false;
                      showReplyVoice = false;
                      gifReplyUrl = "";
                    });
                  }

                  //scrollToBottom(position: results.length);
                }),
            ContainerCorner(
              shadowColor: QuickHelp.isDarkMode(context)
                  ? kContentColorGhostTheme
                  : kGreyColor3,
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : Colors.white,
              blurRadius: 20,
              spreadRadius: 5,
              borderRadius: 50,
              marginBottom: 10,
              marginRight: 20,
              marginLeft: 20,
              marginTop: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        autocorrect: false,
                        controller: gifController,
                        decoration: InputDecoration(
                          hintText: "message_screen.txt_gif_input".tr(),
                          border: InputBorder.none,
                        ),
                        onChanged: (text) {
                          _searchGift(text);
                        },
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_verifyMatch()) {
                          disableMessageWays = true;
                          showTextMessageInput = false;
                          showGifMessageInput = false;
                          showVoiceRecorderArea = false;
                        } else {
                          disableMessageWays = false;
                          showTextMessageInput = true;
                          showGifMessageInput = false;
                          showVoiceRecorderArea = false;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.close),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget voiceRecorderArea() {
    return Column(
      children: [
        replyTextEditing(),
        replyGifEditing(),
        replyVoiceEditing(),
        ContainerCorner(
          color: kTransparentColor,
          marginTop: 20,
          marginRight: 10,
          marginLeft: 10,
          child: ContainerCorner(
            color: kTransparentColor,
            //shadowColor: kGrayColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ContainerCorner(
                        shadowColor: QuickHelp.isDarkMode(context)
                            ? kContentColorGhostTheme
                            : kGreyColor3,
                        color: QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : Colors.white,
                        blurRadius: 20,
                        spreadRadius: 5,
                        borderRadius: 50,
                        marginBottom: 10,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: SvgPicture.asset(
                                        "assets/svg/ic_microphone.svg",
                                        color: Colors.red,
                                        height: 18,
                                      ),
                                    ),
                                    StreamBuilder<int>(
                                      stream: _stopWatchTimer.secondTime,
                                      initialData: 0,
                                      builder: (context, snap) {
                                        final value = snap.data;
                                        callDuration =
                                            QuickHelp.formatTime(value!);
                                        return Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8),
                                              child: TextWithTap(
                                                QuickHelp.formatTime(value),
                                                fontSize: 20,
                                                color: kGrayColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              ContainerCorner(
                                color: kTransparentColor,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: kGreyColor1,
                                    ),
                                    TextWithTap(
                                      "slide to cancel",
                                      color: kGreyColor1,
                                      marginRight: 70,
                                      marginLeft: 10,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          Positioned(
                            right: 0,
                            bottom: -6,
                            child: Draggable<String>(
                              data: "red",
                              axis: Axis.horizontal,
                              onDragEnd: (detail) {
                                setState(() {
                                  stopRecording();
                                  if (_verifyMatch()) {
                                    disableMessageWays = true;
                                    showTextMessageInput = false;
                                    showGifMessageInput = false;
                                    showVoiceRecorderArea = false;
                                  } else {
                                    showTextMessageInput = true;
                                    showGifMessageInput = false;
                                    showVoiceRecorderArea = false;
                                    _stopWatchTimer.onExecute
                                        .add(StopWatchExecute.reset);
                                  }
                                });
                              },
                              child: ContainerCorner(
                                shadowColor: QuickHelp.isDarkMode(context)
                                    ? kContentColorGhostTheme
                                    : kGreyColor3,
                                setShadowToBottom: true,
                                blurRadius: 20,
                                spreadRadius: 5,
                                borderRadius: 50,
                                colors: [kPrimaryColor, kSecondaryColor],
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SvgPicture.asset(
                                    voiceMessageButtonIcon,
                                    color: Colors.white,
                                    height: 10,
                                    width: 10,
                                  ),
                                ),
                                height: 65,
                                width: 65,
                                onTap: () {
                                  if (_verifyMatch()) {
                                    disableMessageWays = true;
                                    showTextMessageInput = false;
                                    showGifMessageInput = false;
                                    showVoiceRecorderArea = false;
                                  } else {
                                    setState(() {
                                      stopRecording();
                                      showTextMessageInput = true;
                                      showGifMessageInput = false;
                                      showVoiceRecorderArea = false;
                                    });

                                    saveVoiceMessage(
                                        repliedMessage: repliedMessage != null
                                            ? repliedMessage
                                            : null);
                                    setState(() {
                                      _stopWatchTimer.onExecute
                                          .add(StopWatchExecute.reset);
                                      showReplyText = false;
                                      textToBeReplied = "";
                                      name = "";
                                      repliedMessage = null;
                                      showReplyGif = false;
                                      showMicrophoneButton = true;
                                      gifReplyUrl = "";
                                    });
                                  }
                                },
                              ),
                              feedback: ContainerCorner(
                                shadowColor: QuickHelp.isDarkMode(context)
                                    ? kContentColorGhostTheme
                                    : kGreyColor3,
                                setShadowToBottom: true,
                                colors: [kPrimaryColor, kSecondaryColor],
                                blurRadius: 20,
                                spreadRadius: 5,
                                borderRadius: 50,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: SvgPicture.asset(
                                    "assets/svg/ic_microphone.svg",
                                    color: Colors.white,
                                    height: 10,
                                    width: 10,
                                  ),
                                ),
                                height: 65,
                                width: 65,
                                onTap: () {},
                              ),
                              childWhenDragging: Container(),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget chatInputField(BuildContext showContext) {
    return Column(
      children: [
        replyTextEditing(),
        replyGifEditing(),
        replyVoiceEditing(),
        ContainerCorner(
          color: kTransparentColor,
          marginTop: 20,
          marginRight: 10,
          marginLeft: 10,
          child: ContainerCorner(
            color: kTransparentColor,
            //shadowColor: kGrayColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ContainerCorner(
                        shadowColor: QuickHelp.isDarkMode(context)
                            ? kContentColorGhostTheme
                            : kGreyColor3,
                        color: QuickHelp.isDarkMode(context)
                            ? kContentColorLightTheme
                            : Colors.white,
                        blurRadius: 20,
                        spreadRadius: 5,
                        borderRadius: 50,
                        marginBottom: 10,
                        child: Row(
                          children: [
                            ContainerCorner(
                              color: kBlueColor1,
                              borderRadius: 50,
                              marginRight: 10,
                              marginLeft: 10,
                              onTap: () {
                                setState(() {
                                  if (_verifyMatch()) {
                                    disableMessageWays = true;
                                    showTextMessageInput = false;
                                    showGifMessageInput = false;
                                    showVoiceRecorderArea = false;
                                  } else {
                                    showTextMessageInput = false;
                                    showGifMessageInput = true;
                                    showVoiceRecorderArea = false;
                                  }
                                });
                              },
                              child: Center(
                                child: TextWithTap(
                                  "message_screen.gif_btn".tr().toUpperCase(),
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  marginTop: 5,
                                  marginBottom: 5,
                                  marginLeft: 5,
                                  marginRight: 5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                focusNode: messageTextFieldFocusNode,
                                minLines: 1,
                                maxLines: 3,
                                autocorrect: false,
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText:
                                      "message_screen.txt_chat_input".tr(),
                                  border: InputBorder.none,
                                ),
                                onChanged: (text) {
                                  if (text.isNotEmpty) {
                                    setState(() {
                                      if (_verifyMatch()) {
                                        disableMessageWays = true;
                                        showTextMessageInput = false;
                                        showGifMessageInput = false;
                                        showVoiceRecorderArea = false;
                                      } else {
                                        showMicrophoneButton = false;
                                      }
                                    });
                                  } else {
                                    if (QuickHelp.isMobile()) {
                                      setState(() {
                                        showMicrophoneButton = true;
                                      });
                                    } else {
                                      showMicrophoneButton = false;
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: showMicrophoneButton && QuickHelp.isMobile(),
                      child: ContainerCorner(
                        shadowColor: QuickHelp.isDarkMode(context)
                            ? kContentColorGhostTheme
                            : kGreyColor3,
                        setShadowToBottom: true,
                        blurRadius: 20,
                        spreadRadius: 5,
                        borderRadius: 50,
                        marginLeft: 10,
                        marginBottom: 10,
                        onLongPress: () {
                          checkMicPermission();
                        },
                        colors: [kPrimaryColor, kSecondaryColor],
                        child: Showcase(
                          key: _one,
                          shapeBorder: CircleBorder(),
                          radius: BorderRadius.all(Radius.circular(40)),
                          showArrow: false,
                          overlayPadding: EdgeInsets.all(5),
                          description: "message_screen.record_info".tr(),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              "assets/svg/ic_microphone.svg",
                              color: Colors.white,
                              height: 10,
                              width: 10,
                            ),
                          ),
                        ),
                        height: 50,
                        width: 50,
                        onTap: () {
                          ShowCaseWidget.of(showContext)!.startShowCase([_one]);
                          setState(() {
                            if (_verifyMatch()) {
                              disableMessageWays = true;
                              showTextMessageInput = false;
                              showGifMessageInput = false;
                              showVoiceRecorderArea = false;
                            } else {
                              showTextMessageInput = true;
                              showGifMessageInput = false;
                            }
                          });
                        },
                      ),
                    ),
                    Visibility(
                      visible: !showMicrophoneButton,
                      child: ContainerCorner(
                        shadowColor: QuickHelp.isDarkMode(context)
                            ? kContentColorGhostTheme
                            : kGreyColor3,
                        setShadowToBottom: true,
                        blurRadius: 20,
                        spreadRadius: 5,
                        borderRadius: 50,
                        marginLeft: 10,
                        marginBottom: 10,
                        colors: [kPrimaryColor, kSecondaryColor],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            sendButtonIcon!,
                            color: Colors.white,
                            height: 10,
                            width: 10,
                          ),
                        ),
                        height: 50,
                        width: 50,
                        onTap: () {
                          if (messageController.text.isNotEmpty) {
                            _saveMessage(messageController.text,
                                replyMessage: repliedMessage != null
                                    ? repliedMessage
                                    : null,
                                messageType: MessageModel.messageTypeText);
                            setState(() {
                              messageController.clear();
                              showReplyText = false;
                              textToBeReplied = "";
                              name = "";
                              repliedMessage = null;
                              showReplyGif = false;
                              showReplyVoice = false;
                              gifReplyUrl = "";
                            });

                            //scrollToBottom(position: results.length);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
