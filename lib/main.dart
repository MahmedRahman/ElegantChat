import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import './model/User.dart';
import './ui/auth/AuthScreen.dart';
import './ui/services/FirebaseHelper.dart';
import './ui/utils/helper.dart';
import 'constants.dart' as Constants;
import 'home.dart';

FireStoreUtils _fireStoreUtils = new FireStoreUtils();
FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
SharedPreferences shard;
List<CameraDescription> cameras;
UserHelper userHelper = new UserHelper();
String tokenDevice;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User currentUser;

  //static TimeUser timeUser;
  FireStoreUtils _fireStoreUtils = new FireStoreUtils();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Color(Constants.COLOR_PRIMARY_DARK)));
    return MaterialApp(
      localizationsDelegates: [
        // ... app-specific localization delegate[s] here
        // TODO: uncomment the line below after codegen
        // AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        // English, no country code
        const Locale('ar', ''),
        // Arabic, no country code
        const Locale.fromSubtags(languageCode: 'zh'),
        // Chinese *See Advanced Locales below*
        // ... other locales the app supports
      ],
      title: 'Elegant',
      theme: ThemeData(
          fontFamily: 'alqabas',
          accentColor: Color(Constants.COLOR_PRIMARY),
          brightness: Brightness.light),
      darkTheme: ThemeData(
          accentColor: Color(Constants.COLOR_PRIMARY),
          brightness: Brightness.dark),
      debugShowCheckedModeBanner: false,
      color: Color(Constants.COLOR_PRIMARY),
      home: OnBoarding(),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    userHelper.notification(context, '');
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (currentUser != null) {
      MyAppState.currentUser.active = false;
      _fireStoreUtils.updateUser(false, MyAppState.currentUser.userID);
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    shard = await SharedPreferences.getInstance();
    String userID = (shard.getString("userID")) ?? '';
    //print(timeUser.timeLogin.toString());

    if (userID != '' && currentUser != null) {
      if (state == AppLifecycleState.paused) {
        currentUser.active = false;
        _fireStoreUtils.updateUser(false, currentUser.userID);
      } else if (state == AppLifecycleState.resumed) {
        //user online
        currentUser.active = true;
        _fireStoreUtils.updateUser(true, currentUser.userID);

        // FireStoreUtils.currentUserDocRef.updateData(currentUser.toJson());
      }
      // else
      if (state == AppLifecycleState.detached) {
        //user online
        currentUser.active = false;
        _fireStoreUtils.updateUser(false, currentUser.userID);

        // FireStoreUtils.currentUserDocRef.updateData(currentUser.toJson());
      }
    } else {
      pushReplacement(context, new AuthScreen());
    }
  }
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  Future validate() async {
    SharedPreferences shard = await SharedPreferences.getInstance();
    String userID = (shard.getString("userID")) ?? '';
    if (userID != '') {
      User user = await FireStoreUtils().getCurrentUser(userID);
      if (user != null) {
        MyAppState.currentUser = user;
        // _fireStoreUtils.updateChannelParticipation(user.userID);
        MyAppState.currentUser.active = true;
        MyAppState.currentUser.lastOnlineTimestamp = Timestamp.now();
        _fireStoreUtils.updateUser(true, MyAppState.currentUser.userID);
        _firebaseMessaging.getToken().then((String token) {
          assert(token != null);
          if (token != null) {
            sentToken(token);
          }
          setState(() {});
        });
        pushReplacement(context, new Home(cameras: cameras, user: user));
      } else {
        pushReplacement(context, new AuthScreen());
      }
    } else {
      pushReplacement(context, new AuthScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    userHelper.notification(context, '');
    validate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 100,
              child: new Image.asset("assets/images/icon.png"),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, right: 8.0, left: 8.0),
            ),
            CircularProgressIndicator(
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sentToken(String token) async {
    // shard = await SharedPreferences.getInstance();
    // String userID = (shard.getString("userID"))??'';
    await http.post(Constants.URL_HOSTING_API + Constants.URL_SET_TOKEN, body: {
      "userID": MyAppState.currentUser.userID,
      "name": MyAppState.currentUser.name,
      "token": token,
    });
    print(token);
  }
}
