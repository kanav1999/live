class MoodModel {

  String? name;
  String? code;

  MoodModel({this.name, this.code});

  String? getName() {
    return name;
  }

  void setName(String name) {
    this.name = name;
  }

  String? getCode() {
    return code;
  }

  void setCode(String code) {
    this.code = code;
  }
}