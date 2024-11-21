import 'package:heyto/helpers/quick_help.dart';
import 'package:flutter/material.dart';

class ButtonWithIcon extends StatelessWidget {
  final Function? press;
  final String text;
  final IconData? icon;
  final double? width;
  final double? height;
  final double? marginTop;
  final double? marginLeft;
  final double? marginRight;
  final double? marginBottom;
  final double? fontSize;
  final double? borderRadius;
  final Color? textColor;
  final Color? color;
  final FontWeight? fontWeight;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final bool? matchParent;


  const ButtonWithIcon({
    Key? key,
    required this.text,
    this.fontWeight,
    this.fontSize,
    this.marginTop = 0,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.marginBottom = 0,
    this.icon,
    this.width,
    this.height,
    this.borderRadius,
    this.textColor,
    this.color,
    this.press,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.matchParent
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(left: marginLeft!, top: marginTop!, bottom: marginBottom!, right: marginRight!),
      child: ElevatedButton(
        onPressed: press as void Function()?,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(color != null ? color! : Colors.grey),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  borderRadius != null ? borderRadius! : 0))),
        ),
        child: Row(
          mainAxisSize: getMainAxisSize(),
          mainAxisAlignment: mainAxisAlignment!,
          crossAxisAlignment: crossAxisAlignment!,
          children: [
            Icon(icon!, color: textColor,),
            Container(width: 10,),
            Text(text,

                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: fontWeight,
                ))
          ],
        ),
      ),
    );
  }

  MainAxisSize getMainAxisSize(){

    if(matchParent != null){
      return matchParent! == true ? MainAxisSize.max : MainAxisSize.min;
    } else {
      return QuickHelp.isWebPlatform() ? MainAxisSize.min : MainAxisSize.max;
    }
  }
}
