import 'package:heyto/home/coins/refill_coins_web.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/coins/coins_screen.dart';
import 'package:flutter_svg/svg.dart';

import '../../app/setup.dart';
import '../../models/UserModel.dart';
import '../../ui/app_bar_center_logo.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../settings/settings_screen.dart';
import '../tickets/tickets_screen.dart';

// ignore: must_be_immutable
class RefillCoinsScreen extends StatefulWidget {
  static String route = "/home/buy/tickets";

  UserModel? currentUser;

  RefillCoinsScreen({this.currentUser});

  @override
  _RefillCoinsScreenState createState() => _RefillCoinsScreenState();
}

class _RefillCoinsScreenState extends State<RefillCoinsScreen> {
  String? credits;

  @override
  Widget build(BuildContext context) {

    QuickHelp.setWebPageTitle(context, "page_title.tickets_title".tr());

    setState(() {
      credits = widget.currentUser!.getCredits.toString();
    });

    return ToolBarCenterLogo(
      logoName: 'ic_logo.png',
      logoWidth: 80,
      iconHeight: 24,
      iconWidth: 24,
      leadingWidth: 100,
      leftIconColor: QuickHelp.getColorToolbarIcons(),
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      leftButtonWidget: ContainerCorner(
        height: 20,
        marginBottom: 10,
        marginTop: 10,
        borderRadius: 20,
        width: 150,
        marginLeft: 10,
        color: Colors.black,
        onTap: () async {

          if(Setup.isPaymentsDisabledOnWeb) return;

          UserModel result = await QuickHelp.goToNavigatorScreenForResult(
              context,
              TicketsScreen(
                currentUser: widget.currentUser,
              ), route: TicketsScreen.route);

          //result as UserModel
          print("result: ${result.objectId}");

          widget.currentUser = result;

          setState(() {
            credits = widget.currentUser!.getCredits.toString();
          });
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, top: 10, bottom: 10, right: 3),
              child: SvgPicture.asset(
                "assets/svg/ticket_icon.svg",
                height: 24,
                width: 24,
              ),
            ),
            Expanded(
                child: TextWithTap(
              credits!,
              color: Colors.white,
            )),
          ],
        ),
      ),
      rightButtonAsset: "ic_nav_profile_settings.svg",
      rightButtonPress: () {
        if (widget.currentUser != null) {
          QuickHelp.goToNavigatorScreen(
              context,
              SettingsScreen(
                currentUser: widget.currentUser,
              ), route: SettingsScreen.route);
        }
      },
      child: QuickHelp.isMobile() || QuickHelp.isMacOsPlatform()
          ? CoinsScreen(
              currentUser: widget.currentUser,
            )
          : CoinsWebPage(
              currentUser: widget.currentUser,
            ),
    );
  }
}
