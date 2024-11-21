import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class EncountersModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "Encounters";

  EncountersModel() : super(keyTableName);
  EncountersModel.clone() : this();

  @override
  EncountersModel clone(Map<String, dynamic> map) => EncountersModel.clone()..fromJson(map);

  /*@override
  EncountersModel fromJson(Map<String, dynamic> objectData) {
    super.fromJson(objectData);
    if (objectData.containsKey(keyAuthor)) {
      setAuthor = UserModel.clone().fromJson(objectData[keyAuthor]);
    }
    return this;
  }*/

  static String keyCreatedAt = "createdAt";
  static String keyUpdatedAt = "updatedAt";
  static String keyObjectId = "objectId";

  static String keyFromUser = "from_user";
  static String keyFromUserId = "from_user_id";

  static String keyToUser = "to_user";
  static String keyToUserId = "to_user_id";

  static String keyLiked = "liked";
  static String keySeen = "seen";

  UserModel? get getAuthor => get<UserModel>(keyFromUser);
  set setAuthor(UserModel author) => set<UserModel>(keyFromUser, author);

  String? get getAuthorId => get<String>(keyFromUserId);
  set setAuthorId(String authorId) => set<String>(keyFromUserId, authorId);

  UserModel? get getReceiver => get<UserModel>(keyToUser);
  set setReceiver(UserModel user) => set<UserModel>(keyToUser, user);

  String? get getReceiverId => get<String>(keyToUserId);
  set setReceiverId(String userId) => set<String>(keyToUserId, userId);

  bool? get getLike {

    bool? like = get<bool>(keyLiked);
    if(like != null){
      return like;
    } else {
      return false;
    }
  }
  set setLike(bool like) => set<bool>(keyLiked, like);

  bool? get getSeen {

    bool? seen = get<bool>(keySeen);
    if(seen != null){
      return seen;
    } else {
      return false;
    }
  }
  set setSeen(bool seen) => set<bool>(keySeen, seen);
}