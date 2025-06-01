import 'dart:io';
import 'dart:typed_data';

import 'package:app/app.dart';
import 'package:app/models/session.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:stated/io.dart';

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
  final int senderAuthId;

  Message({
    required this.payload,
    required this.senderAuthId,
  });

  static Message fromJson(dynamic json) {
    return Message(
      payload: MessagePayload.fromJson(json['payload']),
      senderAuthId: json['sender_auth_id'],
    );
  }
}

class ChatApi extends HttpClient {
  ChatApi(this.host);

  @override
  final String host;

  @override
  final String scheme = "https";

  @override
  http.Client get client => http.Client();

  Session? get session => app.session.session;

  @override
  Map<String, String> get headers => {
    if (session != null) 'authorization': 'Bearer ${session?.token}',
  };

  NetworkImage? avatar(String? userId) {
    final session = app.session.session;
    if (userId == null || session == null) return null;
    return NetworkImage(
      'https://$host/api/user/$userId/profile/picture',
      headers: {
        'authorization': 'Bearer ${session.token}',
      },
    );
  }

  Future<void> deleteAccount() async {
    await delete('/api/auth');
  }

  Future<Session> login(String username, String password) async {
    return await post(
      '/api/auth/login',
      body: {
        "alias": username,
        "password": password,
      },
      marshal: Session.fromJson,
    );
  }

  Future<void> register(String username, String password) async {
    await post(
      '/api/auth/register',
      body: {"alias": username, "password": password},
    );
  }

  Future<void> logout() async {
    if (app.session.session == null) return;
    await post('/api/auth/logout');
  }

  Future<void> postFcmToken(String? token) async {
    if (app.session.session == null || token == null) return;
    await post('/api/auth/fcm', body: {"token": token});
  }

  Future<void> postProfilePicture(Uint8List buffer) async {
    assert(app.session.session != null);
    await postBuffer('/api/profile/picture', buffer);
  }

  Future<List<Room>> rooms() async {
    return await get('/api/rooms', marshal: Room.fromJson.list);
  }

  Future<List<Message>> messages(int roomId) async {
    return await get(
      '/api/room/$roomId/messages',
      marshal: Message.fromJson.list,
    );
  }

  Future<void> postMessage(int roomId, Map<String, Object?> payload) async {
    await post('/api/room/$roomId/message', body: payload);
  }

  Future<WebSocket> webSocket(String path) async {
    return await WebSocket.connect('wss://$host$path', headers: headers);
  }
}
