import 'dart:ui';

class Config {

  static const String packageNameAndroid = "com.angopapo.heyto";
  static const String packageNameiOS = "com.angopapo.heyto";
  static const String iosAppStoreId = "1614015236";
  static const String appName = "Heyto";
  static const String appVersion = "1.1";
  static const String companyName = "Angopapo, Lda";
  static const String appOrCompanyUrl = "www.heyto.live";
  static const String mainAppWebsite = "https://heyto.live";
  static const String appInviteUrl = "https://invite.heyto.live";
  static const String initialCountry = 'US'; // United States

  static const String serverUrl = "https://server_enpoint_url";
  static const String liveQueryUrl = "wss://server_enpoint_url";
  static const String appId = "your_app_id_here";
  static const String clientKey = "your_client_key_here";

  static const String giphyApiKey = "your_giphy_api_key_here";

  static const String facebookAppId = "facebook_app_id";

  static const String appleLoginClientId = "apple_login_client_id";
  static const String appleAndroidLoginRedirectUrl = "apple_login_redirect_url";
  static const String appleWebLoginRedirectUrl = "apple_login_redirect_url_web";

  static const String pushGcm = "fcm_projectId";
  static const String googleIosApiKeyGeo = "google_places_api_key";
  static const String googleAndroidApiKeyGeo = "google_places_api_key";
  static const String googleWebApiKeyGeo = "google_places_api_key";
  static const String webPushCertificate = "push_certificate";

  static const String agoraAppId = "agora.io_api_id";

  // Languages
  static String defaultLanguage = "en"; // English is default language.
  static List<Locale> languages = [
    Locale(defaultLanguage),
    //Locale('pt'),
    //Locale('fr')
  ];

  // Web payment config
  static const String primaryCurrencyCode = "USD";
  static const String primaryCurrencySymbol = "\$";

  static const double credit100Amount = 0.99;
  static const double credit200Amount = 1.99;
  static const double credit500Amount = 4.99;
  static const double credit1000Amount = 9.99;
  static const double credit2000Amount = 19.99;
  static const double credit5000Amount = 49.99;
  static const double credit10000Amount = 99.99;
  static const double subs1MonthAmount = 14.99;
  static const double subs3MonthAmount = 39.99;

  // Dynamic link
  static const String inviteSuffix = "invitee";
  static const String uriPrefix = "https://heyto.page.link";
  static const String link = "https://heyto.page.link";

  // Android Admob ad
  static const String admobAndroidRewardedVideoAd = "ca-app-pub-1084112649181796/8947386305";
  static const String admobAndroidBannerAd = "ca-app-pub-1084112649181796/3692541266";

  // iOS Admob ad
  static const String admobIOSRewardedVideoAd = "ca-app-pub-1084112649181796/1804744529";
  static const String admobIOSBannerAd = "ca-app-pub-1084112649181796/7031669401";

  // Web links for help, privacy policy and terms of use.
  static const String helpCenterUrl = "https://heyto.live/help.html";
  static const String privacyPolicyUrl = "https://heyto.live/privacy.html";
  static const String termsOfUseUrl = "https://heyto.live/terms.html";
  static const String termsOfUseInAppUrl = "https://heyto.live/terms.html";
  static const String dataSafetyUrl = "https://heyto.live/safety.html";
  static const String dataCommunityUrl = "https://heyto.live/community.html";
  static const String appStoreUrl = "https://apps.apple.com/us/app/heyto-live/id1614015236";
  static const String playStoreUrl = "https://play.google.com/store/apps/details?id=com.angopapo.heyto";
  static const String angopapoSupportUrl = "https://www.angopapo.com/support";

  // Google Play and Apple Pay In-app Purchases IDs
  static const String credit100 = "heyto.100.credits";
  static const String credit200 = "heyto.200.credits";
  static const String credit500 = "heyto.500.credits";
  static const String credit1000 = "heyto.1000.credits";
  static const String credit2000 = "heyto.2000.credits";
  static const String credit5000 = "heyto.5000.credits";
  static const String credit10000 = "heyto.10000.credits";

  //Google Play In-app Subscription IDs
  static const String subs1Month = "heyto.1.month";
  static const String subs3Months = "heyto.3.month";
}