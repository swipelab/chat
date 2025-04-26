import 'package:app/app.dart';
import 'package:app/core/router.dart';
import 'package:app/data/server.dart';
import 'package:app/pages/account/account_page.dart';
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
      builder:
          (context, _) => Scaffold(
            appBar: AppBar(
              title: Text('Conversations'),
              actions: [
                IconButton(
                  onPressed: AccountPage().push,
                  icon: Icon(Icons.person),
                ),
              ],
            ),
            body: ListView.builder(
              itemBuilder:
                  (context, index) => ListTile(
                    title: Text(rooms[index].alias),
                    onTap: rooms[index].link.push,
                  ),
              itemCount: rooms.length,
            ),
          ),
    );
  }
}
