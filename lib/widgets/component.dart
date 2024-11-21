import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Component {

  static Widget buildNavIcon(

      SvgPicture icon, int index, BuildContext context,
      {int badge = 0, Color color = kRedColor1}) {

    if (badge > 0) {

      Color bgColor = QuickHelp.isDarkModeNoContext()
          ? kContentColorLightTheme
          : kContentColorDarkTheme;
      return Container(

        width: MediaQuery.of(context).size.width,
        height: kBottomNavigationBarHeight,
        padding:  EdgeInsets.all(0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    padding:  EdgeInsets.all(0.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        icon,
                        Positioned(
                          right: -9,
                          top: 5,
                          child: Container(
                            padding:  EdgeInsets.only(top: 2.0),
                            height: 20,
                            width: 20,
                            constraints:  BoxConstraints(
                              maxHeight: 45,
                              maxWidth: 45,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: bgColor,
                                  width: 2.0,
                                  style: BorderStyle.solid),
                            ),
                            child: Center(
                              child: Text(
                                "$badge",
                                style:  TextStyle(
                                    color: Colors.white, fontSize: 10.0),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        
      );
    } else {
      return icon;
    }
  }

  Widget button() {
    return ElevatedButton(onPressed: () {}, child:  Text(""));
  }
}
