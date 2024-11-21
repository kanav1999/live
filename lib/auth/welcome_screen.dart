import 'package:heyto/app/config.dart';
import 'package:heyto/app/constants.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/social_login.dart';
import 'package:heyto/auth/verify_phone_screen.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/button_with_svg.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/quick_cloud.dart';
import '../utils/shared_manager.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  static const String route = '/';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late SharedPreferences preferences;

  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<void> googleLogin() async {
    QuickHelp.showLoadingDialog(context);

    try {
      GoogleSignInAccount? account = await _googleSignIn.signIn();
      GoogleSignInAuthentication authentication = await account!.authentication;

      final ParseResponse response = await ParseUser.loginWith(
          'google',
          google(authentication.accessToken!, _googleSignIn.currentUser!.id,
              authentication.idToken!));
      if (response.success) {
        UserModel? user = await ParseUser.currentUser();

        if (user != null) {
          if (user.getUid == null) {
            if (SharedManager().getInvitee(preferences)!.isNotEmpty) {
              await QuickCloudCode.sendTicketsToInvitee(
                  authorId: user.objectId!,
                  receivedId: SharedManager().getInvitee(preferences)!);
              SharedManager().clearInvitee(preferences);
            }

            getGoogleUserDetails(user, account, authentication.idToken!);
          } else {
            SocialLogin.goHome(context, user);
          }
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showAppNotificationAdvanced(
              context: context,
              title: "error".tr(),
              message: "auth.gg_login_error".tr());
        }
      } else {
        print(response.error!.message);

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: response.error!.message);
      }
    } catch (error) {
      QuickHelp.hideLoadingDialog(context);

      if (error == GoogleSignIn.kSignInCanceledError) {
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "auth.gg_login_cancelled".tr(),
          message: "auth.gg_login_canceled_message".tr(),
        );
      } else if (error == GoogleSignIn.kNetworkError) {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "not_connected".tr(),
            message: "auth.gg_login_error".tr());
      } else {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.gg_login_error".tr());
      }
    }
  }

  void getGoogleUserDetails(
      UserModel user, GoogleSignInAccount googleUser, String idToken) async {
    Map<String, dynamic>? idMap = QuickHelp.getInfoFromToken(idToken);

    String firstName = idMap!["given_name"];
    String lastName = idMap["family_name"];

    String username =
        lastName.replaceAll(" ", "") + firstName.replaceAll(" ", "");

    user.setFullName = googleUser.displayName!;
    user.setGoogleId = googleUser.id;
    user.setFirstName = firstName;
    user.setLastName = lastName;
    user.username =
        username.toLowerCase().trim() + QuickHelp.generateShortUId().toString();
    user.setEmail = googleUser.email;
    user.setEmailPublic = googleUser.email;
    user.setPopularity = 0;
    user.setUserRole = UserModel.roleUser;
    user.setPrefMinAge = Setup.minimumAgeToRegister;
    user.setPrefMaxAge = Setup.maximumAgeToRegister;
    user.setLocationTypeNearBy = true;
    user.addCredit = Setup.welcomeCredit;
    user.setBio = Setup.bio;
    user.setHasPassword = false;
    ParseResponse response = await user.save();

    if (response.success) {
      SocialLogin.getPhotoFromUrl(context, user, googleUser.photoUrl!);
    } else {
      QuickHelp.showErrorResult(context, response.error!.code);
    }
  }

  @override
  void initState() {
    initSharedPref();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.welcome_title".tr());

    return QuickHelp.isWebPlatform() ? webWelcomePage() : welcomePage();
  }

  Widget webWelcomePage() {
    if (Responsive.isMobile(context) || Responsive.isTablet(context)) {
      return welcomePage();
    } else {
      var size = MediaQuery.of(context).size;
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          backgroundColor: kTransparentColor,
          leadingWidth: 400,
          title: ContainerCorner(
            marginTop: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: Responsive.isTablet(context) ? 10 : 70,
                      top: Responsive.isMobile(context) ? 0 : 20,
                      bottom: 5),
                  child: Image.asset(
                    "assets/images/ic_logo_white.png",
                    height: Responsive.isMobile(context) ? 100 : 150,
                    width: Responsive.isMobile(context) ? 100 : 150,
                  ),
                ),
                if (!Responsive.isTablet(context) &&
                    !Responsive.isMobile(context))
                  TextWithTap(
                    "auth.meet_new".tr(),
                    marginRight: 10,
                    marginTop: 10,
                    marginLeft: 10,
                    fontWeight: FontWeight.w600,
                  ),
                if (!Responsive.isTablet(context) &&
                    !Responsive.isMobile(context))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      "assets/svg/ic_like_swip.svg",
                      color: Colors.red,
                      height: 17,
                      width: 17,
                    ),
                  )
              ],
            ),
          ),
          actions: [
            ContainerCorner(
              shadowColor: kPrimaryGhostColor,
              borderRadius: 50,
              shadowColorOpacity: 0.3,
              width: Responsive.isMobile(context) ? 150 : 200,
              height: 40,
              marginRight: Responsive.isMobile(context) ? 5 : 30,
              marginTop: 30,
              marginBottom: 30,
              color: Colors.white,
              child: TextButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: QuickHelp.isDarkMode(context)
                                ? kContentColorLightTheme
                                : Colors.white,
                            content: logInAndRegister(),
                          );
                        });
                  },
                  child: TextWithTap(
                    "get_started".tr(),
                    color: kPrimaryColor,
                    fontSize: Responsive.isMobile(context) ? 12 : 18,
                  )),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ContainerCorner(
                width: size.width,
                height: size.height,
                colors: [kPrimaryColor, kSecondaryColor],
                child: Responsive.isTablet(context)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: rightSide(),
                          ),
                          leftSide(),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(flex: 2, child: leftSide()),
                          Flexible(flex: 2, child: rightSide())
                        ],
                      ),
              ),
            ),
            ContainerCorner(
              height: 60,
              width: size.width,
              color: Colors.white.withOpacity(0.2),
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 4.0,
                children: [
                  TextButton(
                      onPressed: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypePrivacy,
                          pageUrl: Config.privacyPolicyUrl),
                      child: TextWithTap(
                        "auth.privacy_policy".tr(),
                        fontSize: Responsive.isMobile(context) ? 10 : 14,
                      )),
                  TextButton(
                      onPressed: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypeTerms,
                          pageUrl: Config.termsOfUseUrl),
                      child: TextWithTap(
                        "auth.terms_of_use".tr(),
                        fontSize: Responsive.isMobile(context) ? 10 : 14,
                      )),
                  TextButton(
                      onPressed: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypeSupport,
                          pageUrl: Config.angopapoSupportUrl),
                      child: TextWithTap(
                        "contact_".tr(),
                        fontSize: Responsive.isMobile(context) ? 10 : 14,
                      )),
                  TextButton(
                      onPressed: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypeHelpCenter,
                          pageUrl: Config.helpCenterUrl),
                      child: TextWithTap(
                        "page_title.help_center_title".tr(),
                        fontSize: Responsive.isMobile(context) ? 10 : 14,
                      ))
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget leftSide() {
    var size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: Responsive.isMobile(context)
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        ContainerCorner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWithTap(
                "auth.why_this_app".tr(namedArgs: {"app_name": Config.appName}),
                fontWeight: FontWeight.w900,
                fontSize: Responsive.isMobile(context) ? 20 : 40,
                color: Colors.white,
                marginBottom: Responsive.isMobile(context) ? 20 : 20,
              ),
              TextWithTap(
                "auth.why_this_app_explain"
                    .tr(namedArgs: {"app_name": Config.appName}),
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => QuickHelp.goToWebPage(context,
                        pageType: QuickHelp.pageTypeAppStore,
                        pageUrl: Config.appStoreUrl),
                    child: ContainerCorner(
                      shadowColor: kPrimaryGhostColor,
                      color: kPrimaryColor,
                      borderRadius: 50,
                      shadowColorOpacity: 0.3,
                      marginTop: Responsive.isMobile(context) ? 20 : 50,
                      height: Responsive.isMobile(context) ? 47 : 57,
                      width: Responsive.isMobile(context) ? 140 : 170,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                left: Responsive.isMobile(context) ? 7 : 10),
                            child: SvgPicture.asset(
                              "assets/svg/ic_apple_logo.svg",
                              color: Colors.white,
                              height: Responsive.isMobile(context) ? 30 : 41,
                              width: Responsive.isMobile(context) ? 30 : 41,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWithTap(
                                "auth.ios_version".tr(),
                                color: Colors.white,
                                fontSize: 12,
                                marginRight: 10,
                              ),
                              TextWithTap(
                                "auth.app_store".tr(),
                                color: Colors.white,
                                fontSize:
                                    Responsive.isMobile(context) ? 16 : 19,
                                fontWeight: FontWeight.w700,
                                marginRight: 10,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypePlayStore,
                          pageUrl: Config.playStoreUrl),
                      child: ContainerCorner(
                        borderRadius: 50,
                        shadowColor: kPrimaryGhostColor,
                        shadowColorOpacity: 0.3,
                        color: kPrimaryColor,
                        marginTop: Responsive.isMobile(context) ? 20 : 50,
                        height: Responsive.isMobile(context) ? 47 : 57,
                        width: Responsive.isMobile(context) ? 170 : 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                  left: Responsive.isMobile(context) ? 10 : 20),
                              child: SvgPicture.asset(
                                "assets/svg/google-play.svg",
                                color: Colors.white,
                                height: Responsive.isMobile(context) ? 30 : 41,
                                width: Responsive.isMobile(context) ? 30 : 41,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextWithTap(
                                  "auth.android_version".tr(),
                                  color: Colors.white,
                                  fontSize: 12,
                                  marginRight: 10,
                                ),
                                TextWithTap(
                                  "auth.google_play".tr(),
                                  color: Colors.white,
                                  fontSize:
                                      Responsive.isMobile(context) ? 16 : 19,
                                  fontWeight: FontWeight.w700,
                                  marginRight: 10,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          marginLeft: size.width <= Responsive.MAX_TABLET_WIDTH ? 10 : 70,
          width: 400,
        ),
      ],
    );
  }

  Widget rightSide() {
    var size = MediaQuery.of(context).size;
    return ContainerCorner(
      height: size.width <= Responsive.MAX_TABLET_WIDTH ? 300 : 600,
      width: size.width <= Responsive.MAX_TABLET_WIDTH ? 300 : 600,
      marginRight: Responsive.isMobile(
        context,
      )
          ? 15
          : 50,
      child: Image.asset("assets/images/heyto_leanding.png"),
    );
  }

  Widget welcomePage() {
    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kWelcomeColorUp, kWelcomeColorDown])),
          child: Scaffold(
            backgroundColor: QuickHelp.isDarkModeNoContext()
                ? kContentColorLightTheme
                : Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ContainerCorner(
                    marginTop: 10,
                    child: Image.asset(
                      "assets/images/ic_logo_white.png",
                      height: 40,
                    ),
                  ),
                  ContainerCorner(
                      marginTop: 10,
                      height: Responsive.isMobile(context) ? 250 : 380,
                      width: Responsive.isMobile(context) ? 250 : 380,
                      child: Image.asset("assets/images/heyto_leanding.png")
                  ),
                  if(QuickHelp.isWebPlatform())
                    Container(
                      margin: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => QuickHelp.goToWebPage(context,
                                pageType: QuickHelp.pageTypePlayStore,
                                pageUrl: Config.playStoreUrl),
                            child: ContainerCorner(
                              borderRadius: 50,
                              shadowColor: kPrimaryGhostColor,
                              shadowColorOpacity: 0.2,
                              setShadowToBottom: true,
                              color: kPrimaryColor,
                              marginTop: 20,
                              height: 55,
                              width: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 15),
                                    child: SvgPicture.asset(
                                      "assets/svg/google-play.svg",
                                      color: Colors.white,
                                      height:30,
                                      width: 30,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextWithTap(
                                        "auth.android_version".tr(),
                                        color: Colors.white,
                                        fontSize: 12,
                                        marginRight: 10,
                                      ),
                                      TextWithTap(
                                        "auth.google_play".tr(),
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        marginRight: 10,
                                      ),
                                    ],
                                  ),
                                  Container(),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => QuickHelp.goToWebPage(context,
                                pageType: QuickHelp.pageTypeAppStore,
                                pageUrl: Config.appStoreUrl),
                            child: ContainerCorner(
                              shadowColor: kPrimaryGhostColor,
                              setShadowToBottom: true,
                              color: kPrimaryColor,
                              borderRadius: 50,
                              shadowColorOpacity: 0.2,
                              marginTop: 20,
                              height: 55,
                              width: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: 15),
                                    child: SvgPicture.asset(
                                      "assets/svg/ic_apple_logo.svg",
                                      color: Colors.white,
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextWithTap(
                                        "auth.ios_version".tr(),
                                        color: Colors.white,
                                        fontSize: 12,
                                        marginRight: 10,
                                      ),
                                      TextWithTap(
                                        "auth.app_store".tr(),
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        marginRight: 10,
                                      ),
                                    ],
                                  ),
                                  Container(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ButtonWithSvg(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    height: 48,
                    marginLeft: 30,
                    marginRight: 30,
                    borderRadius: 60,
                    svgHeight: 25,
                    svgWidth: 25,
                    fontSize: 16,
                    svgName: "ic_add_rounded_primary",
                    color: Colors.white,
                    textColor: Colors.black,
                    text: "auth.get_started".tr(),
                    fontWeight: FontWeight.normal,
                    matchParent: true,
                    press: () {
                      if(QuickHelp.areSocialLoginDisabled(preferences)){

                        QuickHelp.goToNavigatorScreen(context, VerifyPhoneScreen(),
                            route: VerifyPhoneScreen.route);
                      } else {
                        showMobileModal();
                      }
                    },
                  ),
                  termsAndPrivacyMobile(color: Colors.white),
                ],
              ),
            ),
          ),
        ));
  }

  void showMobileModal() async {
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

  Widget _showReportBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    //color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(25.0),
                      topRight: const Radius.circular(25.0),
                    ),
                  ),
                  child: ContainerCorner(
                    radiusTopRight: 25.0,
                    radiusTopLeft: 25.0,
                    color: QuickHelp.isDarkMode(context)
                        ? kContentColorLightTheme.withOpacity(0.7)
                        : Colors.white.withOpacity(0.1),
                    child: Center(child: showMobileLogin()),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget showMobileLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Visibility(
          visible: preferences.getBool(Constants.googleLoginConfig)!,
          child: ButtonWithSvg(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            height: 48,
            marginLeft: 30,
            marginRight: 30,
            marginBottom: 10,
            borderRadius: 60,
            svgHeight: 25,
            svgWidth: 25,
            fontSize: 16,
            svgName: "ic_google_login",
            color: Colors.white,
            textColor: Colors.black,
            //svgColor: Colors.white,
            text: "auth.google_login".tr(),
            fontWeight: FontWeight.normal,
            matchParent: true,
            press: () {
              googleLogin();
            },
          ),
        ),
        appleOrFbLogin(),
        Visibility(
          visible: preferences.getBool(Constants.appleLoginConfig)!,
          child: ButtonWithSvg(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            height: 48,
            marginLeft: 30,
            marginRight: 30,
            marginBottom: 10,
            borderRadius: 60,
            svgHeight: 25,
            svgWidth: 25,
            fontSize: 16,
            svgName: "ic_apple_logo",
            color: Colors.white,
            textColor: Colors.black,
            //svgColor: Colors.white,
            text: "auth.apple_login".tr(),
            fontWeight: FontWeight.normal,
            matchParent: true,
            press: () {
              SocialLogin.loginApple(context, preferences);
            },
          ),
        ),
        Visibility(
          visible: preferences.getBool(Constants.phoneLoginConfig)!,
          child: ButtonWithSvg(
            height: 48,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            marginLeft: 30,
            marginRight: 30,
            marginBottom: 20,
            borderRadius: 60,
            svgHeight: 25,
            svgWidth: 25,
            fontSize: 16,
            svgName: "ic_sms_login",
            color: Colors.white,
            textColor: Colors.black,
            //svgColor: Colors.white,
            text: "auth.phone_login".tr(),
            fontWeight: FontWeight.normal,
            matchParent: true,
            press: () {
              QuickHelp.goToNavigatorScreen(context, VerifyPhoneScreen(),
                  route: VerifyPhoneScreen.route);
            },
          ),
        ),
      ],
    );
  }

  Widget logInAndRegister() {
    return SafeArea(
      child: ContainerCorner(
        height: 500,
        marginTop: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/ic_logo.png",
                    height: 60,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Visibility(
                    visible: preferences.getBool(Constants.googleLoginConfig)!,
                    child: ButtonWithSvg(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      height: 48,
                      marginLeft: 5,
                      marginRight: 5,
                      marginBottom: 10,
                      borderRadius: 60,
                      matchParent: true,
                      svgHeight: 25,
                      svgWidth: 25,
                      fontSize: 16,
                      //fontSize: Responsive.isMobile(context) ? 10 : 14,
                      svgName: "ic_google_login",
                      color: Colors.white,
                      textColor: Colors.black,
                      //svgColor: Colors.white,
                      text: "auth.google_login".tr(),
                      fontWeight: FontWeight.normal,
                      press: () {
                        googleLogin();
                      },
                    ),
                  ),
                  Visibility(
                    visible: preferences.getBool(Constants.facebookLoginConfig)!,
                    child: ButtonWithSvg(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      height: 48,
                      marginLeft: 5,
                      marginRight: 5,
                      marginBottom: 10,
                      borderRadius: 60,
                      matchParent: true,
                      svgHeight: 25,
                      svgWidth: 25,
                      fontSize: 16,
                      svgName: "ic_facebook_login",
                      color: Colors.white,
                      textColor: Colors.black,
                      text: "auth.facebook_login".tr(),
                      fontWeight: FontWeight.normal,
                      press: () {
                        SocialLogin.loginFacebook(context, preferences);
                      },
                    ),
                  ),
                  Visibility(
                    visible: preferences.getBool(Constants.phoneLoginConfig)!,
                    child: ButtonWithSvg(
                      height: 48,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      marginLeft: 5,
                      marginRight: 5,
                      marginBottom: 20,
                      borderRadius: 60,
                      matchParent: true,
                      svgHeight: 25,
                      svgWidth: 25,
                      fontSize: 16,
                      svgName: "ic_sms_login",
                      color: Colors.white,
                      textColor: Colors.black,
                      //svgColor: Colors.white,
                      text: "auth.phone_login".tr(),
                      fontWeight: FontWeight.normal,
                      press: () {
                        QuickHelp.goToNavigatorScreen(
                            context, VerifyPhoneScreen(),
                            route: VerifyPhoneScreen.route);
                      },
                    ),
                  ),
                  Visibility(
                    visible: preferences.getBool(Constants.appleLoginConfig)!,
                    child: ButtonWithSvg(
                      height: 48,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      marginLeft: 5,
                      marginRight: 5,
                      marginBottom: 10,
                      borderRadius: 60,
                      matchParent: true,
                      svgHeight: 25,
                      svgWidth: 25,
                      fontSize: 16,
                      svgName: "ic_apple_logo",
                      color: Colors.white,
                      textColor: Colors.black,
                      //svgColor: Colors.white,
                      text: "auth.apple_login".tr(),
                      fontWeight: FontWeight.normal,
                      press: () {
                        SocialLogin.loginApple(context, preferences);
                      },
                    ),
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: termsAndPrivacyMobile(),
            ),
          ],
        ),
      ),
    );
  }

  termsAndPrivacyMobile({Color? color}) {
    return ContainerCorner(
      child: Column(
        children: [
          TextWithTap(
            "auth.by_clicking".tr(),
            marginBottom: 20,
            textAlign: TextAlign.center,
            color: color,
          ),
          RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                    style: TextStyle(
                        color: color != null
                            ? color
                            : QuickHelp.isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    text: "auth.privacy_policy".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        QuickHelp.goToWebPage(context,
                            pageType: QuickHelp.pageTypePrivacy,
                            pageUrl: Config.privacyPolicyUrl);
                      }),
                TextSpan(
                    style: TextStyle(
                        color: color != null
                            ? color
                            : QuickHelp.isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                        fontSize: 16),
                    text: "and_".tr()),
                TextSpan(
                    style: TextStyle(
                        color: color != null
                            ? color
                            : QuickHelp.isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    text: "auth.terms_of_use".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        QuickHelp.goToWebPage(context,
                            pageType: QuickHelp.pageTypeTerms,
                            pageUrl: Config.termsOfUseUrl);
                      }),
              ])),
        ],
      ),
      marginLeft: 5,
      marginRight: 5,
      marginBottom: 10,
    );
  }

  Widget appleOrFbLogin() {
    if (QuickHelp.isIOSPlatform()) {
      return Column(
        children: [
          Visibility(
            visible: preferences.getBool(Constants.facebookLoginConfig)!,
            child: ButtonWithSvg(
              height: 48,
              marginLeft: 30,
              marginRight: 30,
              marginBottom: 10,
              borderRadius: 60,
              svgHeight: 25,
              svgWidth: 25,
              fontSize: 16,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              svgName: "ic_facebook_login",
              color: Colors.white,
              textColor: Colors.black,
              //svgColor: Colors.white,
              text: "auth.facebook_login".tr(),
              fontWeight: FontWeight.normal,
              matchParent: true,
              press: () {
                SocialLogin.loginFacebook(context, preferences);
              },
            ),
          ),
          Visibility(
            visible: preferences.getBool(Constants.appleLoginIosConfig)!,
            child: ButtonWithSvg(
              height: 48,
              marginLeft: 30,
              marginRight: 30,
              marginBottom: 10,
              borderRadius: 60,
              svgHeight: 25,
              svgWidth: 25,
              fontSize: 16,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              svgName: "ic_apple_logo",
              color: Colors.white,
              textColor: Colors.black,
              //svgColor: Colors.white,
              text: "auth.apple_login".tr(),
              fontWeight: FontWeight.normal,
              matchParent: true,
              press: () {
                SocialLogin.loginApple(context, preferences);
              },
            ),
          ),
        ],
      );
    } else {
      return Visibility(
        visible: preferences.getBool(Constants.facebookLoginConfig)!,
        child: ButtonWithSvg(
          height: 48,
          marginLeft: 30,
          marginRight: 30,
          marginBottom: 10,
          borderRadius: 60,
          svgHeight: 25,
          svgWidth: 25,
          fontSize: 16,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          svgName: "ic_facebook_login",
          color: Colors.white,
          textColor: Colors.black,
          //svgColor: Colors.white,
          text: "auth.facebook_login".tr(),
          fontWeight: FontWeight.normal,
          matchParent: true,
          press: () {
            SocialLogin.loginFacebook(context, preferences);
          },
        ),
      );
    }
  }

  initSharedPref() async {
    preferences = await SharedPreferences.getInstance();
    Constants.QueryParseConfig(preferences);
  }
}
