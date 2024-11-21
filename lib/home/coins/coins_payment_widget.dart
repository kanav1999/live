import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/coins/coins_screen.dart';
import 'package:heyto/models/GiftsModel.dart';
import 'package:heyto/models/PaymentsModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../app/config.dart';
import '../../helpers/quick_cloud.dart';

class CoinsFlowPayment{

  CoinsFlowPayment({required BuildContext context, required UserModel currentUser, Function(GiftsModel giftsModel)? onGiftSelected, Function(int coins)? onCoinsPurchased,  bool isDismissible = true, bool enableDrag = true, bool isScrollControlled = true, bool showOnlyCoinsPurchase = false, Color backgroundColor = Colors.transparent}) {

    showModalBottomSheet(
        context: (context),
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        enableDrag: enableDrag,
        isDismissible: isDismissible,
        builder: (context) {
          return _CoinsFlowWidget(
            currentUser: currentUser,
            onCoinsPurchased: onCoinsPurchased,
            onGiftSelected: onGiftSelected,
            showOnlyCoinsPurchase : showOnlyCoinsPurchase,
          );
        });
  }
}

// ignore: must_be_immutable
class _CoinsFlowWidget extends StatefulWidget {
  final Function? onCoinsPurchased;
  final Function? onGiftSelected;
  final bool? showOnlyCoinsPurchase;
  UserModel currentUser;

  _CoinsFlowWidget({
    required this.currentUser,
    this.onCoinsPurchased,
    this.onGiftSelected,
    this.showOnlyCoinsPurchase = false,
  });

  @override
  State<_CoinsFlowWidget> createState() => _CoinsFlowWidgetState();
}

class _CoinsFlowWidgetState extends State<_CoinsFlowWidget> with TickerProviderStateMixin {

  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;
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
            coins: 2000,
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
            coins: 5000,
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
            coins: 10000,
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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController.unbounded(vsync: this);

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
  Widget build(BuildContext context) {
    return _showGiftAndGetCoinsBottomSheet();
    //return getBody();
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

    widget.currentUser.addCredit = _inAppPurchaseModel!.coins!;
    ParseResponse parseResponse = await widget.currentUser.save();
    if(parseResponse.success){

      UserModel user = parseResponse.results!.first as UserModel;
      widget.currentUser = user;

      QuickHelp.hideLoadingDialog(context);

      QuickHelp.showAppNotificationAdvanced(context:context,
        user: widget.currentUser,
        title: "in_app_purchases.coins_purchased".tr(namedArgs: {"coins" : _inAppPurchaseModel!.coins!.toString()}),
        message: "in_app_purchases.coins_added_to_account".tr(),
        isError: false,
      );

      if(widget.onCoinsPurchased != null){

        if(widget.showOnlyCoinsPurchase!){
          QuickHelp.hideLoadingDialog(context);
        } else {
          setState(() {
            bottomSheetCurrentIndex = 0;
          });
        }
        widget.onCoinsPurchased!(_inAppPurchaseModel!.coins) as void Function()?;
      }

      registerPayment(purchaseDetails, _inAppPurchaseModel!.productDetails!);

    } else {

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotification(context:context, title: "in_app_purchases.error_found".tr());
    }
  }

