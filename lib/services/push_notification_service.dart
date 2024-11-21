import 'dart:convert';

import 'package:heyto/app/navigation_service.dart';
import 'package:heyto/helpers/send_notifications.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/message/message_screen.dart';
import 'package:heyto/home/profile/user_profile_details_screen.dart';
import 'package:heyto/providers/counter_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:provider/provider.dart';

import '../app/config.dart';
import '../helpers/quick_help.dart';
import '../models/UserModel.dart';

class PushNotificationService {

  UserModel? currentUser;

  PushNotificationService({this.currentUser, BuildContext? context});


  Future initialise() async {

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    currentUser = await QuickHelp.getUser();

    messaging.onTokenRefresh.listen((newToken) async {
      // Save newToken
      print('new Token: $newToken');
      if(QuickHelp.isIOSPlatform()){

        messaging.getAPNSToken().then((value) {
          print("APNS Token: $value");

          if(value!= null){
            _storeToken(value);
          } else {
            _storeToken("");
          }
        });
      } else {
        _storeToken(newToken);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

      _decodePushMessage(message.data);
    });

    if(QuickHelp.isAndroidPlatform()){
      await registerNotificationListeners();
    }

    messaging.getNotificationSettings().then((value) async {

      if(value.authorizationStatus == AuthorizationStatus.notDetermined){
        print("Notification notDetermined ");

        _notificationAsk(false, messaging);

      } else if(value.authorizationStatus == AuthorizationStatus.authorized) {

        print("Notification authorized ");

        await registerNotificationListeners();
        savePush(messaging);

      } else if(value.authorizationStatus == AuthorizationStatus.denied) {

        print("Notification authorized ");

        _notificationAsk(true, messaging);

      } else if(value.authorizationStatus == AuthorizationStatus.provisional) {

        print("Notification authorized ");

        _notificationAsk(false, messaging);
      }
    });
  }

  _notificationAsk(bool denied, FirebaseMessaging messaging){

    if(denied){

      QuickHelp.showDialogPermission(
        context: NavigationService.navigatorKey.currentContext!,
        title: "permissions.allow_push_denied_title".tr(),
        message: "permissions.allow_push_denied".tr() ,
        dismissible: false,
        confirmButtonText: "ok_".tr(),
        onPressed: () async {

          QuickHelp.hideLoadingDialog(NavigationService.navigatorKey.currentContext!);

          await enableIOSNotifications();
          savePush(messaging);
        },
      );

    } else {

      QuickHelp.showDialogPermission(
        context: NavigationService.navigatorKey.currentContext!,
        title: "permissions.push_notifications_tile".tr(),
        message: "permissions.app_notifications_explain".tr() ,
        dismissible: false,
        confirmButtonText: "permissions.allow_push_notifications".tr(),
        onPressed: () async {
          QuickHelp.hideLoadingDialog(NavigationService.navigatorKey.currentContext!);

          await enableIOSNotifications();
          savePush(messaging);
        },
      );
    }
  }

  savePush(FirebaseMessaging messaging){

    messaging.getToken(vapidKey: Config.webPushCertificate).then((token) {
      if(QuickHelp.isIOSPlatform()){

        messaging.getAPNSToken().then((value) {
          print("APNS Token: $value");

          if(value!= null){
            _storeToken(value);
          } else {
            _storeToken("");
          }
        });
      } else {
        _storeToken(token!);
      }
    });
  }

  _decodePushMessage(Map<String, dynamic> message) async {

    UserModel? mUser;

    var data = message["data"];
    Map notification = json.decode(data);

    print("Push Notification: onBackgroundMessage $notification");

    var type = notification[SendNotifications.pushNotificationType];
    var senderId = notification[SendNotifications.pushNotificationSender];
    //var objectId = notification[SendNotifications.pushNotificationObjectId];

    if(type == SendNotifications.typeMessage || type == SendNotifications.typeMissedCall || type == SendNotifications.typeMatch){

      QueryBuilder<UserModel> queryUser = QueryBuilder<UserModel>(UserModel.forQuery());
      queryUser.whereEqualTo(UserModel.keyObjectId, senderId);

      ParseResponse parseResponse = await queryUser.query();
      if(parseResponse.success && parseResponse.results != null){
        mUser = parseResponse.results!.first! as UserModel;
      }

      if(currentUser != null && mUser != null){
        _gotToChat(currentUser!, mUser);
      }

    } else if(type == SendNotifications.typeLiked){

      if(currentUser != null){
        NavigationService.navigatorKey.currentContext!.read<CountersProvider>().setTabIndex(HomeScreen.tabLikes);
      }

    }else if(type == SendNotifications.typeFavorite || type == SendNotifications.typeProfileVisit){

      QueryBuilder<UserModel> queryUser = QueryBuilder<UserModel>(UserModel.forQuery());
      queryUser.whereEqualTo(UserModel.keyObjectId, senderId);

      ParseResponse parseResponse = await queryUser.query();
      if(parseResponse.success && parseResponse.results != null){
        mUser = parseResponse.results!.first! as UserModel;
      }

      if(currentUser != null && mUser != null){
        QuickHelp.goToNavigatorScreen(NavigationService.navigatorKey.currentContext!, UserProfileDetailsScreen(currentUser: currentUser, mUser: mUser,showComponents: true,), route: UserProfileDetailsScreen.route,);
      }

    }

    print("Push Notification data: $notification");
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickHelp.goToNavigatorScreen(NavigationService.navigatorKey.currentContext!, MessageScreen(currentUser: currentUser, mUser: mUser,), route: MessageScreen.route,);
  }

  registerNotificationListeners() async {

    AndroidNotificationChannel channel = androidNotificationChannel();
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    var androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    var iOSSettings = IOSInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();


    var initSetttings = InitializationSettings(android: androidSettings, iOS: iOSSettings);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: (message) async {

          if(notificationAppLaunchDetails!.didNotificationLaunchApp == true){

            print("Push Notification LaunchApp: ${notificationAppLaunchDetails.payload}");
          }
          print("Push Notification message: $message");
        });

// onMessage is called when the app is in foreground and a notification is received
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) async {

      print("Push Notification onMessage ${message!.data}");
      RemoteNotification? notification = message.notification;

      AndroidNotification? android = message.notification?.android;
      AppleNotification? apple = message.notification?.apple;
      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.

      if (notification != null && android != null) {

        print("Push Notification android");

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              //largeIcon: androidBitmap,
              playSound: true,
              autoCancel: true,
              //groupKey: group,
              importance: Importance.max,

            ),
          ),
        );

      } else if (notification != null && apple != null) {

        print("Push Notification iOS");

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            iOS: IOSNotificationDetails(
             presentSound: true,
              presentBadge: true,
              presentAlert: true,
            ),
          ),
        );
      }

    });
  }
  enableIOSNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    await registerNotificationListeners();
  }

  androidNotificationChannel() => AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  _storeToken(String deviceToken) async {

    print("Push User: ${currentUser != null  ? currentUser!.objectId! : "null"} Token $deviceToken");

    QuickHelp.initInstallation(currentUser, deviceToken);
  }
}