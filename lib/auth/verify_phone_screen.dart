import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/phone_login_screen.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({Key? key}) : super(key: key);

  static const String route = '/phone/verify';

  @override
  _VerifyPhoneScreenState createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.phone_verify_title".tr());
    var size = MediaQuery.of(context).size;

    return ToolBar(
      leftButtonIcon: Icons.arrow_back,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      elevation: 0,
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        child: Responsive.isMobile(context,) ? body() :
        Center(
          child: ContainerCorner(
            width: 400,
            height: size.height,
            borderRadius: 10,
            marginBottom: 20,
            marginTop: 20,
            borderColor: kDisabledGrayColor,
            child: body(),
          ),
        )
        ,
      ),
    );
  }

  Widget body() {
    return Container(
      margin: EdgeInsets.only(top: 50),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            "assets/svg/ic_phone_check.svg",
            height: 100,
            width: 100,
          ),
          TextWithTap(
            "auth.verify_your_phone".tr(),
            marginTop: 40,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          TextWithTap(
            "auth.verify_phone_details".tr(namedArgs: {'app_name': Setup.appName}),
            marginTop: 40,
            marginBottom: 18,
            fontSize: 17,
            marginRight: 10,
            marginLeft: 10,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.normal,
          ),
          RoundedGradientButton(
            height: 48,
            marginLeft: 30,
            marginRight: 30,
            marginBottom: 10,
            borderRadius: 60,
            borderRadiusBottomLeft: 15,
            marginTop: 40,
            fontSize: 17,
            colors: [kPrimaryColor, kSecondaryColor],
            textColor: Colors.white,
            text: "auth.verify_now".tr().toUpperCase(),
            fontWeight: FontWeight.bold,
            onTap: () {
              QuickHelp.goToNavigatorScreen(
                  context,PhoneLoginScreen(), route: PhoneLoginScreen.route);
            },
          ),
        ],
      ),
    );
  }
}
