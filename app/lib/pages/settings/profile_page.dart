import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:app/theme.dart';
import 'package:flutter/material.dart';

class ProfilePage with AppPage, AppPageView {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: ListView(
        children: [
          SizedBox(height: 24),
          ProfilePictureTile(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ProfilePictureTile extends StatelessWidget {
  const ProfilePictureTile({super.key});

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
          onPressed: app.profile.takePicture,
          child: Text('Take Photo'),
        ),
      ],
    );
  }
}
