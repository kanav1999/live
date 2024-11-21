import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/app/config.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../helpers/quick_cloud.dart';
import '../../models/PaymentsModel.dart';


// ignore: must_be_immutable
class CoinsScreen extends StatefulWidget {

  UserModel? currentUser;

  CoinsScreen({this.currentUser});

  @override
  _CoinsScreenState createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  List<ProductDetails> _products = [];
  InAppPurchaseModel? _inAppPurchaseModel;

  List<String> _kProductIds = <String>[
    Config.credit200,
    Config.credit1000,
    Config.credit100,
    Config.credit500,
    Config.credit2000,
    Config.credit5000,
    Config.credit10000,
  ];

  List<InAppPurchaseModel> getInAppList() {
    List<InAppPurchaseModel> inAppPurchaseList = [];

    for (ProductDetails productDetails in _products) {

      if (productDetails.id == Config.credit200) {
        InAppPurchaseModel credits200 = InAppPurchaseModel(
            id: Config.credit200,
            coins: 200,
            price: productDetails.price,
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typePopular,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit200)) {
          inAppPurchaseList.add(credits200);
        }
      }

      if (productDetails.id == Config.credit1000) {
        InAppPurchaseModel credits1000 = InAppPurchaseModel(
            id: Config.credit1000,
            coins: 1000,
            price: productDetails.price,
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeHot,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit1000)) {
          inAppPurchaseList.add(credits1000);
        }
      }

