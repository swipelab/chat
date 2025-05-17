class Session {
  Session({required this.userId, required this.alias, required this.token});

  final int userId;
  final String alias;
  final String token;

  static Session fromJson(dynamic json) {
    return Session(
      userId: json['user_id'] as int,
      alias: json['alias'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'alias': alias, 'token': token, 'user_id': userId};
  }
}
