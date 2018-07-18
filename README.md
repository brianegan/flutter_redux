# flutter_redux

[![Build Status](https://travis-ci.org/brianegan/flutter_redux.svg?branch=master)](https://travis-ci.org/brianegan/flutter_redux)  [![codecov](https://codecov.io/gh/brianegan/flutter_redux/branch/master/graph/badge.svg)](https://codecov.io/gh/brianegan/flutter_redux)

A set of utilities that allow you to easily consume a [Redux](https://pub.dartlang.org/packages/redux) Store to build Flutter Widgets.

This package is built to work with [Redux.dart](https://pub.dartlang.org/packages/redux) 3.0.0+.

## Redux Widgets 

  * `StoreProvider` - The base Widget. It will pass the given Redux Store to all descendants that request it.
  * `StoreBuilder` - A descendant Widget that gets the Store from a `StoreProvider` and passes it to a Widget `builder` function.
  * `StoreConnector` - A descendant Widget that gets the Store from the nearest `StoreProvider` ancestor, converts the `Store` into a `ViewModel` with the given `converter` function, and passes the `ViewModel` to a `builder` function. Any time the Store emits a change event, the Widget will automatically be rebuilt. No need to manage subscriptions!
  
## Dart Versions

  * Dart 1: 0.3.x
  * Dart 2: 0.4.0+. See the migration guide below!
  
## Dart 2 Migration Guide

Dart 2 requires more strict typing (yay!), and gives us the option to make getting the Store from the StoreProvider more convenient!

  1. Ensure you are using Redux 3.0.0+
  2. Change `new StoreProvider(...)` to `new StoreProvider<StateClass>(...)` in your Widget tree. 
  3. Change `new StoreProvider.of(context).store` to `StoreProvider.of<StateClass>(context)` if you're directly fetching the `Store<AppState>` yourself from the `StoreProvider<AppState>`. No need to access the `store` field directly any more since Dart 2 can now infer the proper type with a static function :)

## Examples

  * [Simple example](https://github.com/brianegan/flutter_redux/tree/master/example/counter) - a port of the standard "Counter Button" example from Flutter
  * [Github Search](https://github.com/brianegan/flutter_redux/tree/master/example/github_search) - an example of how to search as a user types, demonstrating both the Middleware and Epic approaches.
  * [Todo app](https://github.com/brianegan/flutter_architecture_samples/tree/master/example/redux) - a more complete example, with persistence, routing, and nested state.
  
### Companion Libraries

  * [flutter_redux_dev_tools](https://pub.dartlang.org/packages/flutter_redux_dev_tools) - Time Travel Dev Tools for Flutter Redux apps
  * [redux_persist](https://github.com/Cretezy/redux_persist) - Persist Redux State   
 
## Usage

Let's demo the basic usage with the all-time favorite: A counter example!

Note: This example requires flutter_redux 0.4.0+ and Dart 2! If you're using Dart 1, [see the old example](https://github.com/brianegan/flutter_redux/blob/eb4289795a5a70517686ccd1d161abdb8cc08af5/example/lib/main.dart).

```dart
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
  final store = new Store<int>(counterReducer, initialState: 0);

  runApp(new FlutterReduxApp(
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
    // The StoreProvider should wrap your MaterialApp or WidgetsApp. This will
    // ensure all routes have access to the store.
    return new StoreProvider<int>(
      // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
      // Widgets will find and use this value as the `Store`.
      store: store,
      child: new MaterialApp(
        theme: new ThemeData.dark(),
        title: title,
        home: new Scaffold(
          appBar: new AppBar(
            title: new Text(title),
          ),
          body: new Center(
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
                  builder: (context, count) {
                    return new Text(
                      count,
                      style: Theme.of(context).textTheme.display1,
                    );
                  },
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
            builder: (context, callback) {
              return new FloatingActionButton(
                // Attach the `callback` to the `onPressed` attribute
                onPressed: callback,
                tooltip: 'Increment',
                child: new Icon(Icons.add),
              );
            },
          ),
        ),
      ),
    );
  }
}
```    

## Purpose

One question that [reasonable people might ask](https://www.reddit.com/r/FlutterDev/comments/6vscdy/a_set_of_utilities_that_allow_you_to_easily/dm3ll7d/): Why do you need all of this if `StatefulWidget` exists?

My advice is the same as the original Redux.JS author: If you've got a simple app, use the simplest thing possible. In Flutter, `StatefulWidget` is perfect for a simple counter app.

However, say you have more complex app, such as an E-commerce app with a Shopping Cart. The Shopping Cart should appear on multiple screens in your app and should be updated by many different types of Widgets on those different screens (An "Add Item to Cart" Widget on all your Product Screens, "Remove Item from Cart" Widget on the Shopping Cart Screen, "Change quantity" Widgets, etc).

Additionally, you definitely want to test this logic, as it's the core business logic to your app!

Now, in this case, you could create a Testable `ShoppingCart` class as a Singleton or Create a Root `StatefulWidget` that passes the `ShoppingCart `*Down Down Down* through your widget hierarchy to the "add to cart" or "remove from cart" Widgets . 

Singletons can be problematic for testing, and Flutter doesn't have a great Dependency Injection library (such as Dagger2) just yet, so I'd prefer to avoid those.

Yet passing the ShoppingCart all over the place can get messy. It also means it's way harder to move that "Add to Item" button to a new location, b/c you'd need up update the Widgets throughout your app that passes the state down.

Furthermore, you'd need a way to Observe when the `ShoppingCart` Changes so you could rebuild your Widgets when it does (from an "Add" button to an "Added" button, as an example). 

One way to handle it would be to simply `setState` every time the `ShoppingCart` changes in your Root Widget, but then your whole app below the RootWidget would be required to rebuild as well! Flutter is fast, but we should be smart about what we ask Flutter to rebuild!

Therefore, `redux` & `redux_flutter` was born for more complex stories like this one. It gives you a set of tools that allow your Widgets to `dispatch` actions in a naive way, then write the business logic in another place that will take those actions and update the `ShoppingCart` in a safe, testable way. 

Even more, once the `ShoppingCart` has been updated in the `Store`, the `Store` will emit an `onChange` event. This lets you listen to `Store` updates and rebuild your UI in the right places when it changes! Now, you can separate your business logic from your UI logic in a testable, observable way, without having to Wire up a bunch of stuff yourself! 

Similar patterns in Android are the MVP Pattern, or using Rx Observables to manage a View's state.

`flutter_redux` simply handles passing your `Store` down to all of your descendant `StoreConnector` Widgets. If your State emits a change event, only the `StoreConnector` Widgets and their descendants will be automatically rebuilt with the latest state of the `Store`! 

This allows you to focus on what your app should look like and how it should work without thinking about all the glue code to hook everything together!

### Contributors

  * [Brian Egan](https://github.com/brianegan)
  * [Chris Bird](https://github.com/chrisabird)
