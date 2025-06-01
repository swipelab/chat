import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/pages/settings/account_page.dart';
import 'package:app/pages/settings/profile_page.dart';
import 'package:app/widgets/group_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsPage with AppPage, AppPageView {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupSection(
              children: [
                GroupTile(
                  onTap: ProfilePage().push,
                  leading: CircleAvatar(
                    foregroundImage: app.profile.picture,
                    child: Icon(CupertinoIcons.settings),
                  ),
                  child: Text(app.session.session?.alias ?? 'unknown'),
                ),
              ],
            ),
            SizedBox(height: 36),
            GroupSection(
              children: [
                GroupTile(
                  onTap: AccountPage().push,
                  child: Text('Account'),
                ),
                GroupTile(
                  onTap: app.session.logout,
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void logout() {
    pop();
    app.session.logout();
  }
}
