import 'dart:io';
import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/complete_profile_screen.dart';
import 'package:heyto/auth/dispache_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app/config.dart';
import '../helpers/quick_cloud.dart';
import '../utils/shared_manager.dart';

class SocialLogin {

  static Future<void> loginFacebook(BuildContext context, SharedPreferences preferences) async {

    QuickHelp.showLoadingDialog(context);

    final result = await FacebookAuth.i.login(
      permissions: [
        'email',
        'public_profile',
      ],
    );

    if (result.status == LoginStatus.success) {

      final ParseResponse response = await ParseUser.loginWith(
          "facebook",
          facebook(
            result.accessToken!.token,
            result.accessToken!.userId,
            result.accessToken!.expires,
          ));

      if (response.success) {
        UserModel? user = await ParseUser.currentUser();

        if (user != null) {
          if (user.getUid == null) {

            if(SharedManager().getInvitee(preferences)!.isNotEmpty){
              await QuickCloudCode.sendTicketsToInvitee(authorId: user.objectId!, receivedId: SharedManager().getInvitee(preferences)!);
              SharedManager().clearInvitee(preferences);
            }

            getFbUserDetails(user, context);
          } else {
            goHome(context, user);
          }
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showAppNotificationAdvanced(
              context: context, title: "error".tr(), message: "auth.fb_login_error".tr());
        }
      } else {

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "error".tr(), message:  response.error!.message);
      }

    } else if (result.status == LoginStatus.cancelled) {

      print("facebook login in cancelled");

      QuickHelp.hideLoadingDialog(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context, title: "auth.fb_login_canceled".tr(), message: "auth.fb_login_canceled_message".tr(),);

    } else if (result.status == LoginStatus.failed) {

      print("facebook login failed: ${result.message}");

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "error".tr(),  message: "auth.fb_login_error".tr());

    } else if (result.status == LoginStatus.operationInProgress) {
      print("facebook login in progress");
    }

  }

  static void getFbUserDetails(UserModel user, BuildContext context) async {
    final _userData = await FacebookAuth.i.getUserData(
      fields:
          //"id,email,name,first_name,last_name,gender,birthday,picture.width(920).height(920),location",
      "id,email,name,first_name,last_name,picture.width(920).height(920)",
    );

    String firstName = _userData['first_name'];
    String lastName = _userData['last_name'];

    String username =
        lastName.replaceAll(" ", "") + firstName.replaceAll(" ", "");

    user.setFullName = _userData['name'];
    user.setFacebookId = _userData['id'];
    user.setFirstName = firstName;
    user.setLastName = lastName;
    user.username = username.toLowerCase().trim()+QuickHelp.generateShortUId().toString();
    if(_userData['email'] != null){
      user.setEmail = _userData['email'];
      user.setEmailPublic = _userData['email'];
    }
    user.setPopularity = 0;
    user.setUserRole = UserModel.roleUser;
    user.setPrefMinAge = Setup.minimumAgeToRegister;
    user.setPrefMaxAge = Setup.maximumAgeToRegister;
    user.setLocationTypeNearBy = true;
    user.addCredit = Setup.welcomeCredit;
    user.setBio = Setup.bio;
    user.setHasPassword = false;
    ParseResponse response = await user.save();

    if (response.success) {
      getPhotoFromUrl(context, user, _userData['picture']['data']['url']);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showErrorResult(context, response.error!.code);
    }
  }

  static loginApple(BuildContext context, SharedPreferences preferences) async {

    QuickHelp.showLoadingDialog(context);

    try {
      // Request credential for the currently signed in Apple account.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // TODO: Set the `clientId` and `redirectUri` arguments to the values you entered in the Apple Developer portal during the setup
          clientId: Config.appleLoginClientId,

          redirectUri:
          QuickHelp.isWebPlatform()
              ? Uri.parse(Config.appleWebLoginRedirectUrl)
              : Uri.parse(Config.appleAndroidLoginRedirectUrl,
          ),
        ),
        //nonce: nonce,
      );

      ParseResponse response = await ParseUser.loginWith(
          'apple', apple(appleCredential.identityToken!, appleCredential.userIdentifier!));

      if (response.success) {
        UserModel? user = await ParseUser.currentUser();

        if (user != null) {
          if (user.getUid == null) {

            if(SharedManager().getInvitee(preferences)!.isNotEmpty){
              await QuickCloudCode.sendTicketsToInvitee(authorId: user.objectId!, receivedId: SharedManager().getInvitee(preferences)!);
              SharedManager().clearInvitee(preferences);
            }

            getAppleUserDetails(context, user, appleCredential);
          } else {
            goHome(context, user);
          }
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showAppNotificationAdvanced(
              context: context, title: "error".tr(), message: "auth.apple_login_error".tr());
        }
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "error".tr(), message: response.error!.message);
      }

    } catch (exception) {

      QuickHelp.hideLoadingDialog(context);

      SignInWithAppleAuthorizationException error = exception as SignInWithAppleAuthorizationException;

      if(error.code == AuthorizationErrorCode.canceled){

        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "auth.apple_login_error_canceled".tr(), message: "auth.gg_login_canceled_message".tr());

      } else if(error.code == AuthorizationErrorCode.notHandled){

        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "auth.apple_login_error_not_handled".tr(), message: "auth.apple_login_error".tr());

      } else if(error.code == AuthorizationErrorCode.notInteractive){

        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "auth.apple_login_error_inter".tr(), message: "auth.apple_login_error".tr());

      } else {

        QuickHelp.showAppNotificationAdvanced(
            context: context, title: "error".tr(), message: "auth.apple_login_error".tr());
      }

      print("Apple Error $exception}");

    }
  }

  static void getAppleUserDetails(BuildContext context, UserModel user, AuthorizationCredentialAppleID credentialAppleID) async {

    if(credentialAppleID.givenName != null){

      String? firstName = credentialAppleID.givenName;
      String? lastName = credentialAppleID.familyName;
      String? fullName = '$firstName $lastName';

      String username = lastName!.replaceAll(" ", "") + firstName!.replaceAll(" ", "");

      user.setFullName = fullName;
      user.setFirstName = firstName;
      user.setLastName = lastName;
      user.username = username.toLowerCase().trim()+QuickHelp.generateShortUId().toString();

      if(credentialAppleID.email != null){
        user.setEmail = credentialAppleID.email!;
        user.setEmailPublic = credentialAppleID.email!;
      }

    } else {
      user.username = QuickHelp.generateUId().toString();
    }

    user.setAppleId = credentialAppleID.userIdentifier!;
    user.setPopularity = 0;
    user.setUserRole = UserModel.roleUser;
    user.setPrefMinAge = Setup.minimumAgeToRegister;
    user.setPrefMaxAge = Setup.maximumAgeToRegister;
    user.setLocationTypeNearBy = true;
    user.addCredit = Setup.welcomeCredit;
    user.setBio = Setup.bio;
    user.setHasPassword = false;
    ParseResponse response = await user.save();

    if (response.success) {

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, CompleteProfileScreen(currentUser: user,), route: CompleteProfileScreen.route, finish: true);
    } else {

      QuickHelp.showErrorResult(context, response.error!.code);
    }
  }

  static void getPhotoFromUrl(
      BuildContext context, UserModel user, String url) async {
    File avatar = await QuickHelp.downloadFile(url, "avatar.jpeg") as File;

    ParseFileBase parseFile;
    if (QuickHelp.isWebPlatform()) {
      //Seems weird, but this lets you get the data from the selected file as an Uint8List very easily.
      ParseWebFile file =
          ParseWebFile(null, name: "avatar.jpeg", url: avatar.path);
      await file.download();
      parseFile = ParseWebFile(file.file, name: file.name);
    } else {
      parseFile = ParseFile(File(avatar.path));
    }

    user.setAvatar = parseFile;
    user.setAvatar1 = parseFile;

    final ParseResponse response = await user.save();
    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, CompleteProfileScreen(currentUser: user,), route: CompleteProfileScreen.route, finish: true);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, CompleteProfileScreen(currentUser: user,), route: CompleteProfileScreen.route, finish: true);
    }
  }

  static void goHome(BuildContext context, UserModel userModel) {

    QuickHelp.hideLoadingDialog(context);
    QuickHelp.goToNavigatorScreen(context, DispatchScreen(currentUser: userModel,), route: DispatchScreen.route, back: false, finish: true);
  }
}
