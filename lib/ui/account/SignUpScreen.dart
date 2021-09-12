import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../../constants.dart' as Constants;
import '../../home.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../utils/helper.dart';

File _image;
UserHelper _userHelper = new UserHelper();

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  String name, password, confirmPassword;

  @override
  Widget build(BuildContext context) {
    _firebaseMessaging.getToken().then((token) {
      print(token);
    });
    if (Platform.isAndroid) {
      retrieveLostData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "انشاء حساب جديد",
          style: TextStyle(fontSize: Constants.FONT_SIZE_LARGE),
        ),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: Form(
            key: _key,
            autovalidate: _validate,
            child: formUI(),
          ),
        ),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await ImagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image = response.file;
      });
    }
  }

  Widget formUI() {
    return Column(
      children: <Widget>[
        ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0, right: 8.0, left: 8.0),
            )),
        SizedBox(
          width: 100,
          child: new Image.asset("assets/images/logo-chat.png"),
        ),
        ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
                padding:
                    const EdgeInsets.only(top: 50.0, right: 8.0, left: 8.0),
                child: TextFormField(
                    style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                    validator: validateName,
                    onSaved: (String val) {
                      name = val;
                    },
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        fillColor: Colors.white,
                        hintText: 'الاسم',
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: BorderSide(
                                color: Color(Constants.COLOR_PRIMARY),
                                width: 2.0)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ))))),
        ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
              child: TextFormField(
                  style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  controller: _passwordController,
                  validator: validatePassword,
                  onSaved: (String val) {
                    password = val;
                  },
                  cursorColor: Color(Constants.COLOR_PRIMARY),
                  decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      fillColor: Colors.white,
                      hintText: 'كلمة المرور',
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: BorderSide(
                              color: Color(Constants.COLOR_PRIMARY),
                              width: 2.0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ))),
            )),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
            child: TextFormField(
                style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _sendToServer();
                },
                obscureText: true,
                validator: (val) =>
                    validateConfirmPassword(_passwordController.text, val),
                onSaved: (String val) {
                  confirmPassword = val;
                },
                cursorColor: Color(Constants.COLOR_PRIMARY),
                decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    fillColor: Colors.white,
                    hintText: 'تأكيد كلمة المرور',
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: BorderSide(
                            color: Color(Constants.COLOR_PRIMARY), width: 2.0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ))),
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 48,
          child: RaisedButton(
            color: Color(Constants.COLOR_PRIMARY),
            child: Text(
              'إنشاء',
              style: TextStyle(
                  fontSize: Constants.FONT_SIZE_MEDIUM,
                  fontWeight: FontWeight.bold),
            ),
            textColor: Colors.white,
            onPressed: _sendToServer,
          ),
        ),
      ],
    );
  }

  _sendToServer() async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      showProgress(context, 'جار انشاء حساب يرجى الانتظار', false);
      var profilePicUrl = Constants.DEFAULT_URL;
      try {
        AuthResult result = await FirebaseAuth.instance.signInAnonymously();
        print(name);
        bool isSuccessful = await _userHelper.checkUserName(name);
        //bool isSuccessful = true;
        if (isSuccessful) {
          UserTimeServer user = UserTimeServer(
              name: name,
              createdAt: FieldValue.serverTimestamp(),
              lastOnlineTimestamp: FieldValue.serverTimestamp(),
              country: "+49",
              about: 'مرحباً أنا أستخدم تطبيق الدردشة',
              phone: "0",
              anonymouslyID: result.user.uid,
              associatedEmail: "@",
              active: true,
              typeUser: "user",
              gender: "غير محدد",
              age: "0",
              points: 500,
              password: password,
              privateLock: false,
              hideFriends: false,
              color: "0xFF222831",
              settings: Settings(allowPushNotifications: true),
              profilePictureURL: profilePicUrl);

          await _userHelper.createUser(user, _passwordController.text);
          hideProgress();
          AuthResult result1 = await FirebaseAuth.instance.signInAnonymously();
          User user1 = await _userHelper.login(name.trim(), password.trim());
          if (user1 != null) {
            MyAppState.currentUser = user1;
            MyAppState.currentUser.anonymouslyID = result1.user.uid;
            SharedPreferences shard = await SharedPreferences.getInstance();
            shard.setString("userID", user1.userID);
            await Firestore.instance
                .collection('users')
                .document(user1.userID)
                .updateData({
              'active': true,
              'lastOnlineTimestamp': FieldValue.serverTimestamp(),
              'anonymouslyID': result1.user.uid
            });
          }
          pushAndRemoveUntil(
              context, Home(user: MyAppState.currentUser), false);
        } else {
          hideProgress();
          Toast.show("الاسم محجوز ", context,
              duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        }

        //MyAppState.currentUser = user;
      } catch (error) {
        hideProgress();
        Toast.show("حدث خطأ يرجى المحاولة لاحقا", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
        print(error.toString());
      }
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  // _sendToServer() async {
  //   if (_key.currentState.validate()) {
  //     _key.currentState.save();
  //     showProgress(context, 'جار انشاء حساب يرجى الانتظار', false);
  //     var profilePicUrl = Constants.DEFAULT_URL;
  //     try {
  //       AuthResult result = await FirebaseAuth.instance
  //           .createUserWithEmailAndPassword(email: name+"@chatstars.com", password: password);
  //
  //       User user = User(
  //           email: name,
  //           name: name,
  //           createdAt : Timestamp.now() ,
  //           about: 'مرحباً أنا أستخدم تطبيق نجوم الدردشة',
  //           userID: result.user.uid,
  //           active: true,
  //           settings: Settings(allowPushNotifications: true),
  //           profilePictureURL: profilePicUrl);
  //       await FireStoreUtils.firestore
  //           .collection(Constants.USERS)
  //           .document(result.user.uid)
  //           .setData(user.toJson());
  //       hideProgress();
  //       MyAppState.currentUser = user;
  //       pushAndRemoveUntil(context, HomeScreen(user: user), false);
  //     } catch (error) {
  //       hideProgress();
  //       (error as PlatformException).code != 'ERROR_EMAIL_ALREADY_IN_USE'
  //           ? showAlertDialog(context, 'Failed', 'Couldn\'t sign up')
  //           : showAlertDialog(context, 'الإسم محجوز',
  //           'جرب اسم آخر وأعد المحاولة');
  //       print(error.toString());
  //     }
  //   } else {
  //     setState(() {
  //       _validate = true;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _passwordController.dispose();
    _image = null;
    super.dispose();
  }
}
