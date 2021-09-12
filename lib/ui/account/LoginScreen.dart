import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:auto_direction/auto_direction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../home.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../utils/helper.dart';
import 'AccountRecovery.dart';

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  String name, password;
  int randomNumber = 0;
  UserHelper _userHelper = new UserHelper();
  String text = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text(
          "تسجيل الدخول",
          style: TextStyle(fontSize: Constants.FONT_SIZE_LARGE),
        ),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _key,
          autovalidate: _validate,
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Image.asset('assets/images/logo-chat.png'),
                SizedBox(
                  height: 10,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: double.infinity),
                  child: AutoDirection(
                      text: text,
                      child: TextFormField(
                          style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                          controller: _nameController,
                          onChanged: (str) {
                            setState(() {
                              text = _nameController.text.trim();
                            });
                          },
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Color(Constants.COLOR_PRIMARY),
                          decoration: InputDecoration(
                              hintTextDirection: TextDirection.rtl,
                              contentPadding:
                                  EdgeInsets.only(left: 16, right: 16),
                              fillColor: Colors.white,
                              hintText: 'الاسم',
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  borderSide: BorderSide(
                                      color: Color(Constants.COLOR_PRIMARY),
                                      width: 2.0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              )))),
                ),
                SizedBox(height: 12.0),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: double.infinity),
                  child: TextFormField(
                      style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                      textAlignVertical: TextAlignVertical.center,
                      textDirection: TextDirection.ltr,
                      controller: _passwordController,
                      obscureText: true,
                      validator: validatePassword,
                      onSaved: (String val) {
                        password = val;
                      },
                      onFieldSubmitted: (password) async {
                        await onClick(_nameController.text, password);
                      },
                      textInputAction: TextInputAction.next,
                      cursorColor: Color(Constants.COLOR_PRIMARY),
                      decoration: InputDecoration(
                          hintTextDirection: TextDirection.rtl,
                          contentPadding: EdgeInsets.only(left: 16, right: 16),
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
                ),
                SizedBox(height: 12.0),
                Container(
                  height: 42.0,
                  width: 250,
                  child: RaisedButton(
                    color: Color(Constants.COLOR_PRIMARY),
                    textColor: Colors.black,
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'تسجيل',
                      style: TextStyle(
                        fontSize: Constants.FONT_SIZE_MEDIUM,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      dynamic result = await onClick(
                          _nameController.text, _passwordController.text);
                      if (result != null) {
                        User user = result;
                        MyAppState.currentUser = user;

                        pushAndRemoveUntil(context, Home(user: user), false);
                      }
                    },
                  ),
                ),
                SizedBox(height: 10.0),
                InkWell(
                  onTap: () {
                    TextEditingController _emailController =
                        TextEditingController();

                    showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: SingleChildScrollView(
                              child: Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 16,
                                child: Container(
                                  height: 250,
                                  width: 350,
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0,
                                          left: 16,
                                          right: 16,
                                          bottom: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            "الإيميل المرتبط بالحساب :",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 16),
                                          Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10.0,
                                                  left: 16,
                                                  right: 16,
                                                  bottom: 16)),
                                          TextField(
                                            textInputAction: TextInputAction.done,
                                            keyboardType: TextInputType.text,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            maxLines: 1,
                                            controller: _emailController,
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.only(
                                                  left: 8.0,
                                                  top: 2.0,
                                                  bottom: 2.0),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8.0),
                                                  borderSide: BorderSide(
                                                      color: Color(COLOR_ACCENT),
                                                      width: 2.0)),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8.0)),
                                              labelText: 'البريد الإلكتروني :',
                                              labelStyle: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10.0,
                                              left: 16,
                                              right: 16,
                                              bottom: 16,
                                            ),
                                          ),
                                          SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: <Widget>[
                                              FlatButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text('إلغاء')),
                                              FlatButton(
                                                onPressed: () async {
                                                  Random random = new Random();

                                                  setState(() {
                                                    randomNumber =
                                                        random.nextInt(9999);
                                                  });

                                                  _sendCode(
                                                      randomNumber,
                                                      _emailController.text
                                                          .trim());
                                                },
                                                child: Text(
                                                  'تحقق',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(COLOR_ACCENT),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      )),
                                ),
                              ),
                            ),
                          );
                        });
                  },
                  child: new Text("استعادة الحساب"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode(int code, String email) async {
    final response = await http
        .post(Constants.URL_HOSTING_API + Constants.URL_SEND_CODE_EMAIL, body: {
      "code": code.toString(),
      "email": email,
    });
    print(email);
    print(code);
    print(response.body);
    var dataUser = json.decode(response.body);
    if (dataUser.length == 0) {
      Toast.show("فشل ارسال رمز التحقق", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
    } else {
      if (dataUser[0]['result'] == 'success') {
        Navigator.pop(context);
        TextEditingController _codeController = TextEditingController();
        showDialog(
            context: context,
            builder: (context) {
              return Center(
                  child: SingleChildScrollView(
                      child: Dialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 16,
                          child: Container(
                            height: 250,
                            width: 350,
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 20.0, left: 16, right: 16, bottom: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "أدخل رمز التحقق",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 16),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            top: 10.0,
                                            left: 16,
                                            right: 16,
                                            bottom: 16)),
                                    TextField(
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.text,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      maxLines: 1,
                                      controller: _codeController,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 8.0, top: 2.0, bottom: 2.0),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_ACCENT),
                                                width: 2.0)),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0)),
                                        labelText: 'الرمز :',
                                        labelStyle: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            top: 10.0,
                                            left: 16,
                                            right: 16,
                                            bottom: 16)),
                                    SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        FlatButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('إلغاء')),
                                        FlatButton(
                                            onPressed: () async {
                                              if (_codeController.text !=
                                                  null) {
                                                if (_codeController.text
                                                        .trim() ==
                                                    randomNumber.toString()) {
                                                  pushAndRemoveUntil(
                                                      context,
                                                      AccountRecovery(
                                                          email: email),
                                                      false);
                                                } else {
                                                  Toast.show("رمز التحقق خاطئ",
                                                      context,
                                                      duration:
                                                          Toast.LENGTH_LONG,
                                                      gravity: Toast.CENTER);
                                                }
                                              }
                                            },
                                            child: Text('تأكيد',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Color(COLOR_ACCENT)))),
                                      ],
                                    )
                                  ],
                                )),
                          ))));
            });
      } else if (dataUser[0]['result'] == 'error') {
        Toast.show("فشل ارسال رمز التحقق", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      }
    }
  }

  onClick(String email, String password) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();
      showProgress(context, 'جار تسجيل الدخول', false);

      AuthResult result = await FirebaseAuth.instance.signInAnonymously();
      User user = await _userHelper.login(email.trim(), password.trim());
      if (user != null) {
        MyAppState.currentUser = user;
        MyAppState.currentUser.anonymouslyID = result.user.uid;
        SharedPreferences shard = await SharedPreferences.getInstance();
        shard.setString("userID", user.userID);
        await Firestore.instance
            .collection(USERS)
            .document(user.userID)
            .updateData({
          'active': true,
          'lastOnlineTimestamp': FieldValue.serverTimestamp(),
          'anonymouslyID': result.user.uid
        });
        pushAndRemoveUntil(context, Home(user: user), false);
      } else {
        hideProgress();
        Toast.show("يرجى التحقق من الاسم وكلمة المرور", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.CENTER);
      }
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
