import 'package:heyto/app/config.dart';
import 'package:heyto/auth/dispache_screen.dart';
import 'package:heyto/auth/forgot_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_logo.dart';
import 'package:heyto/ui/button_rounded.dart';
import 'package:heyto/ui/input_password_field.dart';
import 'package:heyto/ui/input_text_field.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/utils/datoo_exeption.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class LoginScreen extends StatefulWidget {
  static const String route = '/login';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController emailOrAccountEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();

  String _emailOrAccountText = '';
  String _passwordText = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailOrAccountEditingController.dispose();
    passwordEditingController.dispose();
    super.dispose();
  }

  String? _validateEmail(String value){

    if(value.isEmpty){

      return "auth.no_email_account".tr();

    } else if(!value.contains("@")){

      if(value.length < 4){
        return "auth.short_username".tr();
      } else{
        return null;
      }

    } else if(!QuickHelp.isValidEmail(value)){

      return "auth.invalid_email".tr();

    } else {
      return null;
    }

  }

  String? _validatePassword(String value){

    if(value.isEmpty){
      return "auth.no_password".tr();

    } else if(value.length < 4){
      return "auth.short_password".tr();
    } else {
      return null;
    }

  }

  // Login button clicked
  Future<void> _doLogin() async {

    _emailOrAccountText = emailOrAccountEditingController.text;
    _passwordText = passwordEditingController.text;

    QuickHelp.showLoadingDialog(context);

    if(_emailOrAccountText.contains('@')){

      QueryBuilder<UserModel> queryBuilder = QueryBuilder<UserModel>(UserModel.forQuery());
      queryBuilder.whereEqualTo(UserModel.keyEmail, _emailOrAccountText);
      ParseResponse apiResponse = await queryBuilder.query();

      if (apiResponse.success && apiResponse.results != null) {

        UserModel userModel = apiResponse.results!.first;
        _processLogin(userModel.getUsername, _passwordText);

      } else {

        showError(apiResponse.error!.code);
      }

    } else {

      _processLogin(_emailOrAccountText, _passwordText);
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

    UserModel? currentUser = await ParseUser.currentUser();
    if (currentUser != null) {

      QuickHelp.goToNavigatorScreen(context, DispatchScreen(currentUser: currentUser,), route: DispatchScreen.route, back: false, finish: true);
      //QuickHelp.goToNavigatorAndClear(context, HomeScreen.route, arguments: currentUser);
    }
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

  @override
  Widget build(BuildContext context) {

    QuickHelp.setWebPageTitle(context, "page_title.login_title".tr());

    return ToolBarCenterLogo(
        leftButtonIcon: Icons.arrow_back_ios,
        leftButtonPress: () => QuickHelp.goBackToPreviousPage(context),
        logoName: "ic_logo.png",
        logoHeight: 24,
        elevation: 2,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InputTextField(
                controller: emailOrAccountEditingController,
                hintText: "auth.email_or_username".tr(),
                marginRight: 20,
                marginLeft: 20,
                marginTop: 20,
                //inputBorder: InputBorder.none,
                isNodeNext: true,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value){
                  return _validateEmail(value!);
                },
              ),
              InputPasswordField(
                controller: passwordEditingController,
                hintText: "auth.pass_word".tr(),
                marginBottom: 20,
                marginRight: 20,
                marginLeft: 20,
                marginTop: 20,
                //inputBorder: InputBorder.none,
                isNodeNext: false,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value){
                  return _validatePassword(value!);
                },
              ),
              ButtonRounded(
                textColor: Colors.white,
                text: "auth.sign_in".tr(),
                color: kPrimaryColor,
                fontSize: 16,
                height: 45,
                borderRadius: 10,
                marginLeft: 20,
                marginRight: 20,
                textAlign: TextAlign.center,
                onTap: (){
                  if(_formKey.currentState!.validate()) {
                    _doLogin();
                  }
                },
              ),
              TextWithTap(
                "auth.forgot_password".tr(),
                color: QuickHelp.isDarkMode(context) ? kContentColorDarkTheme : kPrimaryColor,
                marginBottom: 20,
                marginTop: 15,
                onTap: (){
                  QuickHelp.goToNavigatorScreen(context, ForgotScreen(), route: ForgotScreen.route);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWithTap(
                    "auth.privacy_policy".tr(),
                    marginRight: 5,
                    fontSize: 12,
                    onTap: (){
                      QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypePrivacy, pageUrl: Config.privacyPolicyUrl);
                    },
                  ),
                  TextWithTap("•", fontSize: 16,),
                  TextWithTap(
                    "auth.terms_of_use".tr(),
                    marginLeft: 5,
                    fontSize: 12,
                    onTap: (){
                      QuickHelp.goToWebPage(context, pageType: QuickHelp.pageTypeTerms, pageUrl: Config.termsOfUseUrl);
                    },
                  ),
                ],
              )
            ],
          ),
        )
    );
  }
}
