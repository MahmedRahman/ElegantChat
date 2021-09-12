import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/model/CallsModel.dart';
import 'package:elegant/ui/chat/stopwatch.dart';
import 'package:elegant/ui/services/ChatHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ui/services/SoundHelper.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const appID = 'd52dfd15531f4f57bbe4a0d06bed92bc';
String formatTime(int milliseconds) {
  var secs = milliseconds ~/ 1000;
  var hours = (secs ~/ 3600).toString().padLeft(2, '0');
  var minutes = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
  var seconds = (secs % 60).toString().padLeft(2, '0');

  return "$hours:$minutes:$seconds";
}
 class CallReceiverScreen extends StatefulWidget {
  final CallsModel callModel;
  const CallReceiverScreen({Key key, this.callModel}) : super(key: key);

  @override
  _CallReceiverScreenState createState() => _CallReceiverScreenState();
}

class _CallReceiverScreenState extends State<CallReceiverScreen>  {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  RtcEngine _engine;
  Widget _toolbar;
  bool approval = false;
  Stream<CallsModel> callsStream;
  static Firestore firestore = Firestore.instance;
  IconData _icon;
  ChatHelper _chatHelper = new ChatHelper();
  SoundHelper helper = new SoundHelper();
  Stopwatch _stopwatch;
  Timer _timer;


  @override
  void dispose() {
    _timer.cancel();
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
    setupStream();
    _stopwatch = Stopwatch();
    _timer = new Timer.periodic(new Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
    setState(() {
        approval = false;

        if (widget.callModel.typeCall == "video") {
          _icon = Icons.videocam_outlined;
        } else {
          _icon = Icons.call;
        }
        helper.soundPlay("assets/sounds/call.mp3");

        _toolbar = _toolbarRinging();
      });


    if (approval) {
      if (widget.callModel.typeCall == "video") {
        _toolbar = _toolbarVideo();
      } else {
        _toolbar = _toolbarVoice();
      }
      initialize();

    }
  }
  setupStream() {
    callsStream = _getStatusCalls()
        .asBroadcastStream();
    callsStream.listen((callModel) {
      if(callModel.status=="end"){

        Navigator.of(context).pop();

      }
    })


    ;

  }
   Future<void> initialize() async {
     _stopwatch.start();
     approval=true;
    if (widget.callModel.typeCall == "video") {
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
    if (widget.callModel.channelName.isNotEmpty){

    await _engine.joinChannel(null, widget.callModel.channelName, null, 0);}
    _chatHelper.updateCallStatus(widget.callModel.id,'active');
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appID);
    if (widget.callModel.typeCall == "video") {
      await _engine.enableVideo();
    }
    if (widget.callModel.typeCall == "voice") {
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
            onPressed: () => _onCallFinish(context),
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
  Widget _toolbarVoice() {

    return
      Container(
        color: Colors.white,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
           Container(

            child:
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
               // displayCircleImage(widget.callModel..profilePictureURL, 40, false),
                Padding(padding: EdgeInsets.only(top: 20)),
                Text(
                  widget.callModel.nameUser1,
                  style: TextStyle(color: Colors.black54, fontSize: 18),
                ),
              ],
            ),


          ),
          Container(

            child: FlutterStopWatch( t: true,),



          ),
          RawMaterialButton(
            onPressed: () => _onCallFinish(context),
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
    );
  }
  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
  Widget _toolbarRinging() {

    return
      Container(
        color: Colors.white,
     child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
         Padding( padding: EdgeInsets.only(top: 5)),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(widget.callModel.nameUser1,style: TextStyle(color:Colors.black54,fontSize: 18),),

              ],
            ),
          ) ,
          Padding( padding: EdgeInsets.only(top: 5)),
          SizedBox(
            width: 50,
            child: new Image.asset("assets/images/call.gif"),
          ),
    Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[

          RawMaterialButton(
            onPressed: () => _onCallReject(context),
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
          RawMaterialButton(
            onPressed: () async {
              await _handleCameraAndMic(Permission.camera);
              await _handleCameraAndMic(Permission.microphone);
              initialize();
            },
            child: Icon(_icon,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.green,
            padding: const EdgeInsets.all(15.0),
          )
        ],
      ),
    )
   ] ));
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

    _chatHelper.updateCallStatus(widget.callModel.id,'end');
    Navigator.pop(context);
  }
  void _onCallFinish(BuildContext context) {
    _engine.leaveChannel();
    _chatHelper.updateCallStatus(widget.callModel.id,'finish');
    Navigator.pop(context);
  }
  void _onCallReject(BuildContext context) {
    _chatHelper.updateCallStatus(widget.callModel.id,'end');

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



  Stream<CallsModel> _getStatusCalls() async* {
    StreamController<CallsModel> callsModelStreamController =
    StreamController();
    CallsModel callModel = CallsModel();
    List<CallsModel> listOfCalls = [];
    firestore
        .collection("calls")
        .where('channelName', isEqualTo: widget.callModel.channelName)
        .snapshots()
        .listen((onData) {
      onData.documents.forEach((document) async {
        listOfCalls.add(CallsModel.fromJson(document.data));
        if (document.data.isNotEmpty) {
          if (document.data["status"] == "end") {
            listOfCalls.clear();
            _onCallEnd(context);

          }
          
          if (document.data["status"] == "active") {


          }
        }
      });
      callsModelStreamController.sink.add(callModel);
    });

    yield* callsModelStreamController.stream;
  }
}