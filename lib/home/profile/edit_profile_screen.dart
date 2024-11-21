import 'dart:io';
import 'dart:math' as math;

import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/location/add_city_screen.dart';
import 'package:heyto/home/profile/image_crop_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/providers/update_user_provider.dart';
import 'package:heyto/ui/app_bar.dart';
import 'package:heyto/ui/button_with_gradient.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/rounded_gradient_button.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/widgets/need_resume.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_compression_flutter/image_compression_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/src/provider.dart';

// ignore: must_be_immutable
class EditProfileScreen extends StatefulWidget {
  static const String route = '/profile/edit';

  UserModel? currentUser;

  EditProfileScreen({this.currentUser});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ResumableState<EditProfileScreen> {

  var currentStep = 0;
  var currentStepProfile = 0;
  var currentStepPassions = 1;
  var currentStepPhotosSelection = 2;

  bool isValidPassions = false;
  bool isValidPhotos = false;

  List<String> mySelectedPassions = [];

  String? _genderSelection = UserModel.keyGender;

  List<String?> pictures = [];

  ParseFileBase? parseFile;

  String? imageFilePath0 = "";
  String? imageFilePath1 = "";
  String? imageFilePath2 = "";
  String? imageFilePath3 = "";
  String? imageFilePath4 = "";
  String? imageFilePath5 = "";

  String sourcePosition = UserModel.keyAvatar;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController aboutYouTitleEditingController =
      TextEditingController();
  TextEditingController jobTitleEditingController = TextEditingController();
  TextEditingController companyNameEditingController = TextEditingController();
  TextEditingController schoolEditingController = TextEditingController();
  TextEditingController cityEditingController = TextEditingController();
  TextEditingController passionsEditingController = TextEditingController();

  _getUser() async {

    aboutYouTitleEditingController.text = widget.currentUser!.getAboutYou!;
    jobTitleEditingController.text = widget.currentUser!.getJobTitle!;
    companyNameEditingController.text = widget.currentUser!.getCompanyName!;
    schoolEditingController.text = widget.currentUser!.getSchool!;

    if(widget.currentUser!.getPassionsRealList!.length > 0){

      for (String passion in widget.currentUser!.getPassionsRealList!){
        mySelectedPassions.add(passion);
      }
    }

    if(widget.currentUser!.getPassionsRealList!.length == 5){
      isValidPassions = true;
    }

    setState(() {

      if (widget.currentUser!.getGender!.isNotEmpty) {
        _genderSelection = widget.currentUser!.getGender;
      }

      if (widget.currentUser!.getPassions!.isNotEmpty) {
        passionsEditingController.text =
            QuickHelp.getPassionsListWithName(widget.currentUser!);
      }

      if (widget.currentUser!.getAvatar1 != null) {
        imageFilePath0 = widget.currentUser!.getAvatar1!.url;
      } else {
        imageFilePath0 = "";
      }

      if (widget.currentUser!.getAvatar2 != null) {
        imageFilePath1 = widget.currentUser!.getAvatar2!.url;
      } else {
        imageFilePath1 = "";
      }

      if (widget.currentUser!.getAvatar3 != null) {
        imageFilePath2 = widget.currentUser!.getAvatar3!.url;
      } else {
        imageFilePath2 = "";
      }

      if (widget.currentUser!.getAvatar4 != null) {
        imageFilePath3 = widget.currentUser!.getAvatar4!.url;
      } else {
        imageFilePath3 = "";
      }

      if (widget.currentUser!.getAvatar5 != null) {
        imageFilePath4 = widget.currentUser!.getAvatar5!.url;
      } else {
        imageFilePath4 = "";
      }

      if (widget.currentUser!.getAvatar6 != null) {
        imageFilePath5 = widget.currentUser!.getAvatar6!.url;
      } else {
        imageFilePath5 = "";
      }
    });
  }

  Future<bool> _onBackPressed() async {
    _updateCurrentStepPrevious();

    return false;
  }

  void _updateCurrentState(int step) {
    //currentStep++;
    currentStep = step;

    setState(() {});
  }

  void _updateCurrentStepPrevious() {
    if (currentStep == currentStepProfile) {
      QuickHelp.goBackToPreviousPage(context, result: widget.currentUser);
    }

    //currentStep--;
    currentStep = currentStepProfile;

    setState(() {});
  }

  String getButtonText() {
    if (currentStep == currentStepPassions) {
      return "auth.continue_count"
          .tr(namedArgs: {"count": "${mySelectedPassions.length}/5"});
    } else {
      return "continue".tr();
    }
  }

  bool showSaveButton() {
    if (currentStep == currentStepProfile) {
      return true;
    }

    return false;
  }

  bool getButtonState() {
    if (currentStep == currentStepPassions) {
      return isValidPassions;
    }

    return false;
  }


  @override
  void initState() {
    _getUser();
    super.initState();
  }

  @override
  void dispose() {
    aboutYouTitleEditingController.dispose();
    jobTitleEditingController.dispose();
    companyNameEditingController.dispose();
    schoolEditingController.dispose();
    cityEditingController.dispose();
    passionsEditingController.dispose();

    super.dispose();
  }

  _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      widget.currentUser!.setAboutYou = aboutYouTitleEditingController.text;

      if (jobTitleEditingController.text.isNotEmpty) {
        widget.currentUser!.setJobTitle = jobTitleEditingController.text;
      }

      if (companyNameEditingController.text.isNotEmpty) {
        widget.currentUser!.setCompanyName = companyNameEditingController.text;
      }

      if (schoolEditingController.text.isNotEmpty) {
        widget.currentUser!.setSchool = schoolEditingController.text;
      }

      QuickHelp.showLoadingDialog(context, isDismissible: false);
      ParseResponse response = await widget.currentUser!.save();

      if(response.success){

        widget.currentUser = response.results!.first;
        context.read<UpdateUserProvider>().updateUser(response.results!.first);

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.goBackToPreviousPage(context, result: response.results!.first);

      } else {
        QuickHelp.hideLoadingDialog(context);
      }
    }
  }

  _removePhoto(String position, String url){
    QuickHelp.showDialogWithButtonCustom(
        context: context,
        cancelButtonText: "cancel".tr(),
        confirmButtonText: "edit_profile.yes_delete".tr(),
      title: "edit_profile.delete_photo".tr(),
      message: "edit_profile.delete_photo_ask".tr(),
      onPressed: (){
          QuickHelp.goBackToPreviousPage(context);

          if(url != widget.currentUser!.getAvatar!.url){
            widget.currentUser!.unset(position);
            widget.currentUser!.save();
          }

          setState(() {
           if(position == UserModel.keyAvatar1){
             imageFilePath0 = "";

           } else if(position == UserModel.keyAvatar2){
             imageFilePath1 = "";

           } else if(position == UserModel.keyAvatar3){
             imageFilePath2 = "";

           } else if(position == UserModel.keyAvatar4){
             imageFilePath3 = "";

           } else if(position == UserModel.keyAvatar5){
             imageFilePath4 = "";

           } else if(position == UserModel.keyAvatar6){
             imageFilePath5 = "";

           }
          });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.edit_profile_title".tr());


    return WillPopScope(
      onWillPop: _onBackPressed,
      child: GestureDetector(
        //FocusManager.instance.primaryFocus?.unfocus(),
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: ToolBar(
          iconHeight: 24,
          iconWidth: 24,
          centerTitle: true,
          title: "page_title.edit_profile_title".tr(),
          leftButtonIcon: Icons.arrow_back,
          rightButtonIcon: showSaveButton() ? Icons.check : null,
          rightButtonPress: () => showSaveButton() ? _saveUserData() : null,
          onLeftButtonTap: () => _onBackPressed(),
          rightIconColor: QuickHelp.getColorToolbarIcons(),
          child: Responsive.isMobile(context) || Responsive.isTablet(context) ? getBody() : webBody(),
        ),
      ),
    );
  }

  Widget webBody() {
    var size = MediaQuery.of(context).size;

    return IndexedStack(
      alignment: AlignmentDirectional.center,
      index: currentStep,
      children: [
        ContainerCorner(
          height: size.height,
          width: size.width,
          marginLeft: spaces(),
          marginRight: spaces(),
          marginBottom: 30,
          child: Card(
            elevation: 3.0,
            color: QuickHelp.isDarkMode(context) ? kContentColorLightTheme : Colors.white,
            child: Row(
              children: [
                Flexible(
                    flex: 2,
                    child: Column(
                      children: [
                        photosStepWidget(),
                        ButtonWithGradient(
                          onTap: ()=> checkPermission(UserModel.keyAvatar1),
                          height: 46,
                          borderRadius: 100,
                          marginLeft: 20,
                          marginRight: 20,
                          text: "edit_profile.add_avatar".tr().toUpperCase(),
                          beginColor: kPrimaryColor,
                          endColor: kSecondaryColor,
                        ),
                      ],
                    ),
                ),
                Flexible(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          title("edit_profile.about_name"
                              .tr(namedArgs: {"name": "${widget.currentUser!.getFirstName}"})),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: kGreyColor0,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: TextFormField(
                                        controller: aboutYouTitleEditingController,
                                        maxLength: 500,
                                        minLines: 1,
                                        maxLines: 100,
                                        autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                        style: TextStyle(
                                          color: kGreyColor2,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "edit_profile.hint_about_you".tr();
                                          } else {
                                            return null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          //hintText: currentUser!.getAboutYou,
                                          focusedBorder: InputBorder.none,
                                          border: InputBorder.none,
                                          //errorText: "edit_profile.hint_about_you".tr(),
                                          hintStyle: TextStyle(
                                            color: kGreyColor2,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                title("edit_profile.passions_section".tr()),
                                /*inputEdit("edit_profile.add_passions".tr(),
                                      passionsEditingController, function: () => _updateCurrentState()),*/
                                GestureDetector(
                                  onTap: () => _updateCurrentState(currentStepPassions),
                                  child: option(passionsEditingController.text),
                                ),
                                title("edit_profile.job_title".tr()),
                                inputEdit("edit_profile.add_job_title".tr(),
                                    jobTitleEditingController),
                                title("edit_profile.company_name".tr()),
                                inputEdit("edit_profile.add_company_name".tr(),
                                    companyNameEditingController),
                                title("edit_profile.school_name".tr()),
                                inputEdit("edit_profile.add_school_name".tr(),
                                    schoolEditingController),
                              ],
                            ),
                          ),
                          /*GestureDetector(
                          onTap: () => QuickHelp.goToNavigator(
                              context, AddSchoolScreen.route,
                              arguments: currentUser),
                          child: option("edit_profile.add_school_name".tr()),
                        ),*/
                          title("edit_profile.living_in".tr()),
                          GestureDetector(
                            onTap: () async {
                              UserModel? result = await QuickHelp.goToNavigatorScreenForResult(context, AddCityScreen(currentUser: widget.currentUser), route: AddCityScreen.route);

                              if(result != null){
                                setState(() {
                                  widget.currentUser = result;
                                });
                              }
                            },
                            child: option(widget.currentUser!.getLocationOnly!),
                          ),
                          title("edit_profile.my_gender".tr()),
                          Padding(
                            padding: EdgeInsets.only(bottom: 13.0),
                            child: ContainerCorner(
                              height: 80,
                              borderRadius: 10,
                              marginTop: 15,
                              color: kGreyColor0,
                              child: Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    genderOptions(UserModel.keyGenderMale,
                                        "auth.a_man".tr(), _genderSelection!),
                                    Expanded(
                                        child: genderOptions(UserModel.keyGenderFemale,
                                            "auth.a_woman".tr(), _genderSelection!)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        passionsStepWidget(),
        photosSelectionStepWidget(),
      ],
    );
  }

  double spaces() {
    var size = MediaQuery.of(context).size.width;
    if(size == 1200) {
      return 100.0;
    }else if(size > 1200){
      return 100.0;
    }else if(size <= 1024){
      return 10;
    }else{
      return 5;
    }
  }

  Widget getBody() {
    return IndexedStack(
      alignment: AlignmentDirectional.center,
      index: currentStep,
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            top: 15,
          ),
          child: ListView(
            children: [
              //cards(context),
              photosStepWidget(),
              ButtonWithGradient(
                onTap: ()=> checkPermission(UserModel.keyAvatar1),
                height: 46,
                borderRadius: 100,
                marginTop: 10,
                marginLeft: 20,
                marginRight: 20,
                text: "edit_profile.add_avatar".tr().toUpperCase(),
                beginColor: kPrimaryColor,
                endColor: kSecondaryColor,
              ),
              title("edit_profile.about_name".tr(namedArgs: {"name": "${widget.currentUser!.getFirstName}"})),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: kGreyColor0,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: TextFormField(
                            controller: aboutYouTitleEditingController,
                            maxLength: 500,
                            minLines: 1,
                            maxLines: 100,
                            autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                            style: TextStyle(
                              color: kGreyColor2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.multiline,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "edit_profile.hint_about_you".tr();
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                              //hintText: currentUser!.getAboutYou,
                              focusedBorder: InputBorder.none,
                              border: InputBorder.none,
                              //errorText: "edit_profile.hint_about_you".tr(),
                              hintStyle: TextStyle(
                                color: kGreyColor2,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    title("edit_profile.passions_section".tr()),
                    GestureDetector(
                      onTap: () => _updateCurrentState(currentStepPassions),
                      child: option(passionsEditingController.text),
                    ),
                    title("edit_profile.job_title".tr()),
                    inputEdit("edit_profile.add_job_title".tr(),
                        jobTitleEditingController),
                    title("edit_profile.company_name".tr()),
                    inputEdit("edit_profile.add_company_name".tr(),
                        companyNameEditingController),
                    title("edit_profile.school_name".tr()),
                    inputEdit("edit_profile.add_school_name".tr(),
                        schoolEditingController),
                  ],
                ),
              ),
              title("edit_profile.living_in".tr()),
              GestureDetector(
                onTap: () async {
                  UserModel? result = await QuickHelp.goToNavigatorScreenForResult(context, AddCityScreen(currentUser: widget.currentUser), route: AddCityScreen.route);

                  if(result != null){
                    setState(() {
                      widget.currentUser = result;
                    });
                  }
                },
                child: option(widget.currentUser!.getLocationOnly!),
              ),
              title("edit_profile.my_gender".tr()),
              Padding(
                padding: EdgeInsets.only(bottom: 13.0),
                child: ContainerCorner(
                  height: 80,
                  borderRadius: 10,
                  marginTop: 15,
                  color: kGreyColor0,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        genderOptions(UserModel.keyGenderMale,
                            "auth.a_man".tr(), _genderSelection!),
                        Expanded(
                            child: genderOptions(UserModel.keyGenderFemale,
                                "auth.a_woman".tr(), _genderSelection!)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        passionsStepWidget(),
        photosSelectionStepWidget(),
      ],
    );
  }

  ContainerCorner inputEdit(String text, TextEditingController controller) {
    return ContainerCorner(
      height: 50,
      borderRadius: 10,
      marginTop: 15,
      color: kGreyColor0,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TextField(
                style: TextStyle(
                  color: kGreyColor2,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                controller: controller,
                decoration: InputDecoration(
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: kGreyColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: text,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Row genderOptions(String gender, String text, String selected) {
    return Row(
      children: [
        Radio(
            activeColor: kPrimaryColor,
            value: gender,
            groupValue: _genderSelection,
            onChanged: (String? value) {
              setState(() {
                _genderSelection = value;
                widget.currentUser!.setGender = gender;
                widget.currentUser!.save();
              });
            }),
        SizedBox(
          width: 10,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _genderSelection = gender;
              widget.currentUser!.setGender = gender;
              widget.currentUser!.save();
            });
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: selected == gender ? kPrimaryColor : kGreyColor2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Padding title(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        top: 25,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  ContainerCorner option(String option) {
    return ContainerCorner(
      height: 50,
      borderRadius: 10,
      marginTop: 15,
      color: kGreyColor0,
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: kGreyColor2,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget passionsStepWidget() {
    return Container(
      width: Responsive.isWebOrDeskTop(context) ? 600 : null,
      margin: EdgeInsets.only(top: 25),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Column(
          children: [
            Wrap(
              spacing: 10.0, // gap between adjacent chips
              runSpacing: 10.0,
              alignment: WrapAlignment.center,
              //crossAxisAlignment: WrapCrossAlignment.center,
              children: List.generate(QuickHelp.getPassionsList().length, (index) {
                String code = QuickHelp.getPassionsList()[index];

                return Container(
                  child: GestureDetector(
                    child: ContainerCorner(
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
            RoundedGradientButton(
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
                if (currentStep == currentStepPassions) {
                  if (isValidPassions) {

                    widget.currentUser!.setPassions = mySelectedPassions;
                    widget.currentUser!.save();

                    setState(() {
                      passionsEditingController.text = QuickHelp.getPassionsListWithName(widget.currentUser!);
                    });

                    _updateCurrentState(currentStepProfile);
                  }
                }
              }
            ),
          ],
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            photosBuilder(UserModel.keyAvatar1, imageFilePath0),
            photosBuilder(UserModel.keyAvatar2, imageFilePath1),
            photosBuilder(UserModel.keyAvatar3, imageFilePath2),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            photosBuilder(UserModel.keyAvatar4, imageFilePath3),
            photosBuilder(UserModel.keyAvatar5, imageFilePath4),
            photosBuilder(UserModel.keyAvatar6, imageFilePath5),
          ],
        ),
      ],
    );
  }

  Widget photosBuilder(String keyAvatar, String? imagePath) {
    return Expanded(
      child: ContainerCorner(
        width: 104,
        height: Responsive.isMobile(context) ? 180 : 300,  //Responsive.isWebOrDeskTop(context) ? 300 : Responsive.isTablet(context) ? 300 : 145,
        alignment: Alignment.center,
        color: kPhotosGrayColor,
        borderColor: Colors.transparent,
        borderRadius: 10,
        marginAll: 2,
        child: imagePath!.isNotEmpty
            ? Container(
                child: Stack(
                  children: [
                    QuickActions.photosWidget(imagePath),
                    Visibility(
                      visible: widget.currentUser!.getAvatar!.url != imagePath,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: () => _removePhoto(keyAvatar, imagePath),
                          child: Container(
                            child: SvgPicture.asset(
                              "assets/svg/ic_close_red.svg",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
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
                        margin: EdgeInsets.only(bottom: 10),
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
          checkPermission(keyAvatar);
        },
      ),
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
            "assets/svg/ic_source_gallery.svg"),
      ],
    );
  }

  Widget sourceBuilder(ImageSource sourceType, String source, String svg, {Color? color}) {
    return ContainerCorner(
      width: QuickHelp.isMobile() ? null : 400,
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

      Future.delayed(Duration(seconds: 1), () async{
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
    } else {
      parseFile = ParseWebFile(imageFile.rawBytes, name: "avatar.jpg");
    }

    if(parseFile != null){

      if(sourcePosition == UserModel.keyAvatar1){
        widget.currentUser!.setAvatar = parseFile!;
        widget.currentUser!.setAvatar1 = parseFile!;

      } else if(sourcePosition == UserModel.keyAvatar2){
        widget.currentUser!.setAvatar2 = parseFile!;

      } else if(sourcePosition == UserModel.keyAvatar3){
        widget.currentUser!.setAvatar3 = parseFile!;

      } else if(sourcePosition == UserModel.keyAvatar4){
        widget.currentUser!.setAvatar4 = parseFile!;

      } else if(sourcePosition == UserModel.keyAvatar5){
        widget.currentUser!.setAvatar5 = parseFile!;

      } else if(sourcePosition == UserModel.keyAvatar6){
        widget.currentUser!.setAvatar6 = parseFile!;
      }

      final ParseResponse pictureResult = await widget.currentUser!.save();
      if (pictureResult.success) {
        QuickHelp.hideLoadingDialog(context);

        setState(() {

          if (sourcePosition == UserModel.keyAvatar1) {
            imageFilePath0 = parseFile!.url;

          } else if (sourcePosition == UserModel.keyAvatar2) {
            imageFilePath1 = parseFile!.url;

          } else if (sourcePosition == UserModel.keyAvatar3) {
            imageFilePath2 = parseFile!.url;

          } else if (sourcePosition == UserModel.keyAvatar4) {
            imageFilePath3 = parseFile!.url;

          } else if (sourcePosition == UserModel.keyAvatar5) {
            imageFilePath4 = parseFile!.url;

          } else if (sourcePosition == UserModel.keyAvatar6) {
            imageFilePath5 = parseFile!.url;
          }

        });

        _updateCurrentState(currentStepProfile);

      } else {

        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAlertError(context: context, title: "auth.upload_file_failed".tr());

        _updateCurrentState(currentStepProfile);
        //return;
      }
    }

  }

  Future<void> checkPermission(String keyAvatar) async {
    sourcePosition = keyAvatar;

    if (QuickHelp.isAndroidPlatform()) {
      PermissionStatus status = await Permission.storage.status;
      PermissionStatus status2 = await Permission.camera.status;
      print('Permission android');

      checkStatus(status, status2, keyAvatar);
    } else if (QuickHelp.isIOSPlatform()) {
      PermissionStatus status = await Permission.photos.status;
      PermissionStatus status2 = await Permission.camera.status;
      print('Permission ios');

      checkStatus(status, status2, keyAvatar);
    } else {
      print('Permission other device');
      _updateCurrentState(currentStepPhotosSelection);
    }
  }

  void checkStatus(
      PermissionStatus status, PermissionStatus status2, String keyAvatar) {
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
              _updateCurrentState(currentStepPhotosSelection);
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
      _updateCurrentState(currentStepPhotosSelection);
    }

    print('Permission $status');
    print('Permission $status2');
  }
}
