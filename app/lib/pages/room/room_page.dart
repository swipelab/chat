import 'dart:math';

import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/pages/call/call_page.dart';
import 'package:app/services/server.dart';
import 'package:app/widgets/touch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class RoomPage with AppPage, AppPageView, Emitter {
  RoomPage(this.roomId) {
    load();
  }

  final int roomId;
  List<Message> messages = [];
  final textField = TextEditingController(text: '');

  Future<void> load() async {
    messages = await app.server
        .messages(roomId)
        .then((e) => e.reversed.toList());
    notifyListeners();
  }

  Future<void> send() async {
    if (textField.text.isEmpty) return;
    await app.server.postMessage(roomId, {"text": textField.text});
    textField.text = '';
    notifyListeners();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => CallPage(callId: roomId).push(),
            icon: Icon(Icons.video_call),
          ),
        ],
      ),
      body: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        reverse: true,
        itemBuilder: (context, index) => MessageTile(
          state: messages[index],
          onLongPress: () =>
              textField.text = messages[index].payload.toString(),
        ),
        itemCount: messages.length,
      ),
      bottomNavigationBar: Composer(
        controller: textField,
        onSubmit: send,
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({required this.state, this.onLongPress, super.key});

  final Message state;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: app.server.avatar(state.senderAuthId.toString()),
        radius: 12,
        child: Icon(
          CupertinoIcons.person,
          size: 12,
        ),
      ),
      title: Text(state.payload.toString()),
      onLongPress: onLongPress,
    );
  }
}

class Composer extends StatelessWidget {
  const Composer({this.controller, this.onSubmit, super.key});

  final TextEditingController? controller;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF202020)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: max(max(insets.bottom, padding.bottom), 12) + 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                minLines: 1,
                maxLines: 5,
                controller: controller,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Color(0xFF3E3E3E),
                  border: Border.all(
                    color: Color(0xFF666666),
                    strokeAlign: BorderSide.strokeAlignOutside,
                    width: 0.5,
                  ),
                ),
                style: TextStyle(color: Color(0xFFFFFFFF)),
                padding: EdgeInsets.all(8),
              ),
            ),
            SizedBox(width: 8),
            Touch(
              onTap: onSubmit,
              child: Container(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 8,
                  left: 10,
                  right: 6,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: Icon(Icons.send, size: 20, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
