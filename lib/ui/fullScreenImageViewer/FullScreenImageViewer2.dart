

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer2 extends StatelessWidget {
  final   image;

  const FullScreenImageViewer2({Key key, @required this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: Colors.black,

       child: Image.file(image)

        ));
  }
}
