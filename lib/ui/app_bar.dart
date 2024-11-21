import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../helpers/quick_help.dart';
import '../app/colors.dart';

class ToolBar extends StatelessWidget {
  final Function? onLeftButtonTap;
  final IconData? leftButtonIcon;
  final Widget? leftButtonWidget;
  final Function? rightButtonPress;
  final IconData? rightButtonIcon;
  final String? rightButtonAsset;
  final Color? rightIconColor;
  final double? iconWidth;
  final double? iconHeight;
  final Color? iconColor;
  final String? title;
  final Widget? titleChild;
  final Widget child;
  final double? elevation;
  final bool? centerTitle;
  final bool ? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool? extendBodyBehindAppBar;
  final FloatingActionButton? floatingActionButton;
  const ToolBar({
    Key? key,
    this.leftButtonIcon,
    this.onLeftButtonTap,
    this.iconColor,
    this.elevation,
    this.title,
    this.titleChild,
    this.centerTitle,
    this.rightButtonPress,
    this.rightButtonIcon,
    this.iconWidth,
    this.iconHeight,
    this.leftButtonWidget,
    this.rightButtonAsset,
    this.rightIconColor,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Color titleColor = QuickHelp.isDarkModeNoContext()
        ? kContentColorDarkTheme
        : kContentColorLightTheme;

    Color bgColor = QuickHelp.isDarkModeNoContext()
        ? kContentColorLightTheme
        : kContentColorDarkTheme;

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar!,
      resizeToAvoidBottomInset : resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        centerTitle: centerTitle,
        leading: IconButton(
          icon: leftButtonWidget!= null ? leftButtonWidget! : Icon(leftButtonIcon, color: iconColor != null ? iconColor : titleColor),
          onPressed: onLeftButtonTap as void Function()?,
        ),
        backgroundColor: backgroundColor != null ? backgroundColor : bgColor,
        title: titleChild != null ? titleChild : Text(title != null ? title! : "", style: TextStyle(color: titleColor),),
        bottomOpacity: 10,
        elevation: elevation,
        actions: [
          IconButton(
            icon: rightButtonAsset != null
                ? SvgPicture.asset("assets/svg/$rightButtonAsset",
                width: iconWidth,
                height: iconHeight,
                color: rightIconColor != null ? rightIconColor : titleColor)
                : Icon(rightButtonIcon,
                color:
                rightIconColor != null ? rightIconColor : titleColor),
            onPressed: rightButtonPress as void Function()?,
          )
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return child;
      }),
    );
  }
}