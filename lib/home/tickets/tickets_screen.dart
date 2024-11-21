import 'dart:async';

import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/tickets/tickets_ads_screen.dart';
import 'package:heyto/home/tickets/wave.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/payment_slider_model.dart';
import 'package:heyto/ui/app_bar_center_logo.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../../app/config.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_cloud.dart';
import '../../models/PaymentsModel.dart';
import '../../models/others/in_app_model.dart';

// ignore: must_be_immutable
class TicketsScreen extends StatefulWidget {
  static String route = '/tickets';

  UserModel? currentUser;
  TicketsScreen({this.currentUser});

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {

  final CarouselController _controller = CarouselController();
  int _current = 0;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;
  List<ProductDetails> _products = [];
  InAppPurchaseModel? _inAppPurchaseModel;

  List<String> _kProductIds = <String>[
    Config.subs1Month,
    Config.subs3Months,
  ];

  List<InAppPurchaseModel> getInAppList() {
    List<InAppPurchaseModel> inAppPurchaseList = [];

    for (ProductDetails productDetails in _products) {

      if (productDetails.id == Config.subs1Month) {
        InAppPurchaseModel subs1Month = InAppPurchaseModel(
            id: Config.subs1Month,
            period: QuickHelp.getUntilDateFromDays(30),
            price: productDetails.price,
            type: InAppPurchaseModel.typeNormal,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.subs1Month)) {
          inAppPurchaseList.add(subs1Month);
        }
      }

      if (productDetails.id == Config.subs3Months) {
        InAppPurchaseModel subs3Months = InAppPurchaseModel(
            id: Config.subs3Months,
            period: QuickHelp.getUntilDateFromDays(90),
            price: productDetails.price,
            type: InAppPurchaseModel.typePopular,
            productDetails: productDetails,
            currency: productDetails.currencyCode,
            currencySymbol: productDetails.currencySymbol);

        if (!inAppPurchaseList.contains(Config.subs3Months)) {
          inAppPurchaseList.add(subs3Months);
        }
      }
    }

    return inAppPurchaseList;
  }

  @override
  void dispose() {
    _disposePayment();
    super.dispose();
  }

  _disposePayment(){
    if (QuickHelp.isIOSPlatform()) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
  }

  @override
  void initState() {
    _initPayment();
    super.initState();
  }

