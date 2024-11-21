import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class OrderMessagesModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "OrderMessages";

  OrderMessagesModel() : super(keyTableName);
  OrderMessagesModel.clone() : this();

  @override
  OrderMessagesModel clone(Map<String, dynamic> map) => OrderMessagesModel.clone()..fromJson(map);

  static String keyCreatedAt = "createdAt";
  static String keyUpdatedAt = "updatedAt";
  static String keyObjectId = "objectId";

  static const RECENT_FIRST = "RF";
  static const UNREAD_FIRST = "UF";
  static const ONLINE = "OL";
  static const FAVORITES = "FV";

  static String keyAuthor = "Author";

  static String keyOrder = "order";


  UserModel? get getAuthor => get<UserModel>(keyAuthor);
  set setAuthor(UserModel user) => set<UserModel>(keyAuthor, user);

  String? get getOrder => get<String>(keyOrder);
  set setOrder(String order) => set<String>(keyOrder, order);

}