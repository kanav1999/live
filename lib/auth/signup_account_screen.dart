import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:heyto/app/config.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/components/DateTextFormatter.dart';
import 'package:heyto/components/FirstUpperCaseTextFormatter.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/profile/image_crop_screen.dart';
import 'package:heyto/models/PictureModel.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_widget.dart';
import 'package:heyto/ui/button_rounded_outline.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/rounded_input_field.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/quick_actions.dart';
import '../helpers/quick_cloud.dart';
import '../utils/shared_manager.dart';
import 'dispache_screen.dart';

// ignore: must_be_immutable
class SignUpAccountScreen extends StatefulWidget {
  static const String route = '/signup';
  PhoneNumber? number;

  SignUpAccountScreen({this.number});
  @override
  _SignUpAccountScreenState createState() => _SignUpAccountScreenState();
}

class _SignUpAccountScreenState extends State<SignUpAccountScreen> {

  late SharedPreferences preferences;

  var currentStep = 0;

  var currentStepWelcome = 0;
  var currentStepFullName = 1;
  var currentStepBirthday = 2;
  var currentStepGender = 3;
  var currentStepSexualOrientation = 4;
  var currentStepShowMeGender = 5;
  var currentStepSchool = 6;
  var currentStepPassions = 7;
  var currentStepPhotos = 8;
  var currentStepPhotosSelection = 9;

  bool isValidName = false;
  bool isValidBirthday = false;
  bool isValidGender = false;
  bool isValidSexualOrientation = false;
  bool isValidShowMeGender = false;
  bool isValidSchool = false;
  bool isValidPassions = false;
  bool isValidPhotos = false;

  bool showGenderProfile = false;
  bool showSexualOrientationProfile = false;

  //String phoneNumber = "";
  String myBirthday = "";
  String mySelectedGender = "";
  List<dynamic> mySelectedOrientations = [];
  String mySelectedShowMeGender = "";
  List<dynamic> mySelectedPassions = [];

  int sourcePosition = 0;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController fullNameEditingController = TextEditingController();
  TextEditingController birthdayEditingController = TextEditingController();
  TextEditingController schoolEditingController = TextEditingController();

  ParseFileBase? parseFile;
  PictureModel? pictureModel;

  List<PictureModel> pictureList = [];

  String? imageFilePath0 = "";
  String? imageFilePath1 = "";
  String? imageFilePath2 = "";
  String? imageFilePath3 = "";
  String? imageFilePath4 = "";
  String? imageFilePath5 = "";

  @override
  void dispose() {
    fullNameEditingController.dispose();
    birthdayEditingController.dispose();
    schoolEditingController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    initSharedPref();
    super.initState();
  }

  initSharedPref() async{
     preferences = await SharedPreferences.getInstance();
  }

  Future<bool> _onBackPressed() async {
    _updateCurrentStepPrevious();

    return false;
  }

  void _updateCurrentState() {
    currentStep++;

    setState(() {});
  }

  void _updateCurrentStepPrevious() {
    if (currentStep == currentStepWelcome) {
      QuickHelp.goBackToPreviousPage(context);
      //QuickHelp.goToNavigatorAndClear(context, WelcomeScreen.route);
    }

    currentStep--;

    setState(() {});
  }

  String getHeaderText() {
    if (currentStep == currentStepWelcome) {
      return "auth.wel_come_to_app".tr(namedArgs: {"app_name": Setup.appName});
    } else if (currentStep == currentStepFullName) {
      return "auth.first_name_is".tr();
    } else if (currentStep == currentStepBirthday) {
      return "auth.my_birth_is".tr();
    } else if (currentStep == currentStepGender) {
      return "auth.my_gender_is".tr();
    } else if (currentStep == currentStepSexualOrientation) {
      return "auth.my_sexual_orientation_is".tr();
    } else if (currentStep == currentStepShowMeGender) {
      return "auth.show_me".tr();
    } else if (currentStep == currentStepSchool) {
      return "auth.my_school_is".tr();
    } else if (currentStep == currentStepPassions) {
      return "auth.choose_passions".tr();
    } else if (currentStep == currentStepPhotos) {
      return "auth.add_photos".tr();
    } else if (currentStep == currentStepPhotosSelection) {
      return "";
    } else {
      return "continue".tr();
    }
  }

  String getHeaderSubText() {
    if (currentStep == currentStepWelcome) {
      return "auth.welcome_subtitle".tr();
    } else if (currentStep == currentStepSexualOrientation) {
      return "auth.my_sexual_ori_subtitle".tr();
    } else if (currentStep == currentStepPassions) {
      return "auth.choose_passions_details".tr();
    } else if (currentStep == currentStepPhotos) {
      return "auth.add_photos_details".tr(namedArgs: {"photos_count" : Setup.photoNeededToRegister.toString()});
    } else {
      return "";
    }
  }

