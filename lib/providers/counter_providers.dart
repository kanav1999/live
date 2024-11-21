import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/MessageListModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class CountersProvider extends ChangeNotifier {

  int messagesCounter = 0;
  int likesCounter = 0;
  int tabIndex = 0;
  //int credits = 0;


  void setTabIndex(int index){
    tabIndex = index;
    notifyListeners();
  }

  /*void updateCredit(UserModel currentUser){
    credits = currentUser.getCredits!;
    notifyListeners();
  }*/

  void getLikesCounter(BuildContext context, UserModel currentUser) async {
    QueryBuilder<EncountersModel> encountersQuery = QueryBuilder<EncountersModel>(EncountersModel());

    //keySeen == true && keyLiked == true (Match)
    //keySeen == false && keyLiked == true (Like)

    encountersQuery.whereEqualTo(EncountersModel.keyToUser, currentUser);
    encountersQuery.whereEqualTo(EncountersModel.keySeen, false);
    encountersQuery.whereEqualTo(EncountersModel.keyLiked, true);

    var apiResponse = await encountersQuery.count();
    if (apiResponse.success) {

      if(apiResponse.result != null){

        likesCounter = apiResponse.count;

      } else {

        likesCounter = 0;
      }
    }
  }

  void getMessagesCounter(BuildContext context, UserModel currentUser) async {
    QueryBuilder<MessageListModel> queryToMe =
    QueryBuilder<MessageListModel>(MessageListModel());
    queryToMe.whereEqualTo(MessageListModel.keyReceiver, currentUser);
    queryToMe.whereGreaterThan(MessageListModel.keyMessageCounter, 0);

    var apiResponse = await queryToMe.count();
    if (apiResponse.success) {

      if(apiResponse.result != null){

        messagesCounter = apiResponse.count;

      } else {
        messagesCounter = 0;

      }
    }
  }
}