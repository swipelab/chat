import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/models/session.dart';
import 'package:http/http.dart' as http;
import 'package:stated/stated.dart';

class Room {
  const Room({required this.roomId, required this.alias});

  final int roomId;
  final String alias;

  String get link => '/room/$roomId';

  static Room fromJson(dynamic json) {
    return Room(roomId: json['room_id'] as int, alias: json['alias'] as String);
  }
}

class MessagePayload {
  final String? text;

  MessagePayload({this.text});

  static MessagePayload fromJson(dynamic json) {
    return MessagePayload(text: json["text"] as String?);
  }

  @override
  String toString() {
    return text ?? '';
  }
}

class Message {
  final MessagePayload payload;

  Message({required this.payload});

  static Message fromJson(dynamic json) {
    return Message(payload: MessagePayload.fromJson(json['payload']));
  }
}

class Server {
  Server(this.host);

  final String host;

  http.Client get client => http.Client();

  Future<void> deleteAccount() async {
    await delete('/api/auth');
  }

  Future<Session> login(String username, String password) async {
    return await post('/api/auth/login', {
      "alias": username,
      "password": password,
    }, Session.fromJson).then((e) => e!);
  }

  Future<void> register(String username, String password) async {
    await post('/api/auth/register', {"alias": username, "password": password});
  }

  Future<void> logout() async {
    if (app.session.session == null) return;
    await post('/api/auth/logout');
  }

  Future<void> updateFcmToken(String? token) async {
    if (app.session.session == null) return;
    if (token == null) {
      await delete('/api/auth/fcm');
    } else {
      await post('/api/auth/fcm', {"token": token});
    }
  }

  Future<List<Room>> rooms() async {
    return await getList('/api/rooms', Room.fromJson);
  }

  Future<List<Message>> messages(int roomId) async {
    return await getList('/api/room/$roomId/messages', Message.fromJson);
  }

  Future<void> postMessage(int roomId, Map<String, Object?> payload) async {
    await post('/api/room/$roomId/message', payload);
  }

  Future<List<T>> getList<T>(
    String path,
    T Function(dynamic json) fromJson,
  ) async {
    final uri = Uri.parse('$host$path');
    final result = await client.get(
      uri,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    if (result.statusCode >= 300) {
      throw Exception('GET $uri -> ${result.statusCode} ${result.body}');
    }
    return (jsonDecode(utf8.decode(result.bodyBytes, allowMalformed: true))
            as List)
        .map(fromJson)
        .toList();
  }

  Future<T?> post<T>(
    String path, [
    Object? body,
    T Function(dynamic json)? fromJson,
  ]) async {
    final uri = Uri.parse('$host$path');
    final session = app.session.session;
    final result = await client.post(
      uri,
      body: body?.pipe(jsonEncode),
      headers: {
        'content-type': 'application/json',
        if (session != null) 'authorization': 'Bearer ${session.token}',
      },
    );
    if (result.statusCode >= 300) {
      throw Exception('POST $uri -> ${result.statusCode} ${result.body}');
    }
    if (fromJson == null) return null;
    return fromJson(jsonDecode(result.body));
  }

  Future<T?> delete<T>(
    String path, [
    Object? body,
    T Function(dynamic json)? fromJson,
  ]) async {
    final uri = Uri.parse('$host$path');
    final session = app.session.session;
    final result = await client.delete(
      uri,
      body: body?.pipe(jsonEncode),
      headers: {
        'content-type': 'application/json',
        if (session != null) 'authorization': 'Bearer ${session.token}',
      },
    );
    if (result.statusCode >= 300) {
      throw Exception('DELETE $uri -> ${result.statusCode} ${result.body}');
    }
    if (fromJson == null) return null;
    return fromJson(jsonDecode(result.body));
  }
}
