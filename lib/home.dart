import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'custom_camera.dart';

class Home extends StatelessWidget {
  final List<CameraDescription> cameras;

  const Home({
    Key key,
    @required this.cameras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Camera Demo'),
      ),
      body: Center(
        child: CustomCameraButton(cameras: cameras),
      ),
    );
  }
}

class CustomCameraButton extends StatelessWidget {
  final List<CameraDescription> cameras;

  const CustomCameraButton({
    Key key,
    @required this.cameras,
  }) : super(key: key);

  void customCameraResult(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCamera(
          cameras: cameras,
          cameraDevice: CameraDevice.front,
        ),
      ),
    ) as String;

    if (result != null) {
      Scaffold.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Photo saved to:  $result')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
        child: Text('Custom Camera'),
        onPressed: () async {
          customCameraResult(context);
        });
  }
}
