import 'package:heyto/app/config.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:easy_localization/easy_localization.dart';

class Setup {

  static const bool isDebug = kDebugMode;

  static String appName = Config.appName;
  static String appVersion = Config.appVersion;
  static final String dataBaseName = '/${Config.appName.replaceAll(" ", "")}';
  static String bio = "welcome_bio".tr(namedArgs: {"app_name" : appName});
  static final List<String> allowedCountries = []; // ['FR', 'CA', 'US', 'AO', 'BR', 'IR'];
  static const int verificationCodeDigits = 6;

  static const int photoSliderDuration = 6;
  static const int photoNeededToRegister = 1;
  static const bool useWatermarkInPhotos = false;

  // Social login if config not available from cache or connection problem
  static const bool isFacebookLoginEnabled = false;
  static const bool isPhoneLoginEnabled = true;
  static const bool isGoogleLoginEnabled = false;
  static const bool isAppleLoginEnabled = false;
  static const bool isAppleLoginEnabledForIOS = false;

  // Additional Payments method, Google Play and Apple Pay are enabled by default
  static const bool isStripePaymentsEnabled = true;
  static const bool isPayPalPaymentsEnabled = true;
  static final bool isPaymentsDisabledOnWeb = QuickHelp.isWebPlatform();

  // User fields
  static const int welcomeCredit = 10;
  static const int minimumAgeToRegister = 16;
  static const int maximumAgeToRegister = 80;
  static const int minDistanceBetweenUsers = 1;
  static const int maxDistanceBetweenUsers = 100;
  static const int maxUsersNearToShow = 50;

  static const int freeTicketsToInvite = 20;

  // Enable or Disable Ads and Premium.
  static const bool isPaidMessagesActivated = true;
  static const bool isCrushAdsEnabled = true;
  static const bool isAdsActivated = true;
  static const bool isPremiumEnabled = true;
  static const bool isNearByNativeAdsActivated = true;
  static const bool isEncountersNativeAdsActivated = false;
  static const bool isOpenAppAdsActivated = true;
  static const int ticketsAddedOnRewardedVideo = 5;

  //Giphy gifs parameters
  static const int gifLimit = 20;

  //Calls
  static const int callWaitingDuration = 30; // seconds
  static const int coinsNeededForVideoCallPerMinute = 120; //Coins per minute needed to make video call
  static const int coinsNeededForVoiceCallPerMinute = 60;  //Coins per minute needed to make Voice call

  static const String withdrawCurrent = "\$";  //Withdraw current
  static const int percentageOfWithdraw = 50;  //How many percent user get

  //Withdraw calculations
  static const int diamondsEarnPercent = 69; //Percent to give the streamer.
  static const int withDrawPercent = 50; //Percent to give the streamer.
  static const int agencyPercent = 10; //Percent to give the agency.
  static const int diamondsNeededToRedeem = 5000; // Minimum diamonds needed to redeem

}