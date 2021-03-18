import 'search_result.dart';

/// Actions
class SearchAction {
  final String term;

  SearchAction(this.term);
}

class SearchEmptyAction {}

class SearchLoadingAction {}

class SearchErrorAction {}

class SearchResultAction {
  final SearchResult result;

  SearchResultAction(this.result);
}
