import 'package:app/app.dart';
import 'package:app/services/server.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ProfileBloc {
  ProfileBloc({
    required this.server,
  });

  final Server server;

  NetworkImage get picture => server.profilePicture;

  Future<void> takePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (image == null) return;
    final body = await image.readAsBytes();
    await app.server.postProfilePicture(body);
  }
}
