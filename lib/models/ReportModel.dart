import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class ReportModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "Report";

  ReportModel() : super(keyTableName);
  ReportModel.clone() : this();

  @override
  ReportModel clone(Map<String, dynamic> map) => ReportModel.clone()..fromJson(map);


  static String keyCreatedAt = "createdAt";
  static String keyUpdatedAt = "updatedAt";
  static String keyObjectId = "objectId";

  static String stateResolved = "resolved";
  static String stateFiled = "filed";
  static String statePending = "pending";
  static String stateProgress = "in progress";

  static const I_HAVE_NO_INTEREST_IN_THIS_PERSON = "NI";
  static const FAKE_PROFILE_SPAN = "FPS";
  static const INAPPROPRIATE_MESSAGE = "IM";
  static const INAPPROPRIATE_PROFILE_PICTURE = "IPP";
  static const INAPPROPRIATE_VIDEO_CALL = "IVC";
  static const INAPPROPRIATE_BIOGRAPHY = "IB";
  static const UNDERAGE_USER = "UA";
  static const OFFLINE_BEHAVIOR = "OB";
  static const SOMEONE_IS_IN_DANGER = "SID";

  static String keyAccuser = "accuser";
  static String keyAccuserId = "accuserId";

  static String keyAccused = "accused";
  static String keyAccusedId = "accusedId";

  static String keyMessage = "message";

  static String keyDescription = "description";

  static String keyState = "state";

  UserModel? get getAccuser => get<UserModel>(keyAccuser);
  set setAccuser(UserModel author) => set<UserModel>(keyAccuser, author);

  String? get getAccuserId => get<String>(keyAccuserId);
  set setAccuserId(String authorId) => set<String>(keyAccuserId, authorId);

  UserModel? get getAccused => get<UserModel>(keyAccused);
  set setAccused(UserModel user) => set<UserModel>(keyAccused, user);

  String? get getAccusedId => get<String>(keyAccusedId);
  set setAccusedId(String userId) => set<String>(keyAccusedId, userId);

  String? get getMessage => get<String>(keyMessage);
  set setMessage(String message) => set<String>(keyMessage, message);

  String? get getDescription => get<String>(keyDescription);
  set setDescription(String description) => set<String>(keyDescription, description);

  String? get getState => get<String>(keyState);
  set setState(String state) => set<String>(keyState, state);

}