import 'package:heyto/app/config.dart';
import 'package:heyto/auth/welcome_screen.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/settings/get_money_screen.dart';
import 'package:heyto/home/settings/settings_push_screen.dart';
import 'package:heyto/home/tickets/tickets_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/update_user_provider.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/button_widget.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:provider/src/provider.dart';

import '../../app/setup.dart';
import 'delete_account_screen.dart';

// ignore: must_be_immutable
class SettingsScreen extends StatefulWidget {

  static  String route = '/settings';
  UserModel? currentUser;

  SettingsScreen({this.currentUser});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();


}

class _SettingsScreenState extends State<SettingsScreen> {

  bool isSwitchedStatus = false;

  List<bool> isSelected = [true, false];
  int distance = 0;

  _getUser() async {

    setState(() {
      isSwitchedStatus = widget.currentUser!.getPrivacyShowStatusOnline!;

    });

    setState(() {

      isSwitchedStatus = widget.currentUser!.getPrivacyShowStatusOnline!;

      if(widget.currentUser!.getDistanceInMiles!){
        isSelected = [false, true];
      } else {
        isSelected = [true, false];
      }

    });
  }

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    QuickHelp.setWebPageTitle(context, "page_title.settings_title".tr());

    return ToolBar(
        title: "page_title.settings_title".tr(),
        centerTitle: true,
        leftButtonIcon: Icons.arrow_back,
        onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
        elevation: QuickHelp.isAndroidPlatform() ? 2 : 1,
        child: SafeArea(
          child: Container(
            color: QuickHelp.getColorSettingsBg(),
            padding:  EdgeInsets.only(top: 10.0, left: 16, right: 16),
            child: Responsive.isMobile(context) || Responsive.isTablet(context) ? getBody() : webBody(),
          ),
        )
    );
  }

  double spaces() {
    var size = MediaQuery.of(context).size.width;
    if(size == 1200) {
      return 100.0;
    }else if(size > 1200){
      return 150.0;
    }else if(size <= 1024){
      return 10;
    }else{
      return 5;
    }
  }

  Widget webBody() {
    var size = MediaQuery.of(context).size;

    return ContainerCorner(
      height: size.height,
      width: size.width,
      marginLeft: spaces(),
      marginRight: spaces(),
      marginBottom: 10,
      child: Card(
        elevation: 3.0,
        color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContainerCorner(
                      onTap: () {
                        if(Setup.isPaymentsDisabledOnWeb) return;
                        QuickHelp.goToNavigatorScreen(context, TicketsScreen(currentUser: widget.currentUser), route: TicketsScreen.route);
                      },
                      borderRadius: 10.0,
                      colors:  [
                        kProfileStarsColorPrimary,
                        kProfileStarsColorSecondary,
                      ],
                      height: 72,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 67,
                                height: 25,
                                margin:  EdgeInsets.only(top: 12),
                                alignment: Alignment.topCenter,
                                child: Image.asset("assets/images/ic_logo.png"),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 10,
                                ),
                                child: Text(
                                  "profile_tab.profile_stars".tr(),
                                  style:
                                  TextStyle(fontSize: 15, color: kOrangeColor1),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10.0),
                            child: Text(
                              "profile_tab.unli_like_more".tr(),
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    title("settings.account_settings".tr()),
                    GestureDetector(
                      //onTap: () => ChangePhoneNumber,
                      child: ContainerCorner(
                        borderColor: kGreyColor1,
                        height: 50,
                        borderRadius: 10,
                        marginTop: 15,
                        color: QuickHelp.getColorStandard(inverse: true),
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          child: accountTypeWidget(widget.currentUser!),
                        ),
                      ),
                    ),
                    title("settings.activity_status".tr()),
                    ContainerCorner(
                      borderColor:  kGreyColor1,
                      height: 50,
                      borderRadius: 10,
                      marginTop: 15,
                      color: QuickHelp.getColorStandard(inverse: true),
                      child: Padding(
                        padding:  EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "settings.recent_ac_status".tr(),
                              style: TextStyle(
                                color: QuickHelp.getColorTextCustom1(),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                                activeColor:  kPrimaryColor,
                                value: isSwitchedStatus,
                                onChanged: (bool value) {
                                  setState(() {
                                    isSwitchedStatus = value;
                                    widget.currentUser!.setPrivacyShowStatusOnline = !value;
                                    widget.currentUser!.save();
                                    context.read<UpdateUserProvider>().updateUser(widget.currentUser!);
                                  });
                                }),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "settings.allow_app_24_hours_active".tr(namedArgs: {"app_name" : Config.appName}),
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: kGreyColor1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    title("page_title.notifications_title".tr()),
                    GestureDetector(
                      onTap: () => QuickHelp.goToNavigatorScreen(context, PushSettingsScreen(currentUser: widget.currentUser,), route: PushSettingsScreen.route),
                      child: option("settings.push_notif".tr()),
                    ),
                    title("settings.show_dist_in".tr()),
                    ContainerCorner(
                      color: QuickHelp.getColorStandard(inverse: true),
                      height: 70,
                      borderColor: kGreyColor1,
                      borderRadius: 10,
                      marginTop: 15,
                      child: Center(
                        child: ToggleButtons(
                          borderRadius: BorderRadius.circular(10),
                          borderColor: Colors.transparent,
                          renderBorder: false,
                          selectedBorderColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          selectedColor: Colors.transparent,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          onPressed: (int index) {
                            setState(() {
                              for (int i = 0; i < isSelected.length; i++) {
                                isSelected[i] = i == index;

                                widget.currentUser!.setDistanceInMiles = isSelected[i];
                                widget.currentUser!.save();
                                context.read<UpdateUserProvider>().updateUser(widget.currentUser!);
                              }
                            });
                          },
                          isSelected: isSelected,
                          children: [
                            Container(
                              width: 220,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:  BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10),),
                                color: isSelected[0] ? null : Colors.transparent,
                                gradient: isSelected[0]
                                    ?  LinearGradient(
                                    colors: [kPrimaryColor, kSecondaryColor])
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "km_".tr(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color:
                                    isSelected[0] ? Colors.white :  kGreyColor1,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 220,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:  BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10),),
                                color: isSelected[1] ? null : Colors.transparent,
                                gradient: isSelected[1]
                                    ?  LinearGradient(
                                    colors: [kPrimaryColor, kSecondaryColor])
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "mi_".tr(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color:
                                    isSelected[1] ? Colors.white :  kGreyColor1,
                                  ),
                                ),
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
            VerticalDivider(),
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title("settings.contact_us".tr(),),
                    GestureDetector(
                      onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeHelpCenter, pageUrl: Config.helpCenterUrl),
                      child: option("settings.help_support".tr()),
                    ),
                    title("settings.community_".tr(),),
                    ContainerCorner(
                      borderColor:  kGreyColor1,
                      height: 80,
                      borderRadius: 10,
                      marginTop: 15,
                      width: size.width / 2.5,
                      color: QuickHelp.getColorStandard(inverse: true),
                      child: Padding(
                        padding:  EdgeInsets.only(left: 10, right: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:  [
                            TextWithTap(
                              "settings.community_gui".tr(),
                              color: QuickHelp.getColorTextCustom1(),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeCommunity, pageUrl: Config.dataCommunityUrl),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            TextWithTap(
                              "settings.safety_tips".tr(),
                              color: QuickHelp.getColorTextCustom1(),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeSafety, pageUrl: Config.dataSafetyUrl),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    getMoneyOption(
                      "profile_screen.op_get_money".tr(),
                      "assets/svg/ic_redeem_menu.svg",
                      GetMoneyScreen(currentUser: widget.currentUser,),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    ButtonWithGradient(
                      marginLeft: 5,
                      marginRight: 5,
                      beginColor: kRedColor1,
                      endColor: kRedColor1,
                      text: 'logout'.tr(),
                      fontSize: 14,
                      borderRadius: 10,
                      setShadowToBottom: true,
                      shadowColor: kRedColor1,
                      blurRadius: 5,
                      spreadRadius: 1,
                      activeBoxShadow: true,
                      shadowColorOpacity: 0.2,
                      textColor: Colors.white,
                      onTap: () => showAlert(),
                    ),
                    ButtonWithGradient(
                      marginLeft: 5,
                      marginRight: 5,
                      beginColor: Colors.white,
                      endColor: Colors.white,
                      setShadowToBottom: true,
                      shadowColor: kGreyColor1,
                      blurRadius: 5,
                      spreadRadius: 1,
                      activeBoxShadow: true,
                      shadowColorOpacity: 0.4,
                      text: "settings.delete_acc".tr(),
                      fontSize: 14,
                      borderRadius: 10,
                      textColor: Colors.red,
                      onTap: () => QuickHelp.goToNavigatorScreen(context, DeleteAccountScreen(currentUser: widget.currentUser,), route: DeleteAccountScreen.route),
                      marginTop: 15,
                      marginBottom: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getBody() {
    return ListView(
      children: [
        ContainerCorner(
          onTap: () {
            if(Setup.isPaymentsDisabledOnWeb) return;
            QuickHelp.goToNavigatorScreen(context, TicketsScreen(currentUser: widget.currentUser), route: TicketsScreen.route);
          },
          borderRadius: 10.0,
          colors:  [
            kProfileStarsColorPrimary,
            kProfileStarsColorSecondary,
          ],
          height: 72,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 67,
                    height: 25,
                    margin:  EdgeInsets.only(top: 12),
                    alignment: Alignment.topCenter,
                    child: Image.asset("assets/images/ic_logo.png"),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                    ),
                    child: Text(
                      "profile_tab.profile_stars".tr(),
                      style:
                      TextStyle(fontSize: 15, color: kOrangeColor1),
                    ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  "profile_tab.unli_like_more".tr(),
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 25,
        ),
        title("settings.account_settings".tr()),
        GestureDetector(
          //onTap: () => ChangePhoneNumber,
          child: ContainerCorner(
            borderColor: kGreyColor1,
            height: 50,
            borderRadius: 10,
            marginTop: 15,
            color: QuickHelp.getColorStandard(inverse: true),
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: accountTypeWidget(widget.currentUser!),
            ),
          ),
        ),
        title("settings.activity_status".tr()),
        ContainerCorner(
          borderColor:  kGreyColor1,
          height: 50,
          borderRadius: 10,
          marginTop: 15,
          color: QuickHelp.getColorStandard(inverse: true),
          child: Padding(
            padding:  EdgeInsets.only(left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "settings.recent_ac_status".tr(),
                  style: TextStyle(
                    color: QuickHelp.getColorTextCustom1(),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                    activeColor:  kPrimaryColor,
                    value: isSwitchedStatus,
                    onChanged: (bool value) {
                      setState(() {
                        isSwitchedStatus = value;
                        widget.currentUser!.setPrivacyShowStatusOnline = !value;
                        widget.currentUser!.save();
                        context.read<UpdateUserProvider>().updateUser(widget.currentUser!);
                      });
                    }),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "settings.allow_app_24_hours_active".tr(namedArgs: {"app_name" : Config.appName}),
            textAlign: TextAlign.start,
            style: TextStyle(
              color: kGreyColor1,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        title("page_title.notifications_title".tr()),
        GestureDetector(
          onTap: () => QuickHelp.goToNavigatorScreen(context, PushSettingsScreen(currentUser: widget.currentUser,), route: PushSettingsScreen.route),
          child: option("settings.push_notif".tr()),
        ),
        title("settings.show_dist_in".tr()),
        ContainerCorner(
          color: QuickHelp.getColorStandard(inverse: true),
          height: 70,
          borderColor: kGreyColor1,
          borderRadius: 10,
          marginTop: 15,
          child: Center(
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              borderColor: Colors.transparent,
              renderBorder: false,
              selectedBorderColor: Colors.transparent,
              splashColor: Colors.transparent,
              selectedColor: Colors.transparent,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;

                    widget.currentUser!.setDistanceInMiles = isSelected[i];
                    widget.currentUser!.save();
                    context.read<UpdateUserProvider>().updateUser(widget.currentUser!);
                  }
                });
              },
              isSelected: isSelected,
              children: [
                Container(
                  width: (MediaQuery.of(context).size.width / 2) - 25,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius:  BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10),),
                    color: isSelected[0] ? null : Colors.transparent,
                    gradient: isSelected[0]
                        ?  LinearGradient(
                        colors: [kPrimaryColor, kSecondaryColor])
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "km_".tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color:
                        isSelected[0] ? Colors.white :  kGreyColor1,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: (MediaQuery.of(context).size.width / 2) - 25,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius:  BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10),),
                    color: isSelected[1] ? null : Colors.transparent,
                    gradient: isSelected[1]
                        ?  LinearGradient(
                        colors: [kPrimaryColor, kSecondaryColor])
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "mi_".tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color:
                        isSelected[1] ? Colors.white :  kGreyColor1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        title("settings.contact_us".tr(),),
        GestureDetector(
          onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeHelpCenter, pageUrl: Config.helpCenterUrl),
          child: option("settings.help_support".tr()),
        ),
        title("settings.community_".tr(),),
        ContainerCorner(
          borderColor:  kGreyColor1,
          height: 80,
          borderRadius: 10,
          marginTop: 15,
          color: QuickHelp.getColorStandard(inverse: true),
          child: Padding(
            padding:  EdgeInsets.only(left: 10, right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                TextWithTap(
                  "settings.community_gui".tr(),
                  color: QuickHelp.getColorTextCustom1(),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeCommunity, pageUrl: Config.dataCommunityUrl),
                ),
                SizedBox(
                  height: 10.0,
                ),
                TextWithTap(
                  "settings.safety_tips".tr(),
                  color: QuickHelp.getColorTextCustom1(),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  onTap: () => QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeSafety, pageUrl: Config.dataSafetyUrl),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        getMoneyOption(
          "profile_screen.op_get_money".tr(),
          "assets/svg/ic_redeem_menu.svg",
          GetMoneyScreen(currentUser: widget.currentUser,),
        ),
        SizedBox(
          height: 50,
        ),
        ButtonWithGradient(
          marginLeft: 5,
          marginRight: 5,
          beginColor: kRedColor1,
          endColor: kRedColor1,
          text: 'logout'.tr(),
          fontSize: 14,
          borderRadius: 10,
          setShadowToBottom: true,
          shadowColor: kRedColor1,
          blurRadius: 5,
          spreadRadius: 1,
          activeBoxShadow: true,
          shadowColorOpacity: 0.2,
          textColor: Colors.white,
          onTap: () => showAlert(),
        ),
        ButtonWithGradient(
          marginLeft: 5,
          marginRight: 5,
          beginColor: Colors.white,
          endColor: Colors.white,
          setShadowToBottom: true,
          shadowColor: kGreyColor1,
          blurRadius: 5,
          spreadRadius: 1,
          activeBoxShadow: true,
          shadowColorOpacity: 0.4,
          text: "settings.delete_acc".tr(),
          fontSize: 14,
          borderRadius: 10,
          textColor: Colors.red,
          onTap: () => QuickHelp.goToNavigatorScreen(context, DeleteAccountScreen(currentUser: widget.currentUser,), route: DeleteAccountScreen.route),
          marginTop: 15,
          marginBottom: 20,
        ),
      ],
    );
  }

  Widget getMoneyOption(String text, String svgIconURL, Widget widgetNav) {
    return ButtonWidget(
        backgroundColor: QuickHelp.isDarkMode(context)
            ? kContentColorLightTheme
            : kContentColorDarkTheme,
        borderColor: QuickHelp.isDarkMode(context)
            ? kTabIconDefaultColor
            : kGreyColor0,
        marginLeft: 10,
        marginRight: 10,
        borderRadiusAll: 10,
        marginBottom: 5,
        borderWidth: 1,
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ContainerCorner(
              color: kTransparentColor,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: SvgPicture.asset(
                      svgIconURL,
                      height: 30,
                      width: 30,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWithTap(
                        text,
                        marginLeft: 10,
                        fontSize: 18,
                        color: QuickHelp.isDarkMode(context)
                            ? kContentColorDarkTheme
                            : kGreyColor2,
                        //color: Colors.black,
                      ),
                      Row(
                        children: [
                          TextWithTap(
                            QuickHelp.getDiamondsLeftToRedeem(
                                widget.currentUser!.getDiamonds!),
                            marginRight: 2,
                            marginLeft: 10,
                            marginTop: 5,
                            //color: Colors.black,
                            color: QuickHelp.isDarkMode(context)
                                ? kContentColorDarkTheme
                                : kGreyColor2,
                            fontWeight: FontWeight.bold,
                            marginBottom: 5,
                            fontSize: 15,
                          ),
                          TextWithTap(
                            widget.currentUser!.getPayouts! > 0
                                ? "profile_screen.get_money_for_diamonds_".tr()
                                : "profile_screen.get_money_for_diamonds".tr(),
                            marginRight: 20,
                            marginTop: 5,
                            color: QuickHelp.isDarkMode(context)
                                ? kContentColorDarkTheme
                                : kGreyColor2,
                            marginBottom: 5,
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
            ContainerCorner(
              color: kTransparentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_diamond.svg",
                        height: 30,
                        width: 30,
                      ),
                      TextWithTap(
                        widget.currentUser!.getDiamonds.toString(),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        marginRight: 20,
                        marginLeft: 5,
                        color: QuickHelp.isDarkMode(context)
                            ? kContentColorDarkTheme
                            : kGreyColor2,
                        //color: Colors.black,
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
        onTap: () async {
          UserModel? user = await QuickHelp.goToNavigatorScreenForResult(context, widgetNav, route: '');

          if(user != null){
            widget.currentUser = user;
          }
        }
    );
  }

  ContainerCorner option(String option) {
    return ContainerCorner(
      borderColor:  kGreyColor1,
      height: 50,
      borderRadius: 10,
      marginTop: 15,
      color: QuickHelp.getColorStandard(inverse: true),
      child: Padding(
        padding:  EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWithTap(
              option,
              //onTap: () => push != null ? QuickHelp.goToNavigator(context, push, arguments: widget.currentUser) : QuickHelp.goToWebPage(context, pageType: pageType!),
              color: QuickHelp.getColorTextCustom1(),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  Padding title(String title, {String? pageType}) {
    return Padding(
      padding:  EdgeInsets.only(
        top: 25,
      ),
      child: TextWithTap(
        title,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String loginType(UserModel user){

    if(user.getPhoneNumberFull!.isNotEmpty){
      return "settings.account_type_phone".tr();
    } else if(user.getGoogleId!.isNotEmpty){
      return "settings.account_type_google".tr();
    } else if(user.getFacebookId!.isNotEmpty){
      return "settings.account_type_facebook".tr();
    }

    return "";
  }

  String loginTypeId(UserModel user){

    if(user.getPhoneNumberFull!.isNotEmpty){
      return user.getPhoneNumberFull!;
    } else if(user.getGoogleId!.isNotEmpty){
      return user.getGoogleId!;
    } else if(user.getFacebookId!.isNotEmpty){
      return user.getFacebookId!;
    }

    return "";
  }

  Widget accountTypeWidget (UserModel userModel){

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loginType(userModel),
          style: TextStyle(
            color: QuickHelp.getColorTextCustom1(),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          loginTypeId(userModel),
          style: TextStyle(
            color: QuickHelp.getColorTextCustom1(),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  showAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              width: Responsive.isMobile(context) ? null : 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 15.0),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: SvgPicture.asset(
                        "assets/svg/sad.svg",
                        color: kPhotosGrayColorReverse,
                      ),
                    ),
                  ),
                  Text(
                    "logout_acc_ask".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(
                    height: 35,
                  ),
                  ButtonWithGradient(
                    borderRadius: 100,
                    text: "logout".tr(),
                    marginLeft: 15,
                    marginRight: 15,
                    height: 50,
                    beginColor: kRedColor1,
                    endColor: kRedColor1,
                    onTap: () => doUserLogout(widget.currentUser),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }

  void doUserLogout(UserModel? userModel) async {

    QuickHelp.showLoadingDialog(context);

    userModel!.unset("installation");
    await userModel.save();

    ParseResponse response = await userModel.logout(deleteLocalUserData: true);
    if (response.success) {
      QuickHelp.initInstallation(null, null);
      QuickHelp.hideLoadingDialog(context);

      QuickHelp.goToNavigatorScreen(context, WelcomeScreen(), finish: true, back: false, route: WelcomeScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotification(context: context, title: response.error!.message);
    }
  }
}
