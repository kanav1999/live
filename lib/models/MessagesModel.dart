import 'package:heyto/models/CallsModel.dart';
import 'package:heyto/models/MessageListModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class MessageModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "Message";

  MessageModel() : super(keyTableName);
  MessageModel.clone() : this();

  @override
  MessageModel clone(Map<String, dynamic> map) => MessageModel.clone()..fromJson(map);


  static String messageTypeText = "text";
  static String messageTypeGif = "gif";
  static String messageTypeVoice = "voice";
  static String messageTypeCall = "call";

  static String keyCreatedAt = "createdAt";
  static String keyObjectId = "objectId";

  static String keyAuthor = "Author";
  static String keyAuthorId = "AuthorId";

  static String keyReceiver = "Receiver";
  static String keyReceiverId = "ReceiverId";

  static final String keyText = "text";
  static final String keyMessageFile = "messageFile";
  static final String keyIsMessageFile = "isMessageFile";

  static final String keyRead = "read";

  static final String keyListMessage = "messageList";
  static final String keyListMessageId = "messageListId";

  static final String keyReplyMessage = "replyMessage";
  static final String keyReplyMessageAuthor = "replyMessage.Author";

  static final String keyLikeMessage = "likedMessage";

  static final String keyGifMessage = "gitMessage";

  static final String keyVoiceMessage = "voiceMessage";

  static final String keyMessageType = "messageType";

  static final String keyVoiceDuration = "voiceDuration";

  static final String keyCallDuration = "callDuration";
  static final String keyCall = "call";


  UserModel? get getAuthor => get<UserModel>(keyAuthor);
  set setAuthor(UserModel author) => set<UserModel>(keyAuthor, author);

  String? get getAuthorId => get<String>(keyAuthorId);
  set setAuthorId(String authorId) => set<String>(keyAuthorId, authorId);

  UserModel? get getReceiver => get<UserModel>(keyReceiver);
  set setReceiver(UserModel author) => set<UserModel>(keyReceiver, author);

  String? get getReceiverId => get<String>(keyReceiverId);
  set setReceiverId(String authorId) => set<String>(keyReceiverId, authorId);

  String? get getText => get<String>(keyText);
  set setText(String message) => set<String>(keyText, message);

  ParseFileBase? get getMessageFile => get<ParseFileBase>(keyMessageFile);
  set setMessageFile(ParseFileBase messageFile) => set<ParseFileBase>(keyMessageFile, messageFile);

  bool? get isMessageFile => get<bool>(keyMessageFile);
  set setIsMessageFile(bool isMessageFile) => set<bool>(keyMessageFile, isMessageFile);

  bool? get isRead => get<bool>(keyRead);
  set setIsRead(bool isRead) => set<bool>(keyRead, isRead);

  MessageListModel? get getMessageList => get<MessageListModel>(keyListMessage);
  set setMessageList(MessageListModel messageListModel) => set<MessageListModel>(keyListMessage, messageListModel);

  String? get getMessageListId => get<String>(keyListMessageId);
  set setMessageListId(String messageListId) => set<String>(keyListMessageId, messageListId);

  MessageModel? get getReplyMessage => get<MessageModel>(keyReplyMessage);
  set setReplyMessage(MessageModel replyMessage) => set<MessageModel>(keyReplyMessage, replyMessage);

  String? get getDuration => get<String>(keyCallDuration);
  set setDuration(String message) => set<String>(keyCallDuration, message);

  bool? get isLikedMessage {
    bool? like = get<bool>(keyLikeMessage);
    if(like != null){
      return like;
    }
    return false;
  }
  set setIsLikedMessage(bool isLikedMessage) => set<bool>(keyLikeMessage, isLikedMessage);

  String? get getGifMessage => get<String>(keyGifMessage);
  set setGifMessage(String gifMessage) => set<String>(keyGifMessage, gifMessage);

  String? get getMessageType => get<String>(keyMessageType);
  set setMessageType(String messageType) => set<String>(keyMessageType, messageType);

  ParseFileBase? get getVoiceMessage => get<ParseFileBase>(keyVoiceMessage);
  set setVoiceMessage(ParseFileBase voiceMessage) => set<ParseFileBase>(keyVoiceMessage, voiceMessage);

  String? get getVoiceDuration => get<String>(keyVoiceDuration);
  set setVoiceDuration(String voiceDuration) => set<String>(keyVoiceDuration, voiceDuration);

  CallsModel? get getCall => get<CallsModel>(keyCall);
  set setCall(CallsModel call) => set<CallsModel>(keyCall, call);

}