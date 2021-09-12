import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';

// ignore: must_be_immutable
class CropImage extends StatefulWidget {
  String type;

  CropImage({Key key, @required this.type}) : super(key: key);

  @override
  _CropImageState createState() {
    return _CropImageState(type);
  }
}

class _CropImageState extends State<CropImage> {
  final cropKey = GlobalKey<CropState>();
  File _file;
  File _sample;
  File _lastCropped;

  _CropImageState(String type);

  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.type == 'camera') {
      _openCamera();
    } else {
      _openImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: _sample == null ? _buildOpeningImage() : _buildCroppingImage(),
        ),
      ),
    );
  }

  Widget _buildOpeningImage() {
    return Container(child: Center(child: _buildOpenImage()));
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample, key: cropKey),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                child: Text(
                  'قص وحفظ',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () => _cropImage(),
              ),
              _buildOpenImage(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOpenImage() {
    return TextButton(
      child: Text(
        'اختيار صورة',
        style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
      ),
      onPressed: () => _openImage(),
    );
  }

  Future<void> _openImage() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    final file = File(pickedFile.path);
    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size.longestSide.ceil(),
    );

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
    });
  }

  Future<void> _openCamera() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    final file = File(pickedFile.path);
    final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size.longestSide.ceil(),
    );

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
    });
  }

  Future<void> _cropImage() async {
    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.sampleImage(
      file: _file,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    _lastCropped?.delete();
    _lastCropped = file;

    debugPrint('$file');
    if (file != null) {
      Navigator.pop(context, file);
    }
  }
}
