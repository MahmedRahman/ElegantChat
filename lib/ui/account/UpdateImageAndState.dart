import 'dart:async';
import 'dart:io';

import 'package:elegant/ui/account/crop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../model/User.dart';
import '../../ui/services/FirebaseHelper.dart';
import '../../ui/utils/helper.dart';
import 'FullScreenImage.dart';

class UpdateImageAndState extends StatefulWidget {
  final User user;

  UpdateImageAndState({Key key, @required this.user}) : super(key: key);

  @override
  _UpdateImageAndStateState createState() {
    return _UpdateImageAndStateState(user);
  }
}

class _UpdateImageAndStateState extends State<UpdateImageAndState> {
  @override
  void initState() {
    super.initState();
  }

  User user;

  GlobalKey<FormState> _key = GlobalKey();
  bool _validate = false;
  String about;

  TextEditingController _aboutController = TextEditingController();

  FireStoreUtils _fireStoreUtils = FireStoreUtils();

  _UpdateImageAndStateState(this.user);

  @override
  Widget build(BuildContext context) {
    if (!_validate) {
      _aboutController.text = user.about;
    }

    return Scaffold(
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
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          Center(
                            child: GestureDetector(
                                onTap: () {
                                  print(user.profilePictureURL);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) {
                                    return FullScreenImage(
                                      imageUrl: user.profilePictureURL,
                                      tag: "generate_a_unique_tag",
                                    );
                                  }));
                                },
                                child: displayCircleImage(
                                    user.profilePictureURL, 130, false)),
                          ),
                          Positioned(
                            left: 80,
                            right: 0,
                            child: FloatingActionButton(
                                backgroundColor: Color(COLOR_ACCENT),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                mini: true,
                                onPressed: _onCameraClick),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[],
                    ),
                    SizedBox(height: 20.0),
                    SizedBox(height: 16.0),
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      onSaved: (String val) {
                        about = val;
                      },
                      controller: _aboutController,
                      cursorColor: Color(COLOR_ACCENT),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.grey[300], width: 2.0),
                          ),
                          labelText: "الحالة"),
                    ),
                    SizedBox(height: 16.0),
                    Container(
                      width: double.infinity,
                      child: RaisedButton(
                        color: Color(COLOR_PRIMARY),
                        textColor: Colors.white,
                        child: Text("تحديث الحالة"),
                        onPressed: () async {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                    child: SingleChildScrollView(
                                        child: Dialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            elevation: 16,
                                            child: Container(
                                              height: 140,
                                              width: 350,
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 20.0,
                                                          left: 16,
                                                          right: 16,
                                                          bottom: 16),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(
                                                        "حفظ التغييرات",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      SizedBox(height: 20),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: <Widget>[
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Text(
                                                                  'إلغاء')),
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                _validateAndSave(
                                                                    buildContext);
                                                              },
                                                              child: Text('نعم',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color(
                                                                          COLOR_PRIMARY)))),
                                                        ],
                                                      )
                                                    ],
                                                  )),
                                            ))));
                              });
                        },
                      ),
                    ),
                    SizedBox(height: 14),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState.validate()) {
      _key.currentState.save();

      showProgress(context, "جار الحفظ ...", false);
      await _updateUser(buildContext);
      hideProgress();
    } else {
      setState(() {
        _validate = true;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    user.about = about;

    var updatedUser = await FireStoreUtils().updateCurrentUser(user, context);
    if (updatedUser != null) {
      MyAppState.currentUser = user;
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'تم حفظ البيانات',
        style: TextStyle(fontSize: 17),
      )));
    } else {
      Scaffold.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'فشل الحفظ , حاول لاحقا',
        style: TextStyle(fontSize: 17),
      )));
    }
  }

  Future<void> _imagePicked(File image) async {
    showProgress(context, 'جار تحميل الصورة', false);
    user.profilePictureURL =
        await _fireStoreUtils.uploadUserImageToFireStorage(image, user.userID);
    await _fireStoreUtils.updateCurrentUser(user, context);
    MyAppState.currentUser = user;
    hideProgress();
  }

  @override
  void dispose() {
    _aboutController.dispose();

    super.dispose();
  }

  _onCameraClick() {
    showModalBottomSheet(
        context: context,
        builder: (bc) {
          return Container(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text("التقاط من الكاميرا"),
                  onTap: () async {
                    Navigator.pop(context);
                    // var image =
                    // await ImagePicker.pickImage(source: ImageSource.camera);
                    // if (image != null) {
                    //   await _imagePicked(image);
                    // }
                    // setState(() {});
                    final result = await Navigator.push(
                        context,
                        // Create the SelectionScreen in the next step.
                        MaterialPageRoute(
                            builder: (context) => CropImage(type: 'camera')));
                    if (result != null) {
                      await _imagePicked(result);
                    } else {}
                    // Navigator.pop(context);

                    setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text("صورة من المعرض"),
                  onTap: () async {
                    Navigator.pop(context);
                    //await _imagePicked(image);
                    final result = await Navigator.push(
                        context,
                        // Create the SelectionScreen in the next step.
                        MaterialPageRoute(
                            builder: (context) => CropImage(type: 'gallery')));
                    if (result != null) {
                      await _imagePicked(result);
                    } else {}
                    // Navigator.pop(context);

                    setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text("إزالة الصورة"),
                  onTap: () async {
                    Navigator.pop(context);
                    showProgress(context, 'حذف الصورة', false);
                    user.profilePictureURL = DEFAULT_URL;
                    await _fireStoreUtils.updateCurrentUser(user, context);
                    MyAppState.currentUser = user;
                    hideProgress();
                    setState(() {});
                  },
                ),
                ListTile(
                  title: Text("إلغاء"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }
}
