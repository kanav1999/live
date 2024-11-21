import 'package:heyto/app/config.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String pageType;

  static String routeTerms = QuickHelp.pageTypeTerms;
  static String routePrivacy = QuickHelp.pageTypePrivacy;
  static String routeHelp = QuickHelp.pageTypeHelpCenter;
  static String routeSafety = QuickHelp.pageTypeSafety;
  static String routeCommunity = QuickHelp.pageTypeCommunity;

  //static const String routeType = routePrivacy;

  const WebViewScreen({Key? key, required this.pageType}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {

  String? pageUrl;
  String? pageTitle;

  int position = 1;

  final key = UniqueKey();

  doneLoading(String A) {
    setState(() {
      position = 0;
    });
  }

  startLoading(String A) {
    setState(() {
      position = 1;
    });
  }

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    //if (QuickHelp.isAndroidPlatform()) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageType == QuickHelp.pageTypePrivacy) {
      pageUrl = Config.privacyPolicyUrl;
      pageTitle = "auth.privacy_policy".tr();
    } else if (widget.pageType == QuickHelp.pageTypeTerms) {
      pageUrl = Config.termsOfUseUrl;
      pageTitle = "auth.terms_of_use".tr();

    } else if (widget.pageType == QuickHelp.pageTypeHelpCenter) {
      pageUrl = Config.helpCenterUrl;
      pageTitle = "page_title.help_center_title".tr();

    } else if (widget.pageType == QuickHelp.pageTypeSafety) {
      pageUrl = Config.dataSafetyUrl;
      pageTitle = "page_title.date_safety_title".tr();

    } else if (widget.pageType == QuickHelp.pageTypeCommunity) {
      pageUrl = Config.dataCommunityUrl;
      pageTitle = "page_title.community_title".tr();
    }

    return ToolBar(
        leftButtonIcon: Icons.arrow_back,
        centerTitle: true,
        onLeftButtonTap: (){
          QuickHelp.goBackToPreviousPage(context);
        },
        title: pageTitle!,
        elevation: 2,
        child: IndexedStack(
          index: position,
          children: [
            WebView(
              initialUrl: pageUrl,
              key: key,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: doneLoading,
              onPageStarted: startLoading,
              gestureNavigationEnabled: true,
            ),
            Container(
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : kContentColorDarkTheme,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        )
    );
  }
}
