import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/home_screen.dart';
import 'package:heyto/home/message/message_screen.dart';
import 'package:heyto/home/profile/user_profile_details_screen.dart';
import 'package:heyto/models/EncountersModel.dart';
import 'package:heyto/models/MessageListModel.dart';
import 'package:heyto/models/MessagesModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/counter_providers.dart';
import 'package:heyto/ui/button_widget.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:provider/provider.dart';


// ignore: must_be_immutable
class ResponsiveChat extends StatefulWidget {
  UserModel? currentUser, mUser;

  ResponsiveChat({this.currentUser, this.mUser});

  static const String route = "home/all_chats";

  @override
  State<ResponsiveChat> createState() => _ResponsiveChatState();
}

class _ResponsiveChatState extends State<ResponsiveChat> {
  bool messageSelected = true;
  final LiveQuery liveQuery = LiveQuery();
  Subscription? subscription;
  List<dynamic> globalUsers = [];
  List<dynamic> results = <dynamic>[];
  late QueryBuilder<MessageModel> queryBuilder;
  List<dynamic> unreadMessages = [];
  int unreadMessage = 0;

  UserModel? friendForChat;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    if(widget.mUser != null){
      setState(() {
        friendForChat = widget.mUser;
      });
    }

    return Row(
      children: [
        Flexible(
          flex: 3,
          child: chatMessages(),
        ),
        ContainerCorner(
          width: 1,
          color: kGrayColor,
          height: size.height,
        ),
        if (!Responsive.isMobile(context))
          Flexible(
            flex: 5,
            child: friendForChat != null
                ? conversation()
                : Center(
                    child: QuickActions.noContentFound(
                      "message_screen.no_selected_message_tittle".tr(),
                      "message_screen.no_selected_message_explain".tr(),
                      "assets/svg/ic_tab_message.svg",
                    ),
                  ),
          ),
        ContainerCorner(
          width: 1,
          color: kGrayColor,
          height: size.height,
        ),
        if (!Responsive.isTablet(context) && friendForChat != null)
          Flexible(
              flex: 3,
              child: UserProfileDetailsScreen(currentUser: widget.currentUser, mUser: friendForChat,showComponents: false,),)
      ],
    );
  }

  Widget conversation() {

    return  MessageScreen(
          currentUser: widget.currentUser,
          mUser: friendForChat,
          key: Key(friendForChat!.objectId!),
        );
  }

  Widget chatMessages() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWithTap(
            "chat_screen.new_matches".tr(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            marginLeft: 10,
          ),
          Row(
            children: [
              loadLikes(),
              Flexible(child: loadNewMatches()),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWithTap(
                "chat_screen.messages_".tr(),
                marginLeft: 10,
                fontSize: 20,
                marginTop: 20,
                fontWeight: FontWeight.w600,
              ),
              ContainerCorner(
                color: kPrimaryColor,
                marginRight: 10,
                marginTop: 20,
                width: 22,
                height: 22,
                borderRadius: 50,
                child: FutureBuilder(
                  future: totalUnreadMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      unreadMessages = snapshot.data as List<dynamic>;
                      return FittedBox(
                        child: TextWithTap(
                          unreadMessages.length.toString(),
                          color: Colors.white,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return TextWithTap(
                        "0",
                        color: Colors.white,
                        marginLeft: 5,
                        marginRight: 5,
                      );
                    } else {
                      return TextWithTap(
                        "0",
                        color: Colors.white,
                        marginLeft: 5,
                        marginRight: 5,
                      );
                    }
                  },
                ),
              )
            ],
          ),
          Expanded(
            child: loadMessages(
                widget.currentUser!, MessageListModel.keyUpdatedAt),
          ),
        ],
      ),
    );
  }

  setupLiveQuery() async {
    if (subscription == null) {
      subscription = await liveQuery.client.subscribe(queryBuilder);
    }

    subscription!.on(LiveQueryEvent.create, (MessageModel message) {
      if (message.getAuthorId != widget.currentUser!.objectId) {
        setState(() {
          results.add(message);
          unreadMessage = results.length;
        });
      } else {
        setState(() {});
      }
    });

    subscription!.on(LiveQueryEvent.update, (MessageModel message) {
      setState(() {
        results.add(message);
        unreadMessage = results.length;
      });
    });
  }

  Widget loadNewMatches() {
    QueryBuilder<EncountersModel> queryMatches =
        QueryBuilder<EncountersModel>(EncountersModel());

    queryMatches.whereEqualTo(
        EncountersModel.keyToUserId, widget.currentUser!.objectId);
    queryMatches.whereEqualTo(EncountersModel.keyLiked, true);
    queryMatches.whereEqualTo(EncountersModel.keySeen, true);

    queryMatches.orderByAscending(EncountersModel.keyUpdatedAt);

    queryMatches.includeObject([EncountersModel.keyFromUser]);

    return ContainerCorner(
      color: kTransparentColor,
      height: 100,
      width: MediaQuery.of(context).size.width,
      child: ParseLiveListWidget<EncountersModel>(
        scrollDirection: Axis.horizontal,
        query: queryMatches,
        reverse: false,
        lazyLoading: false,
        shrinkWrap: true,
        duration: Duration(milliseconds: 300),
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<ParseObject> snapshot) {

          if (snapshot.hasData) {
            EncountersModel encounterUser =
                snapshot.loadedData! as EncountersModel;
            return ContainerCorner(
              color: kTransparentColor,
              borderRadius: 50,
              marginLeft: 10,
              marginTop: 5,
              marginRight: 5,
              onTap: () {

                if(!Responsive.isMobile(context)){
                  setState(() {
                    friendForChat = encounterUser.getAuthor;
                  });
                }else{
                  QuickActions.sendMessage(context, widget.currentUser, encounterUser.getAuthor);
                }
              },
              child: Column(
                children: [
                  QuickActions.avatarWidget(encounterUser.getAuthor!,
                      width: 70, height: 70),
                  TextWithTap(
                    encounterUser.getAuthor!.getFirstName!,
                    color: QuickHelp.isDarkMode(context)
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  )
                ],
              ),
            );
          }
          return ContainerCorner(
            color: kBlueColor1,
            width: 30,
            height: 30,
          );
        },
        listLoadingElement: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(6, (index) {
              return ContainerCorner(
                color: kTransparentColor,
                marginTop: 5,
                marginLeft: 10,
                child: Column(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    FadeShimmer(
                      height: 8,
                      width: 50,
                      radius: 4,
                      millisecondsDelay: 0,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>?> loadUser() async {
    QueryBuilder<EncountersModel> queryMatches =
        QueryBuilder<EncountersModel>(EncountersModel());

    queryMatches.whereEqualTo(EncountersModel.keyToUser, widget.currentUser);
    queryMatches.whereEqualTo(EncountersModel.keyLiked, true);
    queryMatches.whereEqualTo(EncountersModel.keySeen, false);

    ParseResponse apiResponse = await queryMatches.query();
    if (apiResponse.success) {
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as List<dynamic>;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  Future<List<dynamic>?> totalUnreadMessages() async {
    queryBuilder = QueryBuilder<MessageModel>(MessageModel());
    queryBuilder.whereEqualTo(MessageModel.keyRead, false);
    queryBuilder.whereEqualTo(
        MessageModel.keyReceiverId, widget.currentUser!.objectId!);

    setupLiveQuery();

    ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success) {
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as List<dynamic>;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  Widget loadLikes() {
    return Column(
      children: [
        ContainerCorner(
          color: kTransparentColor,
          borderRadius: 50,
          borderWidth: 2,
          borderColor: kRedColor1,
          marginTop: 5,
          marginLeft: 10,
          height: 70,
          width: 70,
          onTap: () =>
              context.read<CountersProvider>().setTabIndex(HomeScreen.tabLikes),
          child: ContainerCorner(
            colors: [kRedColor1, kViolet],
            borderColor: Colors.white,
            borderWidth: 2,
            borderRadius: 50,
            height: 40,
            width: 40,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            child: FutureBuilder(
                future: loadUser(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    globalUsers = snapshot.data as List<dynamic>;

                    return Center(
                      child: TextWithTap(
                        globalUsers.length.toString(),
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: TextWithTap(
                      "0",
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    )); //Icon(Icons.error_outline)  freeWidget(thereLikes: true);
                  } else {
                    return Center(
                        child: TextWithTap(
                      "0",
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ));
                  }
                }),
          ),
        ),
        TextWithTap(
          "chat_screen.likes_".tr(),
          color: kRedColor1,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ],
    );
  }

  Widget loadMessages(UserModel currentUser, String orderBy) {

    QueryBuilder<UserModel> queryUsers =
        QueryBuilder<UserModel>(UserModel.forQuery());
    if (orderBy == MessageListModel.keyOnline) {
      queryUsers.whereGreaterThanOrEqualsTo(
          UserModel.keyUpdatedAt, QuickHelp.getMinutesToOnline());

    } else if (orderBy == MessageListModel.keyFavorite) {
      queryUsers.whereContainedIn(
          UserModel.keyFavorites, widget.currentUser!.getFavoritesUsersQuery!);

    } else if (orderBy == MessageListModel.keyRead) {

    } else if (orderBy == MessageListModel.keyUpdatedAt) {

    }

    QueryBuilder<MessageListModel> queryFrom =
        QueryBuilder<MessageListModel>(MessageListModel());
    queryFrom.whereEqualTo(
        MessageListModel.keyAuthorId, widget.currentUser!.objectId!);

    // Query for online users
    if (orderBy == MessageListModel.keyOnline) {
      queryFrom.whereMatchesQuery(MessageListModel.keyAuthor, queryUsers);
    } else if (orderBy == MessageListModel.keyFavorite) {
      queryFrom.whereMatchesQuery(MessageListModel.keyAuthor, queryUsers);
    }

    QueryBuilder<MessageListModel> queryTo =
        QueryBuilder<MessageListModel>(MessageListModel());
    queryTo.whereEqualTo(
        MessageListModel.keyReceiverId, widget.currentUser!.objectId!);

    // Query for online users
    if (orderBy == MessageListModel.keyOnline) {
      queryTo.whereMatchesQuery(MessageListModel.keyReceiver, queryUsers);
    } else if (orderBy == MessageListModel.keyFavorite) {
      queryTo.whereMatchesQuery(MessageListModel.keyReceiver, queryUsers);
    }

    QueryBuilder<MessageListModel> queryBuilder =
        QueryBuilder.or(MessageListModel(), [queryFrom, queryTo]);

    queryBuilder.orderByDescending(orderBy);
    queryBuilder.includeObject([
      MessageListModel.keyAuthor,
      MessageListModel.keyReceiver,
      MessageListModel.keyMessage,
      MessageListModel.keyCall
    ]);

    return ParseLiveListWidget<MessageListModel>(
      query: queryBuilder,
      reverse: false,
      lazyLoading: false,
      listeningIncludes: [
        MessageListModel.keyAuthor,
        MessageListModel.keyReceiver,
        MessageListModel.keyMessage,
        MessageListModel.keyCall
      ],
      listenOnAllSubItems: true,
      duration: Duration(milliseconds: 300),
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<ParseObject> snapshot) {
        if (snapshot.hasData) {
          MessageListModel chatMessage =
              snapshot.loadedData! as MessageListModel;

          UserModel chatUser = chatMessage.getAuthorId! == currentUser.objectId!
              ? chatMessage.getReceiver!
              : chatMessage.getAuthor!;
          bool isMe =
              chatMessage.getAuthorId! == currentUser.objectId! ? true : false;

          bool selectedChat = friendForChat != null && friendForChat == chatUser;

          return ButtonWidget(
            backgroundColor: selectedChat? kPrimaryColor.withOpacity(0.05) : Colors.transparent,
            height: 50,
            onTap: () {
              if(!Responsive.isMobile(context)){
                setState(() {
                  friendForChat = chatUser;
                });
              }else{
                QuickActions.sendMessage(context, currentUser, chatUser);
              }

            },
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            QuickActions.avatarWidget(
                              chatUser,
                              width: 50,
                              height: 50,
                            ),
                            Positioned(
                                bottom: 0,
                                right: 0,
                                child: Visibility(
                                  visible:
                                      QuickHelp.isUserOnlineStatusBool(chatUser)
                                          ? true
                                          : false,
                                  child: ContainerCorner(
                                    color: QuickHelp.isUserOnlineStatus(
                                                chatUser) ==
                                            QuickHelp.userStatusOnline
                                        ? kPrimaryColor
                                        : kBlueColor1,
                                    height: 12,
                                    width: 12,
                                    borderRadius: 50,
                                  ),
                                ))
                          ],
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      TextWithTap(
                                        chatUser.getFirstName!,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        marginLeft: 10,
                                        color: QuickHelp.isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        marginTop: 5,
                                        marginRight: 5,
                                      ),
                                      Visibility(
                                        visible: chatUser.getEmailVerified!,
                                        //chatUser.isPremium! ? true : false,
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: SvgPicture.asset(
                                            "assets/svg/ic_verified_account.svg",
                                            height: 17,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Visibility(
                                        visible: chatMessage.getAuthorId ==
                                            currentUser.objectId,
                                        child: Padding(
                                          padding:
                                              EdgeInsets.only(top: 7, left: 10),
                                          child: SvgPicture.asset(
                                              "assets/svg/sent.svg"),
                                        ),
                                      ),
                                      if (chatMessage.getMessageType ==
                                          MessageModel.messageTypeText)
                                        ContainerCorner(
                                          width: 230,
                                          child: TextWithTap(
                                            chatMessage.getText!,
                                            marginTop: 5,
                                            marginLeft: 10,
                                            color: !chatMessage.isRead! && !isMe
                                                ? Colors.redAccent
                                                : kGrayColor,
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight:
                                                !chatMessage.isRead! && !isMe
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      if (chatMessage.getMessageType ==
                                          MessageModel.messageTypeGif)
                                        ContainerCorner(
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(left: 5),
                                                child: Icon(
                                                  Icons.attach_file,
                                                  size: 16,
                                                  color: kGrayColor,
                                                ),
                                              ),
                                              Icon(
                                                Icons.gif,
                                                size: 40,
                                                color: kGrayColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (chatMessage.getMessageType ==
                                          MessageModel.messageTypeVoice)
                                        ContainerCorner(
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5, left: 5),
                                                child: SvgPicture.asset(
                                                  "assets/svg/ic_microphone.svg",
                                                  height: 14,
                                                  color: kGrayColor,
                                                ),
                                              ),
                                              TextWithTap(
                                                "message_screen.voice_".tr(),
                                                //chatMessage.getMessage!.getVoiceDuration!,
                                                marginTop: 5,
                                                marginLeft: 5,
                                                color: !chatMessage.isRead! &&
                                                        !isMe
                                                    ? Colors.redAccent
                                                    : kGrayColor,
                                                overflow: TextOverflow.ellipsis,
                                                fontSize: 15,
                                                fontWeight:
                                                    !chatMessage.isRead! &&
                                                            !isMe
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (chatMessage.getMessageType ==
                                          MessageModel.messageTypeCall)
                                        ContainerCorner(
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: 8, left: 5),
                                                child: Icon(
                                                  chatMessage.getCall!
                                                              .getAuthorId ==
                                                          currentUser.objectId!
                                                      ? Icons.call_made
                                                      : Icons.call_received,
                                                  size: 20,
                                                  color: kGrayColor,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: 8, left: 5),
                                                child: Icon(
                                                  chatMessage.getCall!
                                                          .getIsVoiceCall!
                                                      ? Icons.call
                                                      : Icons.videocam,
                                                  size: 20,
                                                  color: kGrayColor,
                                                ),
                                              ),
                                              TextWithTap(
                                                chatMessage
                                                        .getCall!.getAccepted!
                                                    ? chatMessage
                                                        .getCall!.getDuration!
                                                    : "message_screen.missed_call"
                                                        .tr(),
                                                marginTop: 5,
                                                marginLeft: 5,
                                                color: !chatMessage.isRead! &&
                                                        !isMe
                                                    ? Colors.redAccent
                                                    : kGrayColor,
                                                overflow: TextOverflow.ellipsis,
                                                fontSize: 17,
                                                fontWeight:
                                                    !chatMessage.isRead! &&
                                                            !isMe
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                            ],
                                          ),
                                        )
                                    ],
                                  ),
                                ],
                              )),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWithTap(
                                        QuickHelp.getMessageListTime(
                                            chatMessage.updatedAt!),
                                        marginLeft: 5,
                                        marginRight: 5,
                                        marginBottom: 5,
                                        color: kGrayColor,
                                      ),
                                    ],
                                  ),
                                  ContainerCorner(
                                    marginTop: 7,
                                    child: Row(
                                      children: [
                                        Visibility(
                                          visible:
                                              !chatMessage.isRead! && !isMe,
                                          child: ContainerCorner(
                                            borderRadius: 100,
                                            color: kRedColor1,
                                            width: 22,
                                            height: 22,
                                            marginRight: 5,
                                            child: FittedBox(
                                              child: TextWithTap(
                                                chatMessage.getCounter
                                                    .toString(),
                                                color: Colors.white,
                                                marginTop: 2,
                                                marginBottom: 2,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: currentUser
                                              .getFavoritesUsers!
                                              .contains(chatUser.objectId),
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right: 5, left: 5),
                                            child: SvgPicture.asset(
                                              "assets/svg/star_active.svg",
                                              height: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Column(
            children: [
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              ContainerCorner(
                color: kTransparentColor,
                marginLeft: 10,
                marginBottom: 5,
                child: Row(
                  children: [
                    FadeShimmer.round(
                      size: 70,
                      fadeTheme: QuickHelp.isDarkMode(context)
                          ? FadeTheme.dark
                          : FadeTheme.light,
                      millisecondsDelay: 0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeShimmer(
                            height: 12,
                            width: MediaQuery.of(context).size.width - 150.0,
                            radius: 10,
                            millisecondsDelay: 0,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FadeShimmer(
                            height: 10,
                            millisecondsDelay: 0,
                            width: MediaQuery.of(context).size.width - 120.0,
                            radius: 10,
                            fadeTheme: QuickHelp.isDarkMode(context)
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        }
      },
      queryEmptyElement: Center(
        child: QuickActions.noContentFound(
          "message_screen.no_message_title".tr(),
          "message_screen.no_message_explain".tr(),
          "assets/svg/ic_tab_message.svg",
        ),
      ),
      listLoadingElement: SingleChildScrollView(
        child: Column(
          children: List.generate(8, (index) {
            return ContainerCorner(
              color: kTransparentColor,
              marginLeft: 10,
              marginBottom: 5,
              child: Row(
                children: [
                  FadeShimmer.round(
                    size: 70,
                    fadeTheme: QuickHelp.isDarkMode(context)
                        ? FadeTheme.dark
                        : FadeTheme.light,
                    millisecondsDelay: 0,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeShimmer(
                          height: 12,
                          width: MediaQuery.of(context).size.width - 150.0,
                          radius: 10,
                          millisecondsDelay: 0,
                          fadeTheme: QuickHelp.isDarkMode(context)
                              ? FadeTheme.dark
                              : FadeTheme.light,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        FadeShimmer(
                          height: 10,
                          millisecondsDelay: 0,
                          width: MediaQuery.of(context).size.width - 120.0,
                          radius: 10,
                          fadeTheme: QuickHelp.isDarkMode(context)
                              ? FadeTheme.dark
                              : FadeTheme.light,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
