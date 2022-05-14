library flutter_redux;

import 'dart:async';

import 'package:flutter/widgets.dart';
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
            ?.widget) as StoreProvider<S>?;

    if (provider == null) throw StoreProviderError<StoreProvider<S>>();

    return provider._store;
  }

  @override
  bool updateShouldNotify(StoreProvider<S> oldWidget) =>
      _store != oldWidget._store;
}

/// Build a Widget using the [BuildContext] and [ViewModel]. The [ViewModel] is
/// derived from the [Store] using a [StoreConverter].
typedef ViewModelBuilder<ViewModel> = Widget Function(
  BuildContext context,
  ViewModel vm,
);

/// Convert the entire [Store] into a [ViewModel]. The [ViewModel] will be used
/// to build a Widget using the [ViewModelBuilder].
typedef StoreConverter<S, ViewModel> = ViewModel Function(
  Store<S> store,
);

/// A function that will be run when the [StoreConnector] is initialized (using
/// the [State.initState] method). This can be useful for dispatching actions
/// that fetch data for your Widget when it is first displayed.
typedef OnInitCallback<S> = void Function(
  Store<S> store,
);

/// A function that will be run when the StoreConnector is removed from the
/// Widget Tree.
///
/// It is run in the [State.dispose] method.
///
/// This can be useful for dispatching actions that remove stale data from
/// your State tree.
typedef OnDisposeCallback<S> = void Function(
  Store<S> store,
);

/// A test of whether or not your `converter` function should run in response
/// to a State change. For advanced use only.
///
/// Some changes to the State of your application will mean your `converter`
/// function can't produce a useful ViewModel. In these cases, such as when
/// performing exit animations on data that has been removed from your Store,
/// it can be best to ignore the State change while your animation completes.
///
/// To ignore a change, provide a function that returns true or false. If the
/// returned value is true, the change will be ignored.
///
/// If you ignore a change, and the framework needs to rebuild the Widget, the
/// `builder` function will be called with the latest `ViewModel` produced by
/// your `converter` function.
typedef IgnoreChangeTest<S> = bool Function(S state);

/// A function that will be run on State change, before the build method.
///
/// This function is passed the previous and current `ViewModel`, and if
/// `distinct` is `true`, it will only be called when the `ViewModel` changes.
///
/// This is useful for making calls to other classes, such as a
/// `Navigator` or `TabController`, in response to state changes.
/// It can also be used to trigger an action based on the previous
/// state.
///
/// ```dart
/// StoreConnector<String, String>(
///   converter: (store) => store.state,
///   onWillChange: (prev, vm) {
///     if (prev != vm) {
///       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
///         content: Text(vm),
///       ));
///     }
///   },
///   builder: (context, vm) {
///     return Text(vm);
///   },
/// );
/// ```
typedef OnWillChangeCallback<ViewModel> = void Function(
  ViewModel? previousViewModel,
  ViewModel newViewModel,
);

/// A function that will be run on State change, after the build method.
///
/// This function is passed the previous and current `ViewModel`, and if
/// `distinct` is `true`, it will only be called when the `ViewModel` changes.
///
/// This can be useful for running certain animations after the build is
/// complete.
///
/// Note: Using a [BuildContext] inside this callback can cause problems if
/// the callback performs navigation. For navigation purposes, please use
/// an [OnWillChangeCallback].
///
/// ```dart
/// StoreConnector<int, int>(
///   converter: (store) => store.state,
///   onDidChange: (prev, vm) {
///     if (prev != vm) {
///       myScrollController.animateTo(200);
///     }
///   },
///   builder: (context, vm) {
///     return ListView.builder(
///       controller: myScrollController,
///       itemCount: vm,
///       builder: (context, index) => Text('$index'),
///     );
///   },
/// );
/// ```
typedef OnDidChangeCallback<ViewModel> = void Function(
  ViewModel? previousViewModel,
  ViewModel viewModel,
);

/// A function that will be run after the Widget is built the first time.
///
/// This function is passed the initial `ViewModel` created by the `converter`
/// function.
///
/// This can be useful for starting certain animations, such as showing
/// Snackbars, after the Widget is built the first time.
typedef OnInitialBuildCallback<ViewModel> = void Function(ViewModel viewModel);

