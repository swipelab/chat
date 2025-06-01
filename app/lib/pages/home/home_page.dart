import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/pages/settings/settings_page.dart';
import 'package:app/services/server.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class HomePage with AppPage, AppPageView, Emitter {
  HomePage() {
    load();
  }

  Future<void> load() async {
    rooms.replaceWith(await app.server.rooms());
    notifyListeners();
  }

  ListEmitter<Room> rooms = ListEmitter();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text('Conversations'),
          actions: [
            IconButton(
              onPressed: SettingsPage().push,
              icon: Icon(CupertinoIcons.settings),
            ),
          ],
        ),
        body: ListView.builder(
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(
              child: Icon(CupertinoIcons.chat_bubble_2),
            ),
            title: Text(rooms[index].alias),
            onTap: rooms[index].link.push,
          ),
          itemCount: rooms.length,
        ),
      ),
    );
  }
}
