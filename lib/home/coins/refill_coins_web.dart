import 'package:heyto/app/setup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/app/config.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import '../../models/PaymentsModel.dart';

// ignore: must_be_immutable
class CoinsWebPage extends StatefulWidget {

  UserModel? currentUser;

  CoinsWebPage({this.currentUser});

  @override
  _CoinsWebPageState createState() => _CoinsWebPageState();
}

class _CoinsWebPageState extends State<CoinsWebPage> {

  List<InAppPurchaseModel> getInAppList() {
    List<InAppPurchaseModel> inAppPurchaseList = [];

        InAppPurchaseModel credits200 = InAppPurchaseModel(
            id: Config.credit200,
            coins: 200,
            price: Config.credit200Amount.toString(),
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typePopular,

            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);



        InAppPurchaseModel credits1000 = InAppPurchaseModel(
            id: Config.credit1000,
            coins: 1000,
            price: Config.credit1000Amount.toString(),
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeHot,

            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);



        InAppPurchaseModel credits100 = InAppPurchaseModel(
            id: Config.credit100,
            coins: 100,
            price: Config.credit100Amount.toString(),
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);


        InAppPurchaseModel credits500 = InAppPurchaseModel(
            id: Config.credit500,
            coins: 500,
            price: Config.credit500Amount.toString(),
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);

        InAppPurchaseModel credits2000 = InAppPurchaseModel(
            id: Config.credit2000,
            coins: 2100,
            price: Config.credit2000Amount.toString(),
            discount: "22,09",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);

        InAppPurchaseModel credits5000 = InAppPurchaseModel(
            id: Config.credit5000,
            coins: 5250,
            price: Config.credit5000Amount.toString(),
            discount: "57,79",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);


        InAppPurchaseModel credits10000 = InAppPurchaseModel(
            id: Config.credit10000,
            coins: 10500,
            price: Config.credit1000Amount.toString(),
            discount: "110,29",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            currency: Config.primaryCurrencyCode,
            currencySymbol: Config.primaryCurrencySymbol);


    inAppPurchaseList.add(credits100);
    inAppPurchaseList.add(credits200);
    inAppPurchaseList.add(credits500);
    inAppPurchaseList.add(credits1000);
    inAppPurchaseList.add(credits2000);
    inAppPurchaseList.add(credits5000);
    inAppPurchaseList.add(credits10000);


    return inAppPurchaseList;
  }

  void getUser() async{
    widget.currentUser = await ParseUser.currentUser();
  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  void initState() {

    super.initState();
  }



  _purchaseProduct(InAppPurchaseModel productDetails) async{

  }

  void registerPayment(InAppPurchaseModel productDetails) async {

    // Save all payment information
    PaymentsModel paymentsModel = PaymentsModel();
    paymentsModel.setAuthor = widget.currentUser!;
    paymentsModel.setAuthorId = widget.currentUser!.objectId!;
    paymentsModel.setPaymentType = PaymentsModel.paymentTypeConsumible;

    paymentsModel.setId = QuickHelp.generateUId().toString();
    paymentsModel.setTitle = productDetails.id.toString();
    paymentsModel.setTransactionId = QuickHelp.generateUId().toString();
    paymentsModel.setCurrency = productDetails.currency!.toUpperCase();
    paymentsModel.setPrice = productDetails.price!;
    paymentsModel.setMethod = "Credit Card";
    paymentsModel.setStatus = PaymentsModel.paymentStatusCompleted;

    await paymentsModel.save();
  }


  showPendingUI() {

    QuickHelp.showLoadingDialog(context);
    print("InAppPurchase showPendingUI");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      QuickHelp.isDarkMode(context) ? kContentColorGhostTheme : kGreyColor0,
      body: Column(
        children: [
          Expanded(child: getBody()),
        ],
      ),
    );
  }

  Widget getBody() {

    if (Setup.isStripePaymentsEnabled || Setup.isPayPalPaymentsEnabled) {
      return getProductList();
    } else {
      return QuickActions.noContentFound(
          "in_app_purchases.no_payment_found_title".tr(),
          "in_app_purchases.no_payment_found_explain".tr(),
          "assets/svg/ticket_icon.svg");
    }
  }

  Widget getProductList() {
    var size = MediaQuery.of(context).size;

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 100),
      children: [
        SizedBox(
          height: 3,
        ),
        Padding(
          padding: EdgeInsets.only(left: 5.0, right: 5),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(getInAppList().length, (index) {
              InAppPurchaseModel inApp = getInAppList()[index];

              return GestureDetector(
                onTap: () {
                  _purchaseProduct(inApp);
                },
                child: Container(
                  padding: EdgeInsets.all(0.8),
                  width: (size.width - 15) / 2,
                  height: 260,
                  child: Stack(
                    children: [
                      Container(
                        width: (size.width - 15) / 2,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      ContainerCorner(
                          width: (size.width - 15) / 2,
                          borderColor: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
                          height: 260,
                          borderRadius: 10,
                          borderWidth: 2,
                          color: QuickHelp.isDarkMode(context)
                              ? kContentColorLightTheme
                              : kContentColorDarkTheme,
                          child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                Positioned(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ContainerCorner(
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            ContainerCorner(
                                              child: SvgPicture.asset(
                                                "assets/svg/ticket_icon.svg",
                                                width: 20,
                                                height: 20,
                                                color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black ,
                                              ),
                                            ),
                                            TextWithTap(
                                              inApp.coins.toString(),
                                              marginLeft: 10,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              //color: kCoinsDark,
                                            ),
                                          ],
                                        ),
                                        radiusTopLeft: 10,
                                        radiusTopRight: 10,
                                        //borderColor: Colors.amber,
                                        marginTop: 15,
                                      ),
                                      ContainerCorner(
                                        height: 80,
                                        width: 80,
                                        color: kTransparentColor,
                                        marginTop: 20,
                                        marginBottom: index < 2 ? 3 : 10,
                                        child: Image.asset(inApp.image!, width: 50, height: 50,),
                                      ),
                                      TextWithTap(
                                        inApp.price!+inApp.currencySymbol.toString(),
                                        marginTop: inApp.type == InAppPurchaseModel.typePopular || inApp.type == InAppPurchaseModel.typeHot
                                            ? 2
                                            : 20,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        //color: kCoinsDark,
                                      ),
                                      inApp.discount != null
                                          ? TextWithTap(
                                        "${inApp.currencySymbol} ${inApp.discount}",
                                        marginTop: 2,
                                        color: kGrayColor,
                                        fontSize: 16,
                                        decoration:
                                        TextDecoration.lineThrough,
                                      )
                                          : Container(),
                                      if (inApp.type == InAppPurchaseModel.typePopular)
                                        ContainerCorner(
                                          marginTop: 33,
                                          radiusBottomRight: 10,
                                          radiusBottomLeft: 10,
                                          width: MediaQuery.of(context).size.width / 2,
                                          colors: [kSecondaryColor, kPrimaryColor],
                                          child: Center(
                                            child: TextWithTap(
                                              'coins.popular_'.tr(),
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (inApp.type == InAppPurchaseModel.typeHot)
                                        ContainerCorner(
                                          marginTop: 40,
                                          radiusBottomRight: 10,
                                          radiusBottomLeft: 10,
                                          width: MediaQuery.of(context).size.width / 2,
                                          colors: [kPrimaryColor, kSecondaryColor],
                                          child: Center(
                                            child: TextWithTap(
                                              'coins.hot_'.tr(),
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ]))
                    ],
                  ),
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}
