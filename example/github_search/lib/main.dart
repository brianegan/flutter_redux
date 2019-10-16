import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:github_search/github_client.dart';
import 'package:github_search/redux.dart';
import 'package:github_search/search_screen.dart';
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';

void main() {
  final store = Store<SearchState>(
    searchReducer,
    initialState: SearchInitial(),
    middleware: [
      // The following middleware both achieve the same goal: Load search
      // results from github in response to SearchActions.
      //
      // One is implemented as a normal middleware, the other is implemented as
      // an epic for demonstration purposes.

//        SearchMiddleware(GithubClient()),
      EpicMiddleware<SearchState>(SearchEpic(GithubClient())),
    ],
  );

  runApp(RxDartGithubSearchApp(
    store: store,
  ));
}

class RxDartGithubSearchApp extends StatelessWidget {
  final Store<SearchState> store;

  RxDartGithubSearchApp({Key key, this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreProvider<SearchState>(
      store: store,
      child: MaterialApp(
        title: 'RxDart Github Search',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.grey,
        ),
        home: SearchScreen(),
      ),
    );
  }
}
