import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/widgets/group_section.dart';
import 'package:flutter/material.dart';

class AccountPage with AppPage, AppPageView {
  void handleDeleteAccount(BuildContext context) {
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
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: ListView(
        children: [
          SizedBox(height: 36),
          GroupSection(
            children: [
              GroupTile(
                onTap: () => handleDeleteAccount(context),
                child: Text('Delete Account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
