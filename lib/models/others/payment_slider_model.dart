import 'package:heyto/models/UserModel.dart';

class PaymentSliderModel {

    String? title;
    String? explain;
    String? badgeImage;
    UserModel? mUser;

     String? getTitle() {
        return title;
    }

     void setTitle(String title) {
        this.title = title;
    }

     String? getExplain() {

        if (explain != null && explain!.isNotEmpty){
            return explain;
        } else {
            return  "";
        }
    }

     void setExplain(String explain) {
        this.explain = explain;
    }

     String? getBadgeImage() {
        return badgeImage;
    }

     void setBadgeImage(String badgeImage) {
        this.badgeImage = badgeImage;
    }

     UserModel? getUser() {
        return mUser;
    }

     void setUser(UserModel mUser) {
        this.mUser = mUser;
    }
}
