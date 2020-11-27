import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum CameraDevice {
  front,
  rear,
}

class CustomCamera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraDevice cameraDevice;
  final Widget overlay;

  const CustomCamera({
    Key key,
    @required this.cameras,
    @required this.cameraDevice,
    this.overlay,
  }) : super(key: key);

  @override
  _CustomCameraState createState() => _CustomCameraState();
}

class _CustomCameraState extends State<CustomCamera> {
  CameraController _cameraController;
  String _imagePath;

  String get _timestamp => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String> _takePicture() async {
    if (_cameraController.value.isInitialized &&
        !_cameraController.value.isTakingPicture) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/Pictures';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/$_timestamp.jpg';

      try {
        await _cameraController.takePicture(filePath);
      } on CameraException {
        // handle camera exception here
      }

      return filePath;
    }

    return null;
  }

  void _onTakePictureButtonPressed() async {
    final imagePath = await _takePicture();

    if (imagePath != null) {
      setState(() {
        this._imagePath = imagePath;
      });
    }
  }

  void _onRetryButtonPressed() {
    Directory(_imagePath).deleteSync(recursive: true);
    setState(() {
      _imagePath = null;
    });
  }

  void _onOkButtonPressed() async {
    try {
      // TODO: copy the image file to download directory
      final image = File(_imagePath);
      final newPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS,
      );
      final fileName = p.basename(image.path);

      image.copySync('$newPath/$fileName');

      Directory(_imagePath).deleteSync(recursive: true);

      Navigator.pop(context, "$newPath/$fileName");
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      widget.cameraDevice == CameraDevice.front
          ? widget.cameras[1]
          : widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    }).catchError((err) {
      // handle error here
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    var _device = MediaQuery.of(context);

    if (!_cameraController.value.isInitialized) {
      return Container();
    } else {
      if (_imagePath != null) {
        return CameraResult(
          imagePath: _imagePath,
          onOkButtonPressed: _onOkButtonPressed,
          onRetryButtonPressed: _onRetryButtonPressed,
        );
      } else {
        return CameraScreen(
          cameraController: _cameraController,
          onTakePictureButtonPressed: _onTakePictureButtonPressed,
          overlay: widget.overlay,
        );
      }
    }
  }
}

class CameraButton extends StatelessWidget {
  final void Function() onTap;

  const CameraButton({
    Key key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      margin: const EdgeInsets.all(10),
      child: Material(
        color: Colors.grey,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        elevation: 5,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: const Icon(
              Icons.camera_alt,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  final CameraController cameraController;
  final void Function() onTakePictureButtonPressed;
  final Widget overlay;

  const CameraScreen({
    Key key,
    @required this.cameraController,
    @required this.onTakePictureButtonPressed,
    this.overlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController),
          ),
          CameraButton(
            onTap: onTakePictureButtonPressed,
          ),
          if (overlay != null) overlay,
        ],
      ),
    );
  }
}

class CameraResult extends StatelessWidget {
  final String imagePath;
  final void Function() onOkButtonPressed;
  final void Function() onRetryButtonPressed;

  const CameraResult({
    Key key,
    @required this.imagePath,
    @required this.onOkButtonPressed,
    @required this.onRetryButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                child: FlatButton(
                  child: Text('OK'),
                  onPressed: onOkButtonPressed,
                ),
              ),
              Expanded(
                child: FlatButton(
                  child: Text('Retry'),
                  onPressed: onRetryButtonPressed,
                ),
              ),
            ],
          ),
        ),
        body: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
