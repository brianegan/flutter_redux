import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';

import 'package:flutter_redux/flutter_redux.dart';

void main() {
  group('StoreProvider', () {
    testWidgets('passes a Redux Store down to its ancestors',
        (WidgetTester tester) async {
      final defaultState = "test";
      final store = new Store(
        new IdentityReducer(),
        initialState: defaultState,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreCaptor(),
      );

      await tester.pumpWidget(widget);

      StoreCaptor captor = tester.firstWidget(find.byType(StoreCaptor));

      expect(captor.store, store);
    });

    testWidgets('should update the children if the store changes',
        (WidgetTester tester) async {
      final defaultState = "test";
      final newState = "new";
      Widget widget([String state]) {
        return new StoreProvider(
          store: new Store(
            new IdentityReducer(),
            initialState: state,
          ),
          child: new StoreCaptor(),
        );
      }

      await tester.pumpWidget(widget(defaultState));
      await tester.pumpWidget(widget(newState));

      StoreCaptor captor = tester.firstWidget(find.byType(StoreCaptor));

      expect(captor.store.state, newState);
    });

    testWidgets('can run a function on Init', (WidgetTester tester) async {
      final defaultState = "test";
      final newState = "new";
      Widget widget([String state]) {
        return new StoreProvider(
          store: new Store(
            new IdentityReducer(),
            initialState: state,
          ),
          child: new StoreCaptor(),
        );
      }

      await tester.pumpWidget(widget(defaultState));
      await tester.pumpWidget(widget(newState));

      StoreCaptor captor = tester.firstWidget(find.byType(StoreCaptor));

      expect(captor.store.state, newState);
    });
  });

  group('StoreConnector', () {
    testWidgets('initially builds from the current state of the store',
        (WidgetTester tester) async {
      final initial = "initial";
      final widget = new StoreProvider(
        store: new Store(new IdentityReducer(), initialState: initial),
        child: new StoreBuilder(
          builder: (context, store) => new Text(
                store.state,
                textDirection: TextDirection.ltr,
              ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text(initial), findsOneWidget);
    });

    testWidgets('can convert the store to a ViewModel',
        (WidgetTester tester) async {
      final initial = "initial";
      final widget = new StoreProvider(
        store: new Store(new IdentityReducer(), initialState: initial),
        child: new StoreConnector(
          converter: (store) => store.state,
          builder: (context, latest) => new Text(
                latest,
                textDirection: TextDirection.ltr,
              ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text(initial), findsOneWidget);
    });

    testWidgets('builds the latest state of the store after a change event',
        (WidgetTester tester) async {
      final initial = "initial";
      final newState = "newState";
      final store = new Store(
        new IdentityReducer(),
        initialState: initial,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreBuilder(
          builder: (context, store) => new Text(
                store.state,
                textDirection: TextDirection.ltr,
              ),
        ),
      );

      // Build the widget with the initial state
      await tester.pumpWidget(widget);

      // Dispatch a new action
      store.dispatch(newState);

      // Build the widget again with the new state
      await tester.pumpWidget(widget);

      expect(find.text(newState), findsOneWidget);
    });

    testWidgets('rebuilds by default whenever the store emits a change',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final initial = "initial";
      final store = new Store(
        new IdentityReducer(),
        initialState: initial,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreConnector(
          converter: (store) => store.state,
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
      store.dispatch(initial);

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });

    testWidgets('does not rebuild if rebuildOnChange is set to false',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final initial = "initial";
      final store = new Store(
        new IdentityReducer(),
        initialState: initial,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreConnector(
          converter: (store) => store.state,
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
      store.dispatch(initial);

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);
    });

    testWidgets('does not rebuild if rebuildOnNull is set to false',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final initial = "initial";
      final store = new Store(
        new IdentityReducer(),
        initialState: initial,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreConnector(
          converter: (store) => store.state,
          rebuildNullViewModels: false,
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
      store.dispatch(null);

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);
    });

    testWidgets('StoreBuilder also runs a function when initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final action = "action";
      final onInit = new OnInitCounter();
      final store = new Store(
        new IdentityReducer(),
        initialState: action,
      );
      final widget = () => new StoreProvider(
            store: store,
            child: new StoreBuilder(
              onInit: onInit,
              builder: (context, store) {
                numBuilds++;

                return new Container();
              },
            ),
          );

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(onInit.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch(action);

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(onInit.callCount, 1);

      store.dispatch("just to be sure");

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a third time.
      expect(numBuilds, 3);
      expect(onInit.callCount, 1);
    });

    testWidgets('optionally runs a function when the State is initialized',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final action = "action";
      final onInit = new OnInitCounter();
      final store = new Store(
        new IdentityReducer(),
        initialState: action,
      );
      final widget = () => new StoreProvider(
            store: store,
            child: new StoreConnector(
              onInit: onInit,
              converter: (store) => store.state,
              builder: (context, latest) {
                numBuilds++;

                return new Container();
              },
            ),
          );

      // Build the widget with the initial state
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt and the onInit method to be called
      expect(onInit.callCount, 1);
      expect(numBuilds, 1);

      store.dispatch(action);

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a second time.
      expect(numBuilds, 2);
      expect(onInit.callCount, 1);

      store.dispatch("just to be sure");

      // Rebuild the widget
      await tester.pumpWidget(widget());

      // Expect the Widget to be rebuilt, but the onInit method should NOT be
      // called a third time.
      expect(numBuilds, 3);
      expect(onInit.callCount, 1);
    });

    testWidgets(
        'avoids rebuilds when distinct is used with an object that implements ==',
        (WidgetTester tester) async {
      var numBuilds = 0;
      final initial = "initial";
      final store = new Store(
        new IdentityReducer(),
        initialState: initial,
      );
      final widget = new StoreProvider(
        store: store,
        child: new StoreConnector(
          // Same exact setup as the previous test, but distinct is set to true.
          distinct: true,
          converter: (store) => store.state,
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
      store.dispatch(initial);

      await tester.pumpWidget(widget);

      expect(numBuilds, 1);

      // Dispatch another action of a different type. This should trigger another
      // rebuild
      store.dispatch("new");

      await tester.pumpWidget(widget);

      expect(numBuilds, 2);
    });
  });
}

// ignore: must_be_immutable
class StoreCaptor<S, A> extends StatelessWidget {
  Store<S> store;

  StoreCaptor({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    store = new StoreProvider.of(context).store;

    return new Container();
  }
}

class IdentityReducer extends ReducerClass {
  @override
  dynamic call(state, action) {
    return action;
  }
}

class OnInitCounter {
  final List<Store> stores = [];

  int get callCount => stores.length;

  void call(Store store) => stores.add(store);
}
