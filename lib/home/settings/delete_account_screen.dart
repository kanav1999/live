import 'package:heyto/auth/welcome_screen.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

// ignore: must_be_immutable
class DeleteAccountScreen extends StatefulWidget {
  static String route = '/settings/delete-account';

  UserModel? currentUser;
  DeleteAccountScreen({this.currentUser});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool isAccountPaused = false;

  @override
  void initState() {

    super.initState();
  }

  _updateCheck() {
    setState(() {
      if (isAccountPaused) {
        isAccountPaused = false;
      } else {
        isAccountPaused = true;
      }

      widget.currentUser!.setAccountHidden = isAccountPaused;
      widget.currentUser!.unset("installation");
      widget.currentUser!.save();

      QuickHelp.initInstallation(null, null);
    });
  }

  _deleteAccount() async {
    QuickHelp.hideLoadingDialog(context);
    QuickHelp.showLoadingDialog(context);

    widget.currentUser!.setAccountDeleted = true;
    var response = await widget.currentUser!.save();

    if (response.success) {
      doUserLogout(widget.currentUser);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showErrorResult(context, response.error!.code);
    }
  }

  void doUserLogout(UserModel? userModel) async {

    ParseResponse response = await userModel!.logout(deleteLocalUserData: true);
    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, WelcomeScreen(), back: false, finish: true, route: WelcomeScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotification(context: context, title: response.error!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.delete_title".tr());

    return ToolBar(
      title: "page_title.delete_title".tr(),
      centerTitle: true,
      leftButtonIcon: Icons.arrow_back,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      elevation: QuickHelp.isAndroidPlatform() ? 2 : 1,
      child: Container(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 70),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ContainerCorner(
                    width: 91,
                    height: 91,
                    borderRadius: 50,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kPrimaryColor,
                      kSecondaryColor,
                    ],
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/svg/play.svg",
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    isAccountPaused
                        ? "settings.resume_account".tr().toUpperCase()
                        : "settings.pause_account".tr().toUpperCase(),
                    style: TextStyle(
                      color: kGreyColor2,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextWithTap(
                    isAccountPaused
                        ? "settings.resume_account_desc".tr()
                        : "settings.pause_account_desc".tr(),
                    textAlign: TextAlign.center,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kDisabledGrayColor,
                    marginLeft: 50,
                    marginRight: 50,
                  ),
                  SizedBox(height: 180),
                  ButtonWithGradient(
                    borderRadius: 100.0,
                    text: isAccountPaused
                        ? "settings.resume_account".tr().toUpperCase()
                        : "settings.pause_account".tr().toUpperCase(),
                    beginColor: kPrimaryColor,
                    endColor: kSecondaryColor,
                    height: 46,
                    marginLeft: 5,
                    marginRight: 5,
                    onTap: () => _updateCheck(),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
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
                                    "settings.delete_acc_ask".tr(),
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
                                    text: "settings.delete_my_account".tr(),
                                    marginLeft: 15,
                                    marginRight: 15,
                                    height: 50,
                                    beginColor: kRedColor1,
                                    endColor: kRedColor1,
                                    onTap: () => _deleteAccount(),
                                  ),
                                  SizedBox(height: 20),
                                  Visibility(
                                    visible: !isAccountPaused,
                                    child: TextButton(
                                      onPressed: () {
                                        _updateCheck();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        "settings.pause_account".tr(),
                                        style: TextStyle(
                                          color: kBlueColor1,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                    },
                    child: Text(
                      "settings.delete_my_account".tr(),
                      style: TextStyle(
                        color: kDisabledGrayColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
