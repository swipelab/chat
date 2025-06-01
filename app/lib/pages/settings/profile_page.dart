import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/theme.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class ProfilePage with AppPage, AppPageView, Emitter {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: ListView(
        children: [
          SizedBox(height: 24),
          ProfilePictureTile(onTap: takeProfilePicture),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  void takeProfilePicture() {
    app.profile.takePicture().whenComplete(notifyListeners);
  }
}

class ProfilePictureTile extends StatelessWidget {
  const ProfilePictureTile({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 72,
          backgroundColor: colors.fill.grey,
          foregroundImage: app.profile.picture,
        ),
        TextButton(
          onPressed: onTap,
          child: Text('Take Photo'),
        ),
      ],
    );
  }
}
