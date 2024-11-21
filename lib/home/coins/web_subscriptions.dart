import 'package:carousel_slider/carousel_slider.dart';
import 'package:heyto/app/config.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/coins/coins_payment_web_widget.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class WebSubscriptions extends StatefulWidget {
  UserModel? currentUser;

  WebSubscriptions({Key? key, this.currentUser}) : super(key: key);

  @override
  State<WebSubscriptions> createState() => _WebSubscriptionsState();
}

List<InAppPurchaseModel> getInAppList() {

  List<InAppPurchaseModel> inAppPurchaseList = [];

  InAppPurchaseModel subs1Month = InAppPurchaseModel(
      id: Config.subs1Month,
      period: QuickHelp.getUntilDateFromDays(30),
      price: Config.subs1MonthAmount.toString(),
      type: InAppPurchaseModel.type1MonthSubscription,
      currency: Config.primaryCurrencyCode,
      currencySymbol: Config.primaryCurrencySymbol);

  InAppPurchaseModel subs3Months = InAppPurchaseModel(
      id: Config.subs3Months,
      period: QuickHelp.getUntilDateFromDays(90),
      price: Config.subs3MonthAmount.toString(),
      type: InAppPurchaseModel.type3MonthSubscription,
      currency: Config.primaryCurrencyCode,
      currencySymbol: Config.primaryCurrencySymbol);

  inAppPurchaseList.add(subs3Months);
  inAppPurchaseList.add(subs1Month);

  return inAppPurchaseList;
}

