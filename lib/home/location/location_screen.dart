import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/location/add_city_screen_force.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as LocationForAll;
import 'package:parse_server_sdk/parse_server_sdk.dart';

import '../../ui/container_with_corner.dart';
import 'location_settings_screen.dart';

// ignore: must_be_immutable
class LocationScreen extends StatefulWidget {
  static const String route = '/location';

  LocationScreen({this.currentUser});

  UserModel? currentUser;

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {

  bool locationSaved = false;

  Future<void> _determinePosition() async {

    print("Location: _determinePosition clicked");

    LocationForAll.Location? location =  LocationForAll.Location();

    bool _serviceEnabled;
    LocationForAll.PermissionStatus _permissionGranted;
    //LocationForAll.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {

      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {

        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_not_supported".tr(),
            message: "permissions.add_location_manually"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);

        return;
      }
    }

    _permissionGranted = await location.hasPermission();

    if (_permissionGranted == LocationForAll.PermissionStatus.denied) {

      _permissionGranted = await location.requestPermission();

      if (_permissionGranted == LocationForAll.PermissionStatus.granted ||
          _permissionGranted == LocationForAll.PermissionStatus.grantedLimited) {

        print("PermissionStatus granted");

        QuickHelp.showLoadingDialog(context);

        checkSaveTime();

        await location.getLocation().then((value){
          print("Location: _locationData valid $value");

          goHome(value);

        }).onError((error, stackTrace){
          print("Location: _locationData null");

          QuickHelp.showAppNotificationAdvanced(
              title: "permissions.location_not_supported".tr(),
              message: "permissions.add_location_manually"
                  .tr(namedArgs: {"app_name": Setup.appName}),
              context: context);

        });

      } else if (_permissionGranted == LocationForAll.PermissionStatus.denied) {

        print("PermissionStatus denied");

        _permissionDeniedForEver();

      } else if (_permissionGranted == LocationForAll.PermissionStatus.deniedForever) {

       _permissionDeniedForEver();

      }

    } else if (_permissionGranted == LocationForAll.PermissionStatus.deniedForever) {

      _permissionDeniedForEver();

    } else if (_permissionGranted == LocationForAll.PermissionStatus.granted ||
        _permissionGranted == LocationForAll.PermissionStatus.grantedLimited ) {

      print("Location: granted grantedLimited 2");

      QuickHelp.showLoadingDialog(context);

      checkSaveTime();

      await location.getLocation().then((value){
        print("Location: _locationData valid $value");

        goHome(value);

      }).onError((error, stackTrace){
        print("Location: _locationData null");

        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_not_supported".tr(),
            message: "permissions.add_location_manually"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);

      });

    }
  }

  checkSaveTime(){

    Future.delayed(Duration(seconds: 6), (){
      if(!locationSaved){

        QuickHelp.hideLoadingDialog(context);

        if(widget.currentUser!.getGeoPoint != null){

          QuickHelp.goToNavigatorScreen(
              context,
              HomeScreen(
                currentUser: widget.currentUser,
              ), back: false,
              route: HomeScreen.route);

        } else {

          QuickHelp.goToNavigatorScreen(
              context,
              AddCityScreenForce(
                currentUser: widget.currentUser,
              ),
              route: AddCityScreenForce.route);

          QuickHelp.showAppNotificationAdvanced(
              title: "permissions.location_not_supported".tr(),
              message: "permissions.add_location_manually"
                  .tr(namedArgs: {"app_name": Setup.appName}),
              context: context);
        }
      }
    });
  }

  _permissionDeniedForEver(){

    QuickHelp.goToNavigatorScreen(
        context,
        LocationSettingsScreen(
          currentUser: widget.currentUser,
          showBack: false,
        ), back: false,
        route: LocationSettingsScreen.route);
  }

  goHome(LocationForAll.LocationData locationData) async{

    locationSaved = true;

    print("Location ${locationData.latitude}, ${locationData.longitude}");

    if (!widget.currentUser!.getLocationTypeNearBy!) {

      QuickHelp.hideLoadingDialog(context);

      QuickHelp.goToNavigatorScreen(
          context,
          HomeScreen(
            currentUser: widget.currentUser,
          ),
          route: HomeScreen.route);
      return;

    } else {

      print("Location getAddressFromLatLong");

      getAddressFromLatLong(locationData);
    }
  }

  Future<void> getAddressFromLatLong(LocationForAll.LocationData position) async {

    ParseGeoPoint parseGeoPoint = new ParseGeoPoint();
    parseGeoPoint.latitude = position.latitude!;
    parseGeoPoint.longitude = position.longitude!;

    widget.currentUser!.setHasGeoPoint = true;
    widget.currentUser!.setGeoPoint = parseGeoPoint;

    if(QuickHelp.isMobile()){

      List<Placemark>? placements;
      placements = await placemarkFromCoordinates(position.latitude!, position.longitude!);
      print(placements);

      Placemark place = placements[0];

      widget.currentUser!.setLocation = "${place.locality}, ${place.country}";
      widget.currentUser!.setCity = "${place.locality}";
    }


    ParseResponse parseResponse = await widget.currentUser!.save();

    if (parseResponse.success) {
      widget.currentUser = parseResponse.results!.first as UserModel;

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(
          context,
          HomeScreen(
            currentUser: widget.currentUser,
          ),
          route: HomeScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  Future<bool> _onBackPressed() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.location_title".tr());
    var size = MediaQuery.of(context).size;

    return new WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
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
      ),
    );
  }

  Widget body() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(),
            ],
          ),
          Container(
            child:
            Image.asset("assets/images/ic_location_permission.png"),
          ),
          Column(
            children: [
              TextWithTap(
                "permissions.enable_location".tr(),
                marginTop: 20,
                fontSize: 25,
                marginBottom: 5,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
              TextWithTap(
                "permissions.location_explain"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                marginTop: 0,
                fontSize: 14,
                marginBottom: 5,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
              ),
              RoundedGradientButton(
                height: 48,
                marginLeft: 30,
                marginRight: 30,
                marginBottom: 30,
                borderRadius: 60,
                borderRadiusBottomLeft: 15,
                marginTop: 50,
                fontSize: 17,
                colors: [kPrimaryColor, kSecondaryColor],
                textColor: Colors.white,
                text: "permissions.allow_location".tr().toUpperCase(),
                fontWeight: FontWeight.normal,
                onTap: () {
                  _determinePosition();
                },
              ),
              TextWithTap(
                "permissions.location_tell_more".tr(),
                textAlign: TextAlign.center,
                marginTop: 0,
                fontSize: 14,
                marginBottom: 10,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
                onTap: () {
                  QuickHelp.showDialogPermission(
                      context: context,
                      confirmButtonText:
                      "permissions.allow_location".tr().toUpperCase(),
                      title: "permissions.meet_people".tr(),
                      message: "permissions.meet_people_explain".tr(),
                      onPressed: () async {
                        QuickHelp.hideLoadingDialog(context);

                        _determinePosition();
                      });
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
