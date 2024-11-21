import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:heyto/app/cloud_params.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/dispache_screen.dart';
import 'package:heyto/auth/welcome_screen.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/models/OrderMessagesModel.dart';
import 'package:heyto/models/ReportModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/mood_model.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/widgets/snackbar_pro/snack_bar_pro.dart';
import 'package:heyto/widgets/snackbar_pro/top_snack_bar.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/avd.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:heyto/app/config.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../app/constants.dart';
import '../ui/container_with_corner.dart';
import '../utils/datoo_exeption.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, kIsWeb;

typedef EmailSendingCallback = void Function(bool sent, ParseError? error);

class QuickHelp {

  static const String pageTypeTerms = "/terms";
  static const String pageTypePrivacy = "/privacy";
  static const String pageTypeHelpCenter = "/help";
  static const String pageTypeSafety = "/safety";
  static const String pageTypeCommunity = "/community";
  static const String pageTypeAppStore = "/appstore";
  static const String pageTypePlayStore = "/playStore";
  static const String pageTypeSupport = "/support";

  static String dateFormatTimeOnly = "HH:mm";
  static String dateFormatDmy = "dd/MM/yyyy";
  static String dateFormatFacebook = "MM/dd/yyyy";
  static String dateFormatDateOnly = "dd/MM/yy";

  static String emailTypeWelcome = "welcome_email";
  static String emailTypeVerificationCode = "verification_code_email";

  static const String pageTypeInstructions = "/instructions";
  static const String pageTypeCashOut = "/cashOut";

  static double earthMeanRadiusKm = 6371.0;
  static double earthMeanRadiusMile = 3958.8;

  // Online/offline track
  static int timeToSoon = 60 * 1000;
  static int timeToOffline = 2 * 60 * 1000;

  static String userStatusOnline = "online";
  static String userStatusRecentOnline = "recent";
  static String userStatusOffline = "offline";

  //static String emailTypePasswordReset = "password_reset_password";

  static final String admobRewardedVideoAdTest =
      "ca-app-pub-3940256099942544/5224354917";
  static final String admobBannerAdTest =
      "ca-app-pub-3940256099942544/6300978111";

