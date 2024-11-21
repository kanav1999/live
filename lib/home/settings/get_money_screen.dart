import 'package:blur/blur.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/live/live_preview_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/WithdrawModel.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:iban/iban.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

// ignore: must_be_immutable
class GetMoneyScreen extends StatefulWidget {
  static String route = "/menu/payout";

  UserModel? currentUser;

  GetMoneyScreen({this.currentUser});

  @override
  _GetMoneyScreenState createState() => _GetMoneyScreenState();
}

class _GetMoneyScreenState extends State<GetMoneyScreen> {
  double numberOfDiamonds = 0;
  double? totalMoney;
  double? minQuantityToWithdraw;
  double widthOfContainer = 350;

  TextEditingController payoonerEmailController = TextEditingController();
  TextEditingController moneyToTransferController = TextEditingController();
  TextEditingController ibanTextEditingController = TextEditingController();
  TextEditingController accountNameTextEditingController =
      TextEditingController();
  TextEditingController bankNameTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    numberOfDiamonds = widget.currentUser!.getDiamonds!.toDouble() *
        (widthOfContainer / Setup.diamondsNeededToRedeem);

    totalMoney =
        QuickHelp.convertDiamondsToMoney(widget.currentUser!.getDiamonds!);

    minQuantityToWithdraw =
        QuickHelp.convertDiamondsToMoney(Setup.diamondsNeededToRedeem);

