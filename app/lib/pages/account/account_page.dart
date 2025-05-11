import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:flutter/material.dart';

class AccountPage with AppPage, AppPageView {
  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      onPressed: Navigator.of(context).pop,
      child: Text("Cancel"),
    );
    Widget continueButton = TextButton(
      onPressed: () async {
        await app.server.deleteAccount();
        await app.session.logout();
      },
      child: Text("Continue", style: TextStyle(color: Colors.red)),
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Warning"),
      content: Text("Deleting the account is irreversible!"),
      actions: [cancelButton, continueButton],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text(app.session.session?.alias ?? 'unknown'),
              onTap: () {},
            ),
            ListTile(title: Text('logout'), onTap: logout),
            Expanded(child: SizedBox.shrink()),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () => showAlertDialog(context),
                child: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
              ),
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