  static Future<void> _launchInWebViewWithJavaScript(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrl(
        url,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static String getDiamondsLeftToRedeem(int diamonds) {
    if (diamonds >= Setup.diamondsNeededToRedeem) {
      return 0.toString();
    } else {
      return (Setup.diamondsNeededToRedeem - diamonds).toString();
    }
  }

  static Future<void> launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrl(
        url,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static AlertStyle _alertStyle() {
    return AlertStyle(
        backgroundColor: QuickHelp.isDarkModeNoContext()
            ? kContentColorLightTheme
            : kContentColorDarkTheme,
        descStyle: TextStyle(
            color:
                QuickHelp.isDarkModeNoContext() ? Colors.white : Colors.black),
        titleStyle: TextStyle(
            color:
                QuickHelp.isDarkModeNoContext() ? Colors.white : Colors.black));
  }

  static Color getColorStandard({bool? inverse}) {
    if (isDarkModeNoContext()) {
      if (inverse != null && inverse) {
        return kContentColorLightTheme;
      } else {
        return kContentColorDarkTheme;
      }
    } else {
      if (inverse != null && inverse) {
        return kContentColorDarkTheme;
      } else {
        return kContentColorLightTheme;
      }
    }
  }

  static String formatTime(int second) {
    var hour = (second / 3600).floor();
    var minutes = ((second - hour * 3600) / 60).floor();
    var seconds = (second - hour * 3600 - minutes * 60).floor();

    var secondExtraZero = (seconds < 10) ? "0" : "";
    var minuteExtraZero = (minutes < 10) ? "0" : "";
    var hourExtraZero = (hour < 10) ? "0" : "";

    if (hour > 0) {
      return "$hourExtraZero$hour:$minuteExtraZero$minutes:$secondExtraZero$seconds";
    } else {
      return "$minuteExtraZero$minutes:$secondExtraZero$seconds";
    }
  }

  static void showAppNotification(
      {required BuildContext context,
        String? title,
        bool isError = true}) {
    showTopSnackBar(
      context,
      isError
          ? SnackBarPro.error(
        title: title!,
      )
          : SnackBarPro.success(
        title: title!,
      ),
    );
  }

  static Color getColorSettingsBg() {
    if (isDarkModeNoContext()) {
      return kContentColorLightTheme;
    } else {
      return kSettingsBg;
    }
  }

  static String getMessageListTime(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    DateTime now = DateTime.now();
    int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (dateDiff == -1) {
      // Yesterday
      return "date_time.yesterday_".tr();
    } else if (dateDiff == 0) {
      // today
      return DateFormat(dateFormatTimeOnly).format(dateTime);
    } else if (diff.inDays > 0 && diff.inDays < 6) {
      // Day name
      return getDaysOfWeek(dateTime);
    } else {
      return DateFormat(dateFormatDateOnly).format(dateTime);
    }
  }

  static void showDialogLivEend(
      {required BuildContext context,
        String? message,
        String? title,
        required String? confirmButtonText,
        VoidCallback? onPressed,
        bool? dismiss = true}) {

    showDialog(
      barrierDismissible: dismiss!,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: const RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(10.0))),
          title: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: TextWithTap(
              title!,
              marginTop: 5,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ),
          content: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: TextWithTap(
              message!,
              textAlign: TextAlign.center,
              color: kSecondaryGrayColor,
            ),
          ),
          actions: [
            RoundedGradientButton(
              text: confirmButtonText!,
              //width: 150,
              height: 48,
              marginLeft: Responsive.isMobile(context) ? 30 : 2,
              marginRight: 30,
              marginBottom: 20,
              borderRadius: 60,
              width: Responsive.isMobile(context) ? null : 180,
              textColor: Colors.white,
              borderRadiusBottomLeft: 15,
              colors: const [kPrimaryColor, kSecondaryColor],
              marginTop: 0,
              fontSize: 15,
              onTap: () {
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }




  static Color getColorTextCustom1({bool? inverse}) {
    if (isDarkModeNoContext()) {
      if (inverse != null && inverse) {
        return kContentColorLightTheme;
      } else {
        return kContentColorDarkTheme;
      }
    } else {
      if (inverse != null && inverse) {
        return kContentColorDarkTheme;
      } else {
        return kContentColorLightTheme;
      }
    }
  }

  static Color getColorToolbarIcons() {
    if (isDarkModeNoContext()) {
      return kContentColorDarkTheme;
    } else {
      return kColorsGrey600;
    }
  }

  static String getDaysOfWeek(DateTime dateTime) {
    int day = dateTime.weekday;

    if (day == 1) {
      return "date_time.monday_".tr();
    } else if (day == 2) {
      return "date_time.tuesday_".tr();
    } else if (day == 3) {
      return "date_time.wednesday_".tr();
    } else if (day == 4) {
      return "date_time.thursday_".tr();
    } else if (day == 5) {
      return "date_time.friday_".tr();
    } else if (day == 6) {
      return "date_time.saturday_".tr();
    } else if (day == 7) {
      return "date_time.sunday_".tr();
    }

    return "";
  }

  static String getMessageTime(DateTime dateTime, {bool? time}) {
    if (time != null && time == true) {
      return DateFormat(dateFormatTimeOnly).format(dateTime);
    } else {
      Duration diff = DateTime.now().difference(dateTime);
      DateTime now = DateTime.now();
      int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

      if (dateDiff == -1) {
        // Yesterday
        return "date_time.yesterday_".tr();
      } else if (dateDiff == 0) {
        // today
        return "date_time.today_".tr();
      } else if (diff.inDays > 0 && diff.inDays < 6) {
        // Day name
        return getDaysOfWeek(dateTime);
      } else {
        return DateFormat().add_MMMEd().format(dateTime);
      }
    }
  }

  static String getMessageTimeGrouped(DateTime dateTime) {
    Duration diff = DateTime.now().difference(dateTime);
    DateTime now = DateTime.now();
    int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (dateDiff == -1) {
      // Yesterday
      return "date_time.yesterday_".tr();
    } else if (dateDiff == 0) {
      // today
      return "date_time.today_".tr();
    } else if (diff.inDays > 0 && diff.inDays < 6) {
      // Day name
      return getDaysOfWeek(dateTime);
    } else {
      return DateFormat().add_MMMEd().format(dateTime);
    }
  }

  static bool isDarkMode(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark;
  }

  static bool isDarkModeNoContext() {
    var brightness = SchedulerBinding.instance!.window.platformBrightness;
    return brightness == Brightness.dark;
  }

  static bool isWebPlatform() {
    return UniversalPlatform.isWeb;
  }

  static bool isIpad() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance!.window);

    return data.size.shortestSide < 600 ? false : true;
  }


  static bool isAndroidPlatform() {
    return UniversalPlatform.isAndroid;
  }

  static bool isFuchsiaPlatform() {
    return UniversalPlatform.isFuchsia;
  }

  static bool isIOSPlatform() {
    return UniversalPlatform.isIOS;
  }

  static bool isMacOsPlatform() {
    return UniversalPlatform.isMacOS;
  }

  static bool isLinuxPlatform() {
    return UniversalPlatform.isLinux;
  }

  static bool isWindowsPlatform() {
    return UniversalPlatform.isWindows;
  }

  // Get country code
  static String? getCountryIso() {
    final List<Locale> systemLocales = WidgetsBinding.instance!.window.locales;
    return systemLocales.first.countryCode;
  }

  static String? getCountryCodeFromLocal(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);

    return myLocale.countryCode;
  }

  // Save Installation
  static Future<void> initInstallation(UserModel? user, String? token) async {
    DateTime dateTime = DateTime.now();

    final ParseInstallation installation =
    await ParseInstallation.currentInstallation();

    if (token != null) {
      installation.set('deviceToken', token);
    } else {
      installation.unset('deviceToken');
    }

    installation.set('GCMSenderId', Config.pushGcm);
    installation.set('timeZone', dateTime.timeZoneName);
    installation.set('installationId', installation.installationId);

    if (kIsWeb) {
      installation.set('deviceType', 'web');
      installation.set('pushType', 'FCM');
    } else if (Platform.isAndroid) {
      installation.set('deviceType', 'android');
      installation.set('pushType', 'FCM');
    } else if (Platform.isIOS) {
      installation.set('deviceType', 'ios');
      installation.set('pushType', 'APN');
    }

    if (user != null) {
      user.set("installation", installation);
      installation.set('user', user);
      installation.subscribeToChannel('global');
    } else {
      installation.unset('user');
      installation.unsubscribeFromChannel('global');
    }
  }

  static setCurrentUser(UserModel? userModel, {StateSetter? setState}) async {
    UserModel userModel = await ParseUser.currentUser();

    if (setState != null) {
      setState(() {
        userModel = userModel;
      });
    } else {
      userModel = userModel;
    }
  }

  static Future<UserModel?>? getCurrentUser() async {
    UserModel? currentUser = await ParseUser.currentUser();
    return currentUser;
  }

  static Future<UserModel?> getCurrentUserModel(UserModel? userModel) async {
    UserModel currentUser = await ParseUser.currentUser();
    return currentUser;
  }

  static Future<UserModel> getUserModelResult(dynamic d) async {
    UserModel? user = await ParseUser.currentUser();
    user = UserModel.clone()..fromJson(d as Map<String, dynamic>);

    return user;
  }

  static Future<UserModel?> getUser() async {
    UserModel? currentUser = await ParseUser.currentUser();

    if (currentUser != null) {
      ParseResponse response = await currentUser.getUpdatedUser();
      if (response.success) {
        currentUser = response.result;
        return currentUser;
      } else if (response.error!.code == 100) {
        // Return stored user

        return currentUser;
      } else if (response.error!.code == 101) {
        // User deleted or doesn't exist.

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else if (response.error!.code == 209) {
        // Invalid session token

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else {
        // General error

        return currentUser;
      }
    } else {
      return null;
    }
  }

  // Check if email is valid
  static bool isValidEmail(String email) {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);
  }

  // Check if string has only number(s)
  static bool isNumeric(String string) {
    return double.tryParse(string) != null;
  }

  static bool isPasswordCompliant(String password, [int minLength = 6]) {
    bool hasUppercase = password.contains(new RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(new RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(new RegExp(r'[a-z]'));
    bool hasSpecialCharacters =
        password.contains(new RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length > minLength;

    return hasDigits &
        hasUppercase &
        hasLowercase &
        hasSpecialCharacters &
        hasMinLength;
  }

  static DateTime getDateFromString(String date, String format) {
    return new DateFormat(format).parse(date);
  }

  static Object getDateDynamic(String date) {
    DateFormat dateFormat = DateFormat(dateFormatDmy);
    DateTime dateTime = dateFormat.parse(date);

    return json.encode(dateTime, toEncodable: myEncode);
  }

  static dynamic myEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  static DateTime getDate(String date) {
    DateFormat dateFormat = DateFormat(dateFormatDmy);
    DateTime dateTime = dateFormat.parse(date);

    return dateTime;
  }

  static bool isValidDateBirth(String date, String format) {
    try {
      int day = 1, month = 1, year = 2000;

      //Get separator data  10/10/2020, 2020-10-10, 10.10.2020
      String separator = RegExp("([-/.])").firstMatch(date)!.group(0)![0];

      //Split by separator [mm, dd, yyyy]
      var frSplit = format.split(separator);
      //Split by separtor [10, 10, 2020]
      var dtSplit = date.split(separator);

      for (int i = 0; i < frSplit.length; i++) {
        var frm = frSplit[i].toLowerCase();
        var vl = dtSplit[i];

        if (frm == "dd")
          day = int.parse(vl);
        else if (frm == "mm")
          month = int.parse(vl);
        else if (frm == "yyyy") year = int.parse(vl);
      }

      //First date check
      //The dart does not throw an exception for invalid date.
      var now = DateTime.now();
      if (month > 12 ||
          month < 1 ||
          day < 1 ||
          day > daysInMonth(month, year) ||
          year < 1810 ||
          (year > now.year && day > now.day && month > now.month))
        throw Exception("Date birth invalid.");

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool minimumAgeAllowed(String birthDateString, String datePattern) {
    // Current time - at this moment
    DateTime today = DateTime.now();

    // Parsed date to check
    DateTime birthDate = DateFormat(datePattern).parse(birthDateString);

    // Date to check but moved 18 years ahead
    DateTime adultDate = DateTime(
      birthDate.year + Setup.minimumAgeToRegister,
      birthDate.month,
      birthDate.day,
    );

    return adultDate.isBefore(today);
  }

  static int daysInMonth(int month, int year) {
    int days = 28 +
        (month + (month / 8).floor()) % 2 +
        2 % month +
        2 * (1 / month).floor();
    return (isLeapYear(year) && month == 2) ? 29 : days;
  }

  static bool isLeapYear(int year) =>
      ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);

  static void showLoadingDialog(BuildContext context, {bool? isDismissible, bool? useLogo = false}) {
    showDialog(
        context: context,
        barrierDismissible: isDismissible != null ? isDismissible : false,
        builder: (BuildContext context) {
          return useLogo! ? appLoadingLogo() : appLoading();
        });
  }

  static void showLoadingDialogWithText(BuildContext context, {bool? isDismissible, bool? useLogo = false, required String description, Color? backgroundColor}) {
    showDialog(
        context: context,
        barrierDismissible: isDismissible != null ? isDismissible : false,
        builder: (BuildContext context) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: backgroundColor,
            body: Container(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    useLogo! ? appLoadingLogo() : appLoading(),
                    TextWithTap(description, marginTop: !useLogo ? 10 : 0, marginLeft: 10, marginRight: 10,),
                  ],
                ),
              ),
            ),
          );
        });
  }

  static void hideLoadingDialog(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result );
  }

