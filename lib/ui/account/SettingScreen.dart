import 'package:flutter/material.dart';
import 'package:share/share.dart';

import '../../constants.dart' as Constants;
import '../../model/User.dart';
import '../contactUs/ContactUsScreen.dart';
import '../settings/SettingsScreen.dart';
import '../utils/helper.dart';
import 'AccountDetailsScreen.dart';

class SettingScreen extends StatefulWidget {
  final User user;

  SettingScreen({Key key, @required this.user}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState(user);
}

class _SettingScreenState extends State<SettingScreen> {
  final User user;

  _SettingScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("الملف الشخصي"),
        backgroundColor: Color(Constants.COLOR_PRIMARY),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            onTap: () {
              push(context, AccountDetailsScreen(user: user));
            },
            title: Text(user.fullName()),
            subtitle: Text(user.about),
            leading: CircleAvatar(
              backgroundImage: user.profilePictureURL != null
                  ? NetworkImage(user.profilePictureURL)
                  : NetworkImage(Constants.DEFAULT_URL),
            ),
          ),
          ListTile(
            onTap: () {
              push(context, SettingsScreen(user: user));
            },
            title: Text('الاعدادات'),
            subtitle: Text("ادارة اعدادات التطبيق"),
            leading: Icon(
              Icons.settings,
              color: Colors.orangeAccent,
            ),
          ),
          ListTile(
            onTap: () {
              push(context, ContactUsScreen());
            },
            title: Text('المساعدة'),
            subtitle: Text("المساعدة والدعم"),
            leading: Icon(
              Icons.help_outline,
              color: Colors.orangeAccent,
            ),
          ),
          ListTile(
            onTap: () => Share.share(
                Constants.INVITE_TEXT + '\n' + Constants.INVITE_URL),
            title: Text('شارك التطبيق'),
            leading: Icon(
              Icons.people,
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }
}
