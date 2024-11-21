import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToolBarChatWidget extends StatelessWidget {
  final Function? leftButtonPress;
  final IconData? leftButtonIcon;
  final String? leftButtonAsset;
  final Color? leftIconColor;
  final Function? rightButtonPress;
  final IconData? rightButtonIcon;
  final Widget? rightButtonWidget;
  final String? rightButtonAsset;
  final Color? rightIconColor;
  final Function? afterLogoButtonPress;
  final IconData? afterLogoButtonIcon;
  final String? afterLogoButtonAsset;
  final Color? afterLogoIconColor;
  final Widget? centerWidget;
  final Widget child;
  final double? elevation;
  final BottomNavigationBar? bottomNavigationBar;
  final double? iconWidth;
  final double? iconHeight;
  final double? leftSideWidth;
  final bool? centerTitle;

  const ToolBarChatWidget(
      {Key? key,
      this.centerWidget,
      required this.child,
      this.iconWidth,
      this.iconHeight,
      this.leftButtonIcon,
      this.leftButtonPress,
      this.leftIconColor,
      this.rightButtonPress,
      this.rightButtonIcon,
      this.rightIconColor,
      this.afterLogoButtonPress,
      this.afterLogoButtonIcon,
      this.afterLogoIconColor,
      this.elevation,
      this.bottomNavigationBar,
      this.afterLogoButtonAsset,
      this.leftButtonAsset,
      this.centerTitle,
      this.rightButtonWidget,
        this.leftSideWidth,
      this.rightButtonAsset})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color titleColor = QuickHelp.isDarkModeNoContext()
        ? kContentColorDarkTheme
        : kContentColorLightTheme;

    Color bgColor = QuickHelp.isDarkModeNoContext()
        ? kContentColorLightTheme
        : kContentColorDarkTheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: leftSideWidth != null ? leftSideWidth : null,
        leading: IconButton(
          icon: leftButtonAsset != null
              ? SvgPicture.asset("assets/svg/$leftButtonAsset",
                  width: iconWidth,
                  height: iconHeight,
                  color: leftIconColor != null ? leftIconColor : titleColor)
              : Icon(leftButtonIcon,
                  color: leftIconColor != null ? leftIconColor : titleColor),
          onPressed: leftButtonPress as void Function()?,
        ),
        backgroundColor: bgColor,
        title: centerWidget,
        centerTitle: centerTitle,
        //bottomOpacity: 10,
        elevation: elevation,
        actions: [
          rightButtonWidget!
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: child,
      /*body: Builder(builder: (BuildContext context) {
        return child;
      }),*/
    );
  }
}
