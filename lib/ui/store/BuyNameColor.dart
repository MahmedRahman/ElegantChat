import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/constants.dart' as Constants;
import 'package:elegant/ui/services/FirebaseHelper.dart';
import 'package:elegant/ui/services/UserHelper.dart';
import 'package:elegant/ui/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

import '../../constants.dart';
import '../../main.dart';

Firestore firestore = Firestore.instance;
FireStoreUtils _fireStoreUtils = FireStoreUtils();
UserHelper _userHelper = new UserHelper();
String idStudent = '';
String idSchool = '';

class BuyColor extends StatefulWidget {
  @override
  _BuyColorState createState() => _BuyColorState();
}

class _BuyColorState extends State<BuyColor> {
  @override
  void initState() {
    super.initState();
    _getMaterials().then((value) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: new AppBar(
          title: new Text("اختر اللون المناسب"),
          backgroundColor: Color(Constants.COLOR_PRIMARY),
        ),
        body: new Column(children: <Widget>[
          Expanded(
              child: Container(
            height: 100,
            child: alarm(_getMaterials),
          )),
        ]));
  }
}

Widget alarm(_getMaterials()) {
  return Container(
    child: FutureBuilder(
      future: _getMaterials(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print(snapshot.data);
        if (snapshot.data == null) {
          return Container(
              child: Center(
            child: Text('يرجى الانتظار'),
          ));
        } else {
          return GridView.builder(
            shrinkWrap: true,
            //physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.6,
            ),
            itemCount: snapshot.data.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                color: Colors.white,
                elevation: 7,
                child: InkWell(
                  onTap: () {
                    changeColor(snapshot.data[index].color, context);
                  },
                  child: new Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                      ),
                      SizedBox(
                        width: 100,
                        height: 140,
                        child: new Image(
                            image: NetworkImage(snapshot.data[index].url)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 0),
                      ),
                      SizedBox(
                        child: new Text(snapshot.data[index].color),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    ),
  );
}

void changeColor(String color, BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return Center(
            child: SingleChildScrollView(
                child: Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.only(
                                top: 20.0, left: 16, right: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "تأكيد تغيير اللون",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "تكلفة تغيير اللون 500 نقطة , اللون الأسود مجاني",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Container(
                                  width: 200,
                                  child: Text(
                                    MyAppState.currentUser.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                        color: Color(int.parse(color))),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(
                                  top: 10.0,
                                  left: 16,
                                  right: 16,
                                )),
                                SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    FlatButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('إلغاء')),
                                    FlatButton(
                                        onPressed: () async {
                                          if (color== '0xFF222831' || color=='0xFF000000'){
                                            showProgress(
                                                context,
                                                ' جاري تغيير اللون ، الرجاء الانتظار ...',
                                                false);

                                            await firestore
                                                .collection(USERS)
                                                .document(MyAppState
                                                .currentUser.userID)
                                                .updateData({'color': 0xFF000000});

                                            MyAppState.currentUser.color =
                                                color;
                                            hideProgress();
                                            Navigator.pop(context);
                                          }else{
                                          bool isSuccessful = await _userHelper
                                              .paymentPoints(500);
                                          if (isSuccessful) {
                                            hideProgress();
                                            Toast.show("تم خصم  500 نقطة بنجاح",
                                                context,
                                                duration: Toast.LENGTH_LONG,
                                                gravity: Toast.CENTER);
                                            showProgress(
                                                context,
                                                ' جاري تغيير اللون ، الرجاء الانتظار ...',
                                                false);

                                            await firestore
                                                .collection(USERS)
                                                .document(MyAppState
                                                    .currentUser.userID)
                                                .updateData({'color': color});

                                            MyAppState.currentUser.color =
                                                color;
                                            hideProgress();
                                            Navigator.pop(context);
                                          }

                                          else {
                                            hideProgress();
                                            Toast.show(
                                                "رصيد نقاطك غير كافي", context,
                                                duration: Toast.LENGTH_LONG,
                                                gravity: Toast.CENTER);
                                          } }
                                        },
                                        child: Text('متابعة',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(COLOR_ACCENT)))),
                                  ],
                                )
                              ],
                            ))
                      ],
                    ))));
      });
}

Future<List<MaterialsModel>> _getMaterials() async {
  List f = List<MaterialsModel>();
  Firestore firestore = Firestore.instance;

  await firestore.collection('colors').getDocuments().then((querysnapShot) {
    querysnapShot.documents.forEach((doc) {
      MaterialsModel friendship = MaterialsModel.fromJson(doc.data);
      if (friendship.color.isEmpty) {}
      f.add(friendship);
    });
  });

  return f.toSet().toList();
}

class MaterialsModel {
  String color = '';
  String url = '';

  MaterialsModel({this.color, this.url});

  factory MaterialsModel.fromJson(Map<String, dynamic> parsedJson) {
    return new MaterialsModel(
      color: parsedJson['color'] ?? "",
      url: parsedJson['url'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "color": this.color,
      "url": this.url,
    };
  }
}