  _initPayment(){
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
    //getUser();
    initStoreInfo();
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

      widget.currentUser?.setPremium = _inAppPurchaseModel!.getPeriod()!;

      ParseResponse parseResponse = await widget.currentUser!.save();
      if(parseResponse.success){
        widget.currentUser = parseResponse.results!.first as UserModel;
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(context:context,
          user: widget.currentUser,
          title: "in_app_purchases.subs_purchased".tr(),
          message: "in_app_purchases.subs_added_to_account".tr(),
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
    paymentsModel.setPaymentType = PaymentsModel.paymentTypeSubscription;

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

    return ToolBarCenterLogo(
      logoName: "ic_logo_stars.png",
      logoHeight: 38,
      leftButtonWidget: IconButton(
        onPressed: ()=> QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
        icon: SvgPicture.asset("assets/svg/close_round.svg", color: kGrayColor,),
      ),
      extendBodyBehindAppBar: true,
      iconHeight: 30,
      iconWidth: 30,
      backGroundColor: kTransparentColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    child: Stack(
                      children: [
                        ClipPath(
                          clipper: WaveClipper(),
                          child: Container(
                            padding: EdgeInsets.only(
                              top: 15,
                            ),
                            height: 200,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: AssetImage(
                                    "assets/images/tickets_photo_bg.png"),
                              ),
                            ),
                          ),
                        ),
                        ClipPath(
                          clipper: WaveClipper(),
                          child: Container(
                            padding: EdgeInsets.only(
                              top: 15,
                            ),
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: MediaQuery.of(context).size.width / 2 - 80,
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10,
                                ),
                                Image.asset(
                                  initPremiumSlider()[_current].badgeImage!,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        sliders(),
                        ticketStep(context, _current, initPremiumSlider().length),
                        getBody(),
                        termsAndPrivacyMobile(),
                        Divider(),
                        TextWithTap(
                          _current == 2
                              ? "tickets.ticket_inventory".tr()
                              : "tickets.ticket_assets".tr(),
                          fontSize: 18, fontWeight: FontWeight.bold,
                          marginTop: 10,
                          marginBottom: 10,
                        ),
                        ticketFree(credits: widget.currentUser!.getCredits.toString()),
                        ButtonWithGradient(
                          text: _current == 0
                              ? "tickets.add_more_tickets".tr()
                              : "tickets.increase_tickets".tr(),
                          onTap: () async {
                            _disposePayment();

                            UserModel? result = await QuickHelp.goToNavigatorScreenForResult(context, TicketsAdsScreen(currentUser: widget.currentUser ), route: TicketsAdsScreen.route);

                            if(result != null){
                              _initPayment();
                            }

                          },
                          height: 45,
                          marginLeft: 29,
                          marginRight: 29,
                          marginTop: 35,
                          marginBottom: 10,
                          borderRadius: 60,
                          fontSize: 17,
                          activeBoxShadow: true,
                          setShadowToBottom: true,
                          blurRadius: 5,
                          spreadRadius: 0,
                          shadowColorOpacity: 0.5,
                          shadowColor: kSecondaryColor,
                          fontWeight: FontWeight.w500,
                          textColor: Colors.white,
                          beginColor: kPrimaryColor,
                          endColor: kSecondaryColor,
                        ),
                        Text(
                          "tickets.do_not_have_to_pay".tr(),
                          style: TextStyle(
                            color: kTicketGrayColor,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  termsAndPrivacyMobile({Color? color}){

    return ContainerCorner(
      child: Column(
        children: [
          TextWithTap("in_app_purchases.debit_auth_cancel_any_time".tr(),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            marginBottom: 5,
            marginTop: 10,
          ),
          TextWithTap("in_app_purchases.debit_auth_eula".tr(namedArgs: {"store" : QuickHelp.isAndroidPlatform() ? "Google Play" : QuickHelp.isIOSPlatform()? "iTunes" : "Credit card"}),
            marginBottom: 5,
            textAlign: TextAlign.center,
            color: color,
            fontSize: 11,
          ),
          RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                    style: TextStyle(
                        color: color != null? color : QuickHelp.isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    text: "auth.privacy_policy".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        QuickHelp.goToWebPage(context,
                            pageType: QuickHelp.pageTypePrivacy,
                            pageUrl: Config.privacyPolicyUrl);
                      }),
                TextSpan(
                    style: TextStyle(
                        color: color != null? color : QuickHelp.isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12),
                    text: "and_".tr()),
                TextSpan(
                    style: TextStyle(
                        color: color != null? color : QuickHelp.isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    text: "auth.terms_of_use".tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        QuickHelp.goToWebPage(context,
                            pageType: QuickHelp.pageTypeTerms,
                            pageUrl: Config.termsOfUseUrl);
                      }),
              ])),
        ],
      ),
      width: 350,
      marginBottom: 10,
    );
  }

  Widget sliders() {
    return CarouselSlider.builder(
        options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 1,
            aspectRatio: 7,
            autoPlayCurve: Curves.linearToEaseOut,
            onPageChanged: (index, reason){
              setState(() {
                _current = index;
              });
            }
        ),
        carouselController: _controller,
        itemCount: initPremiumSlider().length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {

          return Column(
            children: [
             /* Image.asset(
                initPremiumSlider()[_current].badgeImage!,
              ),*/
              TextWithTap(
                initPremiumSlider()[itemIndex].title!,
                fontSize: 18, fontWeight: FontWeight.bold,
                //marginTop: 20,
              ),
              Text(
                initPremiumSlider()[itemIndex].explain!,
                style: TextStyle(
                  color: kTicketGrayColor,
                ),
              ),
            ],
          );
        });
  }

  List<PaymentSliderModel> initPremiumSlider() {
    List<PaymentSliderModel> paymentSliderModelList = [];

    PaymentSliderModel sliderModel1 = PaymentSliderModel();
    sliderModel1.setBadgeImage("assets/images/ticket_llikes.png");
    sliderModel1.setTitle("tickets.unlimited_likes".tr());
    sliderModel1.setExplain("tickets.send_likes_as_you_want".tr());

    PaymentSliderModel sliderModel2 = PaymentSliderModel();
    sliderModel2.setBadgeImage("assets/images/ticket_love.png");
    sliderModel2.setTitle("tickets.who_loves_you".tr());
    sliderModel2.setExplain("tickets.see_who_likes_you".tr());

    PaymentSliderModel sliderModel3 = PaymentSliderModel();
    sliderModel3.setBadgeImage("assets/images/ticket_say.png");
    sliderModel3.setTitle("tickets.say_hey_more".tr());
    sliderModel3.setExplain("tickets.send_up_to_5".tr());

    paymentSliderModelList.add(sliderModel1);
    paymentSliderModelList.add(sliderModel2);
    paymentSliderModelList.add(sliderModel3);

    return paymentSliderModelList;
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
      height: 49,
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
                color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget ticketStep(context, int step, int numberOfSteps) {
    return Container(
      margin: EdgeInsets.only(
        top: 5,
        right: 10,
        left: 10,
        bottom: 20,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: List.generate(numberOfSteps, (index) {
            return GestureDetector(
              onTap: () {},
              child: ContainerCorner(
                borderRadius: 8,
                height: 8,
                width: 8,
                color: index == step ? kPrimaryColor : kGrayColor,
              ),
            );
          }),
        ),
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
        return tiketCards(context);
      } else {
        return QuickActions.noContentFound("in_app_purchases.error_found".tr(),
            _queryProductError!, "assets/svg/ticket_icon.svg");
      }
    } else {
      return QuickActions.noContentFound(
          "in_app_purchases.no_product_found_title".tr(),
          "",//"in_app_purchases.no_product_found_explain".tr(),
          "assets/svg/ticket_icon.svg");
    }
  }

  Widget tiketCards(context) {
    return Container(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 15.0, // gap between adjacent chips
          //runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: List.generate(getInAppList().length, (index) {

            InAppPurchaseModel inApp = getInAppList()[index];
            return ContainerCorner(
                borderWidth: 0.0,
                shadowColor: kPhotosGrayColorReverse.withOpacity(0.7),
                setShadowToBottom: true,
                borderRadius: 10,
                height: 160,
                width: 150,
                spreadRadius: 0,
                blurRadius: 20,
                color: QuickHelp.isDarkModeNoContext()
                    ? kContentColorLightTheme
                    : kContentColorDarkTheme,
                onTap: () {
                  _inAppPurchaseModel = inApp;
                  _purchaseProduct(inApp.getProductDetails()!);
                },
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
                        width: (MediaQuery.of(context).size.width / 2) - 15,
                        color: index == 0 ? kTicketGrayColor : kTicketBlueColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/svg/ticket_icon.svg", width: 20, height: 20,),
                            SizedBox(width: 10),
                            Text(
                              inApp.price!,
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
      ),
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
