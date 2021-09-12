import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant/ui/account/UserMerchantScreen.dart';

import 'package:elegant/ui/services/UserHelper.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
 import 'package:flutter_colorpicker/utils.dart';
import 'package:toast/toast.dart';

import '../../Constants.dart' as Constants;
import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../../model/UserArabic.dart';
import '../services/FirebaseHelper.dart';
import '../utils/helper.dart';
import 'BuyNameColor.dart';

class StoreScreen extends StatefulWidget {
  final User user;

  StoreScreen({Key key, @required this.user}) : super(key: key);

  @override
  _StoreScreenState createState() {
    return _StoreScreenState(user);
  }
}

class _StoreScreenState extends State<StoreScreen> {
  User userMerchant;
  UserArabic user1;
  bool lightTheme = true;
  Color currentColor = Colors.black54;

  @override
  void initState() {
    super.initState();
   _getPointsUser(widget.user.userID);

  }

  static Firestore firestore = Firestore.instance;
  List<Color> currentColors = [Colors.limeAccent, Colors.green];

  void changeColor(Color color) {
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
                                  "سيتم خصم 500 نقطة من رصيدك",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              Container(
                                width: 175,
                                child:Text(
                                  MyAppState.currentUser.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30,
                                      color: currentColor),
                              ),),

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
                                            var colorTemp = color.toString();
                                            print("colorTemp ${colorTemp}");
                                            String colorFinal =
                                            colorTemp.substring(35, 45);
                                           testColor(colorTemp,colorFinal);

