import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

void main() {
  group('StoreProvider', () {
    testWidgets('passes a Redux Store down to its descendants',
        (WidgetTester tester) async {
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreCaptor<String>(),
      );

      await tester.pumpWidget(widget);

      StoreCaptor captor =
          tester.firstWidget(find.byKey(StoreCaptor.captorKey));

      expect(captor.store, store);
    });

    testWidgets('should update the children if the store changes',
        (WidgetTester tester) async {
      Widget widget([String state]) {
        return new StoreProvider<String>(
          store: new Store<String>(
            identityReducer,
            initialState: state,
          ),
          child: new StoreCaptor<String>(),
        );
      }

      await tester.pumpWidget(widget("I"));
      await tester.pumpWidget(widget("A"));

      StoreCaptor captor =
          tester.firstWidget(find.byKey(StoreCaptor.captorKey));

      expect(captor.store.state, "A");
    });
  });

  group('StoreConnector', () {
    testWidgets('initially builds from the current state of the store',
        (WidgetTester tester) async {
      final widget = new StoreProvider<String>(
        store: new Store<String>(identityReducer, initialState: "I"),
        child: new StoreBuilder<String>(
          builder: (context, store) {
            return new Text(
              store.state,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text("I"), findsOneWidget);
    });

    testWidgets('can convert the store to a ViewModel',
        (WidgetTester tester) async {
      final widget = new StoreProvider<String>(
        store: new Store<String>(identityReducer, initialState: "I"),
        child: new StoreConnector<String, String>(
          converter: selector,
          builder: (context, latest) {
            return new Text(
              latest,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text("I"), findsOneWidget);
    });

    testWidgets('builds the latest state of the store after a change event',
        (WidgetTester tester) async {
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreBuilder<String>(
          builder: (context, store) {
            return new Text(
              store.state,
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      // Dispatch a action
      store.dispatch("A");

      // Build the widget again with the state
      await tester.pumpWidget(widget);

      expect(find.text("A"), findsOneWidget);
    });

    testWidgets('rebuilds by default whenever the store emits a change',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreConnector<String, String>(
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return new Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch the exact same event. This should still trigger a rebuild
      store.dispatch("I");

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });

    testWidgets('does not rebuild if rebuildOnChange is set to false',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreConnector<String, String>(
          converter: selector,
          rebuildOnChange: false,
          builder: (context, latest) {
            numBuilds++;

            return new Container();
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
      store.dispatch("I");

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);
    });

    testWidgets('does not rebuild if ignoreChange returns true',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreConnector<String, String>(
          ignoreChange: (dynamic state) => state == 'N',
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return new Container();
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

    testWidgets('optionally runs a function when initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final counter = CallCounter<Store<String>>();
      final store = new Store<String>(
        identityReducer,
        initialState: "A",
      );
      final Widget Function() widget = () {
        return new StoreProvider<String>(
          store: store,
          child: new StoreConnector<String, String>(
            onInit: counter,
            converter: selector,
            builder: (context, latest) {
              numBuilds++;

              return new Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(counter.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch("A");

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(counter.callCount, 1);

      store.dispatch("just to be sure");

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
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final Widget Function() widget = () {
        return new StoreProvider<String>(
          store: store,
          child: new StoreConnector<String, String>(
            converter: selector,
            onInit: (store) {
              store.dispatch("A");
            },
            builder: (context, state) {
              currentState = state;
              return new Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(currentState, "A");
    });

    testWidgets('optionally runs a function before rebuild',
        (WidgetTester tester) async {
      final counter = new CallCounter<String>();
      final store = new Store<String>(identityReducer, initialState: "A");

      final widget = () => new StoreProvider<String>(
            store: store,
            child: new StoreConnector<String, String>(
              onWillChange: counter,
              converter: (store) => store.state,
              builder: (context, latest) => new Container(),
            ),
          );

      await tester.pumpWidget(widget());

      expect(counter.callCount, 0);

      store.dispatch("A");
      await tester.pumpWidget(widget());

      expect(counter.callCount, 1);
    });

    testWidgets('optionally runs a function when disposed',
        (WidgetTester tester) async {
      final counter = CallCounter<Store<String>>();
      final store = new Store<String>(
        identityReducer,
        initialState: "A",
      );
      final Widget Function() widget = () {
        return new StoreProvider<String>(
          store: store,
          child: new StoreConnector<String, String>(
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

      store.dispatch("A");

      // Rebuild a different widget tree. Expect this to trigger `onDispose`.
      await tester.pumpWidget(Container());

      expect(counter.callCount, 1);
    });

    testWidgets('StoreBuilder also runs a function when initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final counter = CallCounter<Store<String>>();
      final store = new Store<String>(
        identityReducer,
        initialState: "A",
      );
      final Widget Function() widget = () {
        return new StoreProvider<String>(
          store: store,
          child: new StoreBuilder<String>(
            onInit: counter,
            builder: (context, store) {
              numBuilds++;

              return new Container();
            },
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(counter.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch("A");

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(counter.callCount, 1);

      store.dispatch("just to be sure");

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a third time.
      expect(numBuilds, 3);
      expect(counter.callCount, 1);
    });

    testWidgets('StoreBuilder also optionally runs a function before rebuild',
        (WidgetTester tester) async {
      final counter = new CallCounter<Store<String>>();
      final store = new Store(identityReducer, initialState: "A");

      final widget = () => new StoreProvider(
            store: store,
            child: new StoreBuilder<String>(
              onWillChange: counter,
              builder: (context, latest) => new Container(),
            ),
          );

      await tester.pumpWidget(widget());

      expect(counter.callCount, 0);

      store.dispatch("A");
      await tester.pumpWidget(widget());

      expect(counter.callCount, 1);
    });

    testWidgets('StoreBuilder also runs a function when disposed',
        (WidgetTester tester) async {
      final counter = CallCounter<Store<String>>();
      final store = new Store<String>(
        identityReducer,
        initialState: "init",
      );
      final Widget Function() widget = () {
        return new StoreProvider<String>(
          store: store,
          child: new StoreBuilder<String>(
            onDispose: counter,
            builder: (context, store) => Container(),
          ),
        );
      };

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      expect(counter.callCount, 0);

      store.dispatch("A");

      // Rebuild a different widget, should trigger a dispose as the
      // StoreBuilder has been removed from the Widget tree.
      await tester.pumpWidget(Container());

      expect(counter.callCount, 1);
    });

    testWidgets(
        'avoids rebuilds when distinct is used with a class that implements ==',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final store = new Store<String>(
        identityReducer,
        initialState: "I",
      );
      final widget = new StoreProvider<String>(
        store: store,
        child: new StoreConnector<String, String>(
          // Same exact setup as the previous test, but distinct is set to true.
          distinct: true,
          converter: selector,
          builder: (context, latest) {
            numBuilds++;

            return new Container();
          },
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch another action of the same type
      store.dispatch("I");

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch another action of a different type. This should trigger another
      // rebuild
      store.dispatch("A");

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });
  });
}

String selector(Store<String> store) => store.state;

// ignore: must_be_immutable
class StoreCaptor<S> extends StatelessWidget {
  static const Key captorKey = const Key("StoreCaptor");

  Store<S> store;

  StoreCaptor() : super(key: captorKey);

  @override
  Widget build(BuildContext context) {
    store = StoreProvider.of<S>(context);

    return new Container();
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
