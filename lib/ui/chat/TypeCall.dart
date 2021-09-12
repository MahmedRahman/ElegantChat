import 'dart:async';
import 'dart:math';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/constants.dart';
import 'package:elegant/model/CallsModel.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';

import '../../main.dart';
import 'CallerScreen.dart';

class IndexPage extends StatefulWidget {
  final User user2;

  IndexPage({Key key, @required this.user2}) : super(key: key);

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  var randomGenerator = Random();
  static Firestore firestore = Firestore.instance;

  String _channelName = randomAlphaNumeric(30);
  String _typeCall = "voice";
  bool _validateError = false;
  bool isSuccessful;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('اتصال'),
        elevation: 0,
        backgroundColor: Color(COLOR_PRIMARY),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Center(
                    child: displayCircleImage(
                        widget.user2.profilePictureURL, 130, false)),
                Padding(padding: EdgeInsets.only(top: 20)),
                Text(
                  'اجراء مكالمة آمنة',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 20)),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 30)),
                Container(
                  width: MediaQuery.of(context).size.width * 0.50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.call),
                          iconSize: 35,
                          onPressed: voice),
                      SizedBox(
                        width: 20,
                      ),
                      IconButton(
                          icon: Icon(Icons.videocam_outlined),
                          iconSize: 50,
                          onPressed: video),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> video() async {
    setState(() {
      _channelName.isEmpty ? _validateError = true : _validateError = false;
      _typeCall = "video";
    });

    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    //_sendCall(widget.recipientID,_channelName, _typeCall);
    createCall(_channelName, _typeCall);
  }

  Future<void> voice() async {
    setState(() {
      _channelName.isEmpty ? _validateError = true : _validateError = false;
      _typeCall = "voice";
    });

    await _handleCameraAndMic(Permission.camera);
    await _handleCameraAndMic(Permission.microphone);
    createCall(_channelName, _typeCall);
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  createCall(String _channelName, String typeCall) async {
    DocumentReference channelDoc = firestore.collection(CALLS).document();
    CallsModel callsModel = CallsModel();
    callsModel.id = channelDoc.documentID;
    callsModel.channelName = _channelName;
    callsModel.status = "wait";
    callsModel.typeCall = _typeCall;
    callsModel.nameUser1 = MyAppState.currentUser.name;
    callsModel.nameUser2 = widget.user2.name;
    callsModel.user1 = MyAppState.currentUser.userID;
    callsModel.user2 = widget.user2.userID;
    callsModel.createdAt = Timestamp.now();
    await channelDoc.setData(callsModel.toJson());
    push(
      context,
      CallerScreen(
          channelName: _channelName,
          typeCall: _typeCall,
          user2: widget.user2,
          callID: channelDoc.documentID),
    );
  }
//
// Future<void> _sendCall(String recipientID,String _channelName,String typeCall) async {
//   await http.post(Constants.URL_HOSTING_API+Constants.URL_CALL, body: {
//     "recipientID":recipientID,
//     "channelName":_channelName,
//     "type":_typeCall,
//     "senderName" : widget.senderName,
//
//
//   });
//
//   print(widget.senderName);
//
// }
}
