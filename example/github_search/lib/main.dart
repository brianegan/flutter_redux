import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:github_search/github_search_api.dart';
import 'package:github_search/github_search_widget.dart';
import 'package:github_search/redux.dart';
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';

void main() {
  final store = new Store<SearchState>(searchReducer,
      initialState: SearchState.initial(),
      middleware: [
//        SearchMiddleware(GithubApi()),
        EpicMiddleware<SearchState>(SearchEpic(GithubApi())),
      ]);

  runApp(new RxDartGithubSearchApp(
    store: store,
  ));
}

class RxDartGithubSearchApp extends StatelessWidget {
  final Store<SearchState> store;

  RxDartGithubSearchApp({Key key, this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreProvider<SearchState>(
      store: store,
      child: new MaterialApp(
        title: 'RxDart Github Search',
        theme: new ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
        ),
        home: new SearchScreen(),
      ),
    );
  }
}
