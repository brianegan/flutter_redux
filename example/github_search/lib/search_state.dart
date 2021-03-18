// The State represents the data the View requires. The View consumes a Stream
// of States. The view rebuilds every time the Stream emits a State!
//
// The State Stream will emit States depending on the situation: The
// initial state, loading states, the list of results, and any errors that
// happen.
//
// The State Stream responds to input from the View by accepting a
// Stream<String>. We call this Stream the onTextChanged "intent".
import 'search_result.dart';

abstract class SearchState {}

class SearchInitial implements SearchState {}

class SearchLoading implements SearchState {}

class SearchEmpty implements SearchState {}

class SearchPopulated implements SearchState {
  final SearchResult result;

  SearchPopulated(this.result);
}

class SearchError implements SearchState {}
