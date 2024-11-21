import 'package:heyto/app/setup.dart';
import 'package:heyto/auth/complete_profile_screen.dart';
import 'package:heyto/auth/welcome_screen.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/location/location_screen.dart';
import 'package:heyto/home/location/location_settings_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

// ignore: must_be_immutable
class DispatchScreen extends StatefulWidget {

  static String route = "/check";

  final UserModel? currentUser;

  const DispatchScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  _DispatchScreenState createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {

  Location location =  Location();
  late PermissionStatus permissionStatus;

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(widget.currentUser != null){

      return Scaffold(
        body: FutureBuilder<UserModel?>(
            future: QuickHelp.getUser(),
            builder: (context, snapshot) {
              if(snapshot.hasData){

                if(widget.currentUser!.getUid == null){
                  return CompleteProfileScreen(currentUser: widget.currentUser);

                } else if(widget.currentUser!.getFullName!.isEmpty){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepFullName,);

                } else if(widget.currentUser!.getBirthday == null){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepBirthday,);

                } else if(widget.currentUser!.getGender == null){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepGender,);

                } else if(widget.currentUser!.getSexualOrientationsReal!.isEmpty){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepSexualOrientation,);

                } else if(widget.currentUser!.getPassionsRealList!.isEmpty){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepPassions,);

                } else if(QuickHelp.getPhotosCounter(widget.currentUser).length < Setup.photoNeededToRegister){
                  return CompleteProfileScreen(currentUser: widget.currentUser, currentStep: CompleteProfileScreen.currentStepPhotos,);

                } else {
                  return checkLocation();
                }

              } else if(snapshot.hasError){
                return WelcomeScreen();
              } else {
                return QuickHelp.appLoadingLogo();
              }
            }),
      );

    } else {
      return WelcomeScreen();
    }
  }

  Widget checkLocation(){

    return Scaffold(
      body: FutureBuilder<PermissionStatus>(
          future: location.hasPermission(),
          builder: (context, snapshot) {
            if(snapshot.hasData){

              permissionStatus = snapshot.data as PermissionStatus;
              print("permissionStatus: $permissionStatus");

              if (permissionStatus == PermissionStatus.granted ||
                  permissionStatus == PermissionStatus.grantedLimited) {

                return HomeScreen(currentUser: widget.currentUser);

              } else {

                if(widget.currentUser!.getLocationTypeNearBy!){
                  return LocationScreen(currentUser: widget.currentUser);

                } else {
                  if(widget.currentUser!.getGeoPoint != null){
                    return HomeScreen(currentUser: widget.currentUser,);
                  } else {
                    return LocationScreen(currentUser: widget.currentUser,);
                  }
                }
              }

            } else if(snapshot.hasError){
              return LocationSettingsScreen(currentUser: widget.currentUser, showBack: false,);
            } else {
              return QuickHelp.appLoadingLogo();
            }
          }),
    );
  }
}
