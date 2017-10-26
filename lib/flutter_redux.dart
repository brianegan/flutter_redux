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

  /// For the special use case of running animations while removing items from
  /// your Store. When your [converter] runs and produces a Null value in
  /// response to a State change, you might not want to rebuild the Widget.
  /// To do so, set [rebuildNullViewModels] to false.
  ///
  /// Example Use case:
  ///
  /// Say you want to delete an Item from your Store. The new value from the
  /// Store will be immediately pushed and rendered. Yay! The Item is now
  /// removed. But wait, it was animating off screen! NullPointerException Red
  /// boxes appear everywhere!
  ///
  /// In this case, you can return a null value from your converter. If you do
  /// so, the widget will not be rebuilt.
  final bool rebuildNullViewModels;

  StoreConnector({
    Key key,
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.rebuildOnChange = true,
    this.rebuildNullViewModels = true,
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
        rebuildNullViewModels: rebuildNullViewModels,
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
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final Store<S> store;
  final bool rebuildOnChange;
  final bool distinct;
  final bool rebuildNullViewModels;
  final OnInitCallback onInit;

  _StoreStreamListener._({
    Key key,
    @required this.builder,
    @required this.store,
    @required this.converter,
    this.distinct = false,
    this.onInit,
    this.rebuildOnChange = true,
    this.rebuildNullViewModels = true,
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
    bool rebuildNullViewModels = true,
  }) {
    return new _StoreStreamListener._(
      builder: builder,
      converter: converter,
      store: store,
      key: key,
      rebuildOnChange: rebuildOnChange,
      onInit: onInit,
      distinct: distinct,
      rebuildNullViewModels: rebuildNullViewModels,
    );
  }

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
    stream = widget.store.onChange.map((_) => widget.converter(widget.store));
    latestValue = widget.converter(widget.store);

    // Don't use `Stream.distinct` because it cannot capture the initial
    // ViewModel produced by the `converter`.
    if (widget.distinct) {
      stream = stream.where((vm) {
        final isDistinct = vm != latestValue;

        return isDistinct;
      });
    }

    if (!widget.rebuildNullViewModels) {
      stream = stream.where((item) {
        return item != null;
      });
    }

    // Poor man's doOnNext. After each ViewModel is emitted from the Stream, we
    // update the latestValue. Important: This must be done after all other
    // optional transformations, such as distinct or rebuildNullViewModels.
    stream = stream
        .transform(new StreamTransformer.fromHandlers(handleData: (vm, sink) {
      latestValue = vm;
      sink.add(vm);
    }));

    if (widget.onInit != null) {
      widget.onInit(widget.store);
    }

    super.initState();
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