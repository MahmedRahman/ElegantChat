import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/CallsModel.dart';
import 'package:elegant/model/User.dart';
import 'package:elegant/ui/chat/stopwatch.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../ui/services/SoundHelper.dart';

const appID = 'd52dfd15531f4f57bbe4a0d06bed92bc';

class CallerScreen extends StatefulWidget {
  final String channelName;
  final String typeCall;
  final User user2;
  final String callID;

  const CallerScreen(
      {Key key, this.channelName, this.typeCall, this.user2, this.callID})
      : super(key: key);

  @override
  _CallerScreenState createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen> {

  bool timer = false;
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;
  Widget _toolbar;
  bool approval = false;
  IconData _icon;
  Stream<CallsModel> callsStream;
  static Firestore firestore = Firestore.instance;
  SoundHelper helper = new SoundHelper();
  ChatHelper _chatHelper = new ChatHelper();

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();


    super.dispose();

  }

  @override
  void initState() {
    super.initState();
    callsStream = _getStatusCalls().asBroadcastStream();
    callsStream.listen((callModel) {
    //   if (callModel.status == "end") {
    //     Navigator.of(context).pop();
    //   }
    //   if (callModel.status == "active") {
    //     setState(() {
    //       timer=true;
    //     });
    //   }
    //
    //
     }
    );
    setToolBar();
  }
  setToolBar(){
    setState(() {
      approval = true;
      if (widget.typeCall == "video") {
        _toolbar = _toolbarVideo();
      } else {
        _toolbar = _toolbarVoice();
      }
    });

    if (approval) {
      if (widget.typeCall == "video") {
        _toolbar = _toolbarVideo();
      } else {
        _toolbar = _toolbarVoice();
      }
      initialize();
    }
  }
  setupStream() {

  }

  Future<void> initialize() async {

    approval = true;
    if (widget.typeCall == "video") {
      _toolbar = _toolbarVideo();
    } else {
      _toolbar = _toolbarVoice();
    }
    if (appID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.joinChannel(null, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appID);
    if (widget.typeCall == "video") {
      await _engine.enableVideo();
    }
    if (widget.typeCall == "voice") {
      await _engine.enableAudio();
    }
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError: $code';
          _infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
          _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
        });
      },
      userOffline: (uid, reason) {
        setState(() {
          final info = 'userOffline: $uid , reason: $reason';
          _infoStrings.add(info);
          _users.remove(uid);
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideoFrame: $uid';
          _infoStrings.add(info);
        });
      },
    ));
  }

  /// Toolbar layout
  Widget _toolbarVideo() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.black54,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.orangeAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: Colors.black54,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  /// Toolbar layout
  // Widget _toolbarVoice() {
  //   return
  //     Column(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: <Widget>[
  //     Padding( padding: EdgeInsets.only(top: 5)),
  //     Container(
  //     alignment: Alignment.bottomCenter,
  //     color: Colors.white,
  //     //padding: const EdgeInsets.symmetric(vertical: 48),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: <Widget>[
  //
  //         RawMaterialButton(
  //           onPressed: () => _onCallEnd(context),
  //           child: Icon(
  //             Icons.call_end,
  //             color: Colors.white,
  //             size: 35.0,
  //           ),
  //           shape: CircleBorder(),
  //           elevation: 2.0,
  //           fillColor: Colors.red,
  //           padding: const EdgeInsets.all(15.0),
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }

  Widget _toolbarVoice() {

    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
       child: Container(
        color: Colors.white,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 5)),
              Container(
                color: Colors.white,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    displayCircleImage(widget.user2.profilePictureURL, 40, false),
                    Text(
                      widget.user2.name,
                      style: TextStyle(color: Colors.black54, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 5)),
            Visibility(
                visible: !timer,
                child:
                SizedBox(
                width: 60,
                child:  Text( 'جار الاتصال ...',textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 18,),
                ),
              ),
              ),
              Visibility(
                  visible: timer,
                  child:
              SizedBox(
                width: 60,
                child:  FlutterStopWatch( t: timer,)  ,

                ),
              ),


              SizedBox(
                width: 40,
                child: new Image.asset("assets/images/icon.png"),
              ),
              Container(
                color: Colors.white,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[

                    RawMaterialButton(

                      onPressed: () =>

                           _onCallEnd(context),


                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 35.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor: Colors.red,
                      padding: const EdgeInsets.all(15.0),
                    ),
                  ],
                ),
              )
            ])),),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          children: <Widget>[
            _viewRows(),
            _toolbar,

          ],
        ),
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    list.add(RtcLocalView.SurfaceView());
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  void _onCallEnd(BuildContext context) {
    _chatHelper.updateCallStatus(widget.callID, 'end');
    _engine.leaveChannel();
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  _approval() {
    if (widget.typeCall == "video") {
      _toolbar = _toolbarVideo();
    } else {
      _toolbar = _toolbarVoice();
    }
    setState(() {
      approval = true;
      initialize();
    });
    initialize();
  }

  Stream<CallsModel> _getStatusCalls() async* {
    StreamController<CallsModel> callsModelStreamController =
        StreamController();
    CallsModel callModel = CallsModel();
    List<CallsModel> listOfCalls = [];
    firestore
        .collection("calls")
        .where('channelName', isEqualTo: widget.channelName)
        .snapshots()
        .listen((onData) {
      onData.documents.forEach((document) async {
        listOfCalls.add(CallsModel.fromJson(document.data));
        if (document.data.isNotEmpty) {
          if (document.data["status"] == "end" ||
              document.data["status"] == "finish") {
            listOfCalls.clear();
            Navigator.pop(context);
            Navigator.pop(context);
          }
          if (document.data["status"] == "active") {
            this.setState(() {
              timer=true;
              setToolBar();
            });

          }

        }
      });

      callsModelStreamController.sink.add(callModel);
    });

    yield* callsModelStreamController.stream;
  }


}
