import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// One simple action: Increment
enum Actions { Increment }

// The reducer, which takes the previous count and increments it in response
// to an Increment action.
int counterReducer(int state, dynamic action) {
  if (action == Actions.Increment) {
    return state + 1;
  }

  return state;
}

void main() {
  // Create your store as a final variable in a base Widget. This works better
  // with Hot Reload than creating it directly in the `build` function.
  final store = Store<int>(counterReducer, initialState: 0);

  runApp(FlutterReduxApp(
    title: 'Flutter Redux Demo',
    store: store,
  ));
}

class FlutterReduxApp extends StatelessWidget {
  final Store<int> store;
  final String title;

  FlutterReduxApp({Key key, this.store, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: title,
      home: StoreProvider<int>(
        // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
        // Widgets will find and use this value as the `Store`.
        store: store,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You have pushed the button this many times:',
                ),
                // Connect the Store to a Text Widget that renders the current
                // count.
                //
                // We'll wrap the Text Widget in a `StoreConnector` Widget. The
                // `StoreConnector` will find the `Store` from the nearest
                // `StoreProvider` ancestor, convert it into a String of the
                // latest count, and pass that String  to the `builder` function
                // as the `count`.
                //
                // Every time the button is tapped, an action is dispatched and
                // run through the reducer. After the reducer updates the state,
                // the Widget will be automatically rebuilt with the latest
                // count. No need to manually manage subscriptions or Streams!
                new StoreConnector<int, String>(
                  converter: (store) => store.state.toString(),
                  builder: (context, count) => Text(
                        count,
                        style: Theme.of(context).textTheme.display1,
                      ),
                )
              ],
            ),
          ),
          // Connect the Store to a FloatingActionButton. In this case, we'll
          // use the Store to build a callback that with dispatch an Increment
          // Action.
          //
          // Then, we'll pass this callback to the button's `onPressed` handler.
          floatingActionButton: new StoreConnector<int, VoidCallback>(
            converter: (store) {
              // Return a `VoidCallback`, which is a fancy name for a function
              // with no parameters. It only dispatches an Increment action.
              return () => store.dispatch(Actions.Increment);
            },
            builder: (context, callback) => FloatingActionButton(
                  // Attach the `callback` to the `onPressed` attribute
                  onPressed: callback,
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
                ),
          ),
        ),
      ),
    );
  }
}
