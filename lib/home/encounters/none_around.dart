import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/location/add_city_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/counter_providers.dart';

class NoneAround extends StatefulWidget {
  final UserModel? currentUser;

  NoneAround({this.currentUser});

  @override
  _NoneAroundState createState() => _NoneAroundState();
}

class _NoneAroundState extends State<NoneAround> {

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180.0,
            height: 180.0,
            child: QuickActions.avatarWidget(widget.currentUser!),
          ),
          Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
              child: Text(
                "encounters_screen.none_around_me".tr(),
                style: TextStyle(
                  color: kGreyColor1,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              )),
          TextWithTap("encounters_screen.update_location".tr(),
            marginRight: 20,
            marginLeft: 20,
            color: kBlueColor1,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            onTap: () async {
              UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
                  context,
                  AddCityScreen(
                    currentUser: widget.currentUser,
                  ),
                  route: AddCityScreen.route);

              if(user != null){
                // Update user now
                reloadScreen();
              }
            },
          ),
        ],
      ),
    );
  }

  reloadScreen(){
    context.read<CountersProvider>().setTabIndex(HomeScreen.tabHome);
  }
}
