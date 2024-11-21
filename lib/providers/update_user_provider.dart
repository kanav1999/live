import 'package:heyto/models/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class UpdateUserProvider extends ChangeNotifier {

  UserModel? currentUser;

  void updateUser(UserModel userModel) async {

    currentUser = await ParseUser.currentUser();

    userModel.clearUnsavedChanges();

    ParseResponse? parseResponse = await ParseUser.getCurrentUserFromServer(currentUser!.getSessionToken!);

    if (parseResponse != null && parseResponse.success && parseResponse.results != null) {

      currentUser = parseResponse.results!.first! as UserModel;
      userModel = parseResponse.results!.first! as UserModel;
      notifyListeners();

      print("PROVIDER USER UPDATED");
    }
  }

  UserModel? getUser() {

    notifyListeners();
    return currentUser;
  }
}