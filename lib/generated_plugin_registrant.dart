//
// Generated file. Do not edit.
//

// ignore_for_file: lines_longer_than_80_chars

import 'package:agora_rtc_engine/agora_rtc_engine_web.dart';
import 'package:audioplayers/audioplayers_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:soundpool_web/soundpool_web.dart';
import 'package:video_player_web/video_player_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(Registrar registrar) {
  AgoraRtcEngineWeb.registerWith(registrar);
  AudioplayersPlugin.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  SoundpoolPlugin.registerWith(registrar);
  VideoPlayerPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