class _WebSubscriptionsState extends State<WebSubscriptions> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  List<String> titles = [
    "tickets.unlimited_likes".tr(),
    "tickets.who_loves_you".tr(),
    "tickets.say_hey_more".tr(),
  ];
  List<String> explains = [
    "tickets.send_likes_as_you_want".tr(),
    "tickets.see_who_likes_you".tr(),
    "tickets.send_up_to_5".tr(),
  ];
  List<String> pictures = [
    "assets/images/ticket_llikes.png",
    "assets/images/ticket_love.png",
    "assets/images/ticket_say.png"
  ];

  @override
  Widget build(BuildContext context) {
    return ContainerCorner(
      borderRadius: 10,
      color: QuickHelp.isDarkMode(context)
          ? kContentColorGhostTheme
          : kPhotosGrayColor.withOpacity(0.3),
      child: Column(
        children: [
          ContainerCorner(
            height: 220,
            width: 300,
            child: CarouselSlider.builder(
                options: CarouselOptions(
                    autoPlay: true,
                    autoPlayInterval:
                        Duration(seconds: Setup.photoSliderDuration),
                    enlargeCenterPage: true,
                    viewportFraction: 1.0,
                    aspectRatio: 3 / 3,
                    autoPlayCurve: Curves.linearToEaseOut,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                      });
                    }),
                carouselController: _controller,
                itemCount: 3,
                itemBuilder:
                    (BuildContext context, int itemIndex, int pageViewIndex) {
                  return cardSubscription(
                      title: titles[_current],
                      explain: explains[_current],
                      pictureURL: pictures[_current],
                      generalMarginTop: 20);
                }),
          ),
          ticketCards(context),
          TextWithTap(
            "tickets.get_ticket".tr(),
            fontSize: 14,
            marginLeft: 20,
            color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
            marginRight: 20,
          ),
          Expanded(
            child: TextButton(
              onPressed: () => openBottomSheet(showCoinsForPurchase()),
              child: ContainerCorner(
                height: 40,
                marginBottom: 5,
                marginTop: 5,
                borderRadius: 20,
                marginLeft: 50,
                marginRight: 50,
                color: kRedColor1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10, top: 10, bottom: 10, right: 10),
                      child: SvgPicture.asset(
                        "assets/svg/ticket_icon.svg",
                        height: 20,
                        width: 20,
                      ),
                    ),
                    SizedBox(
                        child: TextWithTap(
                      widget.currentUser!.getCredits.toString(),
                      color: Colors.white,
                      marginRight: 15,
                      fontSize: 17,
                    )),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                      child: SvgPicture.asset(
                        "assets/svg/ic_add_rounded_primary.svg",
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openBottomSheet(Widget widget) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return widget;
        });
  }

  Widget showCoinsForPurchase() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 1,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(),
                      ),
                      Flexible(
                        flex: 2,
                        child: Container(),
                      ),
                      Flexible(
                        flex: 2,
                        child: CoinsFlowWidget(
                          currentUser: widget.currentUser!,
                          showOnlyCoinsPurchase: true,
                        ),
                      )
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget ticketCards(context) {
    return Container(
      child: Column(
        children: List.generate(2, (index) {
          return ContainerCorner(
              borderWidth: 0.0,
              borderRadius: 10,
              height: 160,
              width: 300,
              marginRight: 10,
              marginLeft: 10,
              spreadRadius: 0,
              marginBottom: 10,
              blurRadius: 20,
              color: QuickHelp.isDarkModeNoContext()
                  ? kContentColorLightTheme
                  : kContentColorDarkTheme,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        index == 0 ? "1" : "3",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 7,
                    ),
                    Text(
                      index == 0 ? "tickets.month".tr() : "tickets.months".tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ContainerCorner(
                      marginTop: 16.9,
                      radiusBottomLeft: 8,
                      radiusBottomRight: 8,
                      height: 35,
                      borderWidth: 0.0,
                      onTap: () {
                        if(QuickHelp.isPremium(widget.currentUser!)){
                          showDialog(
                              context:
                              context,
                              builder:
                                  (BuildContext
                              context) {
                                return AlertDialog(
                                  backgroundColor: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
                                  content:
                                  Column(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/svg/sad.svg",
                                        height: 70,
                                        width: 70,
                                      ),
                                      ContainerCorner(
                                        marginLeft: 10,
                                        marginRight: 10,
                                        width: 350,
                                        child: TextWithTap(
                                          "tickets.subscription_valid".tr(namedArgs: {"date":DateFormat(QuickHelp.dateFormatDmy).format(widget.currentUser!.getPremium!) .toString()}),
                                          textAlign: TextAlign.center,
                                          color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
                                          marginTop: 20,
                                          alignment: Alignment.center,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 35,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ContainerCorner(
                                            child: TextButton(
                                              child: TextWithTap(
                                                "good_".tr().toUpperCase(),
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                            color: kGreenColor,
                                            borderRadius: 10,
                                            marginRight: 5,
                                            width: 125,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              });
                        }else{
                          QuickActions.initPaymentForm(
                            context: context,
                            inAppPurchaseModel: getInAppList()[index],
                            currentUser: widget.currentUser!,
                          );
                        }
                      },
                      width: (MediaQuery.of(context).size.width / 2) - 15,
                      color: index == 0 ? kRedColor1 : kTicketBlueColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/svg/ticket_icon.svg",
                            width: 20,
                            height: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            index == 0
                                ? Config.subs1MonthAmount.toString()
                                : Config.subs3MonthAmount.toString(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ));
        }),
      ),
    );
  }

  Widget cardSubscription({
    required String title,
    required String explain,
    required String pictureURL,
    required double generalMarginTop,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentDirectional.center,
      children: [
        ContainerCorner(
          color: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : Colors.white,
          height: 140,
          marginLeft: 10,
          marginRight: 10,
          marginBottom: 5,
          marginTop: generalMarginTop,
          borderRadius: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: TextWithTap(
                  title,
                  fontSize: 16,
                  marginLeft: 20,
                  marginRight: 20,
                  marginTop: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextWithTap(
                explain,
                fontSize: 13,
                marginLeft: 10,
                marginRight: 10,
                marginTop: 5,
                color: kDisabledGrayColor,
              ),
              ContainerCorner(
                color: kRedColor1,
                height: 40,
                marginLeft: 30,
                marginRight: 30,
                marginTop: 15,
                borderRadius: 50,
                onTap: () {
                  if(QuickHelp.isPremium(widget.currentUser!)){
                    showDialog(
                        context:
                        context,
                        builder:
                            (BuildContext
                        context) {
                          return AlertDialog(
                            backgroundColor: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
                            content:
                            Column(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/sad.svg",
                                  height: 70,
                                  width: 70,
                                ),
                                ContainerCorner(
                                  marginLeft: 10,
                                  marginRight: 10,
                                  width: 350,
                                  child: TextWithTap(
                                    "tickets.subscription_valid".tr(namedArgs: {"date":DateFormat(QuickHelp.dateFormatDmy).format(widget.currentUser!.getPremium!) .toString()}),
                                    textAlign: TextAlign.center,
                                    color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
                                    marginTop: 20,
                                    alignment: Alignment.center,
                                  ),
                                ),
                                SizedBox(
                                  height: 35,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ContainerCorner(
                                      child: TextButton(
                                        child: TextWithTap(
                                          "good_".tr().toUpperCase(),
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      color: kGreenColor,
                                      borderRadius: 10,
                                      marginRight: 5,
                                      width: 125,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          );
                        });
                  }else{
                    QuickActions.initPaymentForm(
                      context: context,
                      inAppPurchaseModel: getInAppList()[0],
                      currentUser: widget.currentUser!,
                    );
                  }
                },
                setShadowToBottom: true,
                shadowColor: QuickHelp.isDarkMode(context)
                    ? kContentColorGhostTheme
                    : kGreyColor3,
                child: Center(
                  child: TextWithTap(QuickHelp.isPremium(widget.currentUser!) ?
                  "tickets.subscribed_".tr() : "tickets.subscribe_".tr(),
                    fontSize: 14,
                    marginLeft: 20,
                    color: Colors.white,
                    marginRight: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -5,
          child: ContainerCorner(
            height: 100,
            width: 100,
            child: Image.asset(pictureURL),
          ),
        ),
      ],
    );
  }
}
