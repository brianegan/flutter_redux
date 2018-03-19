library flutter_redux;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

/// Provides a Redux [Store] to all ancestors of this Widget. This should
/// generally be a root widget in your App. Connect to the Store provided
/// by this Widget using a [StoreConnector] or [StoreBuilder].
class StoreProvider<S> extends InheritedWidget {
  final Store<S> store;

  const StoreProvider({
    Key key,
    @required this.store,
    @required Widget child,
  })
      : assert(store != null),
        assert(child != null),
        super(key: key, child: child);

  factory StoreProvider.of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(StoreProvider);

  @override
  bool updateShouldNotify(StoreProvider old) => store != old.store;
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
/// returned value is false, the change will be ignored.
///
/// If you ignore a change, and the framework needs to rebuild the Widget, the
/// `builder` function will be called with the latest `ViewModel` produced by
/// your `converter` function.
typedef IgnoreChangeTest<S> = bool Function(S state);


/// A function that will be run on State change.
///
/// This function is passed the `ViewModel`, and if `distinct` is `true`,
/// it will only be called in the `ViewModel` changes.
///
/// This can be useful for imperative calls to things like Navigator,
/// TabController, etc
typedef OnWillChangeCallback<ViewModel> = void Function(ViewModel viewModel);

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
  final OnInitCallback onInit;

  /// A function that will be run when the StoreConnector is removed from the
  /// Widget Tree.
  ///
  /// It is run in the [State.dispose] method.
  ///
  /// This can be useful for dispatching actions that remove stale data from
  /// your State tree.
  final OnDisposeCallback onDispose;

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
  /// returned value is false, the change will be ignored.
  ///
  /// If you ignore a change, and the framework needs to rebuild the Widget, the
  /// [builder] function will be called with the latest [ViewModel] produced by
  /// your [converter] function.
  final IgnoreChangeTest<S> ignoreChange;

  /// A function that will be run on State change.
  ///
  /// This function is passed the `ViewModel`, and if `distinct` is `true`,
  /// it will only be called in the `ViewModel` changes.
  ///
  /// This can be useful for imperative calls to things like Navigator,
  /// TabController, etc
  final OnWillChangeCallback<ViewModel> onWillChange;

  StoreConnector({
    Key key,
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
  })
      : assert(builder != null),
        assert(converter != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new _StoreStreamListener<S, ViewModel>(
      store: new StoreProvider.of(context).store,
      builder: builder,
      converter: converter,
      distinct: distinct,
      onInit: onInit,
      onDispose: onDispose,
      rebuildOnChange: rebuildOnChange,
      ignoreChange: ignoreChange,
      onWillChange: onWillChange
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
  final OnInitCallback onInit;

  /// A function that will be run when the StoreBuilder is removed from the
  /// Widget Tree.
  ///
  /// It is run in the [State.dispose] method.
  ///
  /// This can be useful for dispatching actions that remove stale data from
  /// your State tree.
  final OnDisposeCallback onDispose;

  /// A function that will be run on State change.
  ///
  /// This can be useful for imperative calls to things like Navigator,
  /// TabController, etc
  final OnWillChangeCallback<Store<S>> onWillChange;

  StoreBuilder({
    Key key,
    @required this.builder,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.onWillChange,
  })
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<S, Store<S>>(
      builder: builder,
      converter: _identity,
      rebuildOnChange: rebuildOnChange,
      onInit: onInit,
      onDispose: onDispose,
      onWillChange: this.onWillChange,
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
  final OnInitCallback onInit;
  final OnDisposeCallback onDispose;
  final IgnoreChangeTest<S> ignoreChange;
  final OnWillChangeCallback<ViewModel> onWillChange;

  _StoreStreamListener({
    Key key,
    @required this.builder,
    @required this.store,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.onDispose,
    this.rebuildOnChange = true,
    this.ignoreChange,
    this.onWillChange,
  })
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _StoreStreamListenerState();
  }
}

class _StoreStreamListenerState<ViewModel> extends State<_StoreStreamListener> {
  Stream<ViewModel> stream;
  ViewModel latestValue;

  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit(widget.store);
    }

    _init();

    super.initState();
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose(widget.store);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(_StoreStreamListener oldWidget) {
    if (widget.store != oldWidget.store) {
      _init();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _init() {
    latestValue = widget.converter(widget.store);

    stream = widget.store.onChange;

    if (widget.ignoreChange != null) {
      stream = stream.where((state) => !widget.ignoreChange(state));
    }

    stream = stream.map((_) => widget.converter(widget.store));

    // Don't use `Stream.distinct` because it cannot capture the initial
    // ViewModel produced by the `converter`.
    if (widget.distinct) {
      stream = stream.where((vm) {
        final isDistinct = vm != latestValue;

        return isDistinct;
      });
    }

    if (widget.onWillChange != null) {
      stream.forEach(widget.onWillChange);
    }

    // After each ViewModel is emitted from the Stream, we update the
    // latestValue. Important: This must be done after all other optional
    // transformations, such as ignoreChange.
    stream = stream
        .transform(new StreamTransformer.fromHandlers(handleData: (vm, sink) {
      latestValue = vm;
      sink.add(vm);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return widget.rebuildOnChange
        ? new StreamBuilder(
            stream: stream,
            builder: (context, snapshot) => widget.builder(
                  context,
                  snapshot.hasData ? snapshot.data : latestValue,
                ),
          )
        : widget.builder(context, latestValue);
  }
}