  void registerPayment(PurchaseDetails purchaseDetails, ProductDetails productDetails) async {

    // Save all payment information
    PaymentsModel paymentsModel = PaymentsModel();
    paymentsModel.setAuthor = widget.currentUser;
    paymentsModel.setAuthorId = widget.currentUser.objectId!;
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

  Widget _showGiftAndGetCoinsBottomSheet() {
    return GestureDetector(
      onTap: () => QuickHelp.hideLoadingDialog(context),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(25.0),
                      topRight: const Radius.circular(25.0),
                    ),
                  ),
                  child: ContainerCorner(
                    color: kTransparentColor,
                    child: IndexedStack(
                      index: widget.showOnlyCoinsPurchase! ? 1 : bottomSheetCurrentIndex,
                      children: [
                        Scaffold(
                          backgroundColor: kTransparentColor,
                          appBar: AppBar(
                            actions: [
                              ContainerCorner(
                                height: 30,
                                borderRadius: 50,
                                marginRight: 10,
                                marginTop: 10,
                                marginBottom: 10,
                                color: kWarninngColor,
                                onTap: () {
                                  setState(() {
                                    bottomSheetCurrentIndex = 1;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: SvgPicture.asset(
                                        "assets/svg/coin.svg",
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                    TextWithTap(
                                      "message_screen.get_coins".tr().toUpperCase(),
                                      marginRight: 10,
                                    )
                                  ],
                                ),
                              )
                            ],
                            backgroundColor: kTransparentColor,
                            centerTitle: true,
                            title: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/ticket_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                                TextWithTap(
                                  widget.currentUser.getCredits.toString(),
                                  color: Colors.white,
                                  fontSize: 16,
                                  marginLeft: 5,
                                )
                              ],
                            ),
                          ),
                          body: SingleChildScrollView(
                            child: Column(
                              children: [
                                ContainerCorner(
                                    color: kTransparentColor,
                                    child: _tabSection(context, setState)),
                              ],
                            ),
                          ),
                        ),
                        Scaffold(
                          backgroundColor: kTransparentColor,
                          appBar: AppBar(
                            actions: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/ic_coin_with_star.svg",
                                    width: 20,
                                    height: 20,
                                  ),
                                  TextWithTap(
                                    widget.currentUser.getCredits.toString(),
                                    color: Colors.white,
                                    marginLeft: 5,
                                    marginRight: 15,
                                  )
                                ],
                              ),
                            ],
                            backgroundColor: kTransparentColor,
                            title: TextWithTap(
                              "message_screen.get_coins".tr(),
                              marginRight: 10,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            centerTitle: true,
                            automaticallyImplyLeading: false,
                            leading: BackButton(
                              onPressed: () {
                                if(widget.showOnlyCoinsPurchase!){
                                  QuickHelp.hideLoadingDialog(context);
                                } else {
                                  setState(() {
                                    bottomSheetCurrentIndex = 0;
                                  });
                                }
                              },
                            ),
                          ),
                          body: getBody(),
                        )],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _tabSection(BuildContext context, StateSetter stateSetter) {
    return DefaultTabController(
      length: 9,
      child: Column(
        children: [
          Container(
            child: TabBar(
                isScrollable: true,
                enableFeedback: false,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelColor: Colors.white,
                indicatorColor: kTransparentColor,
                indicatorWeight: 0.005,
                tabs: [
                  gefTab("gift_tabs.tab_classic".tr(),
                      "assets/images/ic_gift_tab_classic.png"),
                  gefTab("gift_tabs.tab_3D".tr(),
                      "assets/images/ic_gift_tab_3b.png"),
                  gefTab("gift_tabs.tab_vip".tr(),
                      "assets/images/ic_gift_tab_vip.png"),
                  gefTab("gift_tabs.tab_love".tr(),
                      "assets/images/ic_gift_tab_love.png"),
                  gefTab("gift_tabs.tab_moods".tr(),
                      "assets/images/ic_gift_tab_moods.png"),
                  gefTab("gift_tabs.tab_artists".tr(),
                      "assets/images/ic_gift_tab_artist.png"),
                  gefTab("gift_tabs.tab_collectibles".tr(),
                      "assets/images/ic_gift_tab_collectibles.png"),
                  gefTab("gift_tabs.tab_games".tr(),
                      "assets/images/ic_gift_tab_games.png"),
                  gefTab("gift_tabs.tab_family".tr(),
                      "assets/images/ic_gift_tab_family.png"),
                ]),
          ),
          Container(
            //Add this to give height
            height: MediaQuery.of(context).size.height,
            child: TabBarView(children: [
              getGifts(GiftsModel.giftCategoryTypeClassic, stateSetter),
              getGifts(GiftsModel.giftCategoryType3D, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeVIP, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeLove, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeMoods, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeArtists, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeCollectibles, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeGames, stateSetter),
              getGifts(GiftsModel.giftCategoryTypeFamily, stateSetter),
            ]),
          ),
        ],
      ),
    );
  }