  static _goToPage(BuildContext context, String route,
      {Object? arguments}) {
    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    });
  }

  static void goBackToPreviousPage(BuildContext context,
      {bool? useCustomAnimation,
      PageTransitionsBuilder? pageTransitionsBuilder, dynamic result}) {
    Navigator.of(context).pop(result);
  }

  static void showAlertError(
      {required BuildContext context, required String title, String? message}) {
    QuickHelp.showAppNotificationAdvanced(title: title, context: context, message: message);
  }

  static void showLogoutWarning(
      {required BuildContext context,
      required String title,
      String? message,
      UserModel? userModel}) async {
    Alert(
        context: context,
        style: _alertStyle(),
        image: const Icon(Icons.logout),
        type: AlertType.none,
        title: title,
        desc: message,
        buttons: [
          DialogButton(
            color: kPrimaryColor,
            child: Text(
              "no".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
            //width: 0,
            //height: 0,
          ),
          DialogButton(
            color: kPrimaryColor,
            child: Text(
              "yes".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              _logout(context, userModel);
            },
            //width: 0,
            //height: 0,
          )
        ]).show();
  }

  static _logout(BuildContext context, UserModel? userModel) async {
    Navigator.pop(context);
    QuickHelp.showLoadingDialog(context);

    ParseResponse response = await userModel!.logout(deleteLocalUserData: true);
    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      goToNavigatorScreen(context, const WelcomeScreen(), finish: true, route: WelcomeScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
      goToNavigatorScreen(context, const WelcomeScreen(), finish: true, route: WelcomeScreen.route);
    }
  }

  static void showDialogWithButton(
      {required BuildContext context,
      String? message,
      String? title,
      String? buttonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title!),
          content: Text(message!),
          actions: [
            new ElevatedButton(
              child: Text(buttonText!),
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void showDialogWithButtonCustom(
      {required BuildContext context,
      String? message,
      String? title,
      required String? cancelButtonText,
      required String? confirmButtonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          title: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: TextWithTap(
              title!,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
              width: Responsive.isMobile(context) ? null : 200,
              child: Text(message!)
          ),
          actions: [
            TextWithTap(
              cancelButtonText!,
              fontWeight: FontWeight.bold,
              marginRight: 10,
              marginLeft: 10,
              marginBottom: 10,
              onTap: () => Navigator.of(context).pop(),
            ),
            TextWithTap(
              confirmButtonText!,
              fontWeight: FontWeight.bold,
              marginRight: 10,
              marginLeft: 10,
              marginBottom: 10,
              onTap: () {
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
            /*new ElevatedButton(
              child: Text(cancelButtonText!),
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),*/
          ],
        );
      },
    );
  }

  static void showDialogHeyto(
      {required BuildContext context,
      String? message,
      String? title,
      String? svgAsset,
      bool? isRow = false,
      required String? cancelButtonText,
      required String? confirmButtonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: SvgPicture.asset(
                      svgAsset != null ? svgAsset : 'assets/svg/ic_icon.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
                TextWithTap(
                  title!,
                  marginTop: 28,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: TextWithTap(
              message!,
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            isRow! ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoundedGradientButton(
                        text: confirmButtonText!,
                        width: 150,
                        height: 48,
                        marginLeft: 30,
                        marginRight: 30,
                        marginBottom: 30,
                        borderRadius: 60,
                        textColor: Colors.white,
                        borderRadiusBottomLeft: 15,
                        colors: const [kPrimaryColor, kSecondaryColor],
                        marginTop: 0,
                        fontSize: 16,
                        onTap: () {
                          if (onPressed != null) {
                            onPressed();
                          }
                        },
                      ),
                      TextWithTap(
                        cancelButtonText!.toUpperCase(),
                        fontWeight: FontWeight.bold,
                        color: kPrimacyGrayColor,
                        marginRight: 10,
                        marginLeft: 10,
                        fontSize: 15,
                        marginBottom: 10,
                        textAlign: TextAlign.center,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                    children: [
                      RoundedGradientButton(
                        text: confirmButtonText!,
                        //width: 150,
                        height: 48,
                        marginLeft: 30,
                        marginRight: 30,
                        marginBottom: 30,
                        borderRadius: 60,
                        textColor: Colors.white,
                        borderRadiusBottomLeft: 15,
                        colors: const [kPrimaryColor, kSecondaryColor],
                        marginTop: 0,
                        fontSize: 16,
                        onTap: () {
                          if (onPressed != null) {
                            onPressed();
                          }
                        },
                      ),
                      TextWithTap(
                        cancelButtonText!.toUpperCase(),
                        fontWeight: FontWeight.bold,
                        color: kPrimacyGrayColor,
                        marginRight: 10,
                        marginLeft: 10,
                        fontSize: 15,
                        marginBottom: 10,
                        textAlign: TextAlign.center,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
          ],
        );
      },
    );
  }

  static void showDialogPermission(
      {required BuildContext context,
      String? message,
      String? title,
      required String? confirmButtonText,
      VoidCallback? onPressed, bool? dismissible = true}) {
    showDialog(
      barrierDismissible: dismissible!,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: false,
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: SizedBox(
            width: Responsive.isMobile(context) ? null : 200,
            child: TextWithTap(
              title!,
              marginTop: 5,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ),
          content: SizedBox(
            width: Responsive.isMobile(context) ? null : 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWithTap(
                  message!,
                  textAlign: TextAlign.center,
                  color: kSecondaryGrayColor,
                  marginBottom: 20,
                ),
                RoundedGradientButton(
                  text: confirmButtonText!,
                  //width: 150,
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 20,
                  borderRadius: 60,
                  textColor: Colors.white,
                  borderRadiusBottomLeft: 15,
                  colors: const [kPrimaryColor, kSecondaryColor],
                  marginTop: 0,
                  fontSize: 15,
                  onTap: () {
                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static bool isAccountDisabled(UserModel? user) {
    return user!.getActivationStatus == true;
  }

  static updateUserServer(
      {required String column,
      required dynamic value,
      required UserModel user}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.updateUserGlobalParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.columnGlobal: column,
      CloudParams.valueGlobal: value,
      CloudParams.userGlobal: user.getUsername!,
    };

    ParseResponse parseResponse = await function.execute(parameters: params);
    if (parseResponse.success) {
      UserModel.getUserResult(parseResponse.result);
    }
  }

  // Use this example
  /* Map<String, dynamic> paramsList = <String, dynamic>{
     CloudParams.userGlobal: user.getUsername!,
     UserModel.keyFirstName: "Maravilho",
     UserModel.keyLastName: "Singa",
     UserModel.keyAge: 26,
  }; */

  static updateUserServerList({required Map<String, dynamic> map}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.updateUserGlobalListParam);
    Map<String, dynamic> params = map;

    ParseResponse parseResponse = await function.execute(parameters: params);
    if (parseResponse.success) {
      UserModel.getUserResult(parseResponse.result);
    }
  }

  //final emailSendingCallback? _sendingCallback;

  static sendEmail(String accountNumber, String emailType,
      {EmailSendingCallback? sendingCallback}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.sendEmailParam);
    Map<String, String> params = <String, String>{
      CloudParams.userGlobal: accountNumber,
      CloudParams.emailType: emailType
    };
    ParseResponse result = await function.execute(parameters: params);

    if (result.success) {
      sendingCallback!(true, null);
    } else {
      sendingCallback!(false, result.error);
    }
  }

  static bool isMobile() {
    if (isWebPlatform()) {
      return false;
    } else if (isAndroidPlatform()) {
      return true;
    } else if (isIOSPlatform()) {
      return true;
    } else {
      return false;
    }
  }

  static bool isDesktop() {
    if (isMacOsPlatform()) {
      return true;
    } else if (isLinuxPlatform()) {
      return true;
    } else if (isWindowsPlatform()) {
      return true;
    } else {
      return false;
    }
  }

  static goToWebPage(BuildContext context, {required String pageType, required pageUrl}) {

    if(QuickHelp.isMobile() || QuickHelp.isDesktop()){
      _goToPage(context, pageType,);

    }  else {
      _launchInWebViewWithJavaScript(pageUrl);
    }
  }

  static void showErrorResult(BuildContext context, int error) {
    QuickHelp.hideLoadingDialog(context);

    if (error == DatooException.connectionFailed) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "error".tr(), message: "not_connected".tr());
    } else if (error == DatooException.otherCause) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "error".tr(), message: "not_connected".tr());
    } else if (error == DatooException.emailTaken) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "auth.email_taken".tr());
    } else if(error == DatooException.accountBlocked){
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(context: context, title: "error".tr(), message: "auth.account_blocked".tr());
    } else {
      // Invalid credentials
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "auth.invalid_credentials".tr());
    }
  }

  static areSocialLoginDisabled(SharedPreferences preferences){

    if(isIOSPlatform()){

      return !preferences.getBool(Constants.facebookLoginConfig)! &&
          !preferences.getBool(Constants.googleLoginConfig)! &&
          !preferences.getBool(Constants.appleLoginIosConfig)!;

    } else {

      return !preferences.getBool(Constants.facebookLoginConfig)! &&
          !preferences.getBool(Constants.googleLoginConfig)! &&
          !preferences.getBool(Constants.appleLoginConfig)!;
    }
  }

  static int generateUId() {
    math.Random rnd = new math.Random();
    return 1000000000 + rnd.nextInt(999999999);
  }

  static int generateShortUId() {
    math.Random rnd = new math.Random();
    return 1000 + rnd.nextInt(9999);
  }

  static Future<String> downloadFilePath(
      String url, String fileName, String dir) async {
    HttpClient httpClient = new HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url + '/' + fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else
        filePath = 'Error code: ' + response.statusCode.toString();
    } catch (ex) {
      filePath = 'Can not fetch url';
    }

    return filePath;
  }

  static Map<String, dynamic>? getInfoFromToken(String token) {
    // validate token

    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    // retrieve token payload
    final String payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    // convert to Map
    final payloadMap = json.decode(resp);
    if (payloadMap is! Map<String, dynamic>) {
      return null;
    }
    return payloadMap;
  }

  static Future<dynamic> downloadFile(String url, String filename) async {
    HttpClient httpClient = new HttpClient();

    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static setWebPageTitle(BuildContext context, String title) {
    SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
      label: '${Setup.appName} - $title',
      primaryColor: Theme.of(context).primaryColor.value,
    ));
  }

  static AvdPicture xmlVector(String assetName) {
    return AvdPicture.asset(assetName);
  }

  static List<MoodModel> getMoods() {
    MoodModel rc = new MoodModel();
    rc.setName("profile_tab.mood_rc".tr());
    rc.setCode("RC");

    MoodModel lmu = new MoodModel();
    lmu.setName("profile_tab.mood_lmu".tr());
    lmu.setCode("LMU");

    MoodModel hle = new MoodModel();
    hle.setName("profile_tab.mood_hle".tr());
    hle.setCode("HLE");

    MoodModel bmm = new MoodModel();
    bmm.setName("profile_tab.mood_bmm".tr());
    bmm.setCode("BMM");

    MoodModel cc = new MoodModel();
    cc.setName("profile_tab.mood_cc".tr());
    cc.setCode("CC");

    MoodModel rfd = new MoodModel();
    rfd.setName("profile_tab.mood_rfd".tr());
    rfd.setCode("RFD");

    MoodModel icud = new MoodModel();
    icud.setName("profile_tab.mood_icud".tr());
    icud.setCode("ICUD");

    MoodModel jpt = new MoodModel();
    jpt.setName("profile_tab.mood_jpt".tr());
    jpt.setCode("JPT");

    MoodModel mml = new MoodModel();
    mml.setName("profile_tab.mood_mml".tr());
    mml.setCode("MML");

    MoodModel sm = new MoodModel();
    sm.setName("profile_tab.mood_sm".tr());
    sm.setCode("SM");

    MoodModel none = new MoodModel();
    none.setName("profile_tab.mood_none".tr());
    none.setCode("");

    List<MoodModel> moodModelArrayList = [];

    moodModelArrayList.add(rc);
    moodModelArrayList.add(lmu);
    moodModelArrayList.add(hle);
    moodModelArrayList.add(bmm);
    moodModelArrayList.add(cc);
    moodModelArrayList.add(rfd);
    moodModelArrayList.add(icud);
    moodModelArrayList.add(jpt);
    moodModelArrayList.add(mml);
    moodModelArrayList.add(sm);
    moodModelArrayList.add(none);

    return moodModelArrayList;
  }

  static String getMoodName(MoodModel moodModel) {
    switch (moodModel.getCode()) {
      case "RC":
        return "profile_tab.mood_rc".tr();

      case "LMU":
        return "profile_tab.mood_lmu".tr();

      case "HLE":
        return "profile_tab.mood_hle".tr();

      case "BMM":
        return "profile_tab.mood_bmm".tr();

      case "CC":
        return "profile_tab.mood_cc".tr();

      case "RFD":
        return "profile_tab.mood_rfd".tr();

      case "ICUD":
        return "profile_tab.mood_icud".tr();

      case "JPT":
        return "profile_tab.mood_jpt".tr();

      case "MML":
        return "profile_tab.mood_mml".tr();

      case "SM":
        return "profile_tab.mood_sm".tr();

      default:
        return "profile_tab.mood_none".tr();
    }
  }

  static String getMoodNameByCode(String modeCode) {
    switch (modeCode) {
      case "RC":
        return "profile_tab.mood_rc".tr();

      case "LMU":
        return "profile_tab.mood_lmu".tr();

      case "HLE":
        return "profile_tab.mood_hle".tr();

      case "BMM":
        return "profile_tab.mood_bmm".tr();

      case "CC":
        return "profile_tab.mood_cc".tr();

      case "RFD":
        return "profile_tab.mood_rfd".tr();

      case "ICUD":
        return "profile_tab.mood_icud".tr();

      case "JPT":
        return "profile_tab.mood_jpt".tr();

      case "MML":
        return "profile_tab.mood_mml".tr();

      case "SM":
        return "profile_tab.mood_sm".tr();

      default:
        return "profile_tab.mood_none".tr();
    }
  }

  static void setRandomArray(List arrayList) {
    arrayList.shuffle();
  }

  static int getAgeFromDate(DateTime birthday) {
    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthday.year;

    int month1 = currentDate.month;
    int month2 = birthday.month;

    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthday.day;

      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  static int getAgeFromDateString(String birthDateString, String datePattern) {

    // Parsed date to check
    DateTime birthday = DateFormat(datePattern).parse(birthDateString);

    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthday.year;

    int month1 = currentDate.month;
    int month2 = birthday.month;

    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthday.day;

      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  static DateTime incrementDate(int days) {
    DateTime limitDate = DateTime.now();
    limitDate.add(Duration(days: days));

    return limitDate;
  }

  static String getStringFromDate(DateTime date) {
    return DateFormat(dateFormatDmy).format(date);
  }

  static String getBirthdayFromDate(DateTime date) {
    return DateFormat(dateFormatDmy).format(date.add(const Duration(days: 1)));
  }

  static String getDeviceOsName() {
    if (QuickHelp.isAndroidPlatform()) {
      return "Android";
    } else if (QuickHelp.isIOSPlatform()) {
      return "iOS";
    } else if (QuickHelp.isWebPlatform()) {
      return "Web";
    } else if (QuickHelp.isWindowsPlatform()) {
      return "Windows";
    } else if (QuickHelp.isLinuxPlatform()) {
      return "Linux";
    } else if (QuickHelp.isFuchsiaPlatform()) {
      return "Fuchsia";
    } else if (QuickHelp.isMacOsPlatform()) {
      return "MacOS";
    }

    return "";
  }

  static getGender(UserModel user) {
    if (user.getGender == UserModel.keyGenderMale) {
      return "auth.a_male".tr();
    } else {
      return "auth.a_female".tr();
    }
  }

  static String getHeight(int height) {
    if (height > 91) {
      return "$height cm";
    } else {
      return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getWhatWantList() {
    List<String> list = [
      UserModel.WHAT_I_WANT_JUST_TO_CHAT,
      UserModel.WHAT_I_WANT_SOMETHING_CASUAL,
      UserModel.WHAT_I_WANT_SOMETHING_SERIOUS,
      UserModel.WHAT_I_WANT_LET_SEE_WHAT_HAPPENS
    ];

    return list;
  }

  static String getWhatIWant(String code) {
    switch (code) {
      case UserModel.WHAT_I_WANT_JUST_TO_CHAT:
        return "edit_profile.what_just_chat".tr();

      case UserModel.WHAT_I_WANT_SOMETHING_CASUAL:
        return "edit_profile.what_casual".tr();

      case UserModel.WHAT_I_WANT_SOMETHING_SERIOUS:
        return "edit_profile.what_serious".tr();

      case UserModel.WHAT_I_WANT_LET_SEE_WHAT_HAPPENS:
        return "edit_profile.what_lets_see".tr();

      default:
        return "edit_profile.what_lets_see".tr();
    }
  }

  static List<String> getRelationShipList() {
    List<String> list = [
      UserModel.RELATIONSHIP_COMPLICATED,
      UserModel.RELATIONSHIP_SINGLE,
      UserModel.RELATIONSHIP_TAKEN,
      ""
    ];

    return list;
  }

  static String getRelationShip(String code) {
    switch (code) {
      case UserModel.RELATIONSHIP_COMPLICATED:
        return "edit_profile.rela_compli".tr();

      case UserModel.RELATIONSHIP_SINGLE:
        return "edit_profile.rela_single".tr();

      case UserModel.RELATIONSHIP_TAKEN:
        return "edit_profile.rela_taken".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getSexualityList() {
    List<String> list = [
      UserModel.SEXUALITY_STRAIGHT,
      UserModel.SEXUALITY_GAY,
      UserModel.SEXUALITY_LESBIAN,
      UserModel.SEXUALITY_BISEXUAL,

      UserModel.SEXUALITY_ASEXUAL,
      UserModel.SEXUALITY_DEMI_SEXUAL,
      UserModel.SEXUALITY_PAN_SEXUAL,
      UserModel.SEXUALITY_QUEER,

      UserModel.SEXUALITY_ASK_ME,
      //""
    ];

    return list;
  }

  static String getSexualityListWithName(UserModel userModel) {
    List<String> sexualList = [];

    for (String orientation in userModel.getSexualOrientations!) {
      sexualList.add(getSexuality(orientation));
    }

    return sexualList.join(', ');
  }

  static String getSexuality(String code) {
    switch (code) {
      case UserModel.SEXUALITY_STRAIGHT:
        return "edit_profile.sex_stra".tr();

      case UserModel.SEXUALITY_GAY:
        return "edit_profile.sex_gay".tr();

      case UserModel.SEXUALITY_BISEXUAL:
        return "edit_profile.sex_bi".tr();

      case UserModel.SEXUALITY_LESBIAN:
        return "edit_profile.sex_lesbian".tr();

      case UserModel.SEXUALITY_ASEXUAL:
        return "edit_profile.sex_asexual".tr();

      case UserModel.SEXUALITY_DEMI_SEXUAL:
        return "edit_profile.sex_demi_sexual".tr();

      case UserModel.SEXUALITY_PAN_SEXUAL:
        return "edit_profile.sex_pan_sexual".tr();

      case UserModel.SEXUALITY_QUEER:
        return "edit_profile.sex_queer".tr();

      case UserModel.SEXUALITY_ASK_ME:
        return "edit_profile.sex_ask".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getPassionsList() {
    List<String> list = [
      UserModel.PASSIONS_CYCLING,
      UserModel.PASSIONS_FOODIE,
      UserModel.PASSIONS_SPIRITUALITY,
      UserModel.PASSIONS_MOVIES,
      UserModel.PASSIONS_TECHNOLOGY,
      UserModel.PASSIONS_YOGA,
      UserModel.PASSIONS_GOG_LOVER,
      UserModel.PASSIONS_CROSSFIT,
      UserModel.PASSIONS_SWIMMING,
      UserModel.PASSIONS_BRUNCH,

      UserModel.PASSIONS_Picniking,
      UserModel.PASSIONS_Tattoos,
      UserModel.PASSIONS_Volunteering,
      UserModel.PASSIONS_Art,
      UserModel.PASSIONS_Activism,
      UserModel.PASSIONS_Vegetarian,
      UserModel.PASSIONS_Walking,

      UserModel.PASSIONS_Theater,
      UserModel.PASSIONS_Hiking,
      UserModel.PASSIONS_Blogging,
      UserModel.PASSIONS_Festivals,
      UserModel.PASSIONS_Dancing,
      UserModel.PASSIONS_Vlogging,
      UserModel.PASSIONS_Sushi,
      UserModel.PASSIONS_Craft_BEER,
      UserModel.PASSIONS_Soccer,
      UserModel.PASSIONS_Instagram,

      UserModel.PASSIONS_Baking,
      UserModel.PASSIONS_Snowboarding,
      UserModel.PASSIONS_Outdoors,
      UserModel.PASSIONS_Board,
      UserModel.PASSIONS_enviro,
      UserModel.PASSIONS_Surfing,
      UserModel.PASSIONS_Writer,
      UserModel.PASSIONS_Wine,
      UserModel.PASSIONS_Museum,
      UserModel.PASSIONS_Astrology,
      UserModel.PASSIONS_Sports,

      UserModel.PASSIONS_Tiktok,
      UserModel.PASSIONS_Diy,
      UserModel.PASSIONS_Disney,
      UserModel.PASSIONS_Apple,
      UserModel.PASSIONS_Plant,
      UserModel.PASSIONS_Karaoke,
      UserModel.PASSIONS_CAT_LOVER,
      UserModel.PASSIONS_Photography,
      UserModel.PASSIONS_Gamer,

      UserModel.PASSIONS_Trivia,
      UserModel.PASSIONS_Music,
      UserModel.PASSIONS_Travel,
      UserModel.PASSIONS_Coffee,
      UserModel.PASSIONS_Language,
      UserModel.PASSIONS_Designer,
      UserModel.PASSIONS_Tea,

      //""
    ];

    return list;
  }

  static String getPassions(String code) {
    switch (code) {
      case UserModel.PASSIONS_CYCLING:
        return "edit_profile.passions_cycling".tr();

      case UserModel.PASSIONS_FOODIE:
        return "edit_profile.passions_foodie".tr();

      case UserModel.PASSIONS_SPIRITUALITY:
        return "edit_profile.passions_spirituality".tr();

      case UserModel.PASSIONS_MOVIES:
        return "edit_profile.passions_movies".tr();

      case UserModel.PASSIONS_TECHNOLOGY:
        return "edit_profile.passions_technology".tr();

      case UserModel.PASSIONS_YOGA:
        return "edit_profile.passions_yoga".tr();

      case UserModel.PASSIONS_GOG_LOVER:
        return "edit_profile.passions_doglover".tr();

      case UserModel.PASSIONS_CROSSFIT:
        return "edit_profile.passions_crossfit".tr();

      case UserModel.PASSIONS_SWIMMING:
        return "edit_profile.passions_swimming".tr();

      case UserModel.PASSIONS_BRUNCH:
        return "edit_profile.passions_brunch".tr();

      case UserModel.PASSIONS_Picniking:
        return "edit_profile.passions_picniking".tr();

      case UserModel.PASSIONS_Tattoos:
        return "edit_profile.passions_tattoos".tr();

      case UserModel.PASSIONS_Volunteering:
        return "edit_profile.passions_volunteering".tr();

      case UserModel.PASSIONS_Art:
        return "edit_profile.passions_art".tr();

      case UserModel.PASSIONS_Activism:
        return "edit_profile.passions_activism".tr();

      case UserModel.PASSIONS_Vegetarian:
        return "edit_profile.passions_vegetarian".tr();

      case UserModel.PASSIONS_Walking:
        return "edit_profile.passions_walking".tr();

      case UserModel.PASSIONS_Theater:
        return "edit_profile.passions_theater".tr();

      case UserModel.PASSIONS_Hiking:
        return "edit_profile.passions_hiking".tr();

      case UserModel.PASSIONS_Blogging:
        return "edit_profile.passions_blogging".tr();

      case UserModel.PASSIONS_Festivals:
        return "edit_profile.passions_festivals".tr();

      case UserModel.PASSIONS_Dancing:
        return "edit_profile.passions_dancing".tr();

      case UserModel.PASSIONS_Vlogging:
        return "edit_profile.passions_vlogging".tr();

      case UserModel.PASSIONS_Sushi:
        return "edit_profile.passions_sushi".tr();

      case UserModel.PASSIONS_Craft_BEER:
        return "edit_profile.passions_craft_beer".tr();

      case UserModel.PASSIONS_Soccer:
        return "edit_profile.passions_soccer".tr();

      case UserModel.PASSIONS_Instagram:
        return "edit_profile.passions_instagram".tr();

      case UserModel.PASSIONS_Baking:
        return "edit_profile.passions_baking".tr();

      case UserModel.PASSIONS_Snowboarding:
        return "edit_profile.passions_snowboarding".tr();

      case UserModel.PASSIONS_Outdoors:
        return "edit_profile.passions_outdoors".tr();

      case UserModel.PASSIONS_Board:
        return "edit_profile.passions_board_games".tr();

      case UserModel.PASSIONS_enviro:
        return "edit_profile.passions_enviro".tr();

      case UserModel.PASSIONS_Surfing:
        return "edit_profile.passions_surfing".tr();

      case UserModel.PASSIONS_Writer:
        return "edit_profile.passions_writer".tr();

      case UserModel.PASSIONS_Wine:
        return "edit_profile.passions_wine".tr();

      case UserModel.PASSIONS_Museum:
        return "edit_profile.passions_museum".tr();

      case UserModel.PASSIONS_Astrology:
        return "edit_profile.passions_astrology".tr();

      case UserModel.PASSIONS_Sports:
        return "edit_profile.passions_sports".tr();

      case UserModel.PASSIONS_Tiktok:
        return "edit_profile.passions_tiktok".tr();

      case UserModel.PASSIONS_Diy:
        return "edit_profile.passions_diy".tr();

      case UserModel.PASSIONS_Disney:
        return "edit_profile.passions_disney".tr();

      case UserModel.PASSIONS_Apple:
        return "edit_profile.passions_apple".tr();

      case UserModel.PASSIONS_Plant:
        return "edit_profile.passions_plant-based".tr();

      case UserModel.PASSIONS_Karaoke:
        return "edit_profile.passions_karaoke".tr();

      case UserModel.PASSIONS_CAT_LOVER:
        return "edit_profile.passions_cat_lover".tr();

      case UserModel.PASSIONS_Photography:
        return "edit_profile.passions_photography".tr();

      case UserModel.PASSIONS_Gamer:
        return "edit_profile.passions_gamer".tr();

      case UserModel.PASSIONS_Trivia:
        return "edit_profile.passions_trivia".tr();

      case UserModel.PASSIONS_Music:
        return "edit_profile.passions_music".tr();

      case UserModel.PASSIONS_Travel:
        return "edit_profile.passions_travel".tr();

      case UserModel.PASSIONS_Coffee:
        return "edit_profile.passions_coffee".tr();

      case UserModel.PASSIONS_Language:
        return "edit_profile.passions_language_exchange".tr();

      case UserModel.PASSIONS_Designer:
        return "edit_profile.passions_designer".tr();

      case UserModel.PASSIONS_Tea:
        return "edit_profile.passions_tea".tr();

      default:
        //return "edit_profile.profile_no_answer".tr();
        return "";
    }
  }

  static String getPassionsListWithName(UserModel userModel) {
    List<String> passionsList = [];

    for (String orientation in userModel.getPassions!) {
      passionsList.add(getPassions(orientation));
    }

    return passionsList.join(', ');
  }

  static List<String> getBodyTypeList() {
    List<String> list = [
      UserModel.BODY_TYPE_ATHLETIC,
      UserModel.BODY_TYPE_AVERAGE,
      UserModel.BODY_TYPE_BIG_AND_BEAUTIFUL,
      UserModel.BODY_TYPE_FEW_EXTRA_POUNDS,
      UserModel.BODY_TYPE_MUSCULAR,
      UserModel.BODY_TYPE_SLIM,
      ""
    ];

    return list;
  }

  static String getBodyType(String code) {
    switch (code) {
      case UserModel.BODY_TYPE_ATHLETIC:
        return "edit_profile.body_athl".tr();

      case UserModel.BODY_TYPE_AVERAGE:
        return "edit_profile.body_average".tr();

      case UserModel.BODY_TYPE_BIG_AND_BEAUTIFUL:
        return "edit_profile.body_big".tr();

      case UserModel.BODY_TYPE_FEW_EXTRA_POUNDS:
        return "edit_profile.body_extra".tr();

      case UserModel.BODY_TYPE_MUSCULAR:
        return "edit_profile.body_musc".tr();

      case UserModel.BODY_TYPE_SLIM:
        return "edit_profile.body_slim".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getLivingList() {
    List<String> list = [
      UserModel.LIVING_BY_MYSELF,
      UserModel.LIVING_STUDENT_DORMITORY,
      UserModel.LIVING_WITH_PARENTS,
      UserModel.LIVING_WITH_ROOMMATES,
      ""
    ];

    return list;
  }

  static String getLiving(String code) {
    switch (code) {
      case UserModel.LIVING_BY_MYSELF:
        return "edit_profile.living_myself".tr();

      case UserModel.LIVING_STUDENT_DORMITORY:
        return "edit_profile.living_student".tr();

      case UserModel.LIVING_WITH_PARENTS:
        return "edit_profile.living_parents".tr();

      case UserModel.LIVING_WITH_PARTNER:
        return "edit_profile.living_partner".tr();

      case UserModel.LIVING_WITH_ROOMMATES:
        return "edit_profile.living_room".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getKidsList() {
    List<String> list = [
      UserModel.KIDS_ALREADY_HAVE,
      UserModel.KIDS_GROWN_UP,
      UserModel.KIDS_NO_NOVER,
      UserModel.KIDS_SOMEDAY,
      ""
    ];

    return list;
  }

  static String getKids(String code) {
    switch (code) {
      case UserModel.KIDS_ALREADY_HAVE:
        return "edit_profile.kids_already".tr();

      case UserModel.KIDS_GROWN_UP:
        return "edit_profile.kids_grown".tr();

      case UserModel.KIDS_NO_NOVER:
        return "edit_profile.kids_no_never".tr();

      case UserModel.KIDS_SOMEDAY:
        return "edit_profile.kids_someday".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static String getKidsProfile(String code) {
    switch (code) {
      case UserModel.KIDS_ALREADY_HAVE:
        return "edit_profile.kids_already_profile".tr();

      case UserModel.KIDS_GROWN_UP:
        return "edit_profile.kids_grown_profile".tr();

      case UserModel.KIDS_NO_NOVER:
        return "edit_profile.kids_no_never_profile".tr();

      case UserModel.KIDS_SOMEDAY:
        return "edit_profile.kids_someday".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getSmokingList() {
    List<String> list = [
      UserModel.SMOKING_I_DO_NOT_LIKE_IT,
      UserModel.SMOKING_I_HATE_SMOKING,
      UserModel.SMOKING_I_SMOKE_OCCASIONALLY,
      UserModel.SMOKING_IAM_A_HEAVY_SMOKER,
      UserModel.SMOKING_IAM_A_SOCIAL_SMOKER,
      ""
    ];

    return list;
  }

  static String getSmoking(String code) {
    switch (code) {
      case UserModel.SMOKING_I_DO_NOT_LIKE_IT:
        return "edit_profile.smoke_not_like".tr();

      case UserModel.SMOKING_I_HATE_SMOKING:
        return "edit_profile.smoke_hate".tr();

      case UserModel.SMOKING_I_SMOKE_OCCASIONALLY:
        return "edit_profile.smoke_occasionally".tr();

      case UserModel.SMOKING_IAM_A_HEAVY_SMOKER:
        return "edit_profile.smoke_heavy".tr();

      case UserModel.SMOKING_IAM_A_SOCIAL_SMOKER:
        return "edit_profile.smoke_social".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static String getReportMessage(String code) {
    switch (code) {
      case ReportModel.I_HAVE_NO_INTEREST_IN_THIS_PERSON:
        return "message_report.report_without_interest".tr();

      case ReportModel.FAKE_PROFILE_SPAN:
        return "message_report.report_fake_profile".tr();

      case ReportModel.INAPPROPRIATE_MESSAGE:
        return "message_report.report_inappropriate_message".tr();

      case ReportModel.INAPPROPRIATE_PROFILE_PICTURE:
        return "message_report.report_inappropriate_picture".tr();

      case ReportModel.INAPPROPRIATE_VIDEO_CALL:
        return "message_report.report_inappropriate_video".tr();

      case ReportModel.INAPPROPRIATE_BIOGRAPHY:
        return "message_report.report_inappropriate_biography".tr();

      case ReportModel.UNDERAGE_USER:
        return "message_report.report_underage".tr();

      case ReportModel.OFFLINE_BEHAVIOR:
        return "message_report.report_offline_behavior".tr();

      case ReportModel.SOMEONE_IS_IN_DANGER:
        return "message_report.report_some_in_danger".tr();


      default:
        return "";
    }
  }

  static goToNavigatorScreen(BuildContext context, Widget widget,
      {bool? finish = false, bool? back = true, required String route}) {
    if (finish == false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          //settings: RouteSettings(name: route),
          builder: (context) => widget,
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          //settings: RouteSettings(name: route),
          builder: (BuildContext context) => widget,
        ),
            (route) => back!, //if you want to disable back feature set to false
      );
    }
  }

  static Future<dynamic> goToNavigatorScreenForResult(BuildContext context, Widget widget, {required String route}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          //settings: RouteSettings(name: route),
          builder: (context) => widget),
    );

    return result;
  }

  static void showAppNotificationAdvanced(
      {required String title,
        required BuildContext context,
        Widget? avatar,
        String? message,
        bool? isError = true,
        VoidCallback? onTap,
        UserModel? user,
        String? avatarUrl}) {
    showTopSnackBar(
      context,
      SnackBarPro.custom(
        title: title,
        message: message,
        icon: user != null
            ? QuickActions.avatarWidget(
          user,
          imageUrl: avatarUrl,
          width: 60,
          height: 60,
        )
            : avatar,
        textStyleTitle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isError != null ? Colors.white : Colors.black,
        ),
        textStyleMessage: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 15,
          color: isError != null ? Colors.white : Colors.black,
        ),
        isError: isError,
      ),
      onTap: onTap,
      overlayState: null,
    );
  }

  static List<String> getReportCodeMessageList() {
    List<String> list = [
      ReportModel.I_HAVE_NO_INTEREST_IN_THIS_PERSON,
      ReportModel.FAKE_PROFILE_SPAN,
      ReportModel.INAPPROPRIATE_MESSAGE,
      ReportModel.INAPPROPRIATE_PROFILE_PICTURE,
      ReportModel.INAPPROPRIATE_VIDEO_CALL,
      ReportModel.INAPPROPRIATE_BIOGRAPHY,
      ReportModel.UNDERAGE_USER,
      ReportModel.OFFLINE_BEHAVIOR,
      ReportModel.SOMEONE_IS_IN_DANGER,
    ];

    return list;
  }

  static String getSmokingProfile(String code) {
    switch (code) {
      case UserModel.SMOKING_I_DO_NOT_LIKE_IT:
        return "edit_profile.smoke_not_like_profile".tr();

      case UserModel.SMOKING_I_HATE_SMOKING:
        return "edit_profile.smoke_hate_profile".tr();

      case UserModel.SMOKING_I_SMOKE_OCCASIONALLY:
        return "edit_profile.smoke_occasionally_profile".tr();

      case UserModel.SMOKING_IAM_A_HEAVY_SMOKER:
        return "edit_profile.smoke_heavy_profile".tr();

      case UserModel.SMOKING_IAM_A_SOCIAL_SMOKER:
        return "edit_profile.smoke_social_profile".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static List<String> getOrderCodeList() {
    List<String> list = [
      OrderMessagesModel.RECENT_FIRST,
      OrderMessagesModel.UNREAD_FIRST,
      OrderMessagesModel.ONLINE,
      OrderMessagesModel.FAVORITES,
    ];

    return list;
  }

  static String getOrderMessages(String code) {
    switch (code) {
      case OrderMessagesModel.RECENT_FIRST:
        return "order_by.recent_first".tr();

      case OrderMessagesModel.UNREAD_FIRST:
        return "order_by.unread_first".tr();

      case OrderMessagesModel.ONLINE:
        return "order_by.online".tr();

      case OrderMessagesModel.FAVORITES:
        return "order_by.favorites".tr();

      default:
        return "";
    }
  }

  static List<String> getDrinkingList() {
    List<String> list = [
      UserModel.DRINKING_I_DO_NOT_DRINK,
      UserModel.DRINKING_I_DRINK_A_LOT,
      UserModel.DRINKING_I_DRINK_SOCIALLY,
      UserModel.DRINKING_IAM_AGAINST_DRINKING,
      ""
    ];

    return list;
  }

  static String getDrinking(String code) {
    switch (code) {
      case UserModel.DRINKING_I_DO_NOT_DRINK:
        return "edit_profile.drink_do_not".tr();

      case UserModel.DRINKING_I_DRINK_A_LOT:
        return "edit_profile.drink_drink_lot".tr();

      case UserModel.DRINKING_I_DRINK_SOCIALLY:
        return "edit_profile.drink_socially".tr();

      case UserModel.DRINKING_IAM_AGAINST_DRINKING:
        return "edit_profile.drink_against".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static String getDrinkingProfile(String code) {
    switch (code) {
      case UserModel.DRINKING_I_DO_NOT_DRINK:
        return "edit_profile.drink_do_not_profile".tr();

      case UserModel.DRINKING_I_DRINK_A_LOT:
        return "edit_profile.drink_drink_lot_profile".tr();

      case UserModel.DRINKING_I_DRINK_SOCIALLY:
        return "edit_profile.drink_socially_profile".tr();

      case UserModel.DRINKING_IAM_AGAINST_DRINKING:
        return "edit_profile.drink_against_profile".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static Future<void> launchInWebViewWithJavaScript(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrl(
        url,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static List<String> getPhotosCounter(UserModel? user) {
    List<String> counter = [];

    if (user!.getAvatar1 != null) {
      counter.add(user.getAvatar1!.url!);
    }

    if (user.getAvatar2 != null) {
      counter.add(user.getAvatar2!.url!);
    }

    if (user.getAvatar3 != null) {
      counter.add(user.getAvatar3!.url!);
    }

    if (user.getAvatar4 != null) {
      counter.add(user.getAvatar4!.url!);
    }

    if (user.getAvatar5 != null) {
      counter.add(user.getAvatar5!.url!);
    }

    if (user.getAvatar6 != null) {
      counter.add(user.getAvatar6!.url!);
    }

    if (counter.length == 0) {
      counter.add(user.getAvatar!.url!);
    }

    return counter;
  }

  static double distanceInKilometersTo(
      ParseGeoPoint point1, ParseGeoPoint point2) {
    return _distanceInRadiansTo(point1, point2) * earthMeanRadiusKm;
  }

  static double distanceInMilesTo(ParseGeoPoint point1, ParseGeoPoint point2) {
    return _distanceInRadiansTo(point1, point2) * earthMeanRadiusMile;
  }

  static double _distanceInRadiansTo(
      ParseGeoPoint point1, ParseGeoPoint point2) {
    double d2r = math.pi / 180.0; // radian conversion factor
    double lat1rad = point1.latitude * d2r;
    double long1rad = point1.longitude * d2r;
    double lat2rad = point2.latitude * d2r;
    double long2rad = point2.longitude * d2r;
    double deltaLat = lat1rad - lat2rad;
    double deltaLong = long1rad - long2rad;
    double sinDeltaLatDiv2 = math.sin(deltaLat / 2);
    double sinDeltaLongDiv2 = math.sin(deltaLong / 2);
    // Square of half the straight line chord distance between both points.
    // [0.0, 1.0]
    double a = sinDeltaLatDiv2 * sinDeltaLatDiv2 +
        math.cos(lat1rad) *
            math.cos(lat2rad) *
            sinDeltaLongDiv2 *
            sinDeltaLongDiv2;
    a = math.min(1.0, a);
    return 2 * math.asin(math.sqrt(a));
  }

  static bool isUserOnline(UserModel user) {
    DateTime? dateTime;

    dateTime = user.updatedAt;

    /*if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }*/

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return false;
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return true;
    } else {
      // online
      return true;
    }
  }

  static DateTime getDateFromAge(int age) {
    var birthday = DateTime.now();

    int currentYear = birthday.year;
    int birthYear = currentYear - age;

    return new DateTime(birthYear, birthday.month, birthday.day);
  }

  static String isUserOnlineChat(UserModel user) {
    DateTime? dateTime;

    dateTime = user.updatedAt;

    /*if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }*/

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return "offline_".tr();
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return QuickHelp.timeAgoSinceDate(dateTime);
    } else {
      // online
      return "online_".tr();
    }
  }

  static String isUserOnlineStatus(UserModel user) {
    DateTime? dateTime;

    dateTime = user.updatedAt;
   /* if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }*/

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return userStatusOffline;
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return userStatusRecentOnline;
    } else {
      // online
      return userStatusOnline;
    }
  }

  static bool isUserOnlineStatusBool(UserModel user) {
    DateTime? dateTime;

    dateTime = user.updatedAt;
    /*if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }*/

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return false;
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return true;
    } else {
      // online
      return true;
    }
  }

  static DateTime getMinutesToOnline() {

    var nowTime = DateTime.now();
    return nowTime.subtract(const Duration(minutes: 5));
    //return DateTime(nowTime.year, nowTime.);
  }

  static String timeAgoSinceDate(DateTime dateTime,
      {bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(dateTime);

    if (difference.inDays > 8) {
      return DateFormat(dateFormatDateOnly).format(dateTime);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  static String getDurationInMinutes({Duration? duration}) {

    if(duration != null){
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

      if(duration.inHours > 0){
        return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      } else {
        return "$twoDigitMinutes:$twoDigitSeconds";
      }

    } else {
      return "00:00";
    }

  }

  static Future<bool> checkLocationPermission() async{
    PermissionStatus status = await Permission.location.status;

    if(status.isGranted){
      return Future<bool>.value(true);

    } else {
      return Future<bool>.value(false);
    }
  }

  static DateTime getUntilDateFromDays(int days){
    return DateTime.now().add(Duration(days: days));
  }

  static Widget appLoading({bool adaptive = false, double? width, double? height}) {

    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: adaptive ? const CircularProgressIndicator.adaptive() : const CircularProgressIndicator(), //SvgPicture.asset('assets/svg/ic_icon.svg', width: 50, height: 50,),
      ),
    );
  }

  static Widget appLoadingLogo() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Image.asset(
          'assets/images/ic_logo.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }

  static Widget checkRoute(BuildContext context, Widget widget, {bool authNeeded = true}) {

    return FutureBuilder<UserModel?>(
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
                return returnWidget(context, authNeeded, widget, userModel: snapshot.data);
              } else {
                return returnWidget(context, authNeeded, widget);
              }
          }
        });
  }

  static Widget returnWidget(BuildContext context, bool authNeeded, Widget widget, {UserModel? userModel}){

    if (authNeeded) {
      if (userModel != null) {
        return widget;
      } else {

        Future.delayed(const Duration(seconds: 1), () {
          QuickHelp.showAppNotificationAdvanced(context: context, title: "auth.login_needed".tr(), message: "auth.login_needed_explain".tr());
        });

        return const WelcomeScreen();
      }
    } else {

      if (userModel != null) {
        return DispatchScreen(currentUser: userModel);
      } else {
        return widget;
      }
    }
  }

  static Widget pictureStep(context, int numberOfPictures, int step) {
    return Container(
      margin: const EdgeInsets.only(
        top: 11,
        right: 11,
        left: 11,
        bottom: 11,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(numberOfPictures, (index) {
          return Expanded(
            child: ContainerCorner(
              borderRadius: 8,
              marginLeft: 5,
              marginRight: 5,
              height: 5,
              width:
              (MediaQuery.of(context).size.width / numberOfPictures - 20),
              color:
              index == step ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          );
        }),
      ),
    );
  }

  /*static double convertDiamondsToMoney(UserModel user){

    // 100 Diamonds == 1
    // 50% of 1$ == 0,5$;

    int diamonds = user.getDiamonds!;

    double totalMoney = (diamonds.toDouble() / 10000) * Setup.percentageOfWithdraw;

    return totalMoney;
  }*/

  static double convertDiamondsToMoney(int diamonds){
    double totalMoney = (diamonds.toDouble() / 10000) * Setup.withDrawPercent;
    return totalMoney;
  }

  static double convertMoneyToDiamonds(double amount){
    double diamonds = (amount.toDouble() * 10000) / Setup.withDrawPercent;
    return diamonds;
  }

  static int getDiamondsForReceiver(int diamonds){
    double finalDiamonds = (diamonds /100) * Setup.diamondsEarnPercent;
    return int.parse(finalDiamonds.toStringAsFixed(0));
  }

  static int getDiamondsForAgency(int diamonds){
    double finalDiamonds = (diamonds /100) * Setup.agencyPercent;
    return int.parse(finalDiamonds.toStringAsFixed(0));
  }

  static String getDeviceOsType() {
    if (QuickHelp.isAndroidPlatform()) {
      return "android";
    } else if (QuickHelp.isIOSPlatform()) {
      return "ios";
    } else if (QuickHelp.isWebPlatform()) {
      return "web";
    } else if (QuickHelp.isWindowsPlatform()) {
      return "windows";
    } else if (QuickHelp.isLinuxPlatform()) {
      return "linux";
    } else if (QuickHelp.isFuchsiaPlatform()) {
      return "fuchsia";
    } else if (QuickHelp.isMacOsPlatform()) {
      return "macos";
    }

    return "";
  }

  static bool isPremium(UserModel user){

    DateTime now = DateTime.now();

    if(user.getPremium != null){
      DateTime to = user.getPremium!;

      if(to.isAfter(now)){
        return true;
      }
    }

    return false;
  }

  static Future<ImageFile?> compressImage(ImageFile imageFile, {int quality = 40}) async {


    Configuration config = Configuration(
      outputType: ImageOutputType.jpg,
      // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
      useJpgPngNativeCompressor: QuickHelp.isMobile() ? true : false,
      // set quality between 0-100
      quality: quality,
    );

    final param = ImageFileConfiguration(input: imageFile, config: config);
    final output = await compressor.compress(param);

    return output;
  }
}
