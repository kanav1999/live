import 'package:heyto/models/GiftsModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class LiveStreamingModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "Streaming";

  LiveStreamingModel() : super(keyTableName);
  LiveStreamingModel.clone() : this();

  @override
  LiveStreamingModel clone(Map<String, dynamic> map) => LiveStreamingModel.clone()..fromJson(map);

  static final String privacyTypeAnyone = "anyone";
  static final String privacyTypeFriends = "friends";
  static final String privacyTypeNoOne = "none";

  static final String liveTypeParty = "party";
  static final String liveTypeGoLive = "live";
  static final String liveTypeBattle = "battle";

  static String keyCreatedAt = "createdAt";
  static String keyObjectId = "objectId";

  static String keyAuthor = "Author";
  static String keyAuthorId = "AuthorId";
  static String keyAuthorUid = "AuthorUid";

  static String keyViewsCount = "viewsCount";

  static String keyAuthorInvited = "AuthorInvited";
  static String keyAuthorInvitedUid = "AuthorInvitedUid";

  static final String keyViewersUid = "viewers_uid";
  static final String keyViewersId = "viewers_id";

  static final String keyViewersCountLive = "viewersCountLive";
  static final String keyStreamingPrivate = "private";

  static final String keyLiveImage = "image";
  static final String keyLiveGeoPoint = "geoPoint";
  static final String keyLiveTags = "live_tag";

  static final String keyStreaming = "streaming";
  static final String keyStreamingTime = "streaming_time";
  static final String keyStreamingDiamonds = "streaming_diamonds";

  static final String keyStreamingChannel = "streaming_channel";

  static final String keyStreamingCategory = "streaming_category";

  static final String keyCoHostAvailable = "coHostAvailable";
  static final String keyCoHostAuthor = "coHostAuthor";
  static final String keyCoHostAuthorUid = "coHostAuthorUid";


  static final String keyPrivateLiveGift = "privateLivePrice";
  static final String keyPrivateViewers = "privateViewers";

  static final String keyLiveTitle = "live_title";


  UserModel? get getAuthor => get<UserModel>(keyAuthor);
  set setAuthor(UserModel author) => set<UserModel>(keyAuthor, author);

  int? get getAuthorUid => get<int>(keyAuthorUid);
  set setAuthorUid(int authorUid) => set<int>(keyAuthorUid, authorUid);

  UserModel? get getCoHostAuthor => get<UserModel>(keyCoHostAuthor);
  set setCoHostAuthor(UserModel author) => set<UserModel>(keyCoHostAuthor, author);

  int? get getCoHostAuthorUid => get<int>(keyCoHostAuthorUid);
  set setCoHostAuthorUid(int authorUid) => set<int>(keyCoHostAuthorUid, authorUid);

  bool? get getCoHostAuthorAvailable => get<bool>(keyCoHostAvailable);
  set setCoHostAvailable(bool coHostAvailable) => set<bool>(keyCoHostAvailable, coHostAvailable);

  String? get getAuthorId => get<String>(keyAuthorId);
  set setAuthorId(String authorId) => set<String>(keyAuthorId, authorId);

  UserModel? get getAuthorInvited => get<UserModel>(keyAuthorInvited);
  set setAuthorInvited(UserModel invitedAuthor) => set<UserModel>(keyAuthorInvited, invitedAuthor);

  int? get getAuthorInvitedUid => get<int>(keyAuthorInvitedUid);
  set setAuthorInvitedUid(int invitedAuthorUid) => set<int>(keyAuthorInvitedUid, invitedAuthorUid);

  int? get getViewersCount{

    int? viewersCount = get<int>(keyViewersCountLive);
    if(viewersCount != null){
      return viewersCount;
    } else {
      return 0;
    }
  }
  set addViewersCount(int viewersCount) => setIncrement(keyViewersCountLive, viewersCount);
  set removeViewersCount(int viewersCount) => setDecrement(keyViewersCountLive, viewersCount);


  ParseFileBase? get getImage => get<ParseFileBase>(keyLiveImage);
  set setImage(ParseFileBase imageFile) => set<ParseFileBase>(keyLiveImage, imageFile);

  List<dynamic>? get getViewers{

    List<dynamic>? viewers = get<List<dynamic>>(keyViewersUid);
    if(viewers != null && viewers.length > 0){
      return viewers;
    } else {
      return [];
    }
  }
  set setViewers(int viewerUid) => setAddUnique(keyViewersUid, viewerUid);

  List<dynamic>? get getViewersId{

    List<dynamic>? viewersId = get<List<dynamic>>(keyViewersId);
    if(viewersId != null && viewersId.length > 0){
      return viewersId;
    } else {
      return [];
    }
  }
  set setViewersId(String viewerAuthorId) => setAddUnique(keyViewersId, viewerAuthorId);

  int? get getDiamonds => get<int>(keyStreamingDiamonds);
  set addDiamonds(int diamonds) => setIncrement(keyStreamingDiamonds, diamonds);

  bool? get getStreaming => get<bool>(keyStreaming);
  set setStreaming(bool isStreaming) => set<bool>(keyStreaming, isStreaming);

  String? get getStreamingTime => get<String>(keyStreamingTime);
  set setStreamingTime(String streamingTime) => set<String>(keyStreamingTime, streamingTime);

  String? get getLiveTitle => get<String>(keyLiveTitle);
  set setLiveTitle(String liveTitle) => set<String>(keyLiveTitle, liveTitle);

  String? get getStreamingCategory => get<String>(keyStreamingCategory);
  set setStreamingCategory(String streamingCategory) => set<String>(keyStreamingCategory, streamingCategory);

  String? get getStreamingTags {
    String? text = get<String>(keyLiveTags);
    if(text != null){
      return text;
    } else {
      return "";
    }
  }

  set setStreamingTags(String text) => set<String>(keyLiveTags, text);

  String? get getStreamingChannel => get<String>(keyStreamingChannel);
  set setStreamingChannel(String streamingChannel) => set<String>(keyStreamingChannel, streamingChannel);

  ParseGeoPoint? get getStreamingGeoPoint => get<ParseGeoPoint>(keyLiveGeoPoint);
  set setStreamingGeoPoint(ParseGeoPoint liveGeoPoint) => set<ParseGeoPoint>(keyLiveGeoPoint, liveGeoPoint);

  bool? get getPrivate{
    bool? private = get<bool>(keyStreamingPrivate);
    if(private != null){
      return private;
    } else {
      return false;
    }
  }
  set setPrivate(bool private) => set<bool>(keyStreamingPrivate, private);

  GiftsModel? get getPrivateGift => get<GiftsModel>(keyPrivateLiveGift);
  set setPrivateLivePrice(GiftsModel privateLivePrice) => set<GiftsModel>(keyPrivateLiveGift, privateLivePrice);
  set removePrice(GiftsModel privateLivePrice) => setRemove(keyPrivateLiveGift, privateLivePrice);

  List<dynamic>? get getPrivateViewersId{

    List<dynamic>? viewersId = get<List<dynamic>>(keyPrivateViewers);
    if(viewersId != null && viewersId.length > 0){
      return viewersId;
    } else {
      return [];
    }
  }
  set setPrivateViewersId(String viewerAuthorId) => setAddUnique(keyPrivateViewers, viewerAuthorId);

  set setPrivateListViewersId(List viewersId) {

    List<String> listViewersId = [];

    for(String privateViewer in viewersId){
      listViewersId.add(privateViewer);
    }
    setAddAllUnique(keyPrivateViewers, listViewersId);
  }

}