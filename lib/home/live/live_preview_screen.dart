import 'dart:io';

import 'package:blur/blur.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/LiveStreamingModel.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';

import '../profile/image_crop_screen.dart';
import 'live_streaming_screen.dart';

// ignore: must_be_immutable
class LivePreviewScreen extends StatefulWidget {
  UserModel? currentUser;

  LivePreviewScreen({this.currentUser});

  static String route = "/home/live/preview";

  @override
  _LivePreviewScreenState createState() => _LivePreviewScreenState();
}

TextEditingController liveTitleController = TextEditingController();
late FocusNode? titleTextFieldFocusNode;

String uploadPhoto = "";
ParseFileBase? parseFile;

class _LivePreviewScreenState extends State<LivePreviewScreen> {



  @override
  void initState() {

    titleTextFieldFocusNode = FocusNode();
    titleTextFieldFocusNode!.requestFocus();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        FocusScopeNode focusScopeNode = FocusScope.of(context);
        if (!focusScopeNode.hasPrimaryFocus &&
            focusScopeNode.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: kTransparentColor,
          automaticallyImplyLeading: false,
          leadingWidth: 100,
          actions: [
            ContainerCorner(
              color: Colors.black.withOpacity(0.2),
              borderRadius: 10,
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: IconButton(
                    onPressed: () => QuickHelp.goBackToPreviousPage(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    )),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Stack(alignment: AlignmentDirectional.center, children: [
            if(Responsive.isMobile(context))
            ContainerCorner(
              color: kTransparentColor,
              height: size.height,
              width: size.width,
              borderWidth: 0,
              child: QuickActions.photosWidget(widget.currentUser!.getAvatar!.url!,
                  borderRadius: 10),
            ),
            if(!Responsive.isMobile(context))
              Blur(
                  blurColor: Colors.black,
                  blur: 60,
                  child: ContainerCorner(
                    color: kTransparentColor,
                    height: size.height,
                    width: size.width,
                    borderWidth: 0,
                    child: QuickActions.photosWidget(
                        widget.currentUser!.getAvatar!.url!),
                  )
              ),
            Positioned(
              top: 150,
              child: ContainerCorner(
                height: 130,
                borderRadius: 5,
                width: Responsive.isMobile(context) ? size.width - 20 : 450,
                color: Colors.black.withOpacity(0.5),
                marginLeft: 10,
                marginRight: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(children: [
                      ContainerCorner(
                        color: kTransparentColor,
                        height: 93,
                        width: 102,
                        marginLeft: 10,
                        borderWidth: 0,
                        onTap: () => checkPermission(),
                        child: QuickActions.photosWidget(widget.currentUser!.getInitializingLiveCover == null ?
                        widget.currentUser!.getAvatar!.url! : widget.currentUser!.getInitializingLiveCover!.url!, borderRadius: 5),
                      ),
                      Positioned(
                        bottom: 0.001,
                        child: InkWell(
                          onTap: () {},
                          child: ContainerCorner(
                            width: 102,
                            height: 24,
                            marginLeft: 10,
                            color: Colors.black.withOpacity(0.5),
                            radiusBottomLeft: 5,
                            radiusBottomRight: 5,
                            onTap: () => checkPermission(),
                            child: FittedBox(
                              child: Center(
                                  child: TextWithTap(
                                "live_streaming.change_cover".tr(),
                                color: Colors.white,
                                marginRight: 3,
                                marginLeft: 3,
                                marginBottom: 3,
                                marginTop: 3,
                              )),
                            ),
                          ),
                        ),
                      )
                    ]),
                    Flexible(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 10, top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWithTap(
                            "live_streaming.live_title".tr(),
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          TextField(
                            controller: liveTitleController,
                            focusNode: titleTextFieldFocusNode,
                            autocorrect: false,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (text) {
                              if (text.isNotEmpty) {
                                setState(() {
                                  //searchText = text;
                                  //isSearchFieldFiled = true;
                                });
                              } else {
                                setState(() {
                                  //isSearchFieldFiled = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "live_streaming.live_title_input".tr(),
                                hintStyle:
                                    TextStyle(color: kGrayColor.withOpacity(0.4), fontSize: 14)),
                          ),
                          Row(
                            children: [
                              TextWithTap(
                                "live_streaming.share_with".tr(),
                                color: Colors.white,
                                fontSize: 12,
                                marginTop: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 5, top: 5, right: 5),
                                child: Icon(Icons.facebook, color: Colors.white,),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                ),
                                child: Icon(Icons.transform, color: Colors.white,),
                              )
                            ],
                          )
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              child: ButtonWithGradient(
                  text: "live_streaming.live_broadcast".tr(),
                beginColor: kRedColor1,
                endColor: kRedColor1,
                fontSize: 14,
                width: 237,
                borderRadius: 50,
                marginLeft: 10,
                onTap: (){
                    if(liveTitleController.text.isEmpty){

                      titleTextFieldFocusNode!.requestFocus();

                      QuickHelp.showAppNotificationAdvanced(
                        title: "live_streaming.title_unset_title".tr(),
                        message: "live_streaming.title_unset_explain".tr(),
                        context: context,
                        isError: true,
                      );
                    }else{
                      createLive();
                    }
                },
              ),
            )
          ]),
        ),
      ),
    );
  }

  void createLive() async {

    QuickHelp.showLoadingDialog(context, isDismissible: false);

    QueryBuilder<LiveStreamingModel> queryBuilder = QueryBuilder(LiveStreamingModel());
    queryBuilder.whereEqualTo(LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId);
    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);

    ParseResponse parseResponse = await queryBuilder.query();
    if(parseResponse.success){

      if(parseResponse.results != null){
        LiveStreamingModel live = parseResponse.results!.first! as LiveStreamingModel;

        live.setStreaming = false;
        await live.save();

        createLiveFinish();

      } else {
        createLiveFinish();
      }

    } else {

      QuickHelp.showErrorResult(context, parseResponse.error!.code);
      QuickHelp.hideLoadingDialog(context);
    }
  }

  createLiveFinish() async {

    LiveStreamingModel streamingModel = LiveStreamingModel();
    streamingModel.setStreamingChannel = widget.currentUser!.objectId!+QuickHelp.generateShortUId().toString();

    streamingModel.setAuthor = widget.currentUser!;
    streamingModel.setAuthorId = widget.currentUser!.objectId!;
    streamingModel.setAuthorUid = widget.currentUser!.getUid!;

    if(parseFile != null){
      streamingModel.setImage = parseFile!;
    } else if(widget.currentUser!.getAvatar != null){
      streamingModel.setImage = widget.currentUser!.getAvatar!;
    }

    if(widget.currentUser!.getGeoPoint != null){
      streamingModel.setStreamingGeoPoint = widget.currentUser!.getGeoPoint!;
    }

    streamingModel.setPrivate = false;
    streamingModel.setStreaming = false;
    streamingModel.addViewersCount = 0;
    streamingModel.addDiamonds = 0;

    streamingModel.setLiveTitle = liveTitleController.text;

    ParseResponse parseResponse = await streamingModel.save();

    if(parseResponse.success){
      LiveStreamingModel liveStreaming = parseResponse.results!.first!;

      widget.currentUser!.unset(UserModel.keyInitializingLiveCover);
      widget.currentUser!.save();

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, LiveStreamingScreen(channelName: streamingModel.getStreamingChannel!, isBroadcaster: true, currentUser: widget.currentUser!, mLiveStreamingModel: liveStreaming,), route: LiveStreamingScreen.route);


    } else {

      QuickHelp.showErrorResult(context, parseResponse.error!.code);
      QuickHelp.hideLoadingDialog(context);
    }
  }

  checkPermission() async {

    if(QuickHelp.isMobile()){

      if (await Permission.camera.isGranted) {
        //Choose picture
        _choosePhoto();
      } else if (await Permission.camera.isDenied) {

        QuickHelp.showDialogPermission(
            context: context,
            title: "permissions.photo_access".tr(),
            confirmButtonText: "permissions.okay_".tr().toUpperCase(),
            message: "permissions.photo_access_explain"
                .tr(namedArgs: {"app_name": Setup.appName}),
            onPressed: () async {
              QuickHelp.hideLoadingDialog(context);

              // You can request multiple permissions at once.
              Map<Permission, PermissionStatus> statuses = await [
                Permission.camera
              ].request();

              if (statuses[Permission.camera]!.isGranted) {
                //Choose picture
                _choosePhoto();
              } else {
                QuickHelp.showAppNotificationAdvanced(
                    title: "permissions.photo_access_denied".tr(),
                    message: "permissions.photo_access_denied_explain"
                        .tr(namedArgs: {"app_name": Setup.appName}),
                    context: context,
                    isError: true);
              }
            });
      } else if (await Permission.camera.isPermanentlyDenied) {
        openAppSettings();
      }

    } else {

      _choosePhoto();
    }
  }

  _choosePhoto() async {

    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if(image != null){

      cropPhoto(image: image.path);

    } else {

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "crop_image_scree.cancelled_by_user".tr(),
        message: "crop_image_scree.image_not_selected".tr(),
      );
    }
  }

  void compressImage(Future<ImageFile> image) {

    QuickHelp.showLoadingDialogWithText(context, description: "crop_image_scree.optimizing_image".tr(), useLogo: true);

    image.then((value) {

      Future.delayed(Duration(seconds: 1), () async{
        var result = await QuickHelp.compressImage(value, quality: value.sizeInBytes >= 1000000 ? 30 : 50);

        if(result != null){

          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showLoadingDialogWithText(context, description: "crop_image_scree.optimizing_image_uploading".tr());

          if(result.filePath.isNotEmpty){
            parseFile = ParseFile(File(result.filePath), name: "avatar.jpg");
          } else {
            parseFile = ParseWebFile(result.rawBytes, name: "avatar.jpg");
          }

          ParseResponse parseResponse = await parseFile!.save();
          if (parseResponse.success) {
            QuickHelp.hideLoadingDialog(context);
            setState(() {
              _updateLiveCover(parseFile!);
            });
          } else {
            QuickHelp.showAppNotification(
                context: context, title: parseResponse.error!.message);
            QuickHelp.showLoadingDialog(context);
          }

        } else {

          QuickHelp.hideLoadingDialog(context);

          QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "crop_image_scree.cancelled_by_user".tr(),
            message: "crop_image_scree.image_not_cropped_error".tr(),
          );
        }
      });

    }).onError((error, stackTrace){

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "try_again_later".tr(),
      );

    });
  }

  void cropPhoto({dynamic image}) async {

    QuickHelp.showLoadingDialog(context);

    var result = await QuickHelp.goToNavigatorScreenForResult(
        context,
        ImageCropScreen(
          pathOrBytes: image,
          aspectRatio: ImageCropScreen.aspectRatioSquare,
        ),
        route: ImageCropScreen.route);

    if(result != null){

      XFile? xFile = QuickHelp.isWebPlatform() ?
      await XFile.fromData(result) :
      await XFile(result);

      QuickHelp.hideLoadingDialog(context);
      compressImage(xFile.asImageFile);

    } else {

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "crop_image_scree.cancelled_by_user".tr(),
        message: "crop_image_scree.image_not_cropped_error".tr(),
      );
    }
  }

  _updateLiveCover(ParseFileBase parseFile) async{

    widget.currentUser!.setInitializingLiveCover = parseFile;

    ParseResponse response = await widget.currentUser!.save();

    if(response.success){
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          isError: false,
          title: "profile.success_saving_picture_title".tr(),
          message: "profile.success_saving_live_cover_explain".tr());
    } else{
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          isError: true,
          title: "profile.error_saving_picture_title".tr(),
          message: "profile.error_saving_picture_explain".tr());
    }
  }
}
