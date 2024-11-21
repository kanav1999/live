import 'package:heyto/app/navigation_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/GiftsModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import '../../app/config.dart';

class CoinsFlowPaymentWeb{

  CoinsFlowPaymentWeb({required BuildContext context, required UserModel currentUser, Function(GiftsModel giftsModel)? onGiftSelected, Function(int coins)? onCoinsPurchased,  bool isDismissible = true, bool enableDrag = true, bool isScrollControlled = true, bool showOnlyCoinsPurchase = false, Color backgroundColor = Colors.transparent}) {

    showModalBottomSheet(
        context: (context),
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor,
        enableDrag: enableDrag,
        isDismissible: isDismissible,
        builder: (context) {
          return CoinsFlowWidget(
            currentUser: currentUser,
            onCoinsPurchased: onCoinsPurchased,
            onGiftSelected: onGiftSelected,
            showOnlyCoinsPurchase : showOnlyCoinsPurchase,
          );
        });
  }
}

// ignore: must_be_immutable
class CoinsFlowWidget extends StatefulWidget {
  final Function? onCoinsPurchased;
  final Function? onGiftSelected;
  final bool? showOnlyCoinsPurchase;
  UserModel currentUser;

  CoinsFlowWidget({
    required this.currentUser,
    this.onCoinsPurchased,
    this.onGiftSelected,
    this.showOnlyCoinsPurchase = false,
  });

  @override
  State<CoinsFlowWidget> createState() => _CoinsFlowWidgetState();
}

class _CoinsFlowWidgetState extends State<CoinsFlowWidget> with TickerProviderStateMixin {

  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;

  bool _isAvailable = true;
  bool _purchasePending = false;
  bool _loading = false;
  String? _queryProductError;

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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController.unbounded(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return _showGiftAndGetCoinsBottomSheet();
    //return getBody();
  }

  Widget _showGiftAndGetCoinsBottomSheet() {
    return GestureDetector(
      onTap: () => QuickHelp.hideLoadingDialog(context),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
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
                            automaticallyImplyLeading: false,
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

  Widget checkoutForm() {
    return Scaffold(
      backgroundColor: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
      appBar: AppBar(
        backgroundColor: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: TextWithTap(
          "tickets.pay_card".tr(),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ContainerCorner(
                borderRadius: 5,
                borderWidth: 1,
                borderColor: kGrayColor,
                width: 100,
                height: 60,
                child: Center(
                  child: SvgPicture.asset("assets/svg/master_card.svg",
                    height: 50,
                    width: 50,
                  ),
                ),
              ),
              ContainerCorner(
                borderRadius: 5,
                borderWidth: 1,
                borderColor: kGrayColor,
                width: 100,
                height: 60,
                child: Center(
                  child: SvgPicture.asset(
                    "assets/svg/visa-seeklogo.com.svg",
                    height: 20,
                    width: 20,
                  ),
                ),
              ),
            ],
          )
        ],
      ),

    );
  }

  Widget getBody() {
    if (_purchasePending) {}

    if (_loading) {
      return QuickHelp.appLoading();
    } else if (_isAvailable) {
      //if (_queryProductError == null) {//Use this
        if (!_loading) {

        return ContainerCorner(
          color: kTransparentColor,
          marginLeft: 5,
          marginRight: 5,
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
            children: List.generate(getInAppList().length, (index) {
              InAppPurchaseModel inApp = getInAppList()[index];

              return GestureDetector(
                onTap: () {

                  QuickHelp.hideLoadingDialog(context);

                  Future.delayed(Duration(milliseconds: 200), (){
                    QuickActions.initPaymentForm(
                      context: NavigationService.navigatorKey.currentState!.context,
                      inAppPurchaseModel: inApp,
                      currentUser: widget.currentUser,
                    );
                  });
                },
                child: Stack(
                  children: [
                    ContainerCorner(
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
                                              width: 15,
                                              height: 15,
                                              color: Colors.amber ,
                                            ),
                                          ),
                                          TextWithTap(
                                            inApp.coins.toString(),
                                            marginLeft: 10,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                      radiusTopLeft: 10,
                                      radiusTopRight: 10,
                                      //borderColor: Colors.amber,
                                      marginTop: 4,
                                    ),
                                    ContainerCorner(
                                      height: 45,
                                      width: 55,
                                      color: kTransparentColor,
                                      marginTop: 10,
                                      marginBottom: index < 2 ? 3 : 10,
                                      child: Image.asset(inApp.image!, width: 45, height: 45,),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextWithTap("${inApp.currencySymbol}",
                                          color: Colors.amber,
                                          marginTop: inApp.type == InAppPurchaseModel.typePopular || inApp.type == InAppPurchaseModel.typeHot
                                              ? 2
                                              : 10,
                                          fontSize: 17,
                                        ),
                                        TextWithTap(
                                          inApp.price!,
                                          marginTop: inApp.type == InAppPurchaseModel.typePopular || inApp.type == InAppPurchaseModel.typeHot
                                              ? 2
                                              : 10,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.amber,
                                        ),
                                      ],
                                    ),
                                    inApp.discount != null
                                        ? TextWithTap(
                                      "${inApp.currencySymbol} ${inApp.discount}",
                                      marginTop: 2,
                                      color: kGrayColor,
                                      fontSize: 14,
                                      decoration:
                                      TextDecoration.lineThrough,
                                    )
                                        : Container(),
                                    if (inApp.type == InAppPurchaseModel.typePopular)
                                      ContainerCorner(
                                        marginTop: 41,
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
                                        marginTop: 34,
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
                                      ),
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
