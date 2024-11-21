import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseModel {

  static final String typePopular = "popular";
  static final String typeHot = "hot";
  static final String typeNormal = "normal";
  static final String type1MonthSubscription = "subscription_1_Month";
  static final String type3MonthSubscription = "subscription_3_Months";

  String? id;
  String? price;
  int? coins;
  DateTime? period;
  String? discount;
  String? type;
  String? image;
  String? currencySymbol;
  String? currency;
  ProductDetails? productDetails;

  InAppPurchaseModel({this.id, this.price, this.coins, this.period, this.discount, this.type, this.image, this.productDetails, this.currency, this.currencySymbol});

  String? getId() {
    return id;
  }

  void setId(String id) {
    this.id = id;
  }

  String? getPrice() {
    return price;
  }

  void setPrice(String price) {
    this.price = price;
  }

  int? getCoins() {
    return coins;
  }

  void setCoins(int coins) {
    this.coins = coins;
  }

  DateTime? getPeriod() {
    return period;
  }

  void setPeriod(DateTime time) {
    this.period = time;
  }

  String? getDiscount() {
    return discount;
  }

  void setDiscount(String discount) {
    this.discount = discount;
  }

  String? getType() {
    return type;
  }

  void setType(String type) {
    this.type = type;
  }

  String? getImage() {
    return image;
  }

  void setImage(String image) {
    this.image = image;
  }

  ProductDetails? getProductDetails() {
    return productDetails;
  }

  void setProductDetails(ProductDetails productDetails) {
    this.productDetails = productDetails;
  }


  String? getCurrency() {
    return currency;
  }

  void setCurrency(String currency) {
    this.currency = currency;
  }

  String? getCurrencySymbol() {
    return currencySymbol;
  }

  void setCurrencySymbol(String currencySymbol) {
    this.currencySymbol = currencySymbol;
  }
}