    return ToolBar(
      backgroundColor: QuickHelp.isDarkMode(context)
          ? kContentColorLightTheme
          : Colors.white,
      title: "page_title.payout_title".tr(),
      centerTitle: QuickHelp.isAndroidPlatform() ? false : true,
      leftButtonIcon: Icons.arrow_back_ios,
      onLeftButtonTap: () =>
          QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
      rightButtonIcon: Icons.announcement_outlined,
      rightIconColor: kPrimaryColor,
      rightButtonPress: () => _showFaqsBottomSheet(),
      child: SafeArea(
        child: body(),
      ),
    );
  }

  Widget body() {
    final slider = SleekCircularSlider(
      min: 0,
      max: (Setup.diamondsNeededToRedeem.toDouble()),
      initialValue: widget.currentUser!.getDiamonds!.toDouble(),
      appearance: CircularSliderAppearance(
        size: 130.0,
        infoProperties: InfoProperties(),
        customColors: CustomSliderColors(
          trackColor: kPhotosGrayColor,
          hideShadow: true,
          progressBarColors: [kPrimaryColor, kSecondaryColor],
        ),
      ),
      innerWidget: (double value) {
        // use your custom widget inside the slider (gets a slider value from the callback)
        return Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextWithTap(
              "${(value * 100 / 5000).toStringAsPrecision(3)} %",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            TextWithTap(
              "get_money.completed_".tr(),
              color: Colors.white,
            ),
          ],
        ));
      },
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(alignment: AlignmentDirectional.center, children: [
                ContainerCorner(
                  height: 230,
                  borderRadius: 10,
                  marginLeft: 20,
                  marginRight: 20,
                  marginTop: 20,
                  width: Responsive.isWebOrDeskTop(context) ||
                          Responsive.isTablet(context)
                      ? 420
                      : null,
                  child: Blur(
                    blurColor: Colors.black,
                    colorOpacity: 0.1,
                    blur: 30,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    child: QuickActions.photosWidget(
                        widget.currentUser!.getAvatar!.url!),
                  ),
                ),
                ContainerCorner(
                  width: Responsive.isWebOrDeskTop(context) ||
                          Responsive.isTablet(context)
                      ? 420
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              "get_money.balance_".tr(),
                              color: kGrayColor,
                            ),
                            TextWithTap(
                              "\$ ${totalMoney!.toStringAsFixed(2)}",
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              marginTop: 10,
                              marginBottom: 30,
                            ),
                            TextWithTap(
                              "get_money.min_to_withdraw".tr(),
                              color: kGrayColor,
                              //fontSize: 12,
                            ),
                            TextWithTap(
                              "\$ ${minQuantityToWithdraw!.toStringAsFixed(2)}",
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: kPhotosGrayColor,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 30, top: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            slider,
                            TextWithTap(
                              widget.currentUser!.getFirstName!,
                              color: kGrayColor,
                              marginBottom: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              SizedBox(
                height: 250,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWithTap(
                    Setup.diamondsNeededToRedeem.toString(),
                    color: QuickHelp.isDarkMode(context)
                        ? Colors.white
                        : Colors.black,
                    fontSize: 15,
                  ),
                  SvgPicture.asset(
                    "assets/svg/ic_diamond.svg",
                    height: 28,
                  ),
                  TextWithTap(
                    "get_money.min_required".tr(),
                    color: QuickHelp.isDarkMode(context)
                        ? Colors.white
                        : Colors.black,
                    fontSize: 15,
                  )
                ],
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginTop: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWithTap("get_money.get_remain".tr()),
                    SvgPicture.asset(
                      "assets/svg/ic_diamond.svg",
                      height: 22,
                    ),
                    TextWithTap((Setup.diamondsNeededToRedeem -
                                widget.currentUser!.getDiamonds!) >
                            0
                        ? (Setup.diamondsNeededToRedeem -
                                widget.currentUser!.getDiamonds!)
                            .toString()
                        : "0"),
                  ],
                ),
              ),
              Visibility(
                visible: widget.currentUser!.getDiamonds! <
                    Setup.diamondsNeededToRedeem,
                child: ContainerCorner(
                  marginTop: 20,
                  width: Responsive.isWebOrDeskTop(context) ||
                          Responsive.isTablet(context)
                      ? 350
                      : null,
                  colors: [kSecondaryColor, kPrimaryColor],
                  setShadowToBottom: true,
                  shadowColor: QuickHelp.isDarkMode(context)
                      ? kContentColorGhostTheme
                      : kGrayColor,
                  borderRadius: 50,
                  marginRight: 40,
                  marginLeft: 40,
                  height: 50,
                  onTap: () {},
                  child: GestureDetector(
                    onTap: () => QuickHelp.goToNavigatorScreen(context,
                        LivePreviewScreen(currentUser: widget.currentUser!),
                        route: LivePreviewScreen.route),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_tab_live_selected.svg",
                          color: Colors.white,
                        ),
                        TextWithTap(
                          "get_money.go_live".tr().toUpperCase(),
                          color: Colors.white,
                          marginLeft: 10,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: widget.currentUser!.getDiamonds! >=
                    Setup.diamondsNeededToRedeem,
                child: ContainerCorner(
                  marginTop: 20,
                  colors: [kSecondaryColor, kPrimaryColor],
                  setShadowToBottom: true,
                  width: Responsive.isWebOrDeskTop(context) ||
                          Responsive.isTablet(context)
                      ? 350
                      : null,
                  shadowColor: kGrayColor,
                  borderRadius: 50,
                  marginRight: 40,
                  marginLeft: 40,
                  height: 50,
                  onTap: () {
                    if (widget.currentUser!.getPayEmail != null ||
                        widget.currentUser!.getIban != null) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/dolar_diamond.svg",
                                    height: 70,
                                    width: 70,
                                  ),
                                  TextWithTap(
                                    "get_money.how_much".tr(namedArgs: {
                                      "money": totalMoney.toString()
                                    }),
                                    textAlign: TextAlign.center,
                                    marginTop: 20,
                                  ),
                                  TextField(
                                    autocorrect: false,
                                    keyboardType: TextInputType.number,
                                    maxLines: null,
                                    controller: moneyToTransferController,
                                    decoration: InputDecoration(
                                      hintText: "get_money.transfer_".tr(),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                  Divider(
                                    color: kGrayColor,
                                  ),
                                  SizedBox(
                                    height: 35,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ContainerCorner(
                                        child: TextButton(
                                          child: TextWithTap(
                                            "cancel".tr().toUpperCase(),
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        color: kRedColor1,
                                        borderRadius: 10,
                                        marginLeft: 5,
                                        width: 125,
                                      ),
                                      ContainerCorner(
                                        child: TextButton(
                                          child: TextWithTap(
                                            "confirm_".tr().toUpperCase(),
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          onPressed: () {
                                            if (moneyToTransferController
                                                .text.isEmpty) {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/svg/sad.svg",
                                                            height: 70,
                                                            width: 70,
                                                          ),
                                                          TextWithTap(
                                                            "get_money.empty_field"
                                                                .tr(),
                                                            textAlign: TextAlign
                                                                .center,
                                                            color: Colors.red,
                                                            marginTop: 20,
                                                          ),
                                                          SizedBox(
                                                            height: 35,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "cancel"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                                color:
                                                                    kRedColor1,
                                                                borderRadius:
                                                                    10,
                                                                marginLeft: 5,
                                                                width: 125,
                                                              ),
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "get_money.try_again"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(),
                                                                ),
                                                                color:
                                                                    kGreenColor,
                                                                borderRadius:
                                                                    10,
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
                                            } else if (double.parse(
                                                    moneyToTransferController
                                                        .text) >
                                                double.parse(totalMoney!
                                                    .toStringAsFixed(0))) {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/svg/sad.svg",
                                                            height: 70,
                                                            width: 70,
                                                          ),
                                                          TextWithTap(
                                                            "get_money.not_enough"
                                                                .tr(namedArgs: {
                                                              "money": totalMoney!
                                                                  .toStringAsFixed(
                                                                      0)
                                                            }),
                                                            textAlign: TextAlign
                                                                .center,
                                                            color: Colors.red,
                                                            marginTop: 20,
                                                          ),
                                                          SizedBox(
                                                            height: 35,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "cancel"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                                color:
                                                                    kRedColor1,
                                                                borderRadius:
                                                                    10,
                                                                marginLeft: 5,
                                                                width: 125,
                                                              ),
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "get_money.try_again"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(),
                                                                ),
                                                                color:
                                                                    kGreenColor,
                                                                borderRadius:
                                                                    10,
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
                                            } else if (double.parse(
                                                    moneyToTransferController
                                                        .text) <
                                                minQuantityToWithdraw!) {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/svg/sad.svg",
                                                            height: 70,
                                                            width: 70,
                                                          ),
                                                          TextWithTap(
                                                            "get_money.less_quantity"
                                                                .tr(namedArgs: {
                                                              "amount":
                                                                  minQuantityToWithdraw
                                                                      .toString()
                                                            }),
                                                            textAlign: TextAlign
                                                                .center,
                                                            color: Colors.red,
                                                            marginTop: 20,
                                                          ),
                                                          SizedBox(
                                                            height: 35,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "cancel"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                ),
                                                                color:
                                                                    kRedColor1,
                                                                borderRadius:
                                                                    10,
                                                                marginLeft: 5,
                                                                width: 125,
                                                              ),
                                                              ContainerCorner(
                                                                child:
                                                                    TextButton(
                                                                  child:
                                                                      TextWithTap(
                                                                    "get_money.try_again"
                                                                        .tr()
                                                                        .toUpperCase(),
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(),
                                                                ),
                                                                color:
                                                                    kGreenColor,
                                                                borderRadius:
                                                                    10,
                                                                marginRight: 5,
                                                                marginLeft: 10,
                                                                width: 125,
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 20),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                            } else {
                                              _showListOfPaymentsMode();
                                            }
                                          },
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
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    "assets/svg/sad.svg",
                                    height: 70,
                                    width: 70,
                                  ),
                                  TextWithTap(
                                    "get_money.bank_account".tr(),
                                    textAlign: TextAlign.center,
                                    color: Colors.red,
                                    marginTop: 20,
                                  ),
                                  SizedBox(
                                    height: 35,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ContainerCorner(
                                        child: TextButton(
                                          child: TextWithTap(
                                            "cancel".tr().toUpperCase(),
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        color: kRedColor1,
                                        borderRadius: 10,
                                        marginLeft: 5,
                                        width: 125,
                                      ),
                                      ContainerCorner(
                                        child: TextButton(
                                          child: TextWithTap(
                                            "get_money.set_bank"
                                                .tr()
                                                .toUpperCase(),
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _showEditPaymentAccountsBottomSheet();
                                          },
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
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/dolar_diamond.svg",
                      ),
                      TextWithTap(
                        "get_money.widrawn_money".tr().toUpperCase(),
                        color: Colors.white,
                        marginLeft: 10,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
              TextWithTap(
                "get_money.edit_payment".tr().toUpperCase(),
                color: kPrimaryColor,
                marginTop: 60,
                onTap: () => _showEditPaymentAccountsBottomSheet(),
              ),
            ],
          )),
        ],
      ),
    );
  }

  withdrawMoney(double money, String email, String method) async {
    QuickHelp.showLoadingDialog(context);

    int diamonds = QuickHelp.convertMoneyToDiamonds(money).toInt();

    WithdrawModel withdraw = WithdrawModel();

    withdraw.setAuthor = widget.currentUser!;
    withdraw.setStatus = WithdrawModel.PENDING;
    withdraw.setEmail = email;

    withdraw.setCompleted = false;
    withdraw.setMethod = method;
    withdraw.setDiamonds = diamonds;
    withdraw.setCredit = money;
    withdraw.setCurrency = WithdrawModel.CURRENCY;

    if (method == WithdrawModel.IBAN) {
      withdraw.setIBAN = widget.currentUser!.getIban!;
      withdraw.setAccountName = widget.currentUser!.getAccountName!;
      withdraw.setBankName = widget.currentUser!.getBankName!;
    }

    widget.currentUser!.removeDiamonds = diamonds;
    await widget.currentUser!.save().then((value) async {
      ParseResponse response = await withdraw.save();

      if (response.success) {
        moneyToTransferController.clear();

        setState(() {
          widget.currentUser = value.results!.first! as UserModel;
        });
        QuickHelp.hideLoadingDialog(context, result: widget.currentUser);
        Navigator.of(context).pop(widget.currentUser);
      }
    });
  }

  _showFaqsBottomSheet() {
    return showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Color.fromRGBO(0, 0, 0, 0.001),
              child: GestureDetector(
                onTap: () {},
                child: DraggableScrollableSheet(
                  initialChildSize: 0.30,
                  minChildSize: 0.1,
                  maxChildSize: 1.0,
                  builder: (_, controller) {
                    return StatefulBuilder(builder: (context, setState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                          ),
                        ),
                        child: ContainerCorner(
                            color: Colors.white,
                            radiusTopRight: 30,
                            radiusTopLeft: 30,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                        onPressed: () =>
                                            QuickHelp.goBackToPreviousPage(
                                                context),
                                        icon: Icon(
                                          Icons.close,
                                          color: kGrayColor,
                                        )),
                                  ],
                                ),
                                ContainerCorner(
                                  color: kTransparentColor,
                                  marginLeft: 20,
                                  child: Column(
                                    children: [
                                      settingsOptions(
                                          "get_money.how_to_cash".tr(
                                              namedArgs: {
                                                "app_name": Setup.appName
                                              }),
                                          QuickHelp.pageTypeCashOut),
                                      Padding(
                                        padding: EdgeInsets.only(right: 20),
                                        child: Divider(
                                          color: kGrayColor,
                                        ),
                                      ),
                                      settingsOptions(
                                          "get_money.contact_support".tr(),
                                          QuickHelp.pageTypeSupport)
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      );
                    });
                  },
                ),
              ),
            ),
          );
        });
  }

  _showListOfPaymentsMode() {
    return showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Color.fromRGBO(0, 0, 0, 0.001),
              child: GestureDetector(
                onTap: () {},
                child: DraggableScrollableSheet(
                  initialChildSize: 0.40,
                  minChildSize: 0.1,
                  maxChildSize: 1.0,
                  builder: (_, controller) {
                    return StatefulBuilder(builder: (context, setState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                          ),
                        ),
                        child: Scaffold(
                            backgroundColor: kTransparentColor,
                            appBar: AppBar(
                              backgroundColor: kTransparentColor,
                              centerTitle: true,
                              title: TextWithTap(
                                "get_money.select_payment".tr(),
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            body: Column(
                              children: [
                                if (widget.currentUser!.getPayEmail != null)
                                  ContainerCorner(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        withdrawMoney(
                                            double.parse(
                                                moneyToTransferController.text),
                                            widget.currentUser!.getPayEmail!,
                                            WithdrawModel.PAYONEER);
                                      },
                                      child: Row(
                                        children: [
                                          ContainerCorner(
                                            height: 20,
                                            width: 20,
                                            borderRadius: 50,
                                            borderColor: kRedColor1,
                                          ),
                                          SvgPicture.asset(
                                            "assets/svg/Payoneer-Logo.wine.svg",
                                            height: 50,
                                            width: 50,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.currentUser!.getIban != null)
                                  ContainerCorner(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        withdrawMoney(
                                            double.parse(
                                                moneyToTransferController.text),
                                            "IBAN",
                                            WithdrawModel.IBAN);
                                      },
                                      child: Row(
                                        children: [
                                          ContainerCorner(
                                            height: 20,
                                            width: 20,
                                            borderRadius: 50,
                                            borderColor: kRedColor1,
                                          ),
                                          TextWithTap(
                                            "get_money.iban_"
                                                .tr()
                                                .toUpperCase(),
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            marginLeft: 10,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                Visibility(
                                  visible: widget.currentUser!.getIban ==
                                          null &&
                                      widget.currentUser!.getPayEmail == null,
                                  child: Column(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/svg/sad.svg",
                                        height: 70,
                                        width: 70,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showEditPaymentAccountsBottomSheet();
                                        },
                                        child: TextWithTap(
                                          "get_money.payment_account".tr(),
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      );
                    });
                  },
                ),
              ),
            ),
          );
        });
  }

  _showEditPaymentAccountsBottomSheet() {
    return showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Color.fromRGBO(0, 0, 0, 0.001),
              child: GestureDetector(
                onTap: () {},
                child: DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.1,
                  maxChildSize: 1.0,
                  builder: (_, controller) {
                    return StatefulBuilder(builder: (context, setState) {
                      return Container(
                          decoration: BoxDecoration(
                            color: QuickHelp.isDarkMode(context)
                                ? kContentColorLightTheme
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15.0),
                              topRight: Radius.circular(15.0),
                            ),
                          ),
                          child: ContainerCorner(
                              color: kTransparentColor,
                              child: Column(
                                children: [
                                  Center(
                                    child: ContainerCorner(
                                      color: kGrayColor,
                                      width: 40,
                                      height: 3,
                                      marginBottom: 20,
                                      marginTop: 5,
                                    ),
                                  ),
                                  Center(
                                      child: Column(
                                    children: [
                                      TextWithTap(
                                        "get_money.payment_account".tr(),
                                        color: QuickHelp.isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      ContainerCorner(
                                        color: kTransparentColor,
                                        borderColor: kGrayColor,
                                        height: 60,
                                        borderRadius: 10,
                                        marginLeft: 20,
                                        marginRight: 20,
                                        marginTop: 40,
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SvgPicture.asset(
                                                        "assets/svg/Payoneer-Logo.wine.svg",
                                                        height: 70,
                                                        width: 70,
                                                      ),
                                                      TextWithTap(
                                                        "get_money.payoneer_email"
                                                            .tr(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        marginTop: 20,
                                                      ),
                                                      SizedBox(
                                                        height: 25,
                                                      ),
                                                      TextField(
                                                        autocorrect: false,
                                                        keyboardType:
                                                            TextInputType
                                                                .multiline,
                                                        maxLines: null,
                                                        controller:
                                                            payoonerEmailController,
                                                        decoration:
                                                            InputDecoration(
                                                          hintText: widget
                                                                      .currentUser!
                                                                      .getPayEmail !=
                                                                  null
                                                              ? widget
                                                                  .currentUser!
                                                                  .getPayEmail
                                                              : "get_money.your_email"
                                                                  .tr(),
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                      ),
                                                      Divider(
                                                        color: kGrayColor,
                                                      ),
                                                      SizedBox(
                                                        height: 35,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          ContainerCorner(
                                                            child: TextButton(
                                                              child:
                                                                  TextWithTap(
                                                                "cancel"
                                                                    .tr()
                                                                    .toUpperCase(),
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                            color: kRedColor1,
                                                            borderRadius: 10,
                                                            marginLeft: 5,
                                                            width: 125,
                                                          ),
                                                          ContainerCorner(
                                                            child: TextButton(
                                                              child:
                                                                  TextWithTap(
                                                                "get_money.connect_"
                                                                    .tr()
                                                                    .toUpperCase(),
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                              onPressed: () {
                                                                if (payoonerEmailController
                                                                    .text
                                                                    .isEmpty) {
                                                                  showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        return AlertDialog(
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
                                                                              TextWithTap(
                                                                                "get_money.empty_email".tr(),
                                                                                textAlign: TextAlign.center,
                                                                                color: Colors.red,
                                                                                marginTop: 20,
                                                                              ),
                                                                              SizedBox(
                                                                                height: 35,
                                                                              ),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  ContainerCorner(
                                                                                    child: TextButton(
                                                                                      child: TextWithTap(
                                                                                        "cancel".tr().toUpperCase(),
                                                                                        color: Colors.white,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontSize: 14,
                                                                                      ),
                                                                                      onPressed: () {
                                                                                        Navigator.of(context).pop();
                                                                                        Navigator.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                    color: kRedColor1,
                                                                                    borderRadius: 10,
                                                                                    marginLeft: 5,
                                                                                    width: 125,
                                                                                  ),
                                                                                  ContainerCorner(
                                                                                    child: TextButton(
                                                                                      child: TextWithTap(
                                                                                        "get_money.try_again".tr().toUpperCase(),
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
                                                                } else {
                                                                  checkEmailAndSave(
                                                                      payoonerEmailController
                                                                          .text,
                                                                      "payoneer");
                                                                }
                                                              },
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
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/svg/Payoneer-Logo.wine.svg",
                                              height: 40,
                                              width: 40,
                                            ),
                                            TextWithTap(
                                              widget.currentUser!.getPayEmail !=
                                                      null
                                                  ? "get_money.connected_".tr()
                                                  : "get_money.off_".tr(),
                                              color: kGrayColor,
                                              marginRight: 10,
                                            )
                                          ],
                                        ),
                                      ),
                                      ContainerCorner(
                                        color: kTransparentColor,
                                        borderColor: kGrayColor,
                                        height: 60,
                                        borderRadius: 10,
                                        marginLeft: 20,
                                        marginRight: 20,
                                        marginTop: 40,
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.money,
                                                          color: Colors
                                                              .greenAccent,
                                                        ),
                                                        TextWithTap(
                                                          "get_money.insert_iban"
                                                              .tr(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          marginTop: 20,
                                                        ),
                                                        SizedBox(
                                                          height: 25,
                                                        ),
                                                        TextField(
                                                          autocorrect: false,
                                                          keyboardType:
                                                              TextInputType
                                                                  .multiline,
                                                          maxLines: null,
                                                          controller:
                                                              accountNameTextEditingController,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: widget.currentUser!
                                                                        .getAccountName !=
                                                                    null
                                                                ? widget
                                                                    .currentUser!
                                                                    .getAccountName
                                                                : "get_money.type_account_name"
                                                                    .tr(),
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: kGrayColor,
                                                        ),
                                                        TextField(
                                                          autocorrect: false,
                                                          keyboardType:
                                                              TextInputType
                                                                  .multiline,
                                                          maxLines: null,
                                                          controller:
                                                              bankNameTextEditingController,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: widget.currentUser!
                                                                        .getBankName !=
                                                                    null
                                                                ? widget
                                                                    .currentUser!
                                                                    .getBankName
                                                                : "get_money.type_bank_name"
                                                                    .tr(),
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: kGrayColor,
                                                        ),
                                                        TextField(
                                                          autocorrect: false,
                                                          keyboardType:
                                                              TextInputType
                                                                  .multiline,
                                                          maxLines: null,
                                                          controller:
                                                              ibanTextEditingController,
                                                          decoration:
                                                              InputDecoration(
                                                            hintText: widget.currentUser!.getIban !=
                                                                    null
                                                                ? widget
                                                                    .currentUser!
                                                                    .getIban
                                                                : "get_money.type_iban"
                                                                    .tr(),
                                                            border: InputBorder
                                                                .none,
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: kGrayColor,
                                                        ),
                                                        SizedBox(
                                                          height: 35,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            ContainerCorner(
                                                              child: TextButton(
                                                                child:
                                                                    TextWithTap(
                                                                  "cancel"
                                                                      .tr()
                                                                      .toUpperCase(),
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                              ),
                                                              color: kRedColor1,
                                                              borderRadius: 10,
                                                              marginLeft: 5,
                                                              width: 125,
                                                            ),
                                                            ContainerCorner(
                                                              child: TextButton(
                                                                child:
                                                                    TextWithTap(
                                                                  "get_money.connect_"
                                                                      .tr()
                                                                      .toUpperCase(),
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                                onPressed: () {
                                                                  if (ibanTextEditingController.text.isEmpty ||
                                                                      bankNameTextEditingController
                                                                          .text
                                                                          .isEmpty ||
                                                                      accountNameTextEditingController
                                                                          .text
                                                                          .isEmpty) {
                                                                    showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                context) {
                                                                          return AlertDialog(
                                                                            content:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                SvgPicture.asset(
                                                                                  "assets/svg/sad.svg",
                                                                                  height: 70,
                                                                                  width: 70,
                                                                                ),
                                                                                TextWithTap(
                                                                                  "get_money.empty_iban".tr(),
                                                                                  textAlign: TextAlign.center,
                                                                                  color: Colors.red,
                                                                                  marginTop: 20,
                                                                                ),
                                                                                SizedBox(
                                                                                  height: 35,
                                                                                ),
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    ContainerCorner(
                                                                                      child: TextButton(
                                                                                        child: TextWithTap(
                                                                                          "cancel".tr().toUpperCase(),
                                                                                          color: Colors.white,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontSize: 14,
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          Navigator.of(context).pop();
                                                                                          Navigator.of(context).pop();
                                                                                        },
                                                                                      ),
                                                                                      color: kRedColor1,
                                                                                      borderRadius: 10,
                                                                                      marginLeft: 5,
                                                                                      width: 125,
                                                                                    ),
                                                                                    ContainerCorner(
                                                                                      child: TextButton(
                                                                                        child: TextWithTap(
                                                                                          "get_money.try_again".tr().toUpperCase(),
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
                                                                  } else {
                                                                    checkIbanAndSave(
                                                                        ibanTextEditingController
                                                                            .text,
                                                                        accountNameTextEditingController
                                                                            .text,
                                                                        bankNameTextEditingController
                                                                            .text);
                                                                  }
                                                                },
                                                              ),
                                                              color:
                                                                  kGreenColor,
                                                              borderRadius: 10,
                                                              marginRight: 5,
                                                              width: 125,
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 20),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              });
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextWithTap(
                                              "get_money.iban_"
                                                  .tr()
                                                  .toUpperCase(),
                                              color:
                                                  QuickHelp.isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black,
                                              marginRight: 20,
                                              fontWeight: FontWeight.w700,
                                              marginLeft: 20,
                                              fontSize: 20,
                                            ),
                                            TextWithTap(
                                              widget.currentUser!.getIban !=
                                                      null
                                                  ? "get_money.connected_".tr()
                                                  : "get_money.off_".tr(),
                                              color: kGrayColor,
                                              marginRight: 10,
                                            )
                                          ],
                                        ),
                                      ),
                                      TextWithTap(
                                        "get_money.Instructions_"
                                            .tr()
                                            .toUpperCase(),
                                        color: kPrimaryColor,
                                        marginTop: 40,
                                        onTap: () {
                                          QuickHelp.goToWebPage(context,
                                              pageType: QuickHelp
                                                  .pageTypeInstructions,
                                              pageUrl: "");
                                        },
                                      ),
                                    ],
                                  )),
                                ],
                              )));
                    });
                  },
                ),
              ),
            ),
          );
        });
  }

  bool _validateEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  checkEmailAndSave(String email, String type) {
    if (_validateEmail(email)) {
      createPayoneerEmail(email);
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "assets/svg/sad.svg",
                    height: 70,
                    width: 70,
                  ),
                  TextWithTap(
                    "account_settings.invalid_email".tr(),
                    textAlign: TextAlign.center,
                    color: Colors.red,
                    marginTop: 20,
                  ),
                  SizedBox(
                    height: 35,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ContainerCorner(
                        child: TextButton(
                          child: TextWithTap(
                            "cancel".tr().toUpperCase(),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                        color: kRedColor1,
                        borderRadius: 10,
                        marginLeft: 5,
                        width: 125,
                      ),
                      ContainerCorner(
                        child: TextButton(
                          child: TextWithTap(
                            "get_money.try_again".tr().toUpperCase(),
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
    }
  }

  checkIbanAndSave(String iban, String accountName, String bankName) {
    if (isValid(iban)) {
      createIban(iban, accountName, bankName);
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "assets/svg/sad.svg",
                    height: 70,
                    width: 70,
                  ),
                  TextWithTap(
                    "get_money.invalid_iban".tr(),
                    textAlign: TextAlign.center,
                    color: Colors.red,
                    marginTop: 20,
                  ),
                  SizedBox(
                    height: 35,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ContainerCorner(
                        child: TextButton(
                          child: TextWithTap(
                            "cancel".tr().toUpperCase(),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                        color: kRedColor1,
                        borderRadius: 10,
                        marginLeft: 5,
                        width: 125,
                      ),
                      ContainerCorner(
                        child: TextButton(
                          child: TextWithTap(
                            "get_money.try_again".tr().toUpperCase(),
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
    }
  }

  void createIban(String iban, String accountName, String bankName) async {
    QuickHelp.showLoadingDialog(context);

    widget.currentUser!.setIban = iban;
    widget.currentUser!.setAccountName = accountName;
    widget.currentUser!.setBankName = bankName;

    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      widget.currentUser = response.results!.first! as UserModel;

      QuickHelp.hideLoadingDialog(context);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  void createPayoneerEmail(String email) async {
    QuickHelp.showLoadingDialog(context);

    widget.currentUser!.setPayEmail = email;

    ParseResponse response = await widget.currentUser!.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Widget settingsOptions(String text, String route) {
    return ContainerCorner(
      color: kTransparentColor,
      height: 60,
      child: TextButton(
          onPressed: () {
            QuickHelp.goToWebPage(context, pageType: route, pageUrl: "");
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWithTap(
                text,
                color: Colors.black,
              ),
              Icon(
                Icons.arrow_forward,
                color: kPrimaryColor,
              )
            ],
          )),
    );
  }
}
