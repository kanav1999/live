
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/app/config.dart';
import 'package:heyto/app/navigation_service.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/calls/incomming_call_screen.dart';
import 'package:heyto/models/UserModel.dart';

class CallsProvider extends ChangeNotifier {

  AgoraRtmClient? _client;
  AgoraRtmLocalInvitation? invitation;
  bool _isLogin = false;
  //BuildContext? _context;
  UserModel? _currentUser;
  bool isCallCanceled = false;
  bool isCallRinging = false;
  bool isCallRefused = false;

  AgoraRtmClient? getAgoraRtmClient(){

    if(_client != null){
      _createClient();
    }

    return _client;
  }

  setCallRefused(bool callRefused){
    isCallRefused = callRefused;
    //notifyListeners();
  }

  setCanceled(bool callCanceled){
    isCallCanceled = callCanceled;
    //notifyListeners();
  }

  bool isAgoraUserLogged(UserModel? user){
    _currentUser = user;

    if(!_isLogin){
      _toggleLogin(user!);
    }
    return _isLogin;
  }

  void connectAgoraRtm(){
    _createClient();
  }

  void loginAgoraUser(UserModel? user){
    _currentUser = user;

    _toggleLogin(user!);
  }

  void _createClient() async {

    _client = await AgoraRtmClient.createInstance(Config.agoraAppId);
    _client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _log("Peer msg: " + peerId + ", msg: " + (message.text));
    };
    _client?.onConnectionStateChanged = (int state, int reason) {
      _log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _client?.logout();
        _log('Logout.');
        _isLogin = false;
        notifyListeners();
      }
    };

    _client?.onLocalInvitationReceivedByPeer = (AgoraRtmLocalInvitation invite) {
      _log('Local invitation received by peer: ${invite.calleeId}, content: ${invite.content}');
      isCallRinging = true;
      //isCallRefused = false;
      //isCallCanceled = false;
      notifyListeners();
    };

    // Call MAKER

    _client?.onLocalInvitationRefused = ( AgoraRtmLocalInvitation invite) {
      _log('Local invitation Refused by peer: ${invite.calleeId}, content: ${invite.content}');
      isCallRefused = true;
      notifyListeners();
    };

    _client?.onLocalInvitationCanceled = ( AgoraRtmLocalInvitation invite) {
      _log('Local invitation Canceled by peer calle: ${invite.calleeId}, content: ${invite.content}');
      //isCallRefused = true;
      notifyListeners();
    };

    _client?.onLocalInvitationFailure = ( AgoraRtmLocalInvitation invite, int error) {
      _log('Local invitation Failure by peer: ${invite.calleeId}, content: ${invite.content}');
      //isCallRefused = true;
      //notifyListeners();
    };

    // Call RECEIVER

    _client?.onRemoteInvitationReceivedByPeer = (AgoraRtmRemoteInvitation invite) {
      _log('Remote invitation received by peer: ${invite.callerId}, content: ${invite.content}');
      //isCallCanceled = false;
      initCallScreen(invite);
    };

    _client?.onRemoteInvitationCanceled = (AgoraRtmRemoteInvitation invite) {
      _log('Remote invitation Canceled by peer caller: ${invite.callerId}, content: ${invite.content}');
      isCallCanceled = true;
      notifyListeners();
    };

    _client?.onRemoteInvitationRefused = ( AgoraRtmRemoteInvitation invite) {
      _log('Remote invitation Refused by peer: ${invite.callerId}, content: ${invite.content}');
      //isCallRefused = true;
      //notifyListeners();
    };

    _client?.onRemoteInvitationFailure = ( AgoraRtmRemoteInvitation invite, int error) {
      _log('Remote invitation Failure by peer: ${invite.callerId}, content: ${invite.content}');
      //isCallRefused = true;
      //notifyListeners();
    };
  }

  void _toggleLogin(UserModel? userModel) async {
    if (_isLogin) {
      try {
        await _client?.logout();
        _log('Logout success.');

        _isLogin = false;
        notifyListeners();
      } catch (errorCode) {
        _log('Logout error: ' + errorCode.toString());
      }
    } else {
      if (userModel!.objectId!.isEmpty) {
        _log('Please input your user id to login.');
        return;
      }

      try {
        await _client?.login(null, userModel.objectId!);
        _log('Login success: ' + userModel.objectId!);

        _isLogin = true;
        notifyListeners();
      } catch (errorCode) {
        _log('Login error: ' + errorCode.toString());
      }
    }
  }

  // Make call to other user
  void callUserInvitation({required String calleeId, required String channel, required bool isVideo}) async {

    //isCallRinging = false;
    //isCallRefused = false;
    //isCallCanceled = false;

    try {
      invitation = AgoraRtmLocalInvitation(calleeId, content: isVideo?  "video" : "voice", channelId: channel);
      _log(invitation!.content ?? '');
      await _client?.sendLocalInvitation(invitation!.toJson());
      _log('Send local invitation success.');
      //notifyListeners();
    } catch (errorCode) {
      _log('Send local invitation error: ' + errorCode.toString());
    }
  }

  // Cancel call made to other user before pickup
  void cancelCallInvitation() {
    if (_client != null && invitation != null) {
      _client?.cancelLocalInvitation(invitation!.toJson());
    } else {
      _log("cancelCallInvitation _client null");
    }
  }

  // Accept a call invitation.
  void answerCall(final AgoraRtmRemoteInvitation invitation) {
    if (_client != null) {
      _client?.acceptRemoteInvitation(invitation.toJson());
    } else {
      _log("acceptRemoteInvitation _client null");
    }
  }

  // Refuse a call invitation.
  void refuseRemoteInvitation(AgoraRtmRemoteInvitation invitation) {
    if (_client != null) {
      _client?.refuseRemoteInvitation(invitation.toJson());
    } else {
      _log("refuseRemoteInvitation _client null");
    }
  }

  initCallScreen(AgoraRtmRemoteInvitation agoraRtmRemoteInvitation) async {

    isCallCanceled = false;

    QueryBuilder<UserModel> queryUser = QueryBuilder<UserModel>(UserModel.forQuery());
    queryUser.whereEqualTo(UserModel.keyObjectId, agoraRtmRemoteInvitation.callerId);

    ParseResponse parseResponse = await queryUser.query();
    if(parseResponse.success && parseResponse.results != null){
      UserModel mUser = parseResponse.results!.first! as UserModel;

      _log("Show Incamming Screen");
      QuickHelp.goToNavigatorScreen(NavigationService.navigatorKey.currentContext!,  IncomingCallScreen(mUser: mUser, currentUser: _currentUser  , channel: agoraRtmRemoteInvitation.channelId!, isVideoCall: agoraRtmRemoteInvitation.content! == "video" ? true : false, agoraRtmRemoteInvitation: agoraRtmRemoteInvitation,), route: IncomingCallScreen.route,);
    } else{
      _log("parseResponse error");
    }
  }

  _log(String string) {
    print("AgoraCall " + string);
  }
}