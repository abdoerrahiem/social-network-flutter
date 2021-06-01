import 'package:flutter/material.dart';

AppBar header(
  context, {
  bool isTitle = false,
  String title = '',
  bool removeBackButton = false,
}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isTitle ? 'Social Network' : title,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isTitle ? 'Signatra' : '',
        fontSize: isTitle ? 40 : 20,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    // backgroundColor: Theme.of(context).accentColor,
  );
}
