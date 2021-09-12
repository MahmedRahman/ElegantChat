import 'dart:async';

import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class SoundHelper {
  Future soundPlay(String path) async {
    Soundpool pool = Soundpool(streamType: StreamType.notification);
    int soundId = await rootBundle.load(path).then((ByteData soundData) {
      return pool.load(soundData);
    });
    await pool.play(soundId);
  }
}
