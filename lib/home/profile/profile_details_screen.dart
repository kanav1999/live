import 'package:carousel_slider/carousel_slider.dart';
import 'package:heyto/app/setup.dart';
import 'package:heyto/helpers/quick_actions.dart';
import 'package:heyto/helpers/quick_help.dart';
import 'package:heyto/helpers/responsive.dart';
import 'package:heyto/home/profile/edit_profile_screen.dart';
import 'package:heyto/models/UserModel.dart';
import 'package:heyto/ui/app_bar_center_widget.dart';
import 'package:heyto/ui/container_with_corner.dart';
import 'package:heyto/ui/text_with_tap.dart';
import 'package:heyto/app/colors.dart';
import 'package:heyto/widgets/need_resume.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class ProfileDetailsScreen extends StatefulWidget {
  static String route = '/profile/details';

  UserModel? currentUser;
  ProfileDetailsScreen({this.currentUser});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ResumableState<ProfileDetailsScreen> {

  String getBirthDay(UserModel currentUser) {
    if (currentUser.getBirthday != null) {
      return ", ${QuickHelp.getAgeFromDate(currentUser.getBirthday!)}";
    } else {
      return "";
    }
  }

  String getWork(UserModel currentUser) {

    List<String> myWork = [];

    if (currentUser.getJobTitle!.isNotEmpty) {
      myWork.add(currentUser.getJobTitle!);
    }

    if (currentUser.getCompanyName!.isNotEmpty) {
      myWork.add(currentUser.getCompanyName!);
    }

    return myWork.join(", ");
  }

  @override
  void initState() {
   // _getUser();
    print('HomeScreen is initState!');
    super.initState();
  }

  @override
  void onReady() {
    // Implement your code inside here
    print('HomeScreen is ready!');
  }

  @override
  void onPause() {
    // Implement your code inside here

    print('HomeScreen is paused!');
  }

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.profile_title".tr());

    return ToolBarCenterWidget(
      iconHeight: 24,
      iconWidth: 24,
      centerTitle: true,
      centerWidget: TextWithTap("page_title.profile_title".tr(), color: QuickHelp.getColorStandard()),
      leftButtonIcon: Icons.arrow_back,
      leftButtonPress: () => QuickHelp.goBackToPreviousPage(context, result: widget.currentUser),
      rightIconColor: QuickHelp.getColorToolbarIcons(),
      rightButtonAsset: "ic_nav_edit_profile.svg",
      rightButtonPress: () async {

        UserModel? userModel = await QuickHelp.goToNavigatorScreenForResult(context, EditProfileScreen(currentUser: widget.currentUser,), route: EditProfileScreen.route);

        if(userModel != null){

          setState(() {
            widget.currentUser = userModel;
          });
        }
      },
      child: SafeArea(
        child: Responsive.isMobile(context) || Responsive.isTablet(context) ? getBody() : webBody(),
      ),
    );
  }

  double spaces() {
    var size = MediaQuery.of(context).size.width;
    if(size == 1200) {
      return 100.0;
    }else if(size > 1200){
      return 200.0;
    }else if(size <= 1024){
      return 10;
    }else{
      return 5;
    }
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;
    final CarouselController _controller = CarouselController();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CarouselSlider.builder(
                      options: CarouselOptions(
                          height: size.height / 2.5,
                          autoPlay: QuickHelp.getPhotosCounter(widget.currentUser).length > 1 ? true : false,
                          autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                          enlargeCenterPage: true,
                          viewportFraction: 1,
                          aspectRatio: 4/4,
                          autoPlayCurve: Curves.linearToEaseOut,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          }),
                      carouselController: _controller,
                      itemCount:
                      QuickHelp.getPhotosCounter(widget.currentUser).length,
                      itemBuilder: (BuildContext context, int itemIndex,
                          int pageViewIndex) {
                        return ContainerCorner(
                          color: kTransparentColor,
                          width: size.width,
                          height: size.height,
                          marginLeft: 10,
                          marginRight: 10,
                          child: QuickActions.photosWidget(
                            QuickHelp.getPhotosCounter(widget.currentUser)[itemIndex], borderRadius: 8, fit: BoxFit.cover,
                          ),
                        );
                      }),
                  /*Container(
                        alignment: Alignment.topCenter,
                        margin: EdgeInsets.only(
                          right: 10,
                          left: 10,
                        ),
                        height: size.width,
                        child: QuickActions.photosWidget(pictures[countPicture]!), //QuickActions.photosWidget(isLoading ? "" : pictures[countPicture]!),
                      ),*/
                  /*Align(
                        alignment: Alignment.centerLeft,
                        child: ContainerCorner(
                          width: size.width /2,
                          height: size.width,
                          color: Colors.transparent,
                          onTap: (){

                            if (countPicture > 0) {

                              setState(() {
                                countPicture--;
                              });
                            }

                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ContainerCorner(
                          width: size.width /2,
                          height: size.width,
                          color: Colors.transparent,
                          onTap: (){

                            if (countPicture == numberOfPictures -1) {
                              //countPicture = 0;

                            } else {
                              setState(() {
                                countPicture++;
                              });

                            }

                          },
                        ),
                      ),*/
                  Align(
                    alignment: Alignment.topCenter,
                    child: Visibility(
                      visible: QuickHelp.getPhotosCounter(widget.currentUser).length > 1 ? true : false,
                      child: QuickHelp.pictureStep(
                          context,
                          QuickHelp.getPhotosCounter(widget.currentUser).length,
                          _current),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  top: 20,
                  bottom: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.currentUser!.getFullName!}",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${getBirthDay(widget.currentUser!)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    SizedBox(
                        width: 20,
                        height: 20,
                        child: SvgPicture.asset("assets/svg/ic_verified_account.svg"))
                  ],
                ),
              ),
              info("assets/svg/prof.svg", getWork(widget.currentUser!)),
              info("assets/svg/school.svg", widget.currentUser!.getSchool!),
              info("assets/svg/sex.svg",
                  QuickHelp.getSexualityListWithName(widget.currentUser!)),
              info("assets/svg/country.svg", widget.currentUser!.getLocation!),
              Padding(
                padding: EdgeInsets.only(left: 20, top: 10),
                child: Text(
                  "edit_profile.about_".tr(),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, top: 10, right: 8),
                child: Text(
                  widget.currentUser!.getAboutYou!,
                  style: TextStyle(
                    color: kDisabledGrayColor,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, top: 10),
                child: Text(
                  "edit_profile.passions_section".tr(),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                ),
                child: passionsStepWidget(),
              ),
              /* Padding(
                    padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                    child: Text(
                      "edit_profile.insta_photos".tr(),
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                 Stack(children: [
                    Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(
                        right: 10,
                        left: 10,
                      ),
                      height: 198,
                      width: size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryColor.withOpacity(0.9),
                            kSecondaryColor.withOpacity(0.9)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: cards(context),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 56),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset("assets/svg/insta.svg"),
                            SizedBox(
                              height: 15,
                            ),
                            Text(
                              "edit_profile.connect_insta".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ]),*/
              SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ),
    ]);
  }

  Widget webBody() {
    var size = MediaQuery.of(context).size;
    final CarouselController _controller = CarouselController();

    return ContainerCorner(
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
              child: Stack(
              children: [
                CarouselSlider.builder(
                    options: CarouselOptions(
                        height: size.height,
                        autoPlay: QuickHelp.getPhotosCounter(widget.currentUser).length > 1 ? true : false,
                        autoPlayInterval: Duration(seconds: Setup.photoSliderDuration),
                        enlargeCenterPage: true,
                        viewportFraction: 1,
                        aspectRatio: 4/12,
                        autoPlayCurve: Curves.linearToEaseOut,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        }),
                    carouselController: _controller,
                    itemCount:
                    QuickHelp.getPhotosCounter(widget.currentUser).length,
                    itemBuilder: (BuildContext context, int itemIndex,
                        int pageViewIndex) {
                      return ContainerCorner(
                        color: kTransparentColor,
                        width: size.width,
                        height: size.height,
                        marginLeft: 10,
                        marginRight: 10,
                        child: QuickActions.photosWidget(
                          QuickHelp.getPhotosCounter(widget.currentUser)[itemIndex], borderRadius: 8, fit: BoxFit.cover,
                        ),
                      );
                    }),

                Align(
                  alignment: Alignment.topCenter,
                  child: Visibility(
                    visible: QuickHelp.getPhotosCounter(widget.currentUser).length > 1 ? true : false,
                    child: QuickHelp.pictureStep(
                        context,
                        QuickHelp.getPhotosCounter(widget.currentUser).length,
                        _current),
                  ),
                ),
              ],
            ),),
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                    child: Text(
                      "edit_profile.user_information".tr(),
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      top: 20,
                      bottom: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.currentUser!.getFullName!}",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "${getBirthDay(widget.currentUser!)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: 7,
                        ),
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: SvgPicture.asset(
                                "assets/svg/ic_verified_account.svg"))
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        info("assets/svg/prof.svg", getWork(widget.currentUser!)),
                        info("assets/svg/school.svg", widget.currentUser!.getSchool!),
                        info("assets/svg/sex.svg",
                            QuickHelp.getSexualityListWithName(widget.currentUser!)),
                        info("assets/svg/country.svg", widget.currentUser!.getLocation!),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 10),
                    child: Text(
                      "edit_profile.about_".tr(),
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 10, right: 8),
                    child: Text(
                      widget.currentUser!.getAboutYou!,
                      style: TextStyle(
                        color: kDisabledGrayColor,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, top: 10),
                    child: Text(
                      "edit_profile.passions_section".tr(),
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                    ),
                    child: passionsStepWidget(),
                  ),
                  SizedBox(
                    height: 15,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Padding info(String icon, String text) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 7,
          ),
          SizedBox(width: 15, height: 15, child: SvgPicture.asset(icon)),
          SizedBox(
            width: 7,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF879099),
            ),
          ),
        ],
      ),
    );
  }

  Widget passionsStepWidget() {
    return Container(
      margin: EdgeInsets.only(top: 25),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          //crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(widget.currentUser!.getPassions!.length, (index) {
            return ContainerCorner(
              borderRadius: 70,
              height: 32,
              colors: [kPrimaryColor, kSecondaryColor],
              borderColor: kPrimaryColor,
              borderWidth: 1,
              child: Padding(
                padding: EdgeInsets.only(top: 6),
                child: TextWithTap(
                    QuickHelp.getPassions(widget.currentUser!.getPassions![index]),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    marginLeft: 14,
                    marginRight: 14,
                    textAlign: TextAlign.center,
                    color: Colors.white),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget cards(context) {

    Size size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(
        top: 10,
        right: 10,
        left: 10,
        bottom: 10,
      ),
      child: SingleChildScrollView(
        //controller: _scrollController,
        child: Wrap(
          spacing: 10.0, // gap between adjacent chips
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          //crossAxisAlignment: WrapCrossAlignment.center,
          children: List.generate(8, (index) {
            return ContainerCorner(
              borderRadius: 8,
              height: 80,
              width: (size.width / 4) - 20,
              color: kGreyColor1.withOpacity(0.3),
            );
          }),
        ),
      ),
    );
  }
}
