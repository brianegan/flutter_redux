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
typedef Widget ViewModelBuilder<ViewModel>(
  BuildContext context,
  ViewModel vm,
);

/// Convert the entire [Store] into a [ViewModel]. The [ViewModel] will be used
/// to build a Widget using the [ViewModelBuilder].
typedef ViewModel StoreConverter<S, ViewModel>(
  Store<S> store,
);

/// A function that will be run when the [StoreConnector] is initialized (using
/// the [State.initState] method). This can be useful for dispatching actions
/// that fetch data for your Widget when it is first displayed.
typedef void OnInitCallback<S>(
  Store<S> store,
);

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

  /// Determines whether the Widget should be rebuilt when the Store emits an
  /// onChange event.
  final bool rebuildOnChange;

  /// Enabled by default. If enabled, `null` values produced by your [converter]
  /// will be sent to the [builder] to be converted into a Widget.
  ///
  /// In some cases, however, it can be useful to avoid rebuilding when the
  /// [converter] produces a null value, such as removing an item from your
  /// [Store] while performing an animation on a Widget.
  final bool rebuildOnNull;

  StoreConnector({
    Key key,
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.rebuildOnChange = true,
    this.rebuildOnNull = true,
  })
      : assert(builder != null),
        assert(converter != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => new _StoreStreamListener<S, ViewModel>(
        store: new StoreProvider.of(context).store,
        builder: builder,
        converter: converter,
        distinct: distinct,
        onInit: onInit,
        rebuildOnChange: rebuildOnChange,
        rebuildOnNull: rebuildOnNull,
      );
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

  StoreBuilder({
    Key key,
    @required this.builder,
    this.onInit,
    this.rebuildOnChange = true,
  })
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => new StoreConnector<S, Store<S>>(
        builder: builder,
        converter: _identity,
        rebuildOnChange: rebuildOnChange,
        onInit: onInit,
      );
}

/// Listens to the [Store] and calls [builder] whenever [store] changes.
class _StoreStreamListener<S, ViewModel> extends StatefulWidget {
  final Stream<ViewModel> stream;
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final Store<S> store;
  final bool rebuildOnChange;
  final OnInitCallback onInit;

  _StoreStreamListener._({
    Key key,
    @required this.builder,
    @required this.stream,
    @required this.store,
    @required this.converter,
    this.onInit,
    this.rebuildOnChange = true,
  })
      : super(key: key);

  factory _StoreStreamListener({
    Key key,
    @required Store<S> store,
    @required StoreConverter<S, ViewModel> converter,
    @required ViewModelBuilder<ViewModel> builder,
    bool distinct = false,
    OnInitCallback onInit,
    bool rebuildOnChange = true,
    bool rebuildOnNull = true,
  }) {
    var stream = store.onChange.map((_) => converter(store));

    // Don't use `Stream.distinct` because it cannot capture the initial
    // ViewModel produced by the `converter`.
    if (distinct) {
      var latestValue = converter(store);

      stream = stream.where((vm) {
        final isDistinct = vm != latestValue;
        latestValue = vm;

        return isDistinct;
      });
    }

    if (!rebuildOnNull) {
      stream = stream.where((item) => item != null);
    }

    return new _StoreStreamListener._(
      builder: builder,
      stream: stream,
      converter: converter,
      store: store,
      key: key,
      rebuildOnChange: rebuildOnChange,
      onInit: onInit,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return new _StoreStreamListenerState();
  }
}

class _StoreStreamListenerState extends State<_StoreStreamListener> {
  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit(widget.store);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.rebuildOnChange
        ? new StreamBuilder(
            stream: widget.stream,
            builder: (context, snapshot) => widget.builder(
                  context,
                  snapshot.hasData
                      ? snapshot.data
                      : widget.converter(widget.store),
                ),
          )
        : widget.builder(context, widget.converter(widget.store));
  }
}
