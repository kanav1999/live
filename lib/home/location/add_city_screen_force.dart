import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/models/others/place_model.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/widgets/need_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../app/constants.dart';
import '../../ui/text_with_tap.dart';

// ignore: must_be_immutable
class AddCityScreenForce extends StatefulWidget {
  static const String route = '/home/add/city';
  UserModel? currentUser;

  AddCityScreenForce({this.currentUser});

  @override
  _AddCityScreenForceState createState() => _AddCityScreenForceState();
}

class _AddCityScreenForceState extends ResumableState<AddCityScreenForce> {

  bool isCityHidden = false;
  bool locationSaved = false;

  TextEditingController placesEditingController = TextEditingController();

  String search = "";

  _searchPlaces(String text) {
    setState(() {
      search = text;
    });
  }

  Future<void> getAddressFromLatLong({PlaceModel? placeModel}) async {

    QuickHelp.showLoadingDialog(context);

    if(placeModel != null){

      widget.currentUser!.setLocation = placeModel.getLocation()!;
      widget.currentUser!.setCity = placeModel.getLocality()!;

      ParseGeoPoint parseGeoPoint = new ParseGeoPoint();
      parseGeoPoint.latitude = placeModel.place!.latLng!.lat;
      parseGeoPoint.longitude = placeModel.place!.latLng!.lng;

      widget.currentUser!.setHasGeoPoint = true;
      widget.currentUser!.setGeoPoint = parseGeoPoint;
      widget.currentUser!.setLocationTypeNearBy = false;

      ParseResponse parseResponse = await widget.currentUser!.save();

      if(parseResponse.success){

        widget.currentUser = parseResponse.results!.first as UserModel;

        QuickHelp.hideLoadingDialog(context);
        goHome();

      } else {
        QuickHelp.hideLoadingDialog(context);
      }
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  goHome(){
    QuickHelp.goToNavigatorScreen(
        context,
        HomeScreen(
          currentUser: widget.currentUser,
        ), back: false,
        route: HomeScreen.route);
  }

  @override
  void initState() {
    super.initState();
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
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      child: Container(
        padding:  EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          top: 15,
        ),
        child: Column(
          children: [
            ContainerCorner(
              height: 55,
              borderRadius: 10,
              marginTop: 15,
              color:  kGreyColor0,
              child: Padding(
                padding:  EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:  [
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SvgPicture.asset("assets/svg/ic_search.svg", width: 27, height: 27, color: kDisabledGrayColor,),
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
        )),
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