  String getButtonText() {
    if (currentStep == currentStepWelcome) {
      return "auth.i_agree".tr();
    } else if (currentStep == currentStepPassions) {
      return "auth.continue_count"
          .tr(namedArgs: {"count": "${mySelectedPassions.length}/5"});
    } else {
      return "continue".tr();
    }
  }

  bool getHeaderSubState() {
    if (currentStep == currentStepWelcome) {
      return true;
    } else if (currentStep == currentStepSexualOrientation) {
      return true;
    } else if (currentStep == currentStepPassions) {
      return true;
    } else if (currentStep == currentStepPhotos) {
      return true;
    } else {
      return false;
    }
  }

  bool getButtonState() {
    if (currentStep == currentStepWelcome) {
      return true;
    } else if (currentStep == currentStepFullName) {
      return isValidName;
    } else if (currentStep == currentStepBirthday) {
      return isValidBirthday;
    } else if (currentStep == currentStepGender) {
      return isValidGender;
    } else if (currentStep == currentStepSexualOrientation) {
      return isValidSexualOrientation;
    } else if (currentStep == currentStepShowMeGender) {
      return isValidShowMeGender;
    } else if (currentStep == currentStepSchool) {
      return isValidSchool;
    } else if (currentStep == currentStepPassions) {
      return isValidPassions;
    } else if (currentStep == currentStepPhotos) {
      return isValidPhotos;
    }

    return false;
  }

  bool showSkipState() {
    if (currentStep == currentStepSchool) {
      return true;
    } else if (currentStep == currentStepPassions) {
      return false;
    }

    return false;
  }

  Future<void> checkPermission(int position) async {
    sourcePosition = position;

    if (QuickHelp.isAndroidPlatform()) {
      PermissionStatus status = await Permission.storage.status;
      PermissionStatus status2 = await Permission.camera.status;
      print('Permission android');

      checkStatus(status, status2, position);
    } else if (QuickHelp.isIOSPlatform()) {
      PermissionStatus status = await Permission.photos.status;
      PermissionStatus status2 = await Permission.camera.status;
      print('Permission ios');

      checkStatus(status, status2, position);
    } else {
      print('Permission other device');
      //_uploadPhotos(ImageSource.gallery);
      _updateCurrentState();
    }
  }

