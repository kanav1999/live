import 'package:app_settings/app_settings.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:heyto/app/constants.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/location/location_settings_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/place_model.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/widgets/need_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:location/location.dart' as LocationForAll;

// ignore: must_be_immutable
class AddCityScreen extends StatefulWidget {
  static const String route = '/profile/add/city';
  UserModel? currentUser;

  AddCityScreen({this.currentUser});

  @override
  _AddCityScreenState createState() => _AddCityScreenState();
}

class _AddCityScreenState extends ResumableState<AddCityScreen>
    with WidgetsBindingObserver {
  bool isCityHidden = false;
  bool locationSaved = false;

  bool savingResumed = false;

  int position = 0;
  String search = "";

  int positionInitial = 0;
  int positionResult = 1;

  _searchPlaces(String text) {
    setState(() {

      if(text.isEmpty){
        position = positionInitial;
      } else {
        position = positionResult;
      }
      search = text;
    });
  }

  TextEditingController placesEditingController = TextEditingController();

  Future<void> _determinePositionResume() async {
    print("Location: _determinePosition clicked");

    LocationForAll.Location? location = LocationForAll.Location();

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
        _permissionGranted == LocationForAll.PermissionStatus.grantedLimited) {
      print("Location: granted grantedLimited 2");

      QuickHelp.showLoadingDialog(context);

      await location.getLocation().then((value) {
        print("Location: _locationData valid $value");

        checkSaveTime();

        getAddressFromLatLong(locationData: value);
      }).onError((error, stackTrace) {
        print("Location: _locationData null");

        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_not_supported".tr(),
            message: "permissions.add_location_manually"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);
      });
    }
  }

  Future<void> _determinePosition() async {
    print("Location: _determinePosition clicked");

    LocationForAll.Location location = LocationForAll.Location();

    bool _serviceEnabled;
    LocationForAll.PermissionStatus _permissionGranted;
    LocationForAll.LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_not_supported".tr(),
            message: "permissions.add_location_manually"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);

        QuickHelp.goToNavigatorScreen(
            context,
            HomeScreen(
              currentUser: widget.currentUser,
            ),
            route: HomeScreen.route);

        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == LocationForAll.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();

      if (_permissionGranted == LocationForAll.PermissionStatus.granted ||
          _permissionGranted ==
              LocationForAll.PermissionStatus.grantedLimited) {
        QuickHelp.showLoadingDialog(context);

        checkSaveTime();

        _locationData = await location.getLocation();
        getAddressFromLatLong(locationData: _locationData);
      } else if (_permissionGranted == LocationForAll.PermissionStatus.denied) {
        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_access_denied".tr(),
            message: "permissions.location_explain"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);
      } else if (_permissionGranted ==
          LocationForAll.PermissionStatus.deniedForever) {
        _permissionDeniedForEver();
      }
    } else if (_permissionGranted ==
        LocationForAll.PermissionStatus.deniedForever) {
      _permissionDeniedForEver();
    } else if (_permissionGranted == LocationForAll.PermissionStatus.granted ||
        _permissionGranted == LocationForAll.PermissionStatus.grantedLimited) {
      QuickHelp.showLoadingDialog(context);
      checkSaveTime();

      _locationData = await location.getLocation();
      getAddressFromLatLong(locationData: _locationData);
    }
  }

  checkSaveTime() {
    Future.delayed(Duration(seconds: 10), () {
      if (!locationSaved) {
        QuickHelp.hideLoadingDialog(context);

        QuickHelp.showAppNotificationAdvanced(
            title: "permissions.location_not_supported".tr(),
            message: "permissions.add_location_manually"
                .tr(namedArgs: {"app_name": Setup.appName}),
            context: context);
      }
    });
  }

  _permissionDeniedForEver() {
    if (QuickHelp.isMobile()) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.location_access_denied".tr(),
          confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
          message: "permissions.location_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);
            AppSettings.openLocationSettings();
          });
    } else {
      QuickHelp.goToNavigatorScreen(
          context,
          LocationSettingsScreen(
            currentUser: widget.currentUser,
            showBack: true,
          ),
          route: LocationSettingsScreen.route);
    }
  }

  Future<void> getAddressFromLatLong(
      {PlaceModel? placeModel,
      LocationForAll.LocationData? locationData}) async {
    locationSaved = true;

    QuickHelp.showLoadingDialog(context);

    double latitude = 0.0;
    double longitude = 0.0;
    bool locationNearBy = true;

    if (placeModel != null) {
      locationNearBy = false;

      latitude = placeModel.place!.latLng!.lat;
      longitude = placeModel.place!.latLng!.lng;

      widget.currentUser!.setLocation = placeModel.getLocation()!;
      widget.currentUser!.setCity = placeModel.getLocality()!;

    } else if (locationData != null) {
      locationNearBy = true;

      latitude = locationData.latitude!;
      longitude = locationData.longitude!;

      if (QuickHelp.isMobile()) {
        List<Placemark>? placements;
        placements = await placemarkFromCoordinates(latitude, longitude);

        Placemark place = placements[0];

        widget.currentUser!.setLocation = "${place.locality}, ${place.country}";
        widget.currentUser!.setCity = "${place.locality}";
      }
    }

    ParseGeoPoint parseGeoPoint = new ParseGeoPoint();
    parseGeoPoint.latitude = latitude;
    parseGeoPoint.longitude = longitude;

    widget.currentUser!.setHasGeoPoint = true;
    widget.currentUser!.setGeoPoint = parseGeoPoint;
    widget.currentUser!.setLocationTypeNearBy = locationNearBy;

    ParseResponse parseResponse = await widget.currentUser!.save();

    if (parseResponse.success) {
      widget.currentUser = parseResponse.results!.first as UserModel;

      QuickHelp.hideLoadingDialog(context);

      QuickHelp.goBackToPreviousPage(context, result: parseResponse.results!.first);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  _hideOrShowLocation() async {
    QuickHelp.showLoadingDialog(context);

    widget.currentUser!.setHideMyLocation =
        !widget.currentUser!.getHideMyLocation!;
    ParseResponse parseResponse = await widget.currentUser!.save();

    if (parseResponse.success) {
      QuickHelp.hideLoadingDialog(context);

      setState(() {
        isCityHidden = widget.currentUser!.getHideMyLocation!;
      });
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
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

        if (!savingResumed) {
          _determinePositionResume();
          savingResumed = false;
        }

        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        savingResumed = false;
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.add_city_title".tr());

    return ToolBar(
      iconHeight: 24,
      iconWidth: 24,
      centerTitle: true,
      title: "page_title.add_city_title".tr(),
      leftButtonIcon: Icons.arrow_back,
      onLeftButtonTap: () =>
          QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      child: Container(
        padding: EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 15,
        ),
        child: Column(children: [
          ContainerCorner(
            height: 55,
            borderRadius: 10,
            marginTop: 15,
            color: kGreyColor0,
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SvgPicture.asset(
                      "assets/svg/ic_search.svg",
                      width: 27,
                      height: 27,
                      color: kDisabledGrayColor,
                    ),
                  ),
                  Flexible(
                    child: TextField(
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 1,
                      autocorrect: true,
                      controller: placesEditingController,
                      decoration: InputDecoration(
                        focusedBorder: InputBorder.none,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: kGreyColor1,
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: widget.currentUser!.getLocationOrEmpty!.isNotEmpty? widget.currentUser!.getLocationOrEmpty! : "edit_profile.search_city".tr(),
                      ),
                      onChanged: (text) {
                        _searchPlaces(text);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          IndexedStack(
            index: position,
            children: [
              Column(
                children: [
                  ContainerCorner(
                    height: 55,
                    borderRadius: 10,
                    marginTop: 15,
                    marginBottom: 50,
                    color: kGreyColor0,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.place,
                            size: 27,
                            color: kPrimaryColor,
                          ),
                          Expanded(
                            child: Text(
                              "edit_profile.near_cur_location".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => _determinePosition(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/svg/home_not.svg"),
                      SizedBox(
                        width: 15,
                      ),
                      TextWithTap(
                        isCityHidden
                            ? "edit_profile.show_city".tr()
                            : "edit_profile.do_not_show_city".tr(),
                        textAlign: TextAlign.center,
                        color: kDisabledGrayColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        onTap: () => _hideOrShowLocation(),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  FutureBuilder(
                      future: _getPlaces(search: search),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                          case ConnectionState.waiting:
                          return  Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: QuickHelp.appLoading(adaptive: true, width: 30, height: 30),
                            ),
                          );
                          default:
                            if (snapshot.hasData) {
                              //List<PlaceModel> places = snapshot.data;
                              FindAutocompletePredictionsResponse predictions = snapshot.data;
                              List<AutocompletePrediction> places = predictions.predictions;

                              return Column(
                                children: [
                                  Visibility(
                                    visible: search.isNotEmpty,
                                    child: TextWithTap(
                                      places.length > 0 ? "result_".tr() :  places.length > 0 ? "result_".tr() : "edit_profile.no_location_found".tr(namedArgs: {"location" : search}),
                                      marginTop: 10,
                                      marginBottom: 10,
                                      marginLeft: 10,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      alignment: Alignment.centerLeft,
                                    ),
                                  ),
                                  ListView(
                                    shrinkWrap: true,
                                    children: List.generate(places.length, (index) {

                                     AutocompletePrediction prediction = places[index];

                                      return TextWithTap(
                                        prediction.fullText,
                                        fontSize: 16,
                                        marginBottom: 10,
                                        marginLeft: 10,
                                        fontWeight: FontWeight.w500,
                                        color: kDisabledGrayColor,
                                        onTap: ()=> getPlace(prediction),
                                      );
                                    }),
                                  ),
                                ],
                              );

                            } else {
                              return TextWithTap(
                                "edit_profile.no_location_update".tr(),
                                fontSize: 16,
                                marginBottom: 10,
                                marginLeft: 10,
                                fontWeight: FontWeight.w500,
                                color: kDisabledGrayColor,
                              );
                            }
                        }
                      }),
                ],
              )
            ],
          ),
        ]),
      ),
    );
  }

  getPlace(AutocompletePrediction prediction) async {

    List<PlaceField> placeFields = [
      PlaceField.Id,
      PlaceField.Location,
      PlaceField.Name,
    ];

    final places = FlutterGooglePlacesSdk(Constants.getGoogleApiKeyGeo());
    FetchPlaceResponse place = await places.fetchPlace(prediction.placeId, fields: placeFields);

    PlaceModel placeModel = PlaceModel();

    placeModel.setId(prediction.placeId);
    placeModel.setPlace(place.place!);
    placeModel.setCountry(prediction.secondaryText);
    placeModel.setLocality(prediction.primaryText);
    placeModel.setLocation(prediction.fullText);

    getAddressFromLatLong(placeModel: placeModel);

  }

  Future <dynamic> _getPlaces({String? search = " "}) async {

    final places = FlutterGooglePlacesSdk(Constants.getGoogleApiKeyGeo());
    final predictions =
    await places.findAutocompletePredictions(search!.isEmpty ? " " : search,
        placeTypeFilter: PlaceTypeFilter
            .CITIES);
    return predictions;

  }
}
