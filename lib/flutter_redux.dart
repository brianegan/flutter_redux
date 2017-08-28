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
  ViewModel state,
);

/// Convert the entire [Store] into a [ViewModel]. The [ViewModel] will be used
/// to build a Widget using the [ViewModelBuilder].
typedef ViewModel StoreConverter<S, ViewModel>(
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
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final bool distinct;
  final bool rebuildOnChange;

  StoreConnector({
    @required this.builder,
    @required this.converter,
    this.distinct = false,
    Key key,
    this.rebuildOnChange = true,
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
      rebuildOnChange: rebuildOnChange);
}

/// Build a Widget by passing the [Store] directly to the build function.
///
/// Generally, it's considered best practice to use the [StoreConnector] and to
/// build a `ViewModel` specifically for your Widget rather than passing through
/// the entire [Store], but this is provided for convenience when that isn't
/// necessary.
class StoreBuilder<S> extends StatelessWidget {
  static Store<S> _identity<S>(Store<S> store) => store;

  final ViewModelBuilder<Store<S>> builder;
  final bool rebuildOnChange;

  StoreBuilder({@required this.builder, Key key, this.rebuildOnChange = true})
      : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) => new StoreConnector<S, Store<S>>(
        builder: builder,
        converter: _identity,
        rebuildOnChange: rebuildOnChange,
      );
}

/// Listens to the [Store] and calls [builder] whenever [store] changes.
class _StoreStreamListener<S, ViewModel> extends StatelessWidget {
  final Stream<ViewModel> stream;
  final ViewModelBuilder<ViewModel> builder;
  final StoreConverter<S, ViewModel> converter;
  final Store<S> store;
  final bool rebuildOnChange;

  _StoreStreamListener._({
    @required this.builder,
    @required this.stream,
    @required this.store,
    @required this.converter,
    this.rebuildOnChange = true,
    Key key,
  })
      : super(key: key);

  factory _StoreStreamListener({
    @required Store<S> store,
    @required StoreConverter<S, ViewModel> converter,
    @required ViewModelBuilder<ViewModel> builder,
    bool distinct = false,
    bool rebuildOnChange = true,
    Key key,
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

    return new _StoreStreamListener._(
      builder: builder,
      stream: stream,
      converter: converter,
      store: store,
      key: key,
      rebuildOnChange: rebuildOnChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return rebuildOnChange
        ? new StreamBuilder(
            stream: stream,
            builder: (context, snapshot) => builder(
                  context,
                  snapshot.hasData ? snapshot.data : converter(store),
                ),
          )
        : builder(context, converter(store));
  }
}
