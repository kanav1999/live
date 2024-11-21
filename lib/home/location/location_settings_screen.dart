import 'package:geocoding/geocoding.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/button_rounded_outline.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_settings/app_settings.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:location/location.dart' as LocationForAll;

import '../../ui/app_bar.dart';
import '../../ui/container_with_corner.dart';
import 'add_city_screen_force.dart';

// ignore: must_be_immutable
class LocationSettingsScreen extends StatefulWidget {
  static const String route = '/location/settings';

  bool showBack;
  bool showRemind;
  bool showAddCity;

  LocationSettingsScreen(
      {this.currentUser,
      this.showAddCity = true,
      this.showBack = true,
      this.showRemind = true});

  UserModel? currentUser;

  @override
  _LocationSettingsScreenState createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> with WidgetsBindingObserver  {

  bool locationClicked = false;

  Future<bool> _onBackPressed() async {
    return widget.showBack;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    print("dispose addCity");
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");

        _determinePosition();
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.location_title".tr());
    var size = MediaQuery.of(context).size;

    return new WillPopScope(
      onWillPop: _onBackPressed,
      child: ToolBar(
        iconHeight: 24,
        iconWidth: 24,
        centerTitle: true,
        leftButtonIcon: widget.showBack ? Icons.arrow_back : null,
        onLeftButtonTap: widget.showBack ? () =>  QuickHelp.goBackToPreviousPage(context, result: widget.currentUser) : null,
        rightIconColor: QuickHelp.getColorToolbarIcons(),
        child: SafeArea(
          child: Responsive.isMobile(context)
              ? body()
              : Center(
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
            child: Image.asset("assets/images/ic_location_permission.png",
                width: 200),
          ),
          Column(
            children: [
              TextWithTap(
                "ups_".tr(),
                marginTop: 20,
                fontSize: 25,
                marginBottom: 5,
                fontWeight: FontWeight.bold,
              ),
              TextWithTap(
                "permissions.location_needed_for_app"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                marginTop: 0,
                fontSize: 16,
                marginBottom: 5,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
              ),
              TextWithTap(
                "permissions.location_settings"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                marginTop: 10,
                fontSize: 16,
                marginBottom: 5,
                marginLeft: 50,
                marginRight: 50,
                color: kPrimacyGrayColor,
              ),
              Visibility(
                visible: QuickHelp.isMobile(),
                child: ButtonRoundedOutline(
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 30,
                  borderRadius: 60,
                  marginTop: 50,
                  fontSize: 17,
                  textColor: kPrimaryColor,
                  borderColor: kPrimaryColor,
                  borderWidth: 2,
                  text: locationClicked ? "permissions.allow_location".tr().toUpperCase()  : "permissions.location_settings_open".tr().toUpperCase(),
                  fontWeight: FontWeight.normal,
                  onTap: () {

                    if(locationClicked){
                      _determinePosition();
                    } else {

                      if(QuickHelp.isMobile()){
                        AppSettings.openLocationSettings();
                      }
                    }
                  },
                ),
              ),
              Visibility(
                visible: widget.showAddCity,
                child: RoundedGradientButton(
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 30,
                  borderRadius: 60,
                  borderRadiusBottomLeft: 15,
                  fontSize: 17,
                  colors: [kPrimaryColor, kSecondaryColor],
                  textColor: Colors.white,
                  text: "permissions.location_add_manually".tr().toUpperCase(),
                  fontWeight: FontWeight.normal,
                  onTap: () {

                    WidgetsBinding.instance?.removeObserver(this);
                    QuickHelp.goToNavigatorScreen(
                        context,
                        AddCityScreenForce(
                          currentUser: widget.currentUser,
                        ),
                        route: AddCityScreenForce.route);
                  },
                ),
              ),
              Visibility(
                visible: widget.showRemind,
                child: TextWithTap(
                  "remind_me_later".tr(),
                  textAlign: TextAlign.center,
                  fontSize: 14,
                  marginBottom: 10,
                  marginLeft: 50,
                  marginRight: 50,
                  color: kPrimacyGrayColor,
                  onTap: () {
                    goHomeLater();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  goHomeLater() {
    WidgetsBinding.instance?.removeObserver(this);
    QuickHelp.goToNavigatorScreen(
        context,
        HomeScreen(
          currentUser: widget.currentUser,
        ),
        back: false,
        route: HomeScreen.route);
  }

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

    if (_permissionGranted == LocationForAll.PermissionStatus.granted ||
        _permissionGranted == LocationForAll.PermissionStatus.grantedLimited ) {

      print("Location: granted grantedLimited 2");

      setState(() {
        locationClicked = !locationClicked;
      });

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

    Future.delayed(Duration(seconds: 10), (){
      if(!locationSaved){

        QuickHelp.hideLoadingDialog(context);

        if(widget.currentUser!.getGeoPoint != null){

          WidgetsBinding.instance?.removeObserver(this);

          QuickHelp.goToNavigatorScreen(
              context,
              HomeScreen(
                currentUser: widget.currentUser,
              ), back: false,
              route: HomeScreen.route);

        } else {

          WidgetsBinding.instance?.removeObserver(this);

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

  goHome(LocationForAll.LocationData locationData) async{

    locationSaved = true;

    print("Location ${locationData.latitude}, ${locationData.longitude}");

    if (!widget.currentUser!.getLocationTypeNearBy!) {

      QuickHelp.hideLoadingDialog(context);

      WidgetsBinding.instance?.removeObserver(this);
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

      WidgetsBinding.instance?.removeObserver(this);

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(
          context,
          HomeScreen(
            currentUser: widget.currentUser,
          ), back: false,
          route: HomeScreen.route);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }
}
