import 'package:redux_epics/redux_epics.dart';
import 'package:rxdart/rxdart.dart';

import 'github_client.dart';
import 'search_actions.dart';
import 'search_state.dart';

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
    return actions
        // Narrow down to SearchAction actions
        .whereType<SearchAction>()
        // Don't start searching until the user pauses for 250ms
        .debounce((_) => TimerStream<void>(true, Duration(milliseconds: 250)))
        // Cancel the previous search and start a one with switchMap
        .switchMap<dynamic>((action) => _search(action.term));
  }

  // Use the async* function to make our lives easier
  Stream<dynamic> _search(String term) async* {
    if (term.isEmpty) {
      yield SearchEmptyAction();
    } else {
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
}
