import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/coins/coins_payment_widget.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_widget.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../../app/constants.dart';
import '../../app/setup.dart';

// ignore: must_be_immutable
class TicketsAdsScreen extends StatefulWidget {
  static String route = '/tickets/ads';
  UserModel? currentUser;
  TicketsAdsScreen({this.currentUser});

  @override
  _TicketsAdsScreenState createState() => _TicketsAdsScreenState();
}

class _TicketsAdsScreenState extends State<TicketsAdsScreen> {
  var rewardedAd;
  bool adsLoaded = false;
  String mCredits = "0";
  int creditsAdded = 0;

  @override
  void initState() {
    initAds();

    setState(() {
      mCredits = widget.currentUser!.getCredits.toString();
    });
    super.initState();
  }

  initAds(){

    RewardedAd.load(
      adUnitId: Constants.getAdmobRewardedVideoUnit(),
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('$ad RewardedAd loaded.');
          // Keep a reference to the ad so you can show it later.

          setState(() {
            adsLoaded = true;
            this.rewardedAd = ad;
          });

          setAdsCallback();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  showAds() {

    this.rewardedAd.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) async {

      print('Reward received ${rewardItem.amount}');

      //creditsAdded = rewardItem.amount();
      creditsAdded = Setup.ticketsAddedOnRewardedVideo;

      widget.currentUser!.addCredit = creditsAdded;
      ParseResponse parseResponse = await widget.currentUser!.save();
      if(parseResponse.success){
        widget.currentUser = parseResponse.results!.first;

        setState(() {
          mCredits = widget.currentUser!.getCredits.toString();
          //context.read<CountersProvider>().updateCredit(widget.currentUser!);
        });
      }

    });
  }

  setAdsCallback(){

    this.rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad){

        //ad.dispose();

        setState(() {
          adsLoaded = false;
        });
    },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();

        if (creditsAdded != 0){
          QuickHelp.showAppNotificationAdvanced(
              context: context,
              user: widget.currentUser,
              title: "congrat_".tr(),
              message: "tickets.you_you_got_tickets"
                  .tr(namedArgs: {"tickets": creditsAdded.toString()}),
            isError: false
          );

          creditsAdded = 0;
        }

        initAds();
      },

      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();

        // Show Alert

        setState(() {
          adsLoaded = false;
        });

        initAds();
      },
      onAdImpression: (RewardedAd ad) {
        print('$ad impression occurred.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return ToolBarCenterWidget(
        centerTitle: true,
        leftSideWidth: QuickHelp.isAndroidPlatform() ? 0 : null,
        centerWidget: ticketFree(credits: mCredits),
        leftButtonIcon: Icons.arrow_back,
        leftButtonPress: ()=> QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 15.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: SizedBox(
                              width: 200,
                              height: 200,
                              child:
                              Image.asset("assets/images/ticket-star.png")),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            left: 90,
                            right: 90,
                          ),
                          child: Center(
                            child: TextWithTap(
                              "tickets.get_ticket_by_watching".tr(namedArgs: {"tickets" : Setup.ticketsAddedOnRewardedVideo.toString()}),
                              color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              textAlign: TextAlign.center,
                              marginBottom: 15,
                            ),
                          ),
                        ),
                        ButtonWithGradient(
                          text: "tickets.watch_ad".tr(),
                          height: 45,
                          marginLeft: 29,
                          marginRight: 29,
                          marginTop: 35,
                          borderRadius: 60,
                          fontSize: 17,
                          activeBoxShadow: true,
                          setShadowToBottom: true,
                          blurRadius: 5,
                          spreadRadius: 0,
                          shadowColorOpacity: 0.4,
                          shadowColor: adsLoaded ? kSecondaryColor : kGrayColor,
                          fontWeight: FontWeight.w500,
                          textColor: Colors.white,
                          beginColor: adsLoaded ? kPrimaryColor : kGrayColor,
                          endColor: adsLoaded ? kSecondaryColor : kGrayColor,
                          onTap: ()=> adsLoaded ? showAds() : null,
                        ),
                        orBetweenLines(context),
                        ButtonWithGradient(
                          text: "in_app_purchases.purchase_ticket".tr().toUpperCase(),
                          height: 45,
                          marginLeft: 29,
                          marginRight: 29,
                          marginTop: 10,
                          borderRadius: 60,
                          marginBottom: 50,
                          fontSize: 17,
                          activeBoxShadow: true,
                          setShadowToBottom: true,
                          blurRadius: 5,
                          spreadRadius: 0,
                          shadowColorOpacity: 0.4,
                          shadowColor: kSecondaryColor,
                          fontWeight: FontWeight.w500,
                          textColor: Colors.white,
                          beginColor: kPrimaryColor,
                          endColor: kSecondaryColor,
                          onTap: ()=> _purchaseTickets(),
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
  }

  _purchaseTickets(){

    CoinsFlowPayment(
        context: context,
        currentUser: widget.currentUser!,
        showOnlyCoinsPurchase: true,
        onCoinsPurchased: (coins) {
          print("onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");

          setState(() {
            mCredits = widget.currentUser!.getCredits.toString();
          });
        });
  }

  Widget orBetweenLines(context) {
    return Container(
      margin: EdgeInsets.only(
        top: 30,
        right: 10,
        left: 10,
        bottom: 10,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: List.generate(3, (index) {
            return index == 1
                ? Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text("auth.o_r").tr(),
            )
                : ContainerCorner(
              marginTop: 10,
              borderWidth: 0.0,
              borderRadius: 8,
              height: 2,
              width: (MediaQuery.of(context).size.width / 3),
              color: kTicketGrayColor,
            );
          }),
        ),
      ),
    );
  }

  Container ticketFree({String? credits}) {
    double borderTopRight = 30.0;
    double borderTopLeft = 30.0;
    double borderBottomRight = 30.0;
    double borderBottomLeft = 30.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(borderTopRight),
            bottomRight: Radius.circular(borderBottomRight),
            topLeft: Radius.circular(borderTopLeft),
            bottomLeft: Radius.circular(borderBottomLeft)),
      ),
      height: 40,
      width: 125,
      margin: EdgeInsets.only(
        left: 50,
        right: 50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/svg/ticket_icon.svg"),
          SizedBox(width: 10),
          Text(
            credits!,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
