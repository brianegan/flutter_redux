import 'dart:async';

import 'package:async/async.dart';
import 'package:redux/redux.dart';

import 'github_client.dart';
import 'search_actions.dart';
import 'search_state.dart';

/// The Search Middleware will listen for Search Actions and perform the search
/// after the user stop typing for 250ms.
///
/// If a previous search was still loading, we will cancel the operation and
/// fetch a set of results. This ensures only results for the latest search
/// term are shown.
class SearchMiddleware implements MiddlewareClass<SearchState> {
  final GithubClient api;

  Timer? _timer;
  CancelableOperation<Store<SearchState>>? _operation;

  SearchMiddleware(this.api);

  @override
  void call(Store<SearchState> store, dynamic action, NextDispatcher next) {
    if (action is SearchAction) {
      // Stop our previous debounce timer and search.
      _timer?.cancel();
      _operation?.cancel();

      // Don't start searching until the user pauses for 250ms. This will stop
      // us from over-fetching from our backend.
      _timer = Timer(Duration(milliseconds: 250), () {
        if (action.term.isEmpty) {
          store.dispatch(SearchEmptyAction());
        } else {
          store.dispatch(SearchLoadingAction());

          // Instead of a simple Future, we'll use a CancellableOperation from the
          // `async` package. This will allow us to cancel the previous operation
          // if a Search term comes in. This will prevent us from
          // accidentally showing stale results.
          _operation = CancelableOperation.fromFuture(api
              .search(action.term)
              .then((result) => store..dispatch(SearchResultAction(result)))
              .catchError((Object e, StackTrace s) =>
                  store..dispatch(SearchErrorAction())));
        }
      });
    }

    // Make sure to forward actions to the next middleware in the chain!
    next(action);
  }
}
