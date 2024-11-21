import 'package:cached_network_image/cached_network_image.dart';
import 'package:heyto/app/config.dart';
import 'package:heyto/helpers/quick_cloud.dart';
import 'package:heyto/home/message/message_screen.dart';
import 'package:heyto/home/profile/user_profile_details_screen.dart';
import 'package:heyto/models/PaymentsModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/others/in_app_model.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/utils/formaters/CardMonthInputFormatter.dart';
import 'package:heyto/widgets/AvatarInitials.dart';
import 'package:heyto/widgets/cardPayment/payment_card.dart';
import 'package:heyto/widgets/need_resume.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../app/colors.dart';

class QuickActions {
  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static TextEditingController emailTextEditingController =
      TextEditingController();
  static TextEditingController cardNumberTextEditingController =
      TextEditingController();
  static TextEditingController cvcTextEditingController =
      TextEditingController();
  static TextEditingController fullNameTextEditingController =
      TextEditingController();
  static TextEditingController expTextEditingController =
      TextEditingController();

  static Widget avatarWidget(UserModel currentUser,
      {double? width, double? height, EdgeInsets? margin, String? imageUrl}) {
    if (currentUser.getAvatar != null) {
      return Container(
        margin: margin,
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: currentUser.getAvatar!.url!,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          placeholder: (context, url) => _avatarInitials(currentUser),
          errorWidget: (context, url, error) => _avatarInitials(currentUser),
        ),
      );
    } else if (imageUrl != null) {
      return Container(
        margin: margin,
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          //placeholder: (context, url) => _avatarInitials(currentUser),
          //errorWidget: (context, url, error) => _avatarInitials(currentUser),
        ),
      );
    } else {
      return _avatarInitials(currentUser);
    }
  }

  static Widget _avatarInitials(UserModel currentUser) {
    return AvatarInitials(
      name: '${currentUser.getFirstName}',
      textSize: 18,
      avatarRadius: 10,
      backgroundColor:
          QuickHelp.isDarkModeNoContext() ? Colors.white : kPrimaryColor,
      textColor: QuickHelp.isDarkModeNoContext()
          ? kContentColorLightTheme
          : kContentColorDarkTheme,
    );
  }

  static Widget photosWidget(String imageUrl,
      {double? borderRadius = 8, BoxFit? fit = BoxFit.cover}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          //shape: BoxShape.circle,
          borderRadius: BorderRadius.circular(borderRadius!),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, url) => _loadingWidget(),
      errorWidget: (context, url, error) => _loadingWidget(),
    );
  }

  static Widget avatarBorder(
    UserModel user, {
    Function? onTap,
    double? width,
    double? height,
    EdgeInsets? avatarMargin,
    EdgeInsets? borderMargin,
    Color? borderColor = kPrimacyGrayColor,
    double? borderWidth = 1,
  }) {
    return GestureDetector(
      onTap: () => onTap as Function(),
      child: Center(
        child: Container(
          width: width,
          //160,
          height: height,
          //160,
          margin: borderMargin,
          //EdgeInsets.only(top: 10, bottom: 20, left: 30, right: 30),
          decoration: BoxDecoration(
            border: Border.all(
              width: borderWidth!,
              color: borderColor!,
            ),
            shape: BoxShape.circle,
          ),
          child: QuickActions.avatarWidget(user,
              width: width, height: height, margin: avatarMargin),
        ),
      ),
    );
  }

  static Widget photosWidgetCircle(String imageUrl,
      {double? borderRadius = 8,
      BoxFit? fit = BoxFit.cover,
      double? width,
      double? height,
      EdgeInsets? margin,
      BoxShape? boxShape = BoxShape.rectangle,
      Widget? errorWidget}) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            shape: boxShape!,
            //borderRadius: BorderRadius.circular(borderRadius!),
            image: DecorationImage(image: imageProvider, fit: fit),
          ),
        ),
        placeholder: (context, url) => _loadingWidget(),
        errorWidget: (context, url, error) => _loadingWidget(),
      ),
    );
  }

  static Widget gifWidget(String imageUrl,
      {double? borderRadius = 8, BoxFit? fit = BoxFit.cover}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          //shape: BoxShape.circle,
          borderRadius: BorderRadius.circular(borderRadius!),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, url) => FadeShimmer(
        height: 80,
        width: 80,
        fadeTheme:
            QuickHelp.isDarkMode(context) ? FadeTheme.dark : FadeTheme.light,
        millisecondsDelay: 0,
      ),
      errorWidget: (context, url, error) => FadeShimmer(
        height: 80,
        width: 80,
        fadeTheme:
            QuickHelp.isDarkMode(context) ? FadeTheme.dark : FadeTheme.light,
        millisecondsDelay: 0,
      ),
    );
  }

  static Widget noContentFound(
    String title,
    String explain,
    String image, {
    MainAxisAlignment? mainAxisAlignment = MainAxisAlignment.center,
    CrossAxisAlignment? crossAxisAlignment = CrossAxisAlignment.center,
    Color? color = kGrayColor,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment!,
      crossAxisAlignment: crossAxisAlignment!,
      children: [
        Visibility(
          visible: image.isNotEmpty,
          child: ContainerCorner(
            height: 91,
            width: 91,
            marginBottom: 20,
            color: kTransparentColor,
            child: SvgPicture.asset(
              image,
              color: color,
            ),
          ),
        ),
        Visibility(
          visible: title.isNotEmpty,
          child: TextWithTap(
            title,
            marginBottom: 0,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        Visibility(
          visible: explain.isNotEmpty,
          child: TextWithTap(
            explain,
            marginBottom: 17,
            marginRight: 10,
            marginLeft: 10,
            marginTop: 5,
            fontSize: 18,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
            color: kGreyColor1,
          ),
        )
      ],
    );
  }

  static Widget _loadingWidget() {
    return Center(child: CircularProgressIndicator());
  }

  static showUserProfile(BuildContext context, UserModel mUser,
      {ResumableState? resumeState, UserModel? currentUser}) {
    QuickHelp.goToNavigatorScreen(
      context,
      UserProfileDetailsScreen(
        currentUser: currentUser,
        mUser: mUser,
        showComponents: true,
      ),
      route: UserProfileDetailsScreen.route,
    );
  }

  static addPhotos(BuildContext context, UserModel currentUser) {
    print("addPhotos");
  }

  static verifyPhoto(BuildContext context, UserModel currentUser) {
    print("verifyPhoto");
  }

  static sendMessage(
      BuildContext context, UserModel? currentUser, UserModel? mUser) {
    QuickHelp.goToNavigatorScreen(
      context,
      MessageScreen(
        currentUser: currentUser,
        mUser: mUser,
      ),
      route: MessageScreen.route,
    );

    /*QuickHelp.goToNavigator(context, MessageScreen.route, arguments: {
      "currentUser": currentUser,
      "mUser": mUser,
    });*/
  }

  static initPaymentForm({
    required BuildContext context,
    required InAppPurchaseModel inAppPurchaseModel,
    required UserModel currentUser,
  }) async {
    String? _validateFullName(String value) {
      int firstSpace = value.indexOf(" ");

      if (value.isEmpty) {
        return "auth.no_full_name".tr();
      } else if (firstSpace < 1) {
        return "auth.full_name_please".tr();
      } else if (fullNameTextEditingController.text.endsWith(" ")) {
        return "auth.full_name_please".tr();
      } else {
        return null;
      }
    }

    String? _validateEmail(String value) {
      if (value.isEmpty) {
        return "auth.no_email".tr();
      } else if (!QuickHelp.isValidEmail(value)) {
        return "auth.invalid_email".tr();
      } else {
        return null;
      }
    }

    int _value = 0;
    String? sourceSelected = null;

    emailTextEditingController.text =
        currentUser.getPayEmail != null ? currentUser.getPayEmail! : "";
    fullNameTextEditingController.text =
        currentUser.getFullName != null ? currentUser.getFullName! : "";

    QueryBuilder<UserModel> query =
        QueryBuilder<UserModel>(UserModel.forQuery());
    query.includeObject([UserModel.keyPaymentSource]);
    query.whereEqualTo(UserModel.keyObjectId, currentUser.objectId);

    ParseResponse response = await query.query();

    if (response.success && response.results != null) {
      currentUser = response.results!.first as UserModel;

      if (currentUser.getPaymentSources!.length > 0) {
        sourceSelected = currentUser.getPaymentSources![0].getId;
      }
    }
    ;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : Colors.white,
              contentPadding: EdgeInsets.all(5.0),
              title: TextWithTap(
                "tickets.pay_card".tr(),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    QuickHelp.isDarkMode(context) ? Colors.white : Colors.black,
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 10,
                      width: 500,
                    ),
                    TextWithTap(
                      "email_".tr(),
                      textAlign: TextAlign.center,
                      marginTop: 20,
                      marginLeft: 15,
                    ),
                    ContainerCorner(
                      borderColor: kGrayColor,
                      borderRadius: 5,
                      marginLeft: 15,
                      marginRight: 15,
                      marginBottom: 10,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: TextFormField(
                          autocorrect: false,
                          maxLines: null,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            return _validateEmail(value!);
                          },
                          controller: emailTextEditingController,
                          decoration: InputDecoration(
                            hintText: "email_".tr(),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    if (sourceSelected != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWithTap(
                            "tickets.saved_cards".tr(),
                            textAlign: TextAlign.center,
                            marginTop: 20,
                            marginLeft: 15,
                            marginBottom: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: DropdownButton(
                              dropdownColor: QuickHelp.isDarkMode(context)
                                  ? kContentColorLightTheme
                                  : Colors.white,
                              value: _value,
                              items: List.generate(
                                  currentUser.getPaymentSources!.length,
                                  (index) {
                                return DropdownMenuItem(
                                    value: index,
                                    child: Row(
                                      children: [
                                        if (currentUser
                                                .getPaymentSources![index]
                                                .getBrand! ==
                                            "Visa")
                                          ContainerCorner(
                                            borderRadius: 5,
                                            borderWidth: 1,
                                            marginRight: 5,
                                            marginTop: 7,
                                            marginBottom: 7,
                                            borderColor: kGrayColor,
                                            width: 55,
                                            height: 33,
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 2, right: 2),
                                                child: SvgPicture.asset(
                                                  "assets/svg/visa-seeklogo.com.svg",
                                                  width: 34,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (currentUser
                                                .getPaymentSources![index]
                                                .getBrand! ==
                                            "MasterCard")
                                          ContainerCorner(
                                            borderRadius: 5,
                                            borderWidth: 1,
                                            marginRight: 5,
                                            marginTop: 7,
                                            marginBottom: 7,
                                            borderColor: kGrayColor,
                                            width: 55,
                                            height: 33,
                                            child: Center(
                                              child: SvgPicture.asset(
                                                "assets/svg/master_card.svg",
                                                width: 30,
                                              ),
                                            ),
                                          ),
                                        TextWithTap(
                                          currentUser.getPaymentSources![index]
                                              .getBrand!,
                                          marginRight: 5,
                                          marginLeft: 5,
                                        ),
                                        TextWithTap(
                                          "tickets.ending_in".tr(),
                                          marginRight: 5,
                                          marginLeft: 5,
                                        ),
                                        TextWithTap(currentUser
                                            .getPaymentSources![index]
                                            .getLastDigits!),
                                        TextWithTap(
                                          "tickets.expires_in".tr(),
                                          marginLeft: 25,
                                          marginRight: 5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        TextWithTap(currentUser
                                                    .getPaymentSources![index]
                                                    .getExpMonth! <
                                                10
                                            ? "0${currentUser.getPaymentSources![index].getExpMonth}"
                                            : currentUser
                                                .getPaymentSources![index]
                                                .getExpMonth
                                                .toString()),
                                        TextWithTap(
                                            "/${currentUser.getPaymentSources![index].getExpYear}"),
                                      ],
                                    ));
                              }),
                              onChanged: (int? value) {
                                setState(() {
                                  _value = value!;
                                  sourceSelected = currentUser
                                      .getPaymentSources![value].getId;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    if (sourceSelected != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              sourceSelected = null;
                            });
                          },
                          child: TextWithTap("tickets.add_card".tr()),
                        ),
                      ),
                    if (sourceSelected == null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWithTap(
                            "tickets.card_data".tr(),
                            textAlign: TextAlign.center,
                            marginTop: 20,
                            marginLeft: 15,
                            marginBottom: 5,
                          ),
                          ContainerCorner(
                            borderColor: kGrayColor,
                            radiusTopRight: 10,
                            radiusTopLeft: 10,
                            marginLeft: 15,
                            marginRight: 15,
                            width: 480,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      autocorrect: false,
                                      keyboardType: TextInputType.number,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      maxLines: 1,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        new LengthLimitingTextInputFormatter(
                                            19),
                                        new CardNumberInputFormatter()
                                      ],
                                      controller:
                                          cardNumberTextEditingController,
                                      validator: (value) {
                                        return CardUtils.validateCardNum(value);
                                      },
                                      decoration: InputDecoration(
                                        hintText: "1234 1234 1234 1234".tr(),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ContainerCorner(
                                        borderRadius: 5,
                                        borderWidth: 1,
                                        marginRight: 5,
                                        marginTop: 7,
                                        marginBottom: 7,
                                        borderColor: kGrayColor,
                                        width: 55,
                                        height: 33,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            "assets/svg/master_card.svg",
                                            width: 30,
                                          ),
                                        ),
                                      ),
                                      ContainerCorner(
                                        borderRadius: 5,
                                        borderWidth: 1,
                                        marginRight: 5,
                                        marginTop: 7,
                                        marginBottom: 7,
                                        borderColor: kGrayColor,
                                        width: 55,
                                        height: 33,
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 2, right: 2),
                                            child: SvgPicture.asset(
                                              "assets/svg/visa-seeklogo.com.svg",
                                              width: 34,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          ContainerCorner(
                            borderColor: kGrayColor,
                            radiusBottomRight: 10,
                            radiusBottomLeft: 10,
                            marginLeft: 15,
                            marginRight: 15,
                            marginBottom: 10,
                            width: 480,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: TextFormField(
                                      autocorrect: false,
                                      keyboardType: TextInputType.number,
                                      controller: expTextEditingController,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        new LengthLimitingTextInputFormatter(4),
                                        new CardMonthInputFormatter()
                                      ],
                                      validator: (value) {
                                        return CardUtils.validateDate(value);
                                      },
                                      decoration: InputDecoration(
                                        hintText: "MM/YY".tr(),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  ContainerCorner(
                                    width: 1,
                                    color: kGrayColor,
                                    height: 50,
                                    marginRight: 10,
                                  ),
                                  Flexible(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            autocorrect: false,
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            keyboardType: TextInputType.number,
                                            maxLines: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  4),
                                            ],
                                            controller:
                                                cvcTextEditingController,
                                            validator: CardUtils.validateCVV,
                                            decoration: InputDecoration(
                                              hintText: "CVC".tr(),
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        ContainerCorner(
                                          child: SvgPicture.asset(
                                              "assets/svg/card_code.svg"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (currentUser.getPaymentSources!.length > 0 &&
                        sourceSelected == null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                sourceSelected =
                                    currentUser.getPaymentSources![0].getId;
                              });
                            },
                            child: TextWithTap("tickets.use_old_card".tr()),
                          ),
                        ),
                      ),
                    TextWithTap(
                      "tickets.name_card".tr(),
                      textAlign: TextAlign.center,
                      marginTop: 20,
                      marginLeft: 15,
                    ),
                    ContainerCorner(
                      borderColor: kGrayColor,
                      borderRadius: 5,
                      marginLeft: 15,
                      marginRight: 15,
                      marginBottom: 30,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: TextFormField(
                          autocorrect: false,
                          maxLines: null,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            return _validateFullName(value!);
                          },
                          controller: fullNameTextEditingController,
                          decoration: InputDecoration(
                            hintText: "name_".tr(),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ContainerCorner(
                        width: 250,
                        height: 50,
                        borderRadius: 10,
                        colors: [kPrimaryColor, kSecondaryColor],
                        child: TextButton(
                          onPressed: () {
                            if (sourceSelected != null) {
                              pay(
                                source: sourceSelected,
                                currentUser: currentUser,
                                context: context,
                                inAppPurchaseModel: inAppPurchaseModel,
                              );
                            } else if (_formKey.currentState!.validate()) {
                              pay(
                                source: sourceSelected,
                                currentUser: currentUser,
                                context: context,
                                inAppPurchaseModel: inAppPurchaseModel,
                              );
                            }
                          },
                          child: TextWithTap(
                            "tickets.submit".tr(),
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      width: 500,
                    ),
                    Flexible(
                      child: Center(
                        child: ContainerCorner(
                          width: 480,
                          height: 70,
                          child: TextWithTap(
                            "tickets.by_confirm"
                                .tr(namedArgs: {"app_name": Config.appName}),
                            color: QuickHelp.isDarkMode(context)
                                ? Colors.white
                                : Colors.black,
                            marginLeft: 40,
                            marginRight: 40,
                            marginBottom: 15,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ), //checkoutForm(),
            );
          });
        });
  }

  static String lastDigit() {
    var now = new DateTime.now();
    var formatter = new DateFormat('yy');
    String formattedDate = formatter.format(now);
    return "${int.parse(formattedDate) + 3}"; // 2016-01-25
  }

  static pay({
    String? source,
    required InAppPurchaseModel inAppPurchaseModel,
    required BuildContext context,
    required UserModel? currentUser,
  }) async {
    QuickHelp.showLoadingDialog(context);

    var cardNumber = CardUtils.getCleanedNumber(
        cardNumberTextEditingController.text.isNotEmpty
            ? cardNumberTextEditingController.text
            : "4242 4242 4242 4242");
    var expDate = CardUtils.getExpiryDate(
        expTextEditingController.text.isNotEmpty
            ? expTextEditingController.text
            : "02/${lastDigit()}");

    ParseResponse response = await QuickCloudCode.payFromServer(
      userId: currentUser!.objectId!,
      fullName: fullNameTextEditingController.text,
      email: emailTextEditingController.text,
      currency: inAppPurchaseModel.currency!,
      amount: inAppPurchaseModel.price!,
      description: inAppPurchaseModel.id!,
      source: source,
      customer: currentUser.getStripeCustomerId,
      cardNumber: cardNumber,
      expMonth: expDate[0],
      expYear: expDate[1],
      cvc: cvcTextEditingController.text,
    );

    if (response.success) {
      _addPurchaseToUserAccount(
          inAppPurchaseModel: inAppPurchaseModel,
          currentUser: currentUser,
          context: context);
    } else {
      QuickHelp.hideLoadingDialog(context);
      handleError(response.error!.message, context);
    }
  }

  static handleError(String error, BuildContext context) {
    QuickHelp.hideLoadingDialog(context);
    QuickHelp.showAppNotification(context: context, title: error);
  }

  static _addPurchaseToUserAccount(
      {required InAppPurchaseModel inAppPurchaseModel,
      required BuildContext context,
      required UserModel currentUser}) async {

    if(inAppPurchaseModel.id == Config.subs1Month || inAppPurchaseModel.id == Config.subs3Months){

      currentUser.setPremium = inAppPurchaseModel.getPeriod()!;

      ParseResponse parseResponse = await currentUser.save();
      if(parseResponse.success){
        currentUser = parseResponse.results!.first as UserModel;
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(context:context,
          user: currentUser,
          title: "in_app_purchases.subs_purchased".tr(),
          message: "in_app_purchases.subs_added_to_account".tr(),
          isError: false,
        );

        registerPayment(inAppPurchaseModel, currentUser);
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotification(context:context, title: parseResponse.error!.message);
      }

    } else {

      currentUser.addCredit = inAppPurchaseModel.coins!;
      ParseResponse parseResponse = await currentUser.save();
      if (parseResponse.success) {
        currentUser = parseResponse.results!.first as UserModel;

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(
          context: context,
          user: currentUser,
          title: "in_app_purchases.coins_purchased"
              .tr(namedArgs: {"coins": inAppPurchaseModel.coins!.toString()}),
          message: "in_app_purchases.coins_added_to_account".tr(),
          isError: false,
        );

        registerPayment(inAppPurchaseModel, currentUser);
        QuickHelp.goBackToPreviousPage(context);
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotification(
            context: context, title: parseResponse.error!.message);
      }
    }
  }

  static void registerPayment(
      InAppPurchaseModel productDetails, UserModel currentUser) async {
    // Save all payment information
    PaymentsModel paymentsModel = PaymentsModel();
    paymentsModel.setAuthor = currentUser;
    paymentsModel.setAuthorId = currentUser.objectId!;
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
}
