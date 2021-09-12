import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_view_indicators/page_view_indicators.dart';

import '../../constants.dart';
import '../../constants.dart' as Constants;
import '../../ui/utils/helper.dart';
import '../account/LoginScreen.dart';
import '../account/SignUpScreen.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    children: populatePages(context),
                    onPageChanged: (int index) {
                      _currentPageNotifier.value = index;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildCircleIndicator(),
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              color: Color(Constants.COLOR_PRIMARY),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: RaisedButton(
                        color: Color(COLOR_SECONDARY),
                        child: Text(
                          'تسجيل دخول',
                          style:
                              TextStyle(fontSize: Constants.FONT_SIZE_MEDIUM),
                        ),
                        textColor: Colors.white,
                        onPressed: () {
                          push(context, LoginScreen());
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: RaisedButton(
                        color: Colors.white,
                        child: Text('إنشاء حساب',
                            style: TextStyle(
                                fontSize: Constants.FONT_SIZE_MEDIUM,
                                color: Colors.black)),
                        onPressed: () {
                          push(context, SignUpScreen());
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  final _currentPageNotifier = ValueNotifier<int>(0);

  final List<String> _titlesList = [
    '  Elegant',
    'انضم كبائع للنقاط',
    'ابدأ الأن',
  ];

  final List<String> _subtitlesList = [
    'انشئ غرف دردشة وارسل طلبات صداقة',
    'امنح المستخدمين امكانية تغيير أسماءهم',
    'أنشئ حساب جديد أو سجل دخول',
  ];

  final List<String> _imageList = [
    'assets/images/slide_1.svg',
    'assets/images/slide_2.svg',
    'assets/images/slide_3.svg',
    'assets/images/slide_4.svg'
  ];
  final List<Widget> _pages = [];

  List<Widget> populatePages(BuildContext context) {
    _pages.clear();
    _titlesList.asMap().forEach((index, value) => _pages.add(getPage(
        _imageList.elementAt(index),
        value,
        _subtitlesList.elementAt(index),
        context,
        _isLastPage(index + 1, _titlesList.length))));
    return _pages;
  }

  Widget _buildCircleIndicator() {
    return CirclePageIndicator(
      selectedDotColor: Colors.white,
      dotColor: Colors.white30,
      itemCount: _pages.length,
      currentPageNotifier: _currentPageNotifier,
    );
  }

  Widget getPage(String image, String title, String subTitle,
      BuildContext context, bool isLastPage) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            color: Color(Constants.COLOR_PRIMARY),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    image,
                    color: Colors.white,
                    width: 98.0,
                    height: 98.0,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      subTitle,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isLastPage(int currentPosition, int pagesNumber) {
    if (currentPosition == pagesNumber) {
      return true;
    } else {
      return false;
    }
  }
}
