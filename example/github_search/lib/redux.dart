import 'dart:async';

import 'package:async/async.dart';
import 'package:github_search/github_client.dart';
import 'package:redux/redux.dart';
import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

// The State represents the data the View requires. The View consumes a Stream
// of States. The view rebuilds every time the Stream emits a State!
//
// The State Stream will emit States depending on the situation: The
// initial state, loading states, the list of results, and any errors that
// happen.
//
// The State Stream responds to input from the View by accepting a
// Stream<String>. We call this Stream the onTextChanged "intent".
abstract class SearchState {}

class SearchInitial implements SearchState {}

class SearchLoading implements SearchState {}

class SearchEmpty implements SearchState {}

class SearchPopulated implements SearchState {
  final SearchResult result;

  SearchPopulated(this.result);
}

class SearchError implements SearchState {}

/// Actions
class SearchAction {
  final String term;

  SearchAction(this.term);
}

class SearchLoadingAction {}

class SearchErrorAction {}

class SearchResultAction {
  final SearchResult result;

  SearchResultAction(this.result);
}

/// Reducer
final searchReducer = combineReducers<SearchState>([
  TypedReducer<SearchState, SearchLoadingAction>(_onLoad),
  TypedReducer<SearchState, SearchErrorAction>(_onError),
  TypedReducer<SearchState, SearchResultAction>(_onResult),
]);

SearchState _onLoad(SearchState state, SearchLoadingAction action) =>
    SearchLoading();

SearchState _onError(SearchState state, SearchErrorAction action) =>
    SearchError();

SearchState _onResult(SearchState state, SearchResultAction action) =>
    action.result.items.isEmpty
        ? SearchEmpty()
        : SearchPopulated(action.result);

/// The Search Middleware will listen for Search Actions and perform the search
/// after the user stop typing for 250ms.
///
/// If a previous search was still loading, we will cancel the operation and
/// fetch a set of results. This ensures only results for the latest search
/// term are shown.
class SearchMiddleware implements MiddlewareClass<SearchState> {
  final GithubClient api;

  Timer _timer;
  CancelableOperation<Store<SearchState>> _operation;

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
        store.dispatch(SearchLoadingAction());

        // Instead of a simple Future, we'll use a CancellableOperation from the
        // `async` package. This will allow us to cancel the previous operation
        // if a Search term comes in. This will prevent us from
        // accidentally showing stale results.
        _operation = CancelableOperation.fromFuture(api
            .search(action.term)
            .then((result) => store..dispatch(SearchResultAction(result)))
            .catchError((e, s) => store..dispatch(SearchErrorAction())));
      });
    }

    // Make sure to forward actions to the next middleware in the chain!
    next(action);
  }
}

/// The Search Epic provides the same functionality as the Search Middleware,
/// but uses redux_epics and the RxDart package to perform the work. It will
/// listen for Search Actions and perform the search after the user stop typing
/// for 250ms.
///
/// If a previous search was still loading, we will cancel the operation and
/// fetch a set of results. This ensures only results for the latest search
/// term are shown.
class SearchEpic implements EpicClass<SearchState> {
  final GithubClient api;

  SearchEpic(this.api);

  @override
  Stream<dynamic> call(Stream<dynamic> actions, EpicStore<SearchState> store) {
    return Observable(actions)
        // Narrow down to SearchAction actions
        .ofType(TypeToken<SearchAction>())
        // Don't start searching until the user pauses for 250ms
        .debounce(Duration(milliseconds: 250))
        // Cancel the previous search and start a one with switchMap
        .switchMap((action) => _search(action.term));
  }

  // Use the async* function to make our lives easier
  Stream<dynamic> _search(String term) async* {
    // Dispatch a SearchLoadingAction to show a loading spinner
    yield SearchLoadingAction();

    try {
      // If the api call is successful, dispatch the results for display
      yield SearchResultAction(await api.search(term));
    } catch (e) {
      // If the search call fails, dispatch an error so we can show it
      yield SearchErrorAction();
    }
  }
}
