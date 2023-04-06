library flutter_redux;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart'
    show use, Hook, HookState, useStream;
import 'package:redux/redux.dart';

/// Provides a Redux [Store] to all descendants of this Widget. This should
/// generally be a root widget in your App. Connect to the Store provided
/// by this Widget using a [StoreConnector] or [StoreBuilder].
class StoreProvider<S> extends InheritedWidget {
  final Store<S> _store;

  /// Create a [StoreProvider] by passing in the required [store] and [child]
  /// parameters.
  const StoreProvider({
    Key? key,
    required Store<S> store,
    required Widget child,
  })  : _store = store,
        super(key: key, child: child);

  /// A method that can be called by descendant Widgets to retrieve the Store
  /// from the StoreProvider.
  ///
  /// Important: When using this method, pass through complete type information
  /// or Flutter will be unable to find the correct StoreProvider!
  ///
  /// ### Example
  ///
  /// ```
  /// class MyWidget extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final store = StoreProvider.of<int>(context);
  ///
  ///     return Text('${store.state}');
  ///   }
  /// }
  /// ```
  ///
  /// If you need to use the [Store] from the `initState` function, set the
  /// [listen] option to false.
  ///
  /// ### Example
  ///
  /// ```
  /// class MyWidget extends StatefulWidget {
  ///   static GlobalKey<_MyWidgetState> captorKey = GlobalKey<_MyWidgetState>();
  ///
  ///   MyWidget() : super(key: captorKey);
  ///
  ///   _MyWidgetState createState() => _MyWidgetState();
  /// }
  ///
  /// class _MyWidgetState extends State<MyWidget> {
  ///   Store<String> store;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     store = StoreProvider.of<String>(context, listen: false);
  ///   }
  ///
  ///   @override
  ///  Widget build(BuildContext context) {
  ///     return Container();
  ///   }
  /// }
  /// ```
  static Store<S> of<S>(BuildContext context, {bool listen = true}) {
    final provider = (listen
        ? context.dependOnInheritedWidgetOfExactType<StoreProvider<S>>()
        : context
            .getElementForInheritedWidgetOfExactType<StoreProvider<S>>()
            ?.widget) as StoreProvider<S>;

    return provider._store;
  }

  @override
  bool updateShouldNotify(StoreProvider<S> oldWidget) =>
      _store != oldWidget._store;
}

/// If the StoreProvider.of method fails, this error will be thrown.
///
/// Often, when the `of` method fails, it is difficult to understand why since
/// there can be multiple causes. This error explains those causes so the user
/// can understand and fix the issue.
class StoreProviderError extends Error {
  /// The type of the class the user tried to retrieve
  Type type;

  /// Creates a StoreProviderError
  StoreProviderError(this.type);

  @override
  String toString() {
    return '''Error: No $type found. To fix, please try:
          
  * Wrapping your MaterialApp with the StoreProvider<State>, 
  rather than an individual Route
  * Providing full type information to your Store<State>, 
  StoreProvider<State> and StoreConnector<State, ViewModel>
  * Ensure you are using consistent and complete imports. 
  E.g. always use `import 'package:my_app/app_state.dart';
  
If none of these solutions work, please file a bug at:
https://github.com/brianegan/flutter_redux/issues/new
      ''';
  }
}

/// A hook to access the redux store
///
/// ### Example
///
/// ```
/// class StoreUser extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final store = useStore();
///     return YourWidgetHierarchy(store: store);
///   }
/// }
/// ```
Store<S> useStore<S>() => use(_UseStoreHook());

class _UseStoreHook<S> extends Hook<Store<S>> {
  @override
  HookState<Store<S>, Hook<Store<S>>> createState() => _UseStoreHookState<S>();
}

class _UseStoreHookState<S> extends HookState<Store<S>, _UseStoreHook<S>> {
  @override
  Store<S> build(BuildContext context) => StoreProvider.of<S>(context);
}

typedef Dispatch = dynamic Function(dynamic action);

/// A hook to access the redux `dispatch` function
///
/// ### Example
///
/// ```
/// class StoreUser extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final dispatch = useDispatch<AppState>();
///     useEffect(() {
///       dispatch(SomeAction());
///     }, []);
///     return YourWidgetHierarchy(dispatch: dispatch);
///   }
/// }
/// ```
Dispatch useDispatch<S>() => useStore<S>().dispatch;

typedef Selector<State, Output> = Output Function(State state);
typedef EqualityFn<T> = bool Function(T a, T b);

/// A hook to access the redux store's state. This hook takes a selector function
/// as an argument. The selector is called with the store state.
///
/// This hook takes an optional equality comparison function as the second parameter
/// that allows you to customize the way the selected state is compared to determine
/// whether the widget needs to be re-built. The default equality comparison function
/// is one that uses referential equality.
///
/// ### Example
///
/// ```
/// class StoreUser extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final someCount = useSelector<AppState, int>(selectSomeCount);
///     return YourWidgetHierarchy(someCount: someCount);
///   }
/// }
/// ```
Output? useSelector<State, Output>(Selector<State, Output> selector,
    [EqualityFn? equalityFn]) {
  final store = useStore<State>();
  final snap = useStream<Output>(
      store.onChange.map(selector).distinct(equalityFn),
      initialData: selector(store.state));
  return snap.data;
}
