import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/update_user_provider.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/src/provider.dart';

// ignore: must_be_immutable
class PushSettingsScreen extends StatefulWidget {
  static String route = '/settings/push';

  UserModel? currentUser;

  PushSettingsScreen({this.currentUser});

  @override
  _PushSettingsScreenState createState() => _PushSettingsScreenState();
}

class _PushSettingsScreenState extends State<PushSettingsScreen> {

  bool isSwitchedMessages = false;
  bool isSwitchedMatches = false;
  bool isSwitchedLike = false;

  String typeMessages = "messages";
  String typeMatches = "matches";
  String typeLike = "like";

  @override
  void initState() {

    _getUser();
    super.initState();
  }

  _getUser() async {

    setState(() {
      isSwitchedMessages = widget.currentUser!.getPushNotificationsMessage!;
      isSwitchedMatches = widget.currentUser!.getPushNotificationsMatches!;
      isSwitchedLike = widget.currentUser!.getPushNotificationsLike!;
    });

    setState(() {

      isSwitchedMessages = widget.currentUser!.getPushNotificationsMessage!;
      isSwitchedMatches = widget.currentUser!.getPushNotificationsMatches!;
      isSwitchedLike = widget.currentUser!.getPushNotificationsLike!;
    });
  }


  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.notifications_title".tr());


    return ToolBar(
        title: "page_title.notifications_title".tr(),
        centerTitle: true,
        leftButtonIcon: Icons.arrow_back,
        onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
        elevation: QuickHelp.isAndroidPlatform() ? 2 : 1,
        child: SafeArea(
          child: Container(
            color: QuickHelp.getColorSettingsBg(),
            child: Column(
              children: [
                notification(
                    isSwitchedMessages,
                    "settings.notify_messages".tr(),
                    "settings.notify_messages_text".tr(),
                    typeMessages),
                notification(
                    isSwitchedMatches,
                    "settings.notify_matches".tr(),
                    "settings.notify_matches_text".tr(),
                    typeMatches),
                notification(
                    isSwitchedLike,
                    "settings.notify_liked_you".tr(),
                    "settings.notify_liked_you_text".tr(),
                    typeLike),
              ],
            ),
          ),
        ));
  }

  ContainerCorner notification(
      bool isSwitched, String text, String subtext, String type) {
    return ContainerCorner(
      borderColor: kGreyColor1,
      height: 80,
      borderRadius: 10,
      marginTop: 10,
      marginRight: 10,
      marginLeft: 10,
      color: QuickHelp.getColorStandard(inverse: true),
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    //color: kGreyColor2,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: isSwitched,
                  onChanged: (value) => _goToPage(type, value),
                  activeTrackColor: kPrimaryLightColor,
                  activeColor: kPrimaryColor,
                ),
              ],
            ),
            Text(
              subtext,
              style: TextStyle(
                color: kGreyColor1,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _goToPage(String type, bool value) async{
    setState(() {

      if(type == typeMessages){
        isSwitchedMessages = value;
        widget.currentUser!.setPushNotificationsMessage = !value;

      } else if(type == typeMatches){
        isSwitchedMatches = value;
        widget.currentUser!.setPushNotificationsMatches = !value;

      } else if(type == typeLike){
        isSwitchedLike = value;
        widget.currentUser!.setPushNotificationsLike = !value;
      }

    });

    await widget.currentUser!.save();
    context.read<UpdateUserProvider>().updateUser(widget.currentUser!);
  }

}