/// Build a widget based on the state of the [Store].
///
/// Before the [builder] is run, the [converter] will convert the store into a
/// more specific `ViewModel` tailored to the Widget being built.
///
/// Every time the store changes, the Widget will be rebuilt. As a performance
/// optimization, the Widget can be rebuilt only when the [ViewModel] changes.
/// In order for this to work correctly, you must implement [==] and [hashCode]
/// for the [ViewModel], and set the [distinct] option to true when creating
/// your StoreConnector.
class StoreConnector<S, ViewModel> extends StatelessWidget {
  /// Build a Widget using the [BuildContext] and [ViewModel]. The [ViewModel]
  /// is created by the [converter] function.
  final ViewModelBuilder<ViewModel> builder;

  /// Convert the [Store] into a [ViewModel]. The resulting [ViewModel] will be
  /// passed to the [builder] function.
  final StoreConverter<S, ViewModel> converter;

  /// As a performance optimization, the Widget can be rebuilt only when the
  /// [ViewModel] changes. In order for this to work correctly, you must
  /// implement [==] and [hashCode] for the [ViewModel], and set the [distinct]
  /// option to true when creating your StoreConnector.
  final bool distinct;

  /// A function that will be run when the StoreConnector is initially created.
  /// It is run in the [State.initState] method.
  ///
  /// This can be useful for dispatching actions that fetch data for your Widget
  /// when it is first displayed.
  final OnInitCallback<S>? onInit;

  /// A function that will be run when the StoreConnector is removed from the
  /// Widget Tree.
  ///
  /// It is run in the [State.dispose] method.
  ///
  /// This can be useful for dispatching actions that remove stale data from
  /// your State tree.
  final OnDisposeCallback<S>? onDispose;

  /// Determines whether the Widget should be rebuilt when the Store emits an
  /// onChange event.
  final bool rebuildOnChange;

  /// A test of whether or not your [converter] function should run in response
  /// to a State change. For advanced use only.
  ///
  /// Some changes to the State of your application will mean your [converter]
  /// function can't produce a useful ViewModel. In these cases, such as when
  /// performing exit animations on data that has been removed from your Store,
  /// it can be best to ignore the State change while your animation completes.
  ///
  /// To ignore a change, provide a function that returns true or false. If the
  /// returned value is true, the change will be ignored.
  ///
  /// If you ignore a change, and the framework needs to rebuild the Widget, the
  /// [builder] function will be called with the latest [ViewModel] produced by
  /// your [converter] function.
  final IgnoreChangeTest<S>? ignoreChange;

  /// A function that will be run on State change, before the Widget is built.
  ///
  /// This function is passed the `ViewModel`, and if `distinct` is `true`,
  /// it will only be called if the `ViewModel` changes.
  ///
  /// This can be useful for imperative calls to things like Navigator,
  /// TabController, etc. This can also be useful for triggering actions
  /// based on the previous state.
  final OnWillChangeCallback<ViewModel>? onWillChange;

  /// A function that will be run on State change, after the Widget is built.
  ///
  /// This function is passed the `ViewModel`, and if `distinct` is `true`,
  /// it will only be called if the `ViewModel` changes.
  ///
  /// This can be useful for running certain animations after the build is
  /// complete.
  ///
  /// Note: Using a [BuildContext] inside this callback can cause problems if
  /// the callback performs navigation. For navigation purposes, please use
  /// [onWillChange].
  final OnDidChangeCallback<ViewModel>? onDidChange;

  /// A function that will be run after the Widget is built the first time.
  ///
  /// This function is passed the initial `ViewModel` created by the [converter]
  /// function.
  ///
  /// This can be useful for starting certain animations, such as showing
  /// Snackbars, after the Widget is built the first time.
  final OnInitialBuildCallback<ViewModel>? onInitialBuild;

