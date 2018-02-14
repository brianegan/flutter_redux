import 'dart:async';

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

// The Actions our app supports
enum Actions { increment }

// A special type of action that contains a `Completer`. You can return the
// `action.completer.future` to a RefreshIndicator's `onRefresh` function.
//
// Within your middleware that intercepts this action and performs the async
// work, you should call `action.completer.complete()` after the async task is
// complete to let the RefreshIndicator know it's time to hide the spinner.
class CompletableAction {
  final Completer completer;

  CompletableAction({Completer completer})
      : this.completer = completer ?? new Completer();
}

// The reducer, which takes the previous count and increments it in response
// to an Increment action.
int counterReducer(int state, dynamic action) {
  if (action == Actions.increment) {
    return state + 1;
  }

  return state;
}

// The Middleware that intercepts the CompletableAction, makes an "api call" and
// then completes an action.
void refreshIncrementMiddleware(
  Store<int> store,
  dynamic action,
  NextDispatcher next,
) {
  if (action is CompletableAction) {
    // Make an "api call"
    new Future.delayed(new Duration(seconds: 1), () {
      // As an example, the api will return the increment Action.
      return Actions.increment;
    }).then((result) {
      // Dispatch the result of the Future or a custom payload.
      store.dispatch(result);
      action.completer.complete();
    });
  }

  next(action);
}

Future fetch() async {}

void main() {
  // Create your store as a final variable in a base Widget. This works better
  // with Hot Reload than creating it directly in the `build` function.
  final store = new Store<int>(
    counterReducer,
    initialState: 0,
    // Add our middleware to the app
    middleware: [refreshIncrementMiddleware],
  );

  runApp(new FlutterReduxApp(store: store));
}

class FlutterReduxApp extends StatefulWidget {
  final Store<int> store;

  FlutterReduxApp({Key key, this.store}) : super(key: key);

  @override
  _FlutterReduxAppState createState() => new _FlutterReduxAppState();
}

class _FlutterReduxAppState extends State<FlutterReduxApp> {
  @override
  Widget build(BuildContext context) {
    final title = 'Flutter Redux Demo';

    return new MaterialApp(
      theme: new ThemeData.dark(),
      title: title,
      home: new StoreProvider(
        // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
        // Widgets will find and use this value as the `Store`.
        store: widget.store,
        child: new Scaffold(
          appBar: new AppBar(
            title: new Text(title),
          ),
          body: new RefreshIndicator(
            onRefresh: () {
              final action = new CompletableAction();

              // Since we have access to the store here, we'll directly call it.
              // In general you'd want to use a StoreConnector or StoreBuilder,
              // but this is just a quick example.
              widget.store.dispatch(action);

              // Return the Future from the action. Your middleware should
              // complete this Future after it's done it's async work.
              return action.completer.future;
            },
            child: new ListView(
              children: [
                new Padding(
                  padding: new EdgeInsets.symmetric(vertical: 64.0),
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Text(
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
                        builder: (context, count) => new Text(
                              count,
                              style: Theme.of(context).textTheme.display1,
                            ),
                      )
                    ],
                  ),
                ),
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
              return () => store.dispatch(Actions.increment);
            },
            builder: (context, callback) => new FloatingActionButton(
                  // Attach the `callback` to the `onPressed` attribute
                  onPressed: callback,
                  tooltip: 'Increment',
                  child: new Icon(Icons.add),
                ),
          ),
        ),
      ),
    );
  }
}
