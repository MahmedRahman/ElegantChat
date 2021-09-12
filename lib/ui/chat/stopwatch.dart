import 'dart:async';

import 'package:flutter/material.dart';

class FlutterStopWatch extends StatefulWidget {
  bool t;
  @override
  FlutterStopWatch({

    @required this.t,
    Key key,
  }) : super(key: key);

  @override
  _FlutterStopWatchState createState() => _FlutterStopWatchState();
}

class _FlutterStopWatchState extends State<FlutterStopWatch> {
  bool flag = true;
  Stream<int> timerStream;
  StreamSubscription<int> timerSubscription;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';

  Stream<int> stopWatchStream() {
    StreamController<int> streamController;
    Timer timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void stopTimer() {
      if (timer != null) {
        timer.cancel();
        timer = null;
        counter = 0;
        streamController.close();
      }
    }

    void tick(_) {
      counter++;
      streamController.add(counter);
      if (!flag) {
        stopTimer();
      }
    }

    void startTimer() {
      timer = Timer.periodic(timerInterval, tick);
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onResume: startTimer,
      onPause: stopTimer,
    );

    return streamController.stream;
  }

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.t){
      timerStream = stopWatchStream();
      timerSubscription = timerStream.listen((int newTick) {
        if (mounted) {
          setState(() {
            hoursStr = ((newTick / (60 * 60)) % 60)
                .floor()
                .toString()
                .padLeft(2, '0');
            minutesStr = ((newTick / 60) % 60)
                .floor()
                .toString()
                .padLeft(2, '0');
            secondsStr =
                (newTick % 60).floor().toString().padLeft(2, '0');
          });}
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,

       child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$hoursStr:$minutesStr:$secondsStr",
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),

          ],
        ),
      ),
    );
  }


}