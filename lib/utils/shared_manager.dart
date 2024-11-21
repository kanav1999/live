import 'package:shared_preferences/shared_preferences.dart';

class SharedManager {

  static final String _dynamicInvitee = 'invitee';

  void setInvitee(SharedPreferences? preferences, String objectId){
     preferences!.setString(_dynamicInvitee, objectId);
  }

  String? getInvitee(SharedPreferences? preferences){
    return preferences!.getString(_dynamicInvitee) ?? "";
  }

   void clearInvitee(SharedPreferences? preferences){
     preferences!.setString(_dynamicInvitee, "");
  }
}