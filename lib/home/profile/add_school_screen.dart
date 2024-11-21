import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// ignore: must_be_immutable
class AddSchoolScreen extends StatefulWidget {
  static String route = '/profile/add/school';

  UserModel? currentUser;
  AddSchoolScreen({this.currentUser});

  @override
  _AddSchoolScreenState createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    QuickHelp.setWebPageTitle(context, "page_title.add_school_title".tr());

    return ToolBar(
      iconHeight: 24,
      iconWidth: 24,
      centerTitle: true,
      title: "page_title.add_school_title".tr(),
      leftButtonIcon: Icons.arrow_back,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      child: Container(
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 15,
        ),
        child: ListView(
            children: const [

              TextField(
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  focusColor: Color(0xFFC7C7C7),
                  hintStyle: TextStyle(
                    color: Color(0xFF47525C),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: "Search for school",
                ),
              ),

            ]
        ),
      ),

    );
  }
}