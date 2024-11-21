import 'package:heyto/app/navigation_service.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/forgot_screen.dart';
import 'package:heyto/auth/login_screen.dart';
import 'package:heyto/auth/phone_login_screen.dart';
import 'package:heyto/auth/signup_account_screen.dart';
import 'package:heyto/auth/welcome_screen.dart';
import 'package:heyto/home/profile/image_crop_screen.dart';
import 'package:heyto/home/web/web_url_screen.dart';
import 'package:heyto/models/CallsModel.dart';
import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/GiftsModel.dart';
import 'package:heyto/models/HashTagsModel.dart';
import 'package:heyto/models/LiveStreamingModel.dart';
import 'package:heyto/models/MessagesModel.dart';
import 'package:heyto/models/MessageListModel.dart';
import 'package:heyto/models/OrderMessagesModel.dart';
import 'package:heyto/models/PaymentsModel.dart';
import 'package:heyto/models/PictureModel.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/ReportModel.dart';
import 'package:heyto/models/WithdrawModel.dart';
import 'package:heyto/providers/calls_providers.dart';
import 'package:heyto/providers/counter_providers.dart';
import 'package:heyto/providers/update_user_provider.dart';
import 'package:heyto/services/dynamic_link_service.dart';
import 'package:heyto/services/push_notification_service.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/utils/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app/config.dart';

import 'app/constants.dart';
import 'auth/dispache_screen.dart';
import 'auth/verify_phone_screen.dart';
import 'models/PaymentSourceModel.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
}
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (QuickHelp.isWebPlatform()) {
    setPathUrlStrategy();
    await Firebase.initializeApp(
      // Replace with actual values
      options: const FirebaseOptions(
          apiKey: "AIzaSyAeh8HZBZEBwFoCG9BYcJRuumLweTmTBaY",
          authDomain: "heytoliveapp.firebaseapp.com",
          projectId: "heytoliveapp",
          storageBucket: "heytoliveapp.appspot.com",
          messagingSenderId: "173456849188",
          appId: "1:173456849188:web:804c67b90a8d32d19d9bb1",
          measurementId: "G-6YDEYQSM18"
      ),
    );

    FacebookAuth.i.webInitialize(
      appId: Config.facebookAppId,
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );

  } else if(QuickHelp.isDesktop()) {
    await Firebase.initializeApp();

  } else if(QuickHelp.isMobile()) {

    await Firebase.initializeApp();
    MobileAds.instance.initialize();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //Show both overlays:
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]
  );

  Map<String, ParseObjectConstructor> subClassMap = <String, ParseObjectConstructor>{
    PictureModel.keyTableName: () => PictureModel(),
    EncountersModel.keyTableName: () => EncountersModel(),
    MessageListModel.keyTableName: () => MessageListModel(),
    MessageModel.keyTableName: () => MessageModel(),
    ReportModel.keyTableName: () => ReportModel(),
    HashTagModel.keyTableName: () => HashTagModel(),
    LiveStreamingModel.keyTableName: () => LiveStreamingModel(),
    PictureModel.keyTableName: () => PictureModel(),
    OrderMessagesModel.keyTableName: () => OrderMessagesModel(),
    CallsModel.keyTableName: () => CallsModel(),
    GiftsModel.keyTableName: () => GiftsModel(),
    PaymentsModel.keyTableName: () => PaymentsModel(),
    WithdrawModel.keyTableName: () => WithdrawModel(),
    PaymentSourceModel.keyTableName: () => PaymentSourceModel(),

  };

  await Parse().initialize(
    Config.appId, Config.serverUrl,
    clientKey: Config.clientKey,
    liveQueryUrl: Config.liveQueryUrl,
    autoSendSessionId: true,
    coreStore: QuickHelp.isWebPlatform() ? await CoreStoreSharedPrefsImp.getInstance() : await CoreStoreSembastImp.getInstance(password: Config.appId),
    debug: Setup.isDebug,
    appName: Setup.appName,
    appPackageName: Constants.appPackageName(),
    appVersion: Setup.appVersion,
    locale: await Devicelocale.currentLocale,
    parseUserConstructor: (username, password, email, {client, debug, sessionToken}) => UserModel(username, password, email),
    registeredSubClassMap: subClassMap,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CountersProvider()),
        ChangeNotifierProvider(create: (_) => UpdateUserProvider()),
        ChangeNotifierProvider(create: (_) => CallsProvider()),
      ],

      child: EasyLocalization(
        supportedLocales: Config.languages,
        path: 'assets/translations',
        fallbackLocale: Locale(Config.defaultLanguage),
        child: BaxPayApp(),
      ),
    ),
  );
}


class BaxPayApp extends StatefulWidget {
  @override
  _BaxPayAppState createState() => _BaxPayAppState();
}

class _BaxPayAppState extends State<BaxPayApp> {

  DynamicLinkService _dynamicLinkService = DynamicLinkService();

  @override
  void initState() {

    Future.delayed(Duration(seconds: 1), (){
      PushNotificationService().initialise();
    });

    if(!QuickHelp.isWebPlatform()){
      context.read<CallsProvider>().connectAgoraRtm();
    }


    Future.delayed(Duration(seconds: 2), () {
      _dynamicLinkService.listenDynamicLink(context);
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    return MaterialApp(
      title: Setup.appName,
      debugShowCheckedModeBanner: false,
      theme: lightThemeData(context),
      darkTheme: darkThemeData(context),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: WelcomeScreen.route,
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      routes: {
        //Before Login
        //WelcomeScreen.route: (_) => QuickHelp.checkRoute(context, WelcomeScreen(), authNeeded: false),
        SignUpAccountScreen.route: (_) => QuickHelp.checkRoute(context, SignUpAccountScreen(), authNeeded: false),
        PhoneLoginScreen.route: (_) => QuickHelp.checkRoute(context, PhoneLoginScreen(), authNeeded: false),
        LoginScreen.route: (_) => QuickHelp.checkRoute(context, LoginScreen(), authNeeded: false),
        ForgotScreen.route: (_) => QuickHelp.checkRoute(context, ForgotScreen(), authNeeded: false),
        VerifyPhoneScreen.route: (_) => QuickHelp.checkRoute(context, VerifyPhoneScreen(), authNeeded: false),

        // Logged user or not
        QuickHelp.pageTypeTerms: (_) => WebViewScreen(pageType: QuickHelp.pageTypeTerms),
        QuickHelp.pageTypePrivacy: (_) => WebViewScreen(pageType: QuickHelp.pageTypePrivacy),
        QuickHelp.pageTypeHelpCenter: (_) => WebViewScreen(pageType: QuickHelp.pageTypeHelpCenter),
        QuickHelp.pageTypeSafety: (_) => WebViewScreen(pageType: QuickHelp.pageTypeSafety),
        QuickHelp.pageTypeCommunity: (_) => WebViewScreen(pageType: QuickHelp.pageTypeCommunity),
        ImageCropScreen.route: (_) => ImageCropScreen(),
      },

      home: FutureBuilder<UserModel?>(
          future: QuickHelp.getUser(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return Scaffold(
                    body: QuickHelp.appLoadingLogo(),
                );
              default:
                if (snapshot.hasData) {
                  return DispatchScreen(currentUser: snapshot.data);
                } else {
                  return WelcomeScreen();
                }
            }
          }),
    );
  }
}
