import 'package:app/app.dart';
import 'package:app/services/server.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ProfileBloc {
  ProfileBloc({
    required this.server,
  });

  final ChatApi server;

  NetworkImage? get picture => server.avatar(
    app.session.session?.userId.toString(),
  );

  Future<void> takePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image == null) return;
    await image.readAsBytes().then(app.server.postProfilePicture);
    await picture?.evict();
  }
}
