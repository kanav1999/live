import 'package:heyto/models/UserModel.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class WithdrawModel extends ParseObject implements ParseCloneable {

  static final String keyTableName = "Withdrawn";

  WithdrawModel() : super(keyTableName);
  WithdrawModel.clone() : this();

  @override
  WithdrawModel clone(Map<String, dynamic> map) => WithdrawModel.clone()..fromJson(map);

  static const PENDING = "pending";
  static const PROCESSING = "processing";
  static const COMPLETED = "completed";


  static const PAYONEER = "payoneer";
  static const IBAN = "IBAN";
  static const CURRENCY = "USD";


  static final String keyAuthor = "author";
  static final String keyTokens = "diamonds";
  static final String keyAmount = "amount";
  static final String keyCompleted = "completed"; //false,true
  static final String keyStatus = "status"; // pending, processing, completed
  static final String keyEmail = "email";
  static final String keyMethod = "method";
  static final String keyCurrency = "currency";
  static final String keyIBAN = "IBAN";
  static final String keyAccountName = "account_name";
  static final String keyBankName = "bank_name";

  UserModel? get getAuthor => get<UserModel>(keyAuthor);
  set setAuthor(UserModel author) => set<UserModel>(keyAuthor, author);

  set setDiamonds(int diamonds) => setIncrement(keyTokens, diamonds);
  int? get getDiamonds {
    int? diamond = get<int>(keyTokens);
    if(diamond != null){
      return diamond;
    } else {
      return 0;
    }
  }

  set setCredit(double amount) => setIncrement(keyAmount, amount);
  double? get getCredit {
    double? amount = get<double>(keyAmount);
    if(amount != null){
      return amount;
    } else {
      return 0;
    }
  }

  set setCompleted(bool completed) => set<bool>(keyCompleted, completed);
  bool? get getCompleted{
    bool? completed = get<bool>(keyCompleted);
    if(completed != null){
      return completed;
    }else{
      return true;
    }
  }

  String? get getStatus => get<String>(keyStatus);
  set setStatus(String status) => set<String>(keyStatus, status);

  String? get getAccountName => get<String>(keyAccountName);
  set setAccountName(String name) => set<String>(keyAccountName, name);

  String? get getBankName => get<String>(keyBankName);
  set setBankName(String bank) => set<String>(keyBankName, bank);

  String? get getEmail => get<String>(keyEmail);
  set setEmail(String email) => set<String>(keyEmail, email);

  String? get getIBAN => get<String>(keyIBAN);
  set setIBAN(String iban) => set<String>(keyIBAN, iban);

  String? get getMethod => get<String>(keyMethod);
  set setMethod(String method) => set<String>(keyMethod, method);

  String? get getCurrency => get<String>(keyCurrency);
  set setCurrency(String currency) => set<String>(keyCurrency, currency);

}