class Session {
  Session({required this.alias, required this.token});

  final String alias;
  final String token;

  static Session fromJson(dynamic json) {
    return Session(
      alias: json['alias'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'alias': alias, 'token': token};
  }
}
