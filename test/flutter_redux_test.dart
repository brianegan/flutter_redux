import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

void main() {
  group('StoreProvider', () {
    testWidgets('passes a Redux Store down to its descendants',
        (WidgetTester tester) async {
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreCaptor<String>(),
      );

      await tester.pumpWidget(widget);

      final captor =
          tester.firstWidget<StoreCaptor>(find.byKey(StoreCaptor.captorKey));

      expect(captor.store, store);
    });

    testWidgets('throws a helpful message if no provider found',
        (WidgetTester tester) async {
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreCaptor<int>(),
      );

      await tester.pumpWidget(widget);

      expect(tester.takeException(), isInstanceOf<StoreProviderError>());
    });

    testWidgets('should update the children if the store changes',
        (WidgetTester tester) async {
      Widget widget([String state]) {
        return StoreProvider<String>(
          store: Store<String>(
            identityReducer,
            initialState: state,
          ),
          child: StoreCaptor<String>(),
        );
      }

      await tester.pumpWidget(widget('I'));
      await tester.pumpWidget(widget('A'));

      final captor =
          tester.firstWidget<StoreCaptor>(find.byKey(StoreCaptor.captorKey));

      expect(captor.store.state, 'A');
    });
  });

  group('StoreConnector', () {
    testWidgets('initially builds from the current state of the store',
        (WidgetTester tester) async {
      final widget = StoreProvider<String>(
        store: Store<String>(identityReducer, initialState: 'I'),
        child: StoreBuilder<String>(
          builder: (context, store) {
            return Text(
              store.state,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('I'), findsOneWidget);
    });

    testWidgets('can convert the store to a ViewModel',
        (WidgetTester tester) async {
      final widget = StoreProvider<String>(
        store: Store<String>(identityReducer, initialState: 'I'),
        child: StoreConnector<String, String>(
          converter: selector,
          builder: (context, latest) {
            return Text(
              latest,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('I'), findsOneWidget);
    });

    testWidgets('builds the latest state of the store after a change event',
        (WidgetTester tester) async {
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreBuilder<String>(
          builder: (context, store) {
            return Text(
              store.state,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      // Dispatch a action
      store.dispatch('A');

      // Build the widget again with the state
      await tester.pumpWidget(widget);

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('rebuilds by default whenever the store emits a change',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreConnector<String, String>(
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch the exact same event. This should still trigger a rebuild
      store.dispatch('I');

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });

    testWidgets('does not rebuild if rebuildOnChange is set to false',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreConnector<String, String>(
          converter: selector,
          rebuildOnChange: false,
          builder: (context, latest) {
            numBuilds++;

            return Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch the exact same event. This will cause a change on the Store,
      // but would result in no change to the UI since `rebuildOnChange` is
      // false.
      //
      // By default, this should still trigger a rebuild
      store.dispatch('I');

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);
    });

    testWidgets('does not rebuild if ignoreChange returns true',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreConnector<String, String>(
          ignoreChange: (dynamic state) => state == 'N',
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch a null value. This will cause a change on the Store,
      // but would result in no rebuild since the `converter` is returning
      // this null value.
      store.dispatch('N');

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);
    });

    testWidgets('runs a function when initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final counter = CallCounter<Store<String>>();
      final store = Store<String>(
        identityReducer,
        initialState: 'A',
      );
      final Widget Function() widget = () {
        return StoreProvider<String>(
          store: store,
          child: StoreConnector<String, String>(
            onInit: counter,
            converter: selector,
            builder: (context, latest) {
              numBuilds++;

              return Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(counter.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch('A');

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(counter.callCount, 1);

      store.dispatch('just to be sure');

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a third time.
      expect(numBuilds, 3);
      expect(counter.callCount, 1);
    });

    testWidgets('onInit is called before the first ViewModel is built',
        (WidgetTester tester) async {
      String currentState;
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final Widget Function() widget = () {
        return StoreProvider<String>(
          store: store,
          child: StoreConnector<String, String>(
            converter: selector,
            onInit: (store) {
              store.dispatch('A');
            },
            builder: (context, state) {
              currentState = state;
              return Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(currentState, 'A');
    });

    testWidgets('runs a function before rebuild', (WidgetTester tester) async {
      final states = <BuildState>[];
      final store = Store<String>(identityReducer, initialState: 'A');

      final widget = () => StoreProvider<String>(
            store: store,
            child: StoreConnector<String, String>(
              onWillChange: (_) => states.add(BuildState.before),
              converter: (store) => store.state,
              builder: (context, latest) {
                states.add(BuildState.during);
                return Container();
              },
            ),
          );

      await tester.pumpWidget(widget());

      expect(states, [BuildState.during]);

      store.dispatch('A');
      await tester.pumpWidget(widget());

      expect(states, [BuildState.during, BuildState.before, BuildState.during]);
    });

    testWidgets('runs a function after initial build',
        (WidgetTester tester) async {
      final states = <BuildState>[];
      final store = Store<String>(identityReducer, initialState: 'A');

      final widget = () => StoreProvider<String>(
            store: store,
            child: StoreConnector<String, String>(
              onInitialBuild: (_) => states.add(BuildState.after),
              converter: (store) => store.state,
              builder: (context, latest) {
                states.add(BuildState.during);
                return Container();
              },
            ),
          );

      await tester.pumpWidget(widget());

      expect(states, [BuildState.during, BuildState.after]);

      // Should not run the onInitialBuild function again
      await tester.pump();
      expect(states, [BuildState.during, BuildState.after]);
    });

    testWidgets('runs a function after build when the vm changes',
        (WidgetTester tester) async {
      final states = <BuildState>[];
      final store = Store<String>(identityReducer, initialState: 'A');

      final widget = () => StoreProvider<String>(
            store: store,
            child: StoreConnector<String, String>(
              onDidChange: (_) => states.add(BuildState.after),
              converter: (store) => store.state,
              builder: (context, latest) {
                states.add(BuildState.during);
                return Container();
              },
            ),
          );

      // Does not initially call callback
      await tester.pumpWidget(widget());
      expect(states, [BuildState.during]);

      // Runs the callback after the second build
      store.dispatch('N');
      await tester.pumpWidget(widget());
      expect(states, [BuildState.during, BuildState.during, BuildState.after]);

      // Does not run the callback if the VM has not changed
      await tester.pumpWidget(widget());
      expect(states, [
        BuildState.during,
        BuildState.during,
        BuildState.after,
        BuildState.during,
      ]);
    });

    testWidgets('runs a function when disposed', (WidgetTester tester) async {
      final counter = CallCounter<Store<String>>();
      final store = Store<String>(
        identityReducer,
        initialState: 'A',
      );
      final Widget Function() widget = () {
        return StoreProvider<String>(
          store: store,
          child: StoreConnector<String, String>(
            onDispose: counter,
            converter: selector,
            builder: (context, latest) => Container(),
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // onDispose should not be called yet.
      expect(counter.callCount, 0);

      store.dispatch('A');

      // Rebuild a different widget tree. Expect this to trigger `onDispose`.
      await tester.pumpWidget(Container());

      expect(counter.callCount, 1);
    });

    testWidgets(
        'avoids rebuilds when distinct is used with a class that implements ==',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = Store<String>(
        identityReducer,
        initialState: 'I',
      );
      final widget = StoreProvider<String>(
        store: store,
        child: StoreConnector<String, String>(
          // Same exact setup as the previous test, but distinct is set to true.
          distinct: true,
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch another action of the same type
      store.dispatch('I');

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch another action of a different type. This should trigger another
      // rebuild
      store.dispatch('A');

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });
  });

  group('StoreBuilder', () {
    testWidgets('runs a function when initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final counter = CallCounter<Store<String>>();
      final store = Store<String>(
        identityReducer,
        initialState: 'A',
      );
      final Widget Function() widget = () {
        return StoreProvider<String>(
          store: store,
          child: StoreBuilder<String>(
            onInit: counter,
            builder: (context, store) {
              numBuilds++;

              return Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(counter.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch('A');

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(counter.callCount, 1);

      store.dispatch('just to be sure');

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a third time.
      expect(numBuilds, 3);
      expect(counter.callCount, 1);
    });

    testWidgets('runs a function before rebuild', (WidgetTester tester) async {
      final counter = CallCounter<Store<String>>();
      final store = Store(identityReducer, initialState: 'A');

      final widget = () => StoreProvider(
            store: store,
            child: StoreBuilder<String>(
              onWillChange: counter,
              builder: (context, latest) => Container(),
            ),
          );

      await tester.pumpWidget(widget());

      expect(counter.callCount, 0);

      store.dispatch('A');
      await tester.pumpWidget(widget());

      expect(counter.callCount, 1);
    });

    testWidgets('runs a function after initial build',
        (WidgetTester tester) async {
      final states = <BuildState>[];
      final store = Store<String>(identityReducer, initialState: 'A');

      final widget = () => StoreProvider<String>(
            store: store,
            child: StoreBuilder<String>(
              onInitialBuild: (_) => states.add(BuildState.after),
              builder: (context, latest) {
                states.add(BuildState.during);
                return Container();
              },
            ),
          );

      await tester.pumpWidget(widget());

      expect(states, [BuildState.during, BuildState.after]);

      // Should not run the onInitialBuild function again
      await tester.pump();
      expect(states, [BuildState.during, BuildState.after]);
    });

    testWidgets('runs a function after build when the vm changes',
        (WidgetTester tester) async {
      final states = <BuildState>[];
      final store = Store<String>(identityReducer, initialState: 'A');

      final widget = () => StoreProvider<String>(
            store: store,
            child: StoreBuilder<String>(
              onDidChange: (_) => states.add(BuildState.after),
              builder: (context, latest) {
                states.add(BuildState.during);
                return Container();
              },
            ),
          );

      // Does not initially call callback
      await tester.pumpWidget(widget());
      expect(states, [BuildState.during]);

      // Runs the callback after the second build
      store.dispatch('N');
      await tester.pumpWidget(widget());
      expect(states, [BuildState.during, BuildState.during, BuildState.after]);

      // Does not run the callback if the VM has not changed
      await tester.pumpWidget(widget());
      expect(states, [
        BuildState.during,
        BuildState.during,
        BuildState.after,
        BuildState.during,
      ]);
    });

    testWidgets('runs a function when disposed', (WidgetTester tester) async {
      final counter = CallCounter<Store<String>>();
      final store = Store<String>(
        identityReducer,
        initialState: 'init',
      );
      final Widget Function() widget = () {
        return StoreProvider<String>(
          store: store,
          child: StoreBuilder<String>(
            onDispose: counter,
            builder: (context, store) => Container(),
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      expect(counter.callCount, 0);

      store.dispatch('A');

      // Rebuild a different widget, should trigger a dispose as the
      // StoreBuilder has been removed from the Widget tree.
      await tester.pumpWidget(Container());

      expect(counter.callCount, 1);
    });
  });
}

String selector(Store<String> store) => store.state;

// ignore: must_be_immutable
class StoreCaptor<S> extends StatelessWidget {
  static const Key captorKey = Key('StoreCaptor');

  Store<S> store;

  StoreCaptor() : super(key: captorKey);

  @override
  Widget build(BuildContext context) {
    store = StoreProvider.of<S>(context);

    return Container();
  }
}

String identityReducer(String state, dynamic action) {
  return action.toString();
}

class CallCounter<S> {
  final List<S> states = [];

  int get callCount => states.length;

  void call(S state) => states.add(state);
}

enum BuildState { before, during, after }
