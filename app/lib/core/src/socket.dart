import 'dart:io' as ws;
import 'dart:ui';

import 'package:app/app.dart';

class Socket {
  Socket({required this.url, this.onOpen, this.onClose, this.onMessage});

  final String url;
  ws.WebSocket? _ws;
  final VoidCallback? onOpen;
  void Function(dynamic msg)? onMessage;
  void Function(int? code, String? reason)? onClose;

  connect() async {
    try {
      _ws = await app.server.webSocket(url);
      onOpen?.call();
      _ws?.listen(
        (data) {
          onMessage?.call(data);
        },
        onDone: () {
          final socket = _ws;
          if (socket == null) return;
          onClose?.call(socket.closeCode, socket.closeReason);
        },
      );
    } catch (e) {
      onClose?.call(500, e.toString());
    }
  }

  send(dynamic data) {
    _ws?.add(data);
  }

  close() {
    _ws?.close();
  }
}
