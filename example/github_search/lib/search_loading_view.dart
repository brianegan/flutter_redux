import 'package:flutter/material.dart';

class SearchLoadingView extends StatelessWidget {
  SearchLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: FractionalOffset.center,
      child: CircularProgressIndicator(),
    );
  }
}
