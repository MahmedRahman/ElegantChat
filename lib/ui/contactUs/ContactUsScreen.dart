import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';

class ContactUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        title: Text('المساعدة'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.mail_outline, color: Colors.black54),
            title: Text("تواصل معنا"),
            subtitle: Text("info@chatelegant.com"),
            onTap: () async {
              if (await canLaunch(PRIVACY_URL)) {
                launch(PRIVACY_URL);
              }
            },
          ),
        ],
      ),
    );
  }
}
