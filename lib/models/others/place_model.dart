import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class PlaceModel {

  String? id;
  String? locality;
  String? country;
  String? location;
  Place? place;

  PlaceModel({this.id, this.locality, this.country, this.location, this.place});

  String? getId() {
    return id;
  }

  void setId(String id) {
    this.id = id;
  }

  String? getLocality() {
    return locality;
  }

  void setLocality(String locality) {
    this.locality = locality;
  }

  String? getCountry() {
    return country;
  }

  void setCountry(String country) {
    this.country = country;
  }

  String? getLocation() {
    return location;
  }

  void setLocation(String location) {
    this.location = location;
  }

  Place? getPlace() {
    return place;
  }

  void setPlace(Place place) {
    this.place = place;
  }
}