import 'dart:async';

import 'package:heyto/app/config.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/dispache_screen.dart';
import 'package:heyto/auth/signup_account_screen.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/utils/datoo_exeption.dart';
import 'package:heyto/widgets/CountDownTimer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
late ConfirmationResult confirmationResult;
late UserCredential userCredential;

class PhoneLoginScreen extends StatefulWidget {
  static const String route = '/login/phone';

  @override
  _PhoneLoginScreenState createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PhoneNumber number = PhoneNumber(isoCode: Config.initialCountry);

  TextEditingController phoneNumberEditingController = TextEditingController();
  TextEditingController pinCodeEditingController = TextEditingController();

  StreamController<ErrorAnimationType>? errorController;
  bool hasError = false;

  bool _isNumberValid = false;
  bool _isCodeEntered = false;

  int position = 0;

  int _positionPhoneInput = 0;
  int _positionCodeInput = 1;

  String _phoneNumber = "";
  String _pinCode = "";

  bool _showResend = false;
  late String _verificationId;
  int? _tokenResend;

  // Web confirmation result for OTP.
  ConfirmationResult? _webConfirmationResult;

  @override
  void initState() {
    errorController = StreamController<ErrorAnimationType>();
    super.initState();
  }

  @override
  void dispose() {
    errorController!.close();
    //phoneNumberEditingController.dispose();
    super.dispose();
  }

  void _sendVerificationCode(bool resend) async {

    QuickHelp.showLoadingDialog(context, isDismissible: false);

    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);

      if (kDebugMode) {
        print('Verified automatically');
      }

