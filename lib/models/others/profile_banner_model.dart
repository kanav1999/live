class ProfileBannerModel {

  static final String profileBannerLikes = "BANNER_LIKES";
  static final String profileBannerStartChat = "BANNER_START_CHAT";
  static final String profileBannerMatchesFast = "BANNER_MATCHES_FAST";
  static final String profileBannerPremium = "BANNER_PREMIUM";
  static final String profileBannerSwiping = "BANNER_SWIPING" ;
  static final String profileBannerMatches = "BANNER_MATCHES";
  static final String profileBannerHideAds = "BANNER_HIDE_ADS";
  static final String profileBannerFastFilter = "BANNER_FAST_FILTER";
  static final String profileBannerVerifyMe = "BANNER_VERIFY_ME";
  static final String profileBannerVerifyPhone = "BANNER_VERIFY_PHONE";

  String? type;
  int? credit;
  String? image;
  String? title;
  String? description;
  String? button;
  bool? premium;

  ProfileBannerModel({this.type, this.credit, this.title, this.description, this.button, this.premium});

  String? getType() {
    return type;
  }

  void setType(String type) {
    this.type = type;
  }

  int? getCredit() {
    return credit;
  }

  void setCredit(int credit) {
    this.credit = credit;
  }

  String? getImage() {
    return image;
  }

  void setImage(String image) {
    this.image = image;
  }

  String? getTitle() {
    return title;
  }

  void setTitle(String title) {
    this.title = title;
  }

  String? getDescription() {
    return description;
  }

  void setDescription(String description) {
    this.description = description;
  }

  String? getButton() {
    return button;
  }

  void setButton(String button) {
    this.button = button;
  }

  bool? isPremium() {
    return premium;
  }

  void setPremium(bool isPremium) {
    this.premium = isPremium;
  }
}