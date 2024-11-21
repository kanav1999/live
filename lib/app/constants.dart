import 'dart:convert';

import 'package:heyto/app/config.dart';
import 'package:heyto/app/setup.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/quick_help.dart';

class Constants {

  static String facebookLoginConfig = "facebookLoginConfig";
  static String phoneLoginConfig = "phoneLoginEnabled";
  static String appleLoginConfig = "appleLoginEnabled";
  static String appleLoginIosConfig = "appleLoginEnabledForIOS";
  static String googleLoginConfig = "googleLoginEnabled";

  static String getAdmobRewardedVideoUnit() {
    if (Setup.isDebug) {
      return QuickHelp.admobRewardedVideoAdTest;
    } else {
      if (QuickHelp.isIOSPlatform()) {
        return Config.admobIOSRewardedVideoAd;
      } else {
        return Config.admobAndroidRewardedVideoAd;
      }
    }
  }

  static String getAdmobBannerUnit() {
    if (Setup.isDebug) {
      return QuickHelp.admobBannerAdTest;
    } else {
      if (QuickHelp.isIOSPlatform()) {
        return Config.admobIOSBannerAd;
      } else {
        return Config.admobAndroidBannerAd;
      }
    }
  }

  static String getGoogleApiKeyGeo() {
    if (QuickHelp.isIOSPlatform()) {
      return Config.googleIosApiKeyGeo;
    } else if (QuickHelp.isAndroidPlatform()) {
      return Config.googleAndroidApiKeyGeo;
    } else {
      return Config.googleWebApiKeyGeo;
    }
  }

  static String appPackageName() {
    if (QuickHelp.isIOSPlatform()) {
      return Config.packageNameiOS;
    } else if (QuickHelp.isAndroidPlatform()) {
      return Config.packageNameAndroid;
    } else {
      return Config.packageNameAndroid;
    }
  }

  static void QueryParseConfig(SharedPreferences prefs) async {
    final ParseConfig parseConfig = ParseConfig();

    final ParseResponse response = await parseConfig.getConfigs();
    if (response.success) {
      var config = getParseConfigResults(response.result);

      var facebookLogin = config[facebookLoginConfig];
      var phoneLogin = config[phoneLoginConfig];
      var appleLogin = config[appleLoginConfig];
      var appleIosLogin = config[appleLoginIosConfig];
      var googleLogin = config[googleLoginConfig];

      prefs.setBool(facebookLoginConfig, facebookLogin);
      prefs.setBool(phoneLoginConfig, phoneLogin);
      prefs.setBool(appleLoginConfig, appleLogin);
      prefs.setBool(appleLoginIosConfig, appleIosLogin);
      prefs.setBool(googleLoginConfig, googleLogin);
    } else {
      if (prefs.getBool(facebookLoginConfig) == null)
        prefs.setBool(facebookLoginConfig, Setup.isFacebookLoginEnabled);
      if (prefs.getBool(phoneLoginConfig) == null)
        prefs.setBool(phoneLoginConfig, Setup.isPhoneLoginEnabled);
      if (prefs.getBool(appleLoginConfig) == null)
        prefs.setBool(appleLoginConfig, Setup.isAppleLoginEnabled);
      if (prefs.getBool(appleLoginIosConfig) == null)
        prefs.setBool(appleLoginIosConfig, Setup.isAppleLoginEnabledForIOS);
      if (prefs.getBool(googleLoginConfig) == null)
        prefs.setBool(googleLoginConfig, Setup.isGoogleLoginEnabled);
    }
  }

  static Map getParseConfigResults(Map response) {
    var body = {};
    body.addAll(response);

    var config = {};
    //uncomment to add object before results
    config = body; // config["config"] = body;
    String result = json.encode(config);

    Map map = json.decode(result);
    return map;
  }
}
