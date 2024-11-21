import 'package:heyto/helpers/quick_help.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:heyto/app/cloud_params.dart';
import 'package:heyto/models/UserModel.dart';

import '../app/constants.dart';
import '../app/setup.dart';

class QuickCloudCode {
  static Future<ParseResponse> followUser(
      {required UserModel author,
      required UserModel receiver,
      required bool isFollowing}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.followUserParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.author: author.objectId,
      CloudParams.receiver: receiver.objectId,
      CloudParams.isFollowing: isFollowing,
    };

    return await function.execute(parameters: params);
  }

  static Future<ParseResponse> sendGift(
      {required String authorId, required int credits}) async {
    ParseCloudFunction function = ParseCloudFunction(CloudParams.sendGiftParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.objectId: authorId,
      CloudParams.credits: QuickHelp.getDiamondsForReceiver(credits),
    };

    return await function.execute(parameters: params);
  }

  static Future<ParseResponse> verifyPayment(
      {required String productSku, required String purchaseToken}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.verifyPaymentParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.packageName: Constants.appPackageName(),
      CloudParams.purchaseToken: purchaseToken,
      CloudParams.productId: productSku,
      CloudParams.platform: QuickHelp.getDeviceOsType(),
    };

    return await function.execute(parameters: params);
  }

  static Future<ParseResponse> payFromServer({
    required String userId,
    required String fullName,
    required String email,
    required String amount,
    required String currency,
    required String description,
    String? source,
    String? customer,
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
  }) async {

    ParseCloudFunction function = ParseCloudFunction(customer != null ? CloudParams.makePaymentParam : CloudParams.makePaymentNewParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.objectId: userId,
      CloudParams.fullName: fullName,
      CloudParams.emailAddress: email,

      CloudParams.amount: amount.replaceAll(".", ""),
      CloudParams.currency: currency,
      CloudParams.description: description,

      CloudParams.source: source,
      CloudParams.customer: customer,

      CloudParams.cardNumber: cardNumber,
      CloudParams.expirationMonth: expMonth,
      CloudParams.expirationYear: expYear,
      CloudParams.code: cvc,
    };

    return await function.execute(parameters: params);
  }

  static sendTicketsToInvitee({required String authorId, required String receivedId}) async {

    ParseCloudFunction function = ParseCloudFunction(CloudParams.sendTicketsInviteeParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.author: authorId,
      CloudParams.receiver: receivedId,
      CloudParams.credits: Setup.freeTicketsToInvite,
    };

    await function.execute(parameters: params);
  }
}
