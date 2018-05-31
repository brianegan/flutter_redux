import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:github_search/empty_result_widget.dart';
import 'package:github_search/redux.dart';
import 'package:github_search/search_error_widget.dart';
import 'package:github_search/search_intro_widget.dart';
import 'package:github_search/search_loading_widget.dart';
import 'package:github_search/search_result_widget.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<SearchState, SearchScreenViewModel>(
      converter: (store) {
        return SearchScreenViewModel(
          state: store.state,
          onTextChanged: (term) => store.dispatch(SearchAction(term)),
        );
      },
      builder: (BuildContext context, SearchScreenViewModel vm) {
        return new Scaffold(
          body: new Stack(
            children: <Widget>[
              new Flex(direction: Axis.vertical, children: <Widget>[
                new Container(
                  padding: new EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 4.0),
                  child: new TextField(
                    decoration: new InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search Github...',
                    ),
                    style: new TextStyle(
                      fontSize: 36.0,
                      fontFamily: "Hind",
                      decoration: TextDecoration.none,
                    ),
                    onChanged: vm.onTextChanged,
                  ),
                ),
                new Expanded(
                  child: new Stack(
                    children: <Widget>[
                      // Fade in an intro screen if no term has been entered
                      new SearchIntroWidget(vm.state.result?.isNoTerm ?? false),

                      // Fade in an Empty Result screen if the search contained
                      // no items
                      new EmptyResultWidget(vm.state.result?.isEmpty ?? false),

                      // Fade in a loading screen when results are being fetched
                      // from Github
                      new SearchLoadingWidget(vm.state.isLoading ?? false),

                      // Fade in an error if something went wrong when fetching
                      // the results
                      new SearchErrorWidget(vm.state.hasError ?? false),

                      // Fade in the Result if available
                      new SearchResultWidget(vm.state.result),
                    ],
                  ),
                )
              ])
            ],
          ),
        );
      },
    );
  }
}

class SearchScreenViewModel {
  final SearchState state;
  final void Function(String term) onTextChanged;

  SearchScreenViewModel({this.state, this.onTextChanged});
}
