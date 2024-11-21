import 'package:heyto/app/colors.dart';
import 'package:easy_localization/src/public_ext.dart';
import 'package:flutter/material.dart';
import 'package:heyto/ui/button_with_gradient.dart';

class PauseMyAccount extends StatefulWidget {
  const PauseMyAccount({ Key? key }) : super(key: key);

  @override
  _PauseMyAccountState createState() => _PauseMyAccountState();
}

class _PauseMyAccountState extends State<PauseMyAccount> {
  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("encounters_screen.card_hidden".tr(),style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 25,)),
          Padding(
            padding:  EdgeInsets.only(top: 20.0, bottom: 25.0, right: 10.0, left: 10.0),
            child: Text("encounters_screen.enable_to_meet".tr(), style: TextStyle(color: kDisabledGrayColor,fontWeight: FontWeight.w500, fontSize: 14,), textAlign: TextAlign.center)
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ButtonWithGradient(
              text: "encounters_screen.enable_discovery".tr(),
              textColor: Colors.white,
              beginColor: kPrimaryColor,
              endColor: kSecondaryColor,
              marginLeft: 15,
              marginRight: 15,
              activeBoxShadow: true,
              borderRadius: 30,
              height: 35,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}