      if (productDetails.id == Config.credit100) {
        InAppPurchaseModel credits100 = InAppPurchaseModel(
            id: Config.credit100,
            coins: 100,
            price: productDetails.price,
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit100)) {
          inAppPurchaseList.add(credits100);
        }
      }

      if (productDetails.id == Config.credit500) {
        InAppPurchaseModel credits500 = InAppPurchaseModel(
            id: Config.credit500,
            coins: 500,
            price: productDetails.price,
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit500)) {
          inAppPurchaseList.add(credits500);
        }
      }

      if (productDetails.id == Config.credit2000) {
        InAppPurchaseModel credits2100 = InAppPurchaseModel(
            id: Config.credit2000,
            coins: 2100,
            price: productDetails.price,
            discount: "22,09",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit2000)) {
          inAppPurchaseList.add(credits2100);
        }
      }

      if (productDetails.id == Config.credit5000) {
        InAppPurchaseModel credits5250 = InAppPurchaseModel(
            id: Config.credit5000,
            coins: 5250,
            price: productDetails.price,
            discount: "57,79",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit5000)) {
          inAppPurchaseList.add(credits5250);
        }
      }

      if (productDetails.id == Config.credit10000) {
        InAppPurchaseModel credits10500 = InAppPurchaseModel(
            id: Config.credit10000,
            coins: 10500,
            price: productDetails.price,
            discount: "110,29",
            image: "assets/images/ticket-star.png",
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.credit10000)) {
          inAppPurchaseList.add(credits10500);
        }
      }
    }

    return inAppPurchaseList;
  }

  void getUser() async{
    widget.currentUser = await ParseUser.currentUser();
  }

  @override
  void dispose() {
    if (QuickHelp.isIOSPlatform()) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
      print("InAppPurchase initState: $error");
    });
    getUser();
    initStoreInfo();
    super.initState();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (QuickHelp.isIOSPlatform()) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(IOSPaymentQueueDelegate());
    }

    ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _purchasePending = false;
      _loading = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();

      } else {

        if (purchaseDetails.status == PurchaseStatus.canceled) {

          QuickHelp.hideLoadingDialog(context);


          QuickHelp.showAppNotificationAdvanced(
            context:context,
              user: widget.currentUser,
              title: "in_app_purchases.purchase_cancelled_title".tr(),
              message: "in_app_purchases.purchase_cancelled".tr(),
          );

        } else if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);

        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _addPurchaseToUserAccount(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  _purchaseProduct(ProductDetails productDetails) async{

    if(QuickHelp.isAndroidPlatform()){
      QuickHelp.showLoadingDialog(context);
    }

    _inAppPurchase.buyConsumable(purchaseParam: PurchaseParam(productDetails: productDetails), autoConsume: true)
    .onError((error, stackTrace) {
      print("InAppPurchase error: $error");

      if (error is PlatformException && error.code == "storekit_duplicate_product_object") {
        QuickHelp.showAppNotification( context:context, title: "in_app_purchases.purchase_pending_error".tr(),);
      }
      return false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    //return Future<bool>.value(true);

    ParseResponse response = await QuickCloudCode.verifyPayment(
        productSku: purchaseDetails.productID,
        purchaseToken: purchaseDetails.verificationData.serverVerificationData);
    if(response.success){
      return Future<bool>.value(true);
    } else {
      return Future<bool>.value(false);
    }
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
    QuickHelp.showAppNotification(context:context, title: "in_app_purchases.invalid_purchase".tr());
    QuickHelp.hideLoadingDialog(context);
  }

  _addPurchaseToUserAccount(PurchaseDetails purchaseDetails) async {
    print("InAppPurchase addToUser: ${purchaseDetails.productID}");

    _inAppPurchase.completePurchase(purchaseDetails);

    if (QuickHelp.isAndroidPlatform()) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
      _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      await androidAddition.consumePurchase(purchaseDetails);
    }

    if(widget.currentUser != null){

      widget.currentUser?.addCredit = _inAppPurchaseModel!.coins!;
      ParseResponse parseResponse = await widget.currentUser!.save();
      if(parseResponse.success){
        widget.currentUser = parseResponse.results!.first as UserModel;
        //context.read<CountersProvider>().updateCredit(widget.currentUser!);

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(context:context,
          user: widget.currentUser,
          title: "in_app_purchases.coins_purchased".tr(namedArgs: {"coins" : _inAppPurchaseModel!.coins!.toString()}),
          message: "in_app_purchases.coins_added_to_account".tr(),
          isError: false,
        );

        registerPayment(purchaseDetails, _inAppPurchaseModel!.productDetails!);
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotification(context:context, title: parseResponse.error!.message);
      }

    } else {

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotification(context:context, title: "in_app_purchases.error_found".tr());
    }
  }

  void registerPayment(PurchaseDetails purchaseDetails, ProductDetails productDetails) async {

    // Save all payment information
    PaymentsModel paymentsModel = PaymentsModel();
    paymentsModel.setAuthor = widget.currentUser!;
    paymentsModel.setAuthorId = widget.currentUser!.objectId!;
    paymentsModel.setPaymentType = PaymentsModel.paymentTypeConsumible;

    paymentsModel.setId = productDetails.id;
    paymentsModel.setTitle = productDetails.title;
    paymentsModel.setTransactionId = purchaseDetails.purchaseID!;
    paymentsModel.setCurrency = productDetails.currencyCode.toUpperCase();
    paymentsModel.setPrice = productDetails.price;
    paymentsModel.setMethod = QuickHelp.isAndroidPlatform()? "Google Play" : QuickHelp.isIOSPlatform() ? "App Store" : "";
    paymentsModel.setStatus = PaymentsModel.paymentStatusCompleted;

    await paymentsModel.save();
  }

  void handleError(IAPError error) {

    QuickHelp.hideLoadingDialog(context);
    QuickHelp.showAppNotification(context:context, title: error.message);

    setState(() {
      _purchasePending = false;
    });
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
    if (_purchasePending) {}

    if (_loading) {
      return QuickHelp.appLoading();
    } else if (_isAvailable && _products.isNotEmpty) {
      if (_queryProductError == null) {
        //return Text("Products list: ${_products.length}");
        return getProductList();
      } else {
        return QuickActions.noContentFound("in_app_purchases.error_found".tr(),
            _queryProductError!, "assets/svg/ticket_icon.svg");
      }
    } else {
      return QuickActions.noContentFound(
          "in_app_purchases.no_product_found_title".tr(),
          "in_app_purchases.no_product_found_explain".tr(),
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
                  _inAppPurchaseModel = inApp;
                  _purchaseProduct(inApp.getProductDetails()!);
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
                                        inApp.price!,
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


class IOSPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {

    print("InAppPurchase: $transaction");
    return true;
  }

  @override
  bool shouldShowPriceConsent() {

    print("InAppPurchase: shouldShowPriceConsent");
    return false;
  }
}