  Widget getGifts(String category, StateSetter setState) {
    QueryBuilder<GiftsModel> giftQuery = QueryBuilder<GiftsModel>(GiftsModel());
    giftQuery.whereValueExists(GiftsModel.keyGiftCategories, true);
    giftQuery.whereEqualTo(GiftsModel.keyGiftCategories, category);

    return ContainerCorner(
      color: kTransparentColor,
      child: ParseLiveGridWidget<GiftsModel>(
        query: giftQuery,
        crossAxisCount: 4,
        reverse: false,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        lazyLoading: false,
        //childAspectRatio: 1.0,
        shrinkWrap: true,
        listenOnAllSubItems: true,
        duration: Duration(seconds: 0),
        animationController: _animationController,
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<GiftsModel> snapshot) {
          GiftsModel gift = snapshot.loadedData!;
          return GestureDetector(
            onTap: () => _checkCredits(gift, setState),
            child: Column(
              children: [
                Lottie.network(gift.getFile!.url!,
                    width: 60, height: 60, animate: true, repeat: true),
                ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_coin_with_star.svg",
                        width: 18,
                        height: 18,
                      ),
                      TextWithTap(
                        gift.getTickets.toString(),
                        color: Colors.white,
                        fontSize: 14,
                        marginLeft: 5,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        queryEmptyElement: Padding(
          padding: EdgeInsets.all(8.0),
          child: QuickActions.noContentFound(
              "in_app_purchases.no_gift_title".tr(),
              "in_app_purchases.no_gift_explain".tr(),
              "assets/svg/ic_menu_gifters.svg",
              color: null,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center),
        ),
        gridLoadingElement: Container(
          margin: EdgeInsets.only(top: 50),
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Tab gefTab(String name, String image) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            image,
            color: Colors.white.withOpacity(0.7),
            width: 20,
            height: 20,
          ),
          TextWithTap(
            name,
            fontSize: 12,
            marginTop: 5,
          ),
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

        return ContainerCorner(
          color: kTransparentColor,
          marginLeft: 5,
          marginRight: 5,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.6,
            children: List.generate(getInAppList().length, (index) {
              InAppPurchaseModel inApp = getInAppList()[index];

              return GestureDetector(
                onTap: () {
                  _inAppPurchaseModel = inApp;
                  _purchaseProduct(inApp.getProductDetails()!);
                },
                child: Stack(
                  children: [
                    ContainerCorner(
                        //width: (size.width - 15) / 2,
                        borderColor: Colors.black.withOpacity(0.1),
                        height: 260,
                        borderRadius: 10,
                        borderWidth: 2,
                        color: Colors.black.withOpacity(0.5),
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
                                              width: 17,
                                              height: 17,
                                              color: Colors.amber ,
                                            ),
                                          ),
                                          TextWithTap(
                                            inApp.coins.toString(),
                                            marginLeft: 10,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      radiusTopLeft: 10,
                                      radiusTopRight: 10,
                                      //borderColor: Colors.amber,
                                      marginTop: 8,
                                    ),
                                    ContainerCorner(
                                      height: 50,
                                      width: 60,
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
                                      color: Colors.amber,
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
                                        marginTop: 38,
                                        radiusBottomRight: 10,
                                        radiusBottomLeft: 10,
                                        width: MediaQuery.of(context).size.width / 2,
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: TextWithTap(
                                            'coins.popular_'.tr(),
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (inApp.type == InAppPurchaseModel.typeHot)
                                      ContainerCorner(
                                        marginTop: 46,
                                        radiusBottomRight: 10,
                                        radiusBottomLeft: 10,
                                        width: MediaQuery.of(context).size.width / 2,
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: TextWithTap(
                                            'coins.hot_'.tr(),
                                            color: Colors.white,
                                            fontSize: 16,
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
              );
            },
            ),
          ),
        );
        //return getProductList();
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

  _checkCredits(GiftsModel gift, StateSetter setState){

    if (widget.currentUser.getCredits! >= gift.getTickets!) {

      if(widget.onGiftSelected != null){
        widget.onGiftSelected!(gift) as void Function()?;
        QuickHelp.hideLoadingDialog(context);
      }

    } else {
      setState(() {
        bottomSheetCurrentIndex = 1;
      });
    }
  }
}
