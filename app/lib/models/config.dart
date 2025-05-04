class Config {
  String? fcmToken;

  static Config fromJson(dynamic json) {
    final result = Config();
    result.fcmToken = json['fcm_token'];
    return result;
  }

  Map<String, Object?> toJson() {
    return {'fcm_token': fcmToken};
  }
}