  /// Create a [StoreConnector] by passing in the required [converter] and
  /// [builder] functions.
  ///
  /// You can also specify a number of additional parameters that allow you to
  /// modify the behavior of the StoreConnector. Please see the documentation
  /// for each option for more info.
  const StoreConnector({
    Key? key,
    required this.builder,
    required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _StoreStreamListener<S, ViewModel>(
      store: StoreProvider.of<S>(context),
      builder: builder,
      converter: converter,
      distinct: distinct,
      onInit: onInit,
      onDispose: onDispose,
      rebuildOnChange: rebuildOnChange,
      ignoreChange: ignoreChange,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}

/// Build a Widget by passing the [Store] directly to the build function.
///
/// Generally, it's considered best practice to use the [StoreConnector] and to
/// build a `ViewModel` specifically for your Widget rather than passing through
/// the entire [Store], but this is provided for convenience when that isn't
/// necessary.
class StoreBuilder<S> extends StatelessWidget {
  static Store<S> _identity<S>(Store<S> store) => store;

  /// Builds a Widget using the [BuildContext] and your [Store].
  final ViewModelBuilder<Store<S>> builder;

  /// Indicates whether or not the Widget should rebuild when the [Store] emits
  /// an `onChange` event.
  final bool rebuildOnChange;

  /// A function that will be run when the StoreConnector is initially created.
  /// It is run in the [State.initState] method.
  ///
  /// This can be useful for dispatching actions that fetch data for your Widget
  /// when it is first displayed.
  final OnInitCallback<S>? onInit;

  /// A function that will be run when the StoreBuilder is removed from the
  /// Widget Tree.
  ///
  /// It is run in the [State.dispose] method.
  ///
  /// This can be useful for dispatching actions that remove stale data from
  /// your State tree.
  final OnDisposeCallback<S>? onDispose;

  /// A function that will be run on State change, before the Widget is built.
  ///
  /// This can be useful for imperative calls to things like Navigator,
  /// TabController, etc. This can also be useful for triggering actions
  /// based on the previous state.
  final OnWillChangeCallback<Store<S>>? onWillChange;

  /// A function that will be run on State change, after the Widget is built.
  ///
  /// This can be useful for running certain animations after the build is
  /// complete
  ///
  /// Note: Using a [BuildContext] inside this callback can cause problems if
  /// the callback performs navigation. For navigation purposes, please use
  /// [onWillChange].
  final OnDidChangeCallback<Store<S>>? onDidChange;

  /// A function that will be run after the Widget is built the first time.
  ///
  /// This can be useful for starting certain animations, such as showing
  /// Snackbars, after the Widget is built the first time.
  final OnInitialBuildCallback<Store<S>>? onInitialBuild;

  /// Create's a Widget based on the Store.
  const StoreBuilder({
    Key? key,
    required this.builder,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<S, Store<S>>(
      builder: builder,
      converter: _identity,
      rebuildOnChange: rebuildOnChange,
      onInit: onInit,
      onDispose: onDispose,
      onWillChange: onWillChange,
      onDidChange: onDidChange,
      onInitialBuild: onInitialBuild,
    );
  }
}

/// Listens to the [Store] and calls [builder] whenever [store] changes.
class _StoreStreamListener<S, ViewModel> extends StatefulWidget {
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final Store<S> store;
  final bool rebuildOnChange;
  final bool distinct;
  final OnInitCallback<S>? onInit;
  final OnDisposeCallback<S>? onDispose;
  final IgnoreChangeTest<S>? ignoreChange;
  final OnWillChangeCallback<ViewModel>? onWillChange;
  final OnDidChangeCallback<ViewModel>? onDidChange;
  final OnInitialBuildCallback<ViewModel>? onInitialBuild;

  const _StoreStreamListener({
    Key? key,
    required this.builder,
    required this.store,
    required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
    this.onDidChange,
    this.onInitialBuild,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StoreStreamListenerState<S, ViewModel>();
  }
}

class _StoreStreamListenerState<S, ViewModel>
    extends State<_StoreStreamListener<S, ViewModel>> {
  late Stream<ViewModel> _stream;
  ViewModel? _latestValue;
  Object? _latestError;

  // `_latestValue!` would throw _CastError if `ViewModel` is nullable,
  // therefore `_latestValue as ViewModel` is used.
  // https://dart.dev/null-safety/understanding-null-safety#nullability-and-generics
  ViewModel get _requireLatestValue => _latestValue as ViewModel;

  @override
  void initState() {
    widget.onInit?.call(widget.store);

    _computeLatestValue();

    if (widget.onInitialBuild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialBuild!(_requireLatestValue);
      });
    }

    _createStream();

    super.initState();
  }

  @override
  void dispose() {
    widget.onDispose?.call(widget.store);

    super.dispose();
  }

  @override
  void didUpdateWidget(_StoreStreamListener<S, ViewModel> oldWidget) {
    _computeLatestValue();

    if (widget.store != oldWidget.store) {
      _createStream();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _computeLatestValue() {
    try {
      _latestError = null;
      _latestValue = widget.converter(widget.store);
    } catch (e, s) {
      _latestValue = null;
      _latestError = ConverterError(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.rebuildOnChange
        ? StreamBuilder<ViewModel>(
            stream: _stream,
            builder: (context, snapshot) {
              if (_latestError != null) throw _latestError!;

              return widget.builder(
                context,
                _requireLatestValue,
              );
            },
          )
        : _latestError != null
            ? throw _latestError!
            : widget.builder(context, _requireLatestValue);
  }

  bool _whereDistinct(ViewModel vm) {
    if (widget.distinct) {
      return vm != _latestValue;
    }

    return true;
  }

  bool _ignoreChange(S state) {
    if (widget.ignoreChange != null) {
      return !widget.ignoreChange!(widget.store.state);
    }

    return true;
  }

  void _createStream() {
    _stream = widget.store.onChange
        .where(_ignoreChange)
        .map((_) => widget.converter(widget.store))
        .transform(StreamTransformer.fromHandlers(
          handleError: _handleConverterError,
        ))
        // Don't use `Stream.distinct` because it cannot capture the initial
        // ViewModel produced by the `converter`.
        .where(_whereDistinct)
        // After each ViewModel is emitted from the Stream, we update the
        // latestValue. Important: This must be done after all other optional
        // transformations, such as ignoreChange.
        .transform(StreamTransformer.fromHandlers(
          handleData: _handleChange,
        ))
        // Handle any errors from converter/onWillChange/onDidChange
        .transform(StreamTransformer.fromHandlers(
          handleError: _handleError,
        ));
  }

  void _handleChange(ViewModel vm, EventSink<ViewModel> sink) {
    _latestError = null;
    widget.onWillChange?.call(_latestValue, vm);
    final previousValue = _latestValue;
    _latestValue = vm;

    if (widget.onDidChange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onDidChange!(previousValue, _requireLatestValue);
        }
      });
    }

    sink.add(vm);
  }

  void _handleConverterError(
    Object error,
    StackTrace stackTrace,
    EventSink<ViewModel> sink,
  ) {
    sink.addError(ConverterError(error, stackTrace), stackTrace);
  }

  void _handleError(
    Object error,
    StackTrace stackTrace,
    EventSink<ViewModel> sink,
  ) {
    _latestValue = null;
    _latestError = error;
    sink.addError(error, stackTrace);
  }
}

/// If the StoreProvider.of method fails, this error will be thrown.
///
/// Often, when the `of` method fails, it is difficult to understand why since
/// there can be multiple causes. This error explains those causes so the user
/// can understand and fix the issue.
class StoreProviderError<S> extends Error {
  /// Creates a StoreProviderError
  StoreProviderError();

  @override
  String toString() {
    return '''Error: No $S found. To fix, please try:
          
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

/// If the StoreConnector throws an error,
class ConverterError extends Error {
  /// The error thrown while running the [StoreConnector.converter] function
  final Object error;

  /// The stacktrace that accompanies the [error]
  @override
  final StackTrace stackTrace;

  /// Creates a ConverterError with the relevant error and stacktrace
  ConverterError(this.error, this.stackTrace);

  @override
  String toString() {
    return '''Converter Function Error: $error
    
$stackTrace;
''';
  }
}