                                            await firestore
                                                .collection(USERS)
                                                .document(MyAppState
                                                    .currentUser.userID)
                                                .updateData(
                                                    {'color': colorFinal});
                                            print("colorFinal ${colorFinal}");
                                            MyAppState.currentUser.color =
                                                colorFinal;
                                            hideProgress();
                                            Navigator.pop(context);
                                          } else {
                                            hideProgress();
                                            Toast.show(
                                                "رصيد نقاطك غير كافي", context,
                                                duration: Toast.LENGTH_LONG,
                                                gravity: Toast.CENTER);
                                          }
                                        },
                                        child: Text('متابعة',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(COLOR_ACCENT)))),
                                  ],
                                )
                              ],
                            ))],
                      ))));
        });
    setState(() {
      currentColor = color;
    });
  }

  void changeColors(List<Color> colors) =>
      setState(() => currentColors = colors);

  TextEditingController _passwordController = TextEditingController();
  String nameAr, password, confirmPassword;
  GlobalKey<FormState> _key1 = GlobalKey();
  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  bool _visible = false;
  String name, merchantID, textType, urlIcon;

  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  UserHelper _userHelper = new UserHelper();

  _StoreScreenState(this.userMerchant);

  @override
  Widget build(BuildContext context) {
    if (!_validate) {
      name = userMerchant.name;
      textType = userMerchant.typeUser;
      merchantID = userMerchant.userID;

      switch (textType) {
        case "user":
          textType = "مستخدم عادي";
          urlIcon = "assets/images/icon_user.png";
          break;
        case "admin":
          textType = "حساب مسؤول موثق";
          urlIcon = "assets/images/icon_admin.png";
          break;
        case "merchant":
          textType = "حساب تاجر - مارشنت";
          urlIcon = "assets/images/icon_merchant.png";
          setState(() {
            _visible = true;
          });
          break;
        default:
          textType = "مستخدم ";
          urlIcon = "assets/images/icon_user.png";
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(COLOR_PRIMARY),
        title: Text(
          'متجر التطبيق',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          Visibility(
              visible: _visible,
              child: IconButton(
                icon: Icon(Icons.how_to_reg),
                onPressed: () async {
                  push(
                      context, UserMerchantScreen(user: userMerchant));
                },
              ))
        ],
      ),
      body: Builder(
        builder: (buildContext) => SingleChildScrollView(
          child: Form(
            key: _key,
            autovalidate: _validate,
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 32.0, left: 32, right: 32),
                    ),
                    SizedBox(height: 20.0),
                    Center(
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            urlIcon,
                            width: 45,
                            height: 45,
                          ),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            textType,
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Center(
                          child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              SizedBox(
                                width: 100,
                                height: 30,
                                child: new Text(
                                  "نقاطي",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(5.0),
                                child: new Text(
                                  widget.user.points.toString(),
                                  style: TextStyle(fontSize: 50),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                              ),
                              RaisedButton(
                                elevation: 3.0,
                                onPressed: () {

                                  Navigator.push(
                                      context,
                                      new MaterialPageRoute(
                                          builder: (context) => BuyColor( )));

                                  // showDialog(
                                  //   context: context,
                                  //   builder: (BuildContext context) {
                                  //     return AlertDialog(
                                  //       title: Text(
                                  //         'اختر اللون (500 نقطة) تكلفة تغيير اللون',
                                  //         style: TextStyle(fontSize: 14),
                                  //       ),
                                  //       content: SingleChildScrollView(
                                   //         child: BlockPicker(
                                  //           pickerColor: currentColor,
                                  //           onColorChanged: changeColor,
                                  //         ),
                                  //       ),
                                  //     );
                                  //   },
                                  // );
                                  // print(currentColor);
                                },
                                child: const Text('تغيير لون الاسم'),
                                color: currentColor,
                                textColor: useWhiteForeground(currentColor)
                                    ? const Color(0xffffffff)
                                    : const Color(0xff000000),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: _visible,
                      child: formUI(),
                    )
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget formUI() {
    return Column(
      children: <Widget>[
        ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0, right: 8.0, left: 8.0),
              child: Text(
                "إنشاء ايميل (بالعربي)",
                style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
              ),
            )),
        ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
                child: TextFormField(
                    style: TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
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
                  //  confirmPassword = val;
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
            onPressed:

            _sendToServer,
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
          // AuthResult result = await FirebaseAuth.instance
          // .createUserWithEmailAndPassword(email: name+"@chatstars.com", password: password);
          print(name);
          bool isSuccessful = await _userHelper.checkUserName(name);

          if (isSuccessful) {
            bool isSuccessful = await _userHelper
                .paymentPoints(30000);
            if (isSuccessful) {
              hideProgress();
              Toast.show("تم خصم  30000 نقطة بنجاح",
                  context,
                  duration: Toast.LENGTH_LONG,
                  gravity: Toast.CENTER);
              UserArabic userArabic = UserArabic(
                  name: name,
                  createdAt: Timestamp.now(),
                  country: "+49",
                  about: 'مرحباً أنا أستخدم تطبيق الدردشة',
                  phone: "0",
                  associatedEmail: "@",
                  active: true,
                  privateLock: false,
                  hideFriends: false,
                  typeUser: "user",
                  age: "0",
                  gender: "غير محدد",
                  points: 500,
                  color: "0xFF222831",
                  settings: Settings(allowPushNotifications: true),
                  profilePictureURL: profilePicUrl);
              await _userHelper.createUserArabic(
                  userArabic, _passwordController.text);
              hideProgress();
              push(
                  context, UserMerchantScreen(user: userMerchant));
            } else {
              hideProgress();
              Toast.show(
                  "رصيد نقاطك غير كافي", context,
                  duration: Toast.LENGTH_LONG,
                  gravity: Toast.CENTER);
            }
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

  Future<User> _getPointsUser(String userID) async {
    User user = new User();
    var points = 0;
    await firestore.collection(USERS).document(userID).get().then((value) {
      print(value.data["points"]);
      if (value.data["points"] != null) {
        points = value.data["points"];

        assert(points is int);
        setState(() {
          user.points = value.data["points"];
          MyAppState.currentUser.points = value.data["points"];
        });

      }
    });

    return user;
  }

  void testColor(String colorTemp, String colorFinal) {
    print("colorTemp : ${colorTemp.toString()}");
    print("colorFinal : ${colorFinal.toString()}");
  }
  }
