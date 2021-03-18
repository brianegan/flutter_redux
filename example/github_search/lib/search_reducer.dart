import 'package:redux/redux.dart';

import 'search_actions.dart';
import 'search_state.dart';

/// Reducer
final searchReducer = combineReducers<SearchState>([
  TypedReducer<SearchState, SearchEmptyAction>(_onEmpty),
  TypedReducer<SearchState, SearchLoadingAction>(_onLoad),
  TypedReducer<SearchState, SearchErrorAction>(_onError),
  TypedReducer<SearchState, SearchResultAction>(_onResult),
]);

SearchState _onEmpty(SearchState state, SearchEmptyAction action) =>
    SearchInitial();

SearchState _onLoad(SearchState state, SearchLoadingAction action) =>
    SearchLoading();

SearchState _onError(SearchState state, SearchErrorAction action) =>
    SearchError();

SearchState _onResult(SearchState state, SearchResultAction action) =>
    action.result.items.isEmpty
        ? SearchEmpty()
        : SearchPopulated(action.result);
