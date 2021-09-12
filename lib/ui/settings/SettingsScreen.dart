import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';

class SettingsScreen extends StatefulWidget {
  final User user;

  const SettingsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState(user);
}

class _SettingsScreenState extends State<SettingsScreen> {
  User user;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  _SettingsScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        title: Text('Settings'),
      ),
      body: ListView(children: [
        ListTile(
          title: Text("ارسال الاشعارات"),
          subtitle: Text("تفعيل / تعطيل اإشعارات"),
          trailing: Switch(
              value: user.settings.allowPushNotifications,
              onChanged: (bool newValue) async {
                user.settings.allowPushNotifications = newValue;

                showProgress(context, 'جار حفظ التغييرات', true);
                if (newValue) {
                  _firebaseMessaging.getToken().then((token) async {
                    print(token);
                    user.pushToken = token;
                    User updateUser =
                        await FireStoreUtils().updateCurrentUser(user, context);
                    hideProgress();
                    if (updateUser != null) {
                      this.user = updateUser;
                      MyAppState.currentUser = user;
                    }
                    setState(() {});
                  }).catchError((e) async {
                    user.pushToken = null;
                    User updateUser =
                        await FireStoreUtils().updateCurrentUser(user, context);
                    hideProgress();
                    if (updateUser != null) {
                      this.user = updateUser;
                      MyAppState.currentUser = user;
                    }
                    setState(() {});
                  });
                } else {
                  user.pushToken = null;
                  User updateUser =
                      await FireStoreUtils().updateCurrentUser(user, context);
                  hideProgress();
                  if (updateUser != null) {
                    this.user = updateUser;
                    MyAppState.currentUser = user;
                  }
                  setState(() {});
                }
              }),
        )
      ]),
    );
  }
}