      _checkUserAccount();
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException e) {
      QuickHelp.hideLoadingDialog(context);

      print(
          'Phone number verification failed. Code: ${e.code}. Message: ${e.message}');

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else if (e.code == "invalid-phone-number") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_phone_number".tr());
      } else {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    };

    PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      QuickHelp.hideLoadingDialog(context);
      // Check your phone for the sms code
      _verificationId = verificationId;
      _tokenResend = forceResendingToken;

      print('Verification code sent');

      if (!resend) {
        //_updateCurrentState();
        nextPosition();
      }

      setState(() {
        _showResend = false;
      });
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      print('PhoneCodeAutoRetrievalTimeout');
    };

    try {

      if(QuickHelp.isWebPlatform()){
        confirmationResult = await _auth.signInWithPhoneNumber(number.phoneNumber!);
        //userCredential = await confirmationResult.confirm('123456');

        _webConfirmationResult = await _auth.signInWithPhoneNumber(
            number.phoneNumber!,
            RecaptchaVerifier(
              size: RecaptchaVerifierSize.compact,
              theme: RecaptchaVerifierTheme.dark,
              onSuccess: (){

                print('reCAPTCHA Completed!');

                if(!resend){
                  nextPosition();
                }

                setState(() {
                  _showResend = false;
                });
              },
              onError: (FirebaseAuthException error){

                QuickHelp.showAppNotificationAdvanced(
                    context: context,
                    title: "error".tr(),
                    message: error.message);
              },
              onExpired: () {

                QuickHelp.showAppNotificationAdvanced(
                    context: context,
                    title: "error".tr(),
                    message: "auth.recaptcha_expired".tr());
              },
            )
        );

        QuickHelp.hideLoadingDialog(context);

      } else {
        await _auth.verifyPhoneNumber(
            phoneNumber: number.phoneNumber!,
            timeout: const Duration(seconds: 5),
            verificationCompleted: verificationCompleted,
            verificationFailed: verificationFailed,
            codeSent: codeSent,
            forceResendingToken: _tokenResend,
            codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
      }

    } on FirebaseAuthException catch (e) {
      QuickHelp.hideLoadingDialog(context);

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else if (e.code == "invalid-phone-number") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_phone_number".tr());
      } else {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    }
  }

  Future<void> verifyCode() async {
    QuickHelp.showLoadingDialog(context);

    try {
      if(QuickHelp.isWebPlatform()){

        final UserCredential? userCredential = await _webConfirmationResult!.confirm(_pinCode);
        final User? user = userCredential!.user;

        if (user != null) {
          _checkUserAccount();

        } else {
          QuickHelp.hideLoadingDialog(context);

          QuickHelp.showAppNotificationAdvanced(
              context: context,
              title: "error".tr(),
              message: "auth.canceled_phone".tr());
        }

      } else {

        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _pinCode,
        );

        final User? user = (await _auth.signInWithCredential(credential)).user;

        if (user != null) {
          _checkUserAccount();
        }
      }

      //return;
    } on FirebaseAuthException catch (e) {
      QuickHelp.hideLoadingDialog(context);

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else {
        QuickHelp.showAlertError(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    }
  }

  // Login button clicked
  Future<void> _checkUserAccount() async {

    QueryBuilder<UserModel> queryBuilder =
    QueryBuilder<UserModel>(UserModel.forQuery());
    queryBuilder.whereEqualTo(
        UserModel.keyPhoneNumber, number.parseNumber());
    ParseResponse apiResponse = await queryBuilder.query();


      if (apiResponse.success && apiResponse.results != null) {

      UserModel userModel = apiResponse.results!.first;
      _processLogin(userModel.getUsername, userModel.getSecondaryPassword!);

    } else if (apiResponse.success && apiResponse.results == null) {

      signUpUser();


    } else if(apiResponse.error!.code == DatooException.objectNotFound) {

      signUpUser();

    } else {
      showError(apiResponse.error!.code);
    }
  }

  Future<void> _processLogin(String? username, String password) async {

    final user = ParseUser(username, password, null);

    var response = await user.login();

    if (response.success) {
      showSuccess();
    } else {
      showError(response.error!.code);
    }
  }

  Future<void> showSuccess() async {

    QuickHelp.hideLoadingDialog(context);

    UserModel? currentUser = await ParseUser.currentUser();
    if (currentUser != null) {

      QuickHelp.goToNavigatorScreen(context, DispatchScreen(currentUser: currentUser,), route: DispatchScreen.route, back: false, finish: true);
      //QuickHelp.goToNavigatorAndClear(context, HomeScreen.route, arguments: currentUser);
    }
  }

  void signUpUser(){

    QuickHelp.hideLoadingDialog(context);

    QuickHelp.goToNavigatorScreen(context, SignUpAccountScreen(number: number,), route: SignUpAccountScreen.route,);

  }

  void showError(int error) {
    QuickHelp.hideLoadingDialog(context);

    if(error == DatooException.connectionFailed){

      QuickHelp.showAlertError(context: context, title: "error".tr(), message: "not_connected".tr());
    } else if(error == DatooException.accountBlocked){

      QuickHelp.showAlertError(context: context, title: "error".tr(), message: "auth.account_blocked".tr());

    } else if(error == DatooException.accountDeleted){

      QuickHelp.showAlertError(context: context, title: "error".tr(), message: "auth.account_deleted".tr());
    } else {

      QuickHelp.showAlertError(context: context, title: "error".tr(), message: "auth.invalid_credentials".tr());
    }

  }

  nextPosition() {
    setState(() {
      position = position + 1;
    });
  }

  previousPosition() {
    setState(() {
      position = position - 1;
    });
  }

  bool getButtonState() {
    if (position == _positionPhoneInput) {
      return _isNumberValid;
    } else if (position == _positionCodeInput) {
      return _isCodeEntered;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.phone_login_title".tr());
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ToolBar(
          resizeToAvoidBottomInset: false,
          leftButtonIcon: Icons.arrow_back_ios,
          onLeftButtonTap: () => position == _positionPhoneInput
              ? QuickHelp.goBackToPreviousPage(context)
              : previousPosition(),
          child: Responsive.isMobile(context) ? body() :
          Center(
            child: ContainerCorner(
              width: 400,
              height: size.height,
              borderRadius: 10,
              marginBottom: 20,
              marginTop: 20,
              borderColor: kDisabledGrayColor,
              child: body(),
            ),
          ),
      ),
    );
  }

  Widget body() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: QuickHelp.isMobile() ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          IndexedStack(
            index: position,
            children: [
              phoneNumberInput(),
              phoneCodeInput(),
            ],
          ),
          RoundedGradientButton(
            height: 48,
            marginLeft: 30,
            marginRight: 30,
            marginBottom: 10,
            borderRadius: 60,
            borderRadiusBottomLeft: 15,
            marginTop: 0,
            fontSize: 17,
            colors: getButtonState()
                ? [kPrimaryColor, kSecondaryColor]
                : [kDisabledColor, kDisabledColor],
            textColor:
            getButtonState() ? Colors.white : kDisabledGrayColor,
            text: "continue".tr().toUpperCase(),
            fontWeight: FontWeight.normal,
            onTap: () {
              if (_formKey.currentState!.validate()) {
                FocusManager.instance.primaryFocus?.unfocus();

                if (position == _positionPhoneInput) {

                  _sendVerificationCode(false);

                } else if (position == _positionCodeInput) {

                  if(_isCodeEntered) {
                    verifyCode();
                  } else {
                    //errorController!.stream;
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget phoneNumberInput() {
    return Padding(
      padding: EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          TextWithTap(
            "auth.my_number_is".tr(),
            fontSize: 25,
            marginBottom: 100,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          InternationalPhoneNumberInput(
            inputDecoration: InputDecoration(
              hintText: "auth.phone_number_hint".tr(),
              hintStyle: QuickHelp.isDarkMode(context)
                  ? TextStyle(color: kColorsGrey500)
                  : TextStyle(color: kColorsGrey500),
              //border: InputBorder.none,
            ),
            //countries: Setup.allowedCountries,
            errorMessage: "auth.invalid_phone_number".tr(),
            searchBoxDecoration: InputDecoration(
              hintText: "auth.country_input_hint".tr(),
            ),
            onInputChanged: (PhoneNumber number) {
              //print(number.phoneNumber);
              this.number = number;
              this._phoneNumber = number.phoneNumber!;
            },
            onInputValidated: (bool value) {
              //print(value);
              setState(() {
                _isNumberValid = value;
              });
            },
            countrySelectorScrollControlled: true,
            locale: Config.initialCountry,
            selectorConfig: SelectorConfig(
              selectorType: PhoneInputSelectorType.DIALOG,
              showFlags: true,
              useEmoji: QuickHelp.isWebPlatform() ? false : true,
              setSelectorButtonAsPrefixIcon: false,
              trailingSpace: false,
            ),
            ignoreBlank: false,
            spaceBetweenSelectorAndTextField: 0,
            autoValidateMode: AutovalidateMode.onUserInteraction,
            textStyle: TextStyle(color: Colors.black),
            selectorTextStyle: TextStyle(color: Colors.black),
            initialValue: number,
            countries: Setup.allowedCountries,
            textFieldController: phoneNumberEditingController,
            formatInput: true,
            autoFocus: true,
            autoFocusSearch: true,
            //hintText: number.phoneNumber,
            keyboardType:
                TextInputType.numberWithOptions(signed: false, decimal: false),
            inputBorder: OutlineInputBorder(),
            onSaved: (PhoneNumber number) {
              //print('On Saved: $number');
            },
          ),
          TextWithTap(
            "auth.login_phone_details".tr(),
            marginTop: 30,
            marginBottom: 30,
            fontSize: 13,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
    );
  }

  Widget phoneCodeInput() {
    return Padding(
      padding: EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          TextWithTap(
            "auth.my_code_is".tr(),
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          Row(
            children: [
              TextWithTap(
                _phoneNumber,
                marginTop: 20,
                //marginLeft: 40,
                marginBottom: 18,
                fontSize: 17,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.normal,
                marginRight: 10,
              ),
              TextWithTap(
                "auth.resend_code".tr().toUpperCase(),
                marginTop: 20,
                marginBottom: 18,
                fontSize: 17,
                color: _showResend ? null : kGrayDark,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.normal,
                onTap: () => _showResend ? _sendVerificationCode(true) : null,
              ),
            ],
          ),
          Container(
            child: PinCodeTextField(
              appContext: context,
              length: Setup.verificationCodeDigits,
              keyboardType: TextInputType.number,
              obscureText: false,
              animationType: AnimationType.fade,
              autoFocus: true,
              pinTheme: PinTheme(
                borderWidth: 2.0,
                shape: PinCodeFieldShape.underline,
                borderRadius: BorderRadius.zero,
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.transparent,
                inactiveFillColor: Colors.transparent,
                selectedFillColor: Colors.transparent,
                //errorBorderColor: Color(0xFFC7C7C7),
                activeColor: kPrimaryColor,
                inactiveColor: kDisabledColor,
                selectedColor: kDisabledGrayColor,
              ),
              animationDuration: Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              errorAnimationController: errorController,
              controller: pinCodeEditingController,
              autovalidateMode: AutovalidateMode.always,
              validator: (value){
                return null;
              },
              useHapticFeedback: true,
              hapticFeedbackTypes: HapticFeedbackTypes.selection,
              onChanged: (value) {
                print(value);
                setState(() {
                  if (value.length == Setup.verificationCodeDigits) {
                    _isCodeEntered = true;
                  } else {
                    _isCodeEntered = false;
                  }
                });
              },
              onCompleted: (v) {
                print("Completed" + v);
                setState(() {
                  _pinCode = v;
                  _isCodeEntered = true;
                });
              },
              beforeTextPaste: (text) {
                print("Allowing to paste $text");
                //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                //but you can show anything you want here, like your pop up saying wrong paste format or etc
                return true;
              },
            ),
          ),
          Visibility(
            visible: !_showResend,
            child: Container(
              //width: 60.0,
              padding: EdgeInsets.only(top: 3.0, right: 4.0),
              child: CountDownTimer(
                text: "auth.resend_in".tr(),
                secondsRemaining: 30,
                whenTimeExpires: () {
                  setState(() {
                    _showResend = true;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
