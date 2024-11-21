import 'package:agora_rtm/agora_rtm.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/calls/voice_call_screen.dart';
import 'package:heyto/home/calls/video_call_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/calls_providers.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import '../../providers/provider_inherited_widget.dart';

// ignore: must_be_immutable
class IncomingCallScreen extends StatefulWidget {
  UserModel? mUser, currentUser;
  bool? isVideoCall;
  String? channel;
  static String route = "/call/incoming";

  AgoraRtmRemoteInvitation? agoraRtmRemoteInvitation;

  IncomingCallScreen({this.mUser, this.isVideoCall, this.channel, this.currentUser, this.agoraRtmRemoteInvitation}) ;

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {

  bool screenAvailable = true;

  void _acceptCall(){

    FlutterRingtonePlayer.stop();

    setState(() {
      screenAvailable = false;
    });

    context.read<CallsProvider>().answerCall(widget.agoraRtmRemoteInvitation!);

    if(widget.isVideoCall != null && widget.isVideoCall == true){
      QuickHelp.goToNavigatorScreen(context, VideoCallScreen(currentUser: widget.currentUser, mUser: widget.mUser, channel: widget.channel, isCaller: false), finish: true, back: false, route: VideoCallScreen.route);
    } else {
      QuickHelp.goToNavigatorScreen(context, VoiceCallScreen(mUser: widget.mUser, currentUser: widget.currentUser, channel: widget.channel, isCaller: false,), finish: true, back: false, route: VoiceCallScreen.route) ;
    }
  }

  void _refuseCall(){

    FlutterRingtonePlayer.stop();

    setState(() {
      screenAvailable = false;
    });

    context.read<CallsProvider>().refuseRemoteInvitation(widget.agoraRtmRemoteInvitation!);
    QuickHelp.goBackToPreviousPage(context);
  }

  observeCall(){

    if(context.watch<CallsProvider>().isCallCanceled == true){
      QuickHelp.goBackToPreviousPage(context);

      print("AgoraCall isCallCanceled == true");
    }
  }

  startCallCheck(){

    Future.delayed(Duration(seconds: Setup.callWaitingDuration), (){
      if(mounted && screenAvailable) QuickHelp.goBackToPreviousPage(context);
    });
  }

  setupCallObserver(){
    print("AgoraCall setupCallObserver called");

    bool callRefused = context.watch<CallsProvider>().isCallCanceled;
    if (callRefused == true) {
      print("AgoraCall isCallRefused == true");

      //endCallRefused();
      if(mounted && screenAvailable){
        QuickHelp.goBackToPreviousPage(context);
      }
    }
  }

  @override
  void initState() {

    context.read<CallsProvider>().setCanceled(false);
    startCallCheck();
    FlutterRingtonePlayer.playRingtone();
    super.initState();
  }
  @override
  void dispose() {

    FlutterRingtonePlayer.stop();

    screenAvailable = false;
    super.dispose();
  }

  @override
  didChangeDependencies(){
    context.dependOnInheritedWidgetOfExactType<ProviderInheritedWidget>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {

    ProviderInheritedWidget.of(context);
    observeCall();

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            ContainerCorner(
              color: kTransparentColor,
              borderWidth: 0,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: QuickActions.photosWidget(
                  widget.mUser!.getAvatar!.url!,
                  borderRadius: 0,
                  fit: BoxFit.cover
              ) ,
            ),
            Padding(
              padding:  EdgeInsets.only(top: 150),
              child: Column(
                children: [
                  TextWithTap(widget.mUser!.getFullName!,
                      fontWeight: FontWeight.w600,
                      fontSize: 25,
                      color: Colors.white),
                  TextWithTap(widget.isVideoCall != null && widget.isVideoCall == true ? "video_call.incoming_call_video".tr() : "video_call.incoming_call_voice".tr(), color: Colors.white,)
                ],
              ),
            ),
            Positioned(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ContainerCorner(
                    width: 60,
                    height: 60,
                    marginLeft: 10,
                    marginRight: 70,
                    borderRadius: 50,
                    color: Colors.red,
                    marginBottom: 20,
                    child: Icon(Icons.call_end, size: 45, color: Colors.white,),
                    onTap: (){
                      _refuseCall();
                    },
                  ),
                  ContainerCorner(
                    width: 60,
                    height: 60,
                    marginLeft: 70,
                    borderRadius: 50,
                    color: Colors.green,
                    marginBottom: 20,
                    child: Icon(Icons.call , size: 45, color: Colors.white,),
                    onTap: (){
                      _acceptCall();
                    },
                  )
                ],
              ),
              bottom: 100,
            )
          ],
        ),
      ),
    );
  }
}