  void checkStatus(
      PermissionStatus status, PermissionStatus status2, int position) {
    if (status.isDenied || status2.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.

      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access".tr(),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          message: "permissions.photo_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);

            //if (await Permission.camera.request().isGranted) {
            // Either the permission was already granted before or the user just granted it.
            //}

            // You can request multiple permissions at once.
            Map<Permission, PermissionStatus> statuses = await [
              Permission.camera,
              Permission.photos,
              Permission.storage,
            ].request();

            if (statuses[Permission.camera]!.isGranted &&
                    statuses[Permission.photos]!.isGranted ||
                statuses[Permission.storage]!.isGranted) {
              _updateCurrentState();
            }
          });
    } else if (status.isPermanentlyDenied || status2.isPermanentlyDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access_denied".tr(),
          confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
          message: "permissions.photo_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () {
            QuickHelp.hideLoadingDialog(context);

            openAppSettings();
          });
    } else if (status.isGranted && status2.isGranted) {
      //_uploadPhotos(ImageSource.gallery);
      _updateCurrentState();
    }

    print('Permission $status');
    print('Permission $status2');
  }

  void _uploadPhotos(ImageSource source) async {

    if(source == ImageSource.camera){

      final ImagePicker _picker = ImagePicker();

      final XFile? image = await _picker.pickImage(source: source, preferredCameraDevice: CameraDevice.front);

      if (image != null) {
        cropPhoto(image: image.path);

      } else {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            isError: true,
            title: "profile.choosing_picture_failed_title".tr(),
            message: "profile.choosing_picture_failed_explain".tr());
      }

    } else {

      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: source);

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
  }

  void compressImage(Future<ImageFile> image) {

    QuickHelp.showLoadingDialogWithText(context, description: "crop_image_scree.optimizing_image".tr(), useLogo: true);

    image.then((value) {

      Future.delayed(Duration(seconds: 1), () async {
        var result = await QuickHelp.compressImage(value, quality: value.sizeInBytes >= 1000000 ? 30 : 50);

        if(result != null){

          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showLoadingDialogWithText(context, description: "crop_image_scree.optimizing_image_uploading".tr());

         uploadFile(result);

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

    var result = await QuickHelp.goToNavigatorScreenForResult(context, ImageCropScreen(pathOrBytes: image, aspectRatio: ImageCropScreen.aspectRatioProfile,), route: ImageCropScreen.route);;

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

  uploadFile(ImageFile imageFile) async {

    if(imageFile.filePath.isNotEmpty){
      parseFile = ParseFile(File(imageFile.filePath), name: "avatar.jpg");
      print("Photo uploaded parseFile isNotEmpty");
    } else {
      parseFile = ParseWebFile(imageFile.rawBytes, name: "avatar.jpg");
      print("Photo uploaded parseFile rawBytes");
    }

    if (parseFile != null) {

      print("Photo uploaded parseFile not null");

      print("Photo: ${parseFile!.name}");

      pictureModel = PictureModel();
      print("Photo uploaded pictureModel 1");
      pictureModel!.setFile = parseFile!;
      print("Photo uploaded pictureModel 2");
      pictureModel!.setFileType = PictureModel.keyFileTypeImage;
      print("Photo uploaded pictureModel 3");
      pictureModel!.setFileStatus = PictureModel.keyFileStatusApproved;
      print("Photo uploaded pictureModel");

      final ParseResponse pictureResult = await pictureModel!.save();

      if (pictureResult.success) {

        print("Photo uploaded pictureResult success");

        QuickHelp.hideLoadingDialog(context);

        setState(() {
          if (sourcePosition == 0) {
            imageFilePath0 = parseFile!.url;
          } else if (sourcePosition == 1) {
            imageFilePath1 = parseFile!.url;
          }
          if (sourcePosition == 2) {
            imageFilePath2 = parseFile!.url;
          }
          if (sourcePosition == 3) {
            imageFilePath3 = parseFile!.url;
          }
          if (sourcePosition == 4) {
            imageFilePath4 = parseFile!.url;
          }
          if (sourcePosition == 5) {
            imageFilePath5 = parseFile!.url;
          }

          pictureList.add(pictureResult.result!);
          print("Photo uploaded ${pictureResult.result}");

          if (pictureList.length >= Setup.photoNeededToRegister) {
            isValidPhotos = true;
          } else {
            isValidPhotos = false;
          }
        });

        _updateCurrentStepPrevious();
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAlertError(
            context: context, title: "auth.upload_file_failed".tr());

        return;
      }
    } else {
      QuickHelp.hideLoadingDialog(context);
      return;
    }
  }

  Future<void> _signUpNow() async {
    QuickHelp.showLoadingDialog(context);

    //Country country = await CountryProvider.getCountryByCode(number.isoCode!);

    int firstSpace = fullNameEditingController.text.indexOf(" ");
    String firstName = fullNameEditingController.text.substring(0, firstSpace);
    String lastName =
        fullNameEditingController.text.substring(firstSpace).trim();

    String username =
        lastName.replaceAll(" ", "") + firstName.replaceAll(" ", "");

    String password = QuickHelp.generateUId().toString();

    UserModel user = UserModel(username, password, null);
    user.setFullName = fullNameEditingController.text;
    user.setSecondaryPassword = password;
    user.setFirstName = firstName;
    user.setLastName = lastName;
    user.username = username.toLowerCase().trim()+QuickHelp.generateShortUId().toString();
    user.setPhotoVerified = true;

    //user.setPhoneNumberFull = phoneNumber;

    //user.setCountry = country.name!;
    //user.setCountryCode = number.isoCode!;
    //user.setCountryDialCode = number.dialCode!;
    user.setSchool = schoolEditingController.text;
    user.setPhoneNumber = widget.number!.parseNumber();
    user.setPhoneNumberFull = widget.number!.phoneNumber!;
    //user.setEmail = emailEditingController.text.trim();
    //user.setEmailPublic = emailEditingController.text.trim();
    user.setGender = mySelectedGender;
    user.setUid = QuickHelp.generateUId();
    //user.setPopularity = 0;
    user.setGenderPref = mySelectedShowMeGender;
    user.setShowSexualOrientation = showSexualOrientationProfile;
    user.setShowGenderInProfile = showGenderProfile;

    if(mySelectedOrientations.length > 0){
      user.setSexualOrientations = mySelectedOrientations;
    }
    if(mySelectedPassions.length > 0){
      user.setPassions = mySelectedPassions;
    }

    user.setUserRole = UserModel.roleUser;
    user.setPrefMinAge = Setup.minimumAgeToRegister;
    user.setPrefMaxAge = Setup.maximumAgeToRegister;
    user.setLocationTypeNearBy = true;
    user.addCredit = Setup.welcomeCredit;
    user.setBio = Setup.bio;
    user.setHasPassword = true;
    user.setBirthday = QuickHelp.getDate(birthdayEditingController.text);
    //user.setAvatar = parseFile!;
    user.setAvatar = pictureList[0].getFile!;

    if(pictureList.length > 0 && pictureList[0].getFile != null){
      user.setAvatar1 = pictureList[0].getFile!;
    }

    if(pictureList.length > 1 && pictureList[1].getFile != null){
      user.setAvatar2 = pictureList[1].getFile!;
    }

    if(pictureList.length > 2 && pictureList[2].getFile != null){
      user.setAvatar3 = pictureList[2].getFile!;
    }

    if( pictureList.length > 3 && pictureList[3].getFile != null){
      user.setAvatar4 = pictureList[3].getFile!;
    }

    if(pictureList.length > 4 &&pictureList[4].getFile != null){
      user.setAvatar5 = pictureList[4].getFile!;
    }

    if(pictureList.length > 5 && pictureList[5].getFile != null){
      user.setAvatar6 = pictureList[5].getFile!;
    }

    user.setAvatarsList = pictureList;
    //user.setAvatars = pictureModel!;

    ParseResponse userResult = await user.signUp(allowWithoutEmail: true);

    if (userResult.success) {
      for (PictureModel picture in pictureList) {
        picture.setAuthor = user;
        picture.setAuthorId = user.objectId!;
        await picture.save();
      }


      if(SharedManager().getInvitee(preferences)!.isNotEmpty){
        await QuickCloudCode.sendTicketsToInvitee(authorId: user.objectId!, receivedId: SharedManager().getInvitee(preferences)!);
        SharedManager().clearInvitee(preferences);
      }

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(context, DispatchScreen(currentUser: user,), route: DispatchScreen.route, back: false, finish: true);
      //QuickHelp.goToNavigatorAndClear(context, HomeScreen.route, arguments: user);
    } else if (userResult.error!.code == 100) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAlertError(
          context: context, title: "error".tr(), message: "not_connected".tr());
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAlertError(
          context: context,
          title: "error".tr(),
          message: "try_again_later".tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.signup_title".tr());
    var size = MediaQuery.of(context).size;


    Widget centerWidget() {
      if (currentStep == currentStepPhotosSelection) {
        return TextWithTap(
          "auth.select_source".tr(),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: QuickHelp.isDarkMode(context)
              ? kContentColorDarkTheme
              : kContentColorLightTheme,
        );
      } else {
        return LinearProgressBar(
          maxSteps: 9,
          progressType: LinearProgressBar.progressTypeDots,
          currentStep: currentStep,
          progressColor: kPrimaryColor,
          backgroundColor: kColorsGrey400,
          dotsAxis: Axis.horizontal,
          dotsActiveSize: 10,
          dotsInactiveSize: 10,
          dotsSpacing: const EdgeInsets.only(right: 10),
        );
      }
    }

    return new WillPopScope(
        onWillPop: _onBackPressed,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ToolBarCenterWidget(
              leftButtonIcon: currentStep == currentStepWelcome
                  ? Icons.close_rounded
                  : Icons.arrow_back,
              leftIconColor: kPrimacyGrayColor,
              leftButtonPress: _updateCurrentStepPrevious,
              rightButtonWidget: showSkipState()
                  ? TextWithTap(
                      "skip".tr().toUpperCase(),
                      marginRight: 15,
                      textAlign: TextAlign.center,
                      alignment: Alignment.center,
                      color: kPrimacyGrayColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      onTap: () => _updateCurrentState(),
                    )
                  : null,
              centerTitle: true,
              centerWidget: centerWidget(),
              child: SafeArea(
                child: Responsive.isMobile(context,) ? body() :
                Center(
                  child: ContainerCorner(
                    width: 400,
                    height: size.height,
                    borderRadius: 10,
                    marginTop: 20,
                    marginBottom: 20,
                    borderColor: kDisabledGrayColor,
                    child: body(),
                  ),
                ),
              )),
        ));
  }

  Widget body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Container(
              margin: EdgeInsets.only(
                  top: currentStep == currentStepWelcome ? 20 : 0),
              child: Visibility(
                visible: currentStep == currentStepWelcome
                    ? true
                    : false,
                child: SvgPicture.asset(
                  "assets/svg/ic_icon.svg",
                  width: 43,
                  height: 50,
                ),
              ),
            ),
            TextWithTap(
              getHeaderText(),
              marginTop: 20,
              fontSize: 25,
              marginBottom: 5,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
            Visibility(
              visible: getHeaderSubState(),
              child: TextWithTap(
                getHeaderSubText(),
                textAlign: TextAlign.center,
                marginTop: 0,
                fontSize: 14,
                marginBottom: 5,
                marginLeft: 20,
                marginRight: 20,
                color: kPrimacyGrayColor,
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            child: Form(
              key: _formKey,
              child: IndexedStack(
                alignment: AlignmentDirectional.center,
                index: currentStep,
                children: [
                  welcomeStepWidget(),
                  firstNameStepWidget(),
                  birthdayStepWidget(),
                  genderStepWidget(),
                  sexualOrientationStepWidget(),
                  showMeStepWidget(),
                  schoolStepWidget(),
                  passionsStepWidget(),
                  photosStepWidget(),
                  photosSelectionStepWidget(),
                ],
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: currentStep == currentStepGender,
              child: GestureDetector(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showGenderProfile
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: kPrimaryColor,
                    ),
                    TextWithTap(
                      "auth.show_gender_profile".tr(),
                      textAlign: TextAlign.center,
                      marginLeft: 10,
                      fontSize: 12,
                    ),
                  ],
                ),
                onTap: () {
                  setState(
                        () {
                      if (showGenderProfile) {
                        showGenderProfile = false;
                      } else {
                        showGenderProfile = true;
                      }
                    },
                  );
                },
              ),
            ),
            Visibility(
              visible: currentStep == currentStepSexualOrientation,
              child: GestureDetector(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showSexualOrientationProfile
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: kPrimaryColor,
                    ),
                    TextWithTap(
                      "auth.show_sexual_orien_profile".tr(),
                      textAlign: TextAlign.center,
                      marginLeft: 10,
                      fontSize: 12,
                    ),
                  ],
                ),
                onTap: () {
                  setState(
                        () {
                      if (showSexualOrientationProfile) {
                        showSexualOrientationProfile = false;
                      } else {
                        showSexualOrientationProfile = true;
                      }
                    },
                  );
                },
              ),
            ),
            Visibility(
              visible: currentStep == currentStepPhotosSelection
                  ? false
                  : true,
              child: RoundedGradientButton(
                height: 48,
                marginLeft: 30,
                marginRight: 30,
                marginBottom: 30,
                borderRadius: 60,
                borderRadiusBottomLeft: 15,
                marginTop: 20,
                fontSize: 17,
                colors: getButtonState()
                    ? [kPrimaryColor, kSecondaryColor]
                    : [kDisabledColor, kDisabledColor],
                textColor: getButtonState()
                    ? Colors.white
                    : kDisabledGrayColor,
                text: getButtonText().toUpperCase(),
                fontWeight: FontWeight.normal,
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    FocusManager.instance.primaryFocus?.unfocus();

                    if (currentStep == currentStepWelcome) {
                      _updateCurrentState();
                    } else if (currentStep == currentStepFullName) {
                      _updateCurrentState();
                    } else if (currentStep == currentStepBirthday) {
                      QuickHelp.showDialogHeyto(
                          context: context,
                          title: "auth.confirm_age".tr(),
                          message: "auth.confirm_age_details"
                              .tr(namedArgs: {
                            "age": QuickHelp.getAgeFromDateString(
                                myBirthday,
                                QuickHelp.dateFormatDmy)
                                .toString()
                          }),
                          confirmButtonText: "confirm_".tr(),
                          cancelButtonText: "edit_".tr(),
                          onPressed: () {
                            QuickHelp.hideLoadingDialog(context);
                            _updateCurrentState();
                          });
                    } else if (currentStep == currentStepGender) {
                      if (isValidGender) {
                        _updateCurrentState();
                      }
                    } else if (currentStep ==
                        currentStepSexualOrientation) {
                      if (isValidSexualOrientation) {
                        _updateCurrentState();
                      }
                    } else if (currentStep ==
                        currentStepShowMeGender) {
                      if (isValidShowMeGender) {
                        _updateCurrentState();
                      }
                    } else if (currentStep == currentStepSchool) {
                      _updateCurrentState();
                    } else if (currentStep == currentStepPassions) {
                      if (isValidPassions) {
                        _updateCurrentState();
                      }
                    } else if (currentStep == currentStepPhotos) {
                      if (isValidPhotos) {
                        _signUpNow();
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget welcomeStepWidget() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildWelcomeFields(
              "auth.be_your_self".tr(), "auth.be_your_self_details".tr()),
          const Divider(
            color: Colors.transparent,
            height: 20,
          ),
          buildWelcomeField("auth.stay_safe".tr(),
              "auth.stay_safe_details".tr(), "auth.stay_safe_details_".tr()),
          const Divider(
            color: Colors.transparent,
            height: 20,
          ),
          buildWelcomeFields(
              "auth.play_it_cool".tr(), "auth.play_it_cool_details".tr()),
          const Divider(
            color: Colors.transparent,
            height: 20,
          ),
          buildWelcomeFields(
              "auth.be_proactive".tr(), "auth.be_proactive_details".tr()),
        ],
      ),
    );
  }

  Widget buildWelcomeFields(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check,
              size: 24,
              color: kPrimaryColor,
            ),
            TextWithTap(
              title,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              marginLeft: 10,
              color: kPrimaryColor,
            ),
          ],
        ),
        TextWithTap(
          description,
          marginTop: 5,
          fontSize: 14,
          color: kPrimacyGrayColor,
          textAlign: TextAlign.start,
          fontWeight: FontWeight.normal,
        ),
      ],
    );
  }

  Widget buildWelcomeField(String title, String description, String urlText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check,
              size: 24,
              color: kPrimaryColor,
            ),
            TextWithTap(
              title,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              marginLeft: 10,
              marginBottom: 5,
              color: kPrimaryColor,
            ),
          ],
        ),
        RichText(
            textAlign: TextAlign.start,
            text: TextSpan(children: [
              TextSpan(
                  style: const TextStyle(color: kPrimacyGrayColor, fontSize: 14),
                  text: description),
              TextSpan(
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  text: urlText,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypeSafety, pageUrl: Config.dataSafetyUrl);
                    }),
            ]))
      ],
    );
  }

  Widget firstNameStepWidget() {
    String? _validateFullName(String value) {
      int firstSpace = value.indexOf(" ");

      isValidName = false;
      if (value.isEmpty) {
        return "auth.no_full_name".tr();
      } else if (firstSpace < 1) {
        return "auth.full_name_please".tr();
      } else if (fullNameEditingController.text.endsWith(" ")) {
        return "auth.full_name_please".tr();
      } else {
        isValidName = true;
        return null;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RoundedInputField(
          // Full name
          inputFormatters: [FirstUpperCaseTextFormatter()],
          visible: currentStep == currentStepFullName ? true : false,
          isNodeNext: false,
          textInputAction: TextInputAction.done,
          hintText: "auth.full_name_hint".tr(),
          controller: fullNameEditingController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            setState(() {
              _validateFullName(value);
            });
          },
          validator: (value) {
            return _validateFullName(value!);
          },
        ),
        TextWithTap(
          "auth.will_appear_like".tr(namedArgs: {"app_name": Setup.appName}),
          marginTop: 20,
          marginBottom: 30,
          marginLeft: 30,
          marginRight: 30,
          fontSize: 13,
          textAlign: TextAlign.left,
          fontWeight: FontWeight.normal,
        ),
      ],
    );
  }

  Widget birthdayStepWidget() {
    String? _validateBirthday(String value) {
      isValidBirthday = false;
      if (value.isEmpty) {
        return "auth.choose_birthday".tr();
      } else if (!QuickHelp.isValidDateBirth(value, QuickHelp.dateFormatDmy)) {
        return "auth.invalid_date".tr();
      } else if (!QuickHelp.minimumAgeAllowed(value, QuickHelp.dateFormatDmy)) {
        return "auth.mim_age_required"
            .tr(namedArgs: {'age': Setup.minimumAgeToRegister.toString()});
      } else {
        isValidBirthday = true;
        myBirthday = value;
        return null;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          child: RoundedInputField(
            // Birthday
            visible: currentStep == currentStepBirthday ? true : false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp("[0-9/]")),
              LengthLimitingTextInputFormatter(10),
              DateFormatter(),
            ],
            textInputType: TextInputType.datetime,
            isNodeNext: false,
            textInputAction: TextInputAction.done,
            hintText: "auth.birthday_hint".tr(),
            //icon: Icons.calendar_today,
            //hintText: QuickHelp.toOriginalFormatString(new DateTime.now()),
            onChanged: (value) {
              setState(() {
                _validateBirthday(value);
              });
            },
            controller: birthdayEditingController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              return _validateBirthday(value!);
            },
          ),
        ),
        TextWithTap(
          "auth.age_will_public".tr(),
          marginTop: 44,
          marginLeft: 30,
          marginRight: 30,
          fontSize: 14,
          textAlign: TextAlign.left,
          fontWeight: FontWeight.normal,
        ),
      ],
    );
  }

  Widget genderStepWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ButtonRoundedOutline(
          text: "auth.a_woman".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          borderColor: mySelectedGender == UserModel.keyGenderFemale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedGender == UserModel.keyGenderFemale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidGender = true;
              mySelectedGender = UserModel.keyGenderFemale;
              showGenderProfile = true;
            });
          },
        ),
        ButtonRoundedOutline(
          text: "auth.a_man".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          marginTop: 15,
          borderColor: mySelectedGender == UserModel.keyGenderMale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedGender == UserModel.keyGenderMale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidGender = true;
              mySelectedGender = UserModel.keyGenderMale;
              showGenderProfile = true;
            });
          },
        ),
        ButtonRoundedOutline(
          text: "auth.a_other".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          marginTop: 15,
          borderColor: mySelectedGender == UserModel.keyGenderBoth
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedGender == UserModel.keyGenderBoth
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidGender = true;
              mySelectedGender = UserModel.keyGenderBoth;
              showGenderProfile = true;
            });
          },
        ),
      ],
    );
  }

  Widget sexualOrientationStepWidget() {
    return ListView.builder(
      shrinkWrap: true,
      //controller: controller,
      itemCount: QuickHelp.getSexualityList().length,
      itemBuilder: (_, index) {
        String code = QuickHelp.getSexualityList()[index];
        return GestureDetector(
          child: Container(
            margin: const EdgeInsets.only(bottom: 17, left: 10),
            child: Row(
              children: [
                Visibility(
                  visible: mySelectedOrientations.contains(code),
                  child: const Icon(
                    Icons.check,
                    size: 24,
                    color: kPrimaryColor,
                  ),
                ),
                TextWithTap(
                  QuickHelp.getSexuality(code),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  marginLeft: 10,
                  color: mySelectedOrientations.contains(code)
                      ? kPrimaryColor
                      : kSecondaryGrayColor,
                ),
              ],
            ),
          ),
          onTap: () {
            setState(() {
              if (mySelectedOrientations.contains(code)) {
                mySelectedOrientations.remove(code);
              } else {
                if (mySelectedOrientations.length < 3) {
                  mySelectedOrientations.add(code);
                  showSexualOrientationProfile = true;
                }
              }

              if (mySelectedOrientations.length > 0) {
                isValidSexualOrientation = true;
              } else {
                isValidSexualOrientation = false;
              }
            });
          },
        );
      },
    );
  }

  Widget showMeStepWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ButtonRoundedOutline(
          text: "auth.a_woman".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          borderColor: mySelectedShowMeGender == UserModel.keyGenderFemale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedShowMeGender == UserModel.keyGenderFemale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidShowMeGender = true;
              mySelectedShowMeGender = UserModel.keyGenderFemale;
            });
          },
        ),
        ButtonRoundedOutline(
          text: "auth.a_man".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          marginTop: 15,
          borderColor: mySelectedShowMeGender == UserModel.keyGenderMale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedShowMeGender == UserModel.keyGenderMale
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidShowMeGender = true;
              mySelectedShowMeGender = UserModel.keyGenderMale;
            });
          },
        ),
        ButtonRoundedOutline(
          text: "auth.a_everyone".tr().toUpperCase(),
          borderRadius: 60,
          width: 250,
          //MediaQuery.of(context).size.width * 0.4,
          height: 46,
          fontSize: 17,
          borderWidth: 1,
          marginRight: 10,
          marginLeft: 10,
          marginTop: 15,
          borderColor: mySelectedShowMeGender == UserModel.keyGenderBoth
              ? kPrimaryColor
              : kPrimacyGrayColor,
          textColor: mySelectedShowMeGender == UserModel.keyGenderBoth
              ? kPrimaryColor
              : kPrimacyGrayColor,
          onTap: () {
            setState(() {
              isValidShowMeGender = true;
              mySelectedShowMeGender = UserModel.keyGenderBoth;
            });
          },
        ),
      ],
    );
  }

  Widget schoolStepWidget() {
    String? _validateSchoolName(String value) {

      isValidSchool = false;
      if (value.isEmpty) {
        return "auth.no_school".tr();
      } else {
        isValidSchool = true;
        return null;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RoundedInputField(
          // Full name
          inputFormatters: [FirstUpperCaseTextFormatter()],
          visible: currentStep == currentStepSchool ? true : false,
          isNodeNext: false,
          textInputAction: TextInputAction.done,
          hintText: "auth.schoo_name_hint".tr(),
          controller: schoolEditingController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) {
            setState(() {
              _validateSchoolName(value);
            });
          },
          validator: (value) {
            return _validateSchoolName(value!);
          },
        ),
        TextWithTap(
          "auth.will_appear_like".tr(namedArgs: {"app_name": Setup.appName}),
          marginTop: 20,
          marginBottom: 30,
          marginLeft: 30,
          marginRight: 30,
          fontSize: 13,
          textAlign: TextAlign.left,
          fontWeight: FontWeight.normal,
        ),
      ],
    );
  }

  Widget passionsStepWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.center,
          //crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(QuickHelp.getPassionsList().length, (index) {
            String code = QuickHelp.getPassionsList()[index];

            return Container(
              //margin: EdgeInsets.only(bottom: 10, left: 10),
              child: GestureDetector(
                child: ContainerCorner(
                  //height: MediaQuery.of(context).size.height,
                  //width: double.infinity, //MediaQuery.of(context).size.width,
                  //colors: [kPrimaryColor, kSecondaryColor],
                  borderRadius: 70,
                  height: 32,
                  colors: mySelectedPassions.contains(code)
                      ? [kPrimaryColor, kSecondaryColor]
                      : [kTransparentColor, kTransparentColor],
                  borderColor: mySelectedPassions.contains(code)
                      ? kPrimaryColor
                      : kPrimacyGrayColor,
                  borderWidth: 1,
                  child: TextWithTap(
                    QuickHelp.getPassions(code),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    marginLeft: 14,
                    marginRight: 14,
                    textAlign: TextAlign.center,
                    //alignment: Alignment.center,
                    color: mySelectedPassions.contains(code)
                        ? Colors.white
                        : kPrimacyGrayColor,
                  ),
                ),
                onTap: () {
                  setState(() {
                    if (mySelectedPassions.contains(code)) {
                      mySelectedPassions.remove(code);
                    } else {
                      if (mySelectedPassions.length < 5) {
                        mySelectedPassions.add(code);
                      }
                    }

                    if (mySelectedPassions.length == 5) {
                      isValidPassions = true;
                    } else {
                      isValidPassions = false;
                    }
                  });
                },
              ),
            );

            /*return Chip(
              //avatar: CircleAvatar(backgroundColor: Colors.blue.shade900, child: Text('JL')),
              label: Text(
                QuickHelp.getPassions(code),
              ),
            );*/
          }),
        ),
      ),
    );
  }

  Widget photosStepWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            photosBuilder(0, imageFilePath0),
            photosBuilder(1, imageFilePath1),
            photosBuilder(2, imageFilePath2),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            photosBuilder(3, imageFilePath3),
            photosBuilder(4, imageFilePath4),
            photosBuilder(5, imageFilePath5),
          ],
        ),
      ],
    );
  }

  Widget photosBuilder(int position, String? imagePath) {
    return ContainerCorner(
      width: 104,
      height: 144,
      alignment: Alignment.center,
      color: kPhotosGrayColor,
      borderColor: Colors.transparent,
      borderRadius: 10,
      marginAll: 4,
      child: imagePath!.isNotEmpty
          ? QuickActions.photosWidget(imagePath,)
          : Container(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      "assets/svg/profil.svg",
                      width: 32,
                      height: 40,
                      color: kPhotosGrayColorReverse,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: SvgPicture.asset(
                        "assets/svg/ic_add_rounded_primary.svg",
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      onTap: () {
        checkPermission(position);
      },
    );
  }

  Widget photosSelectionStepWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        sourceBuilder(ImageSource.camera, "auth.source_camera".tr(),
            "assets/svg/ic_source_camera.svg", color: QuickHelp.isMobile() ? null : kDisabledColor),
        sourceBuilder(ImageSource.gallery, "auth.source_gallery".tr(),
            "assets/svg/ic_source_gallery.svg",),
      ],
    );
  }

  Widget sourceBuilder(ImageSource sourceType, String source, String svg, {Color? color}) {
    return ContainerCorner(
      //width: 315,
      height: 100,
      borderRadius: 10,
      marginTop: 10,
      marginBottom: 10,
      marginRight: 30,
      marginLeft: 30,
      blurRadius: 10,
      spreadRadius: 1,
      shadowColor: color != null ? color : kPrimaryShadowColor,
      setShadowToBottom: false,
      colors: color != null ? [color, color] : [kPrimaryColor, kSecondaryColor],
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 25,
            child: ClipRect(
              child: Image.asset(
                "assets/images/ic_source_bg.png",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextWithTap(
                source,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                fontSize: 30,
                color: kContentColorDarkTheme,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: -15 * (math.pi / 180),
              child: SvgPicture.asset(
                svg,
                width: 89,
                height: 80,
                color: color != null ? kPhotosGrayColorReverse : null,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        if(sourceType == ImageSource.camera){
          QuickHelp.isMobile() ? _uploadPhotos(sourceType) : null;
        } else {
          _uploadPhotos(sourceType);
        }
      },
    );
  }
}
