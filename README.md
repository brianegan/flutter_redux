# flutter_redux_hooks

[![Build Status](https://travis-ci.org/mrnkr/flutter_redux_hooks.svg?branch=master)](https://travis-ci.org/mrnkr/flutter_redux_hooks)  [![codecov](https://codecov.io/gh/mrnkr/flutter_redux_hooks/branch/master/graph/badge.svg)](https://codecov.io/gh/mrnkr/flutter_redux_hooks)

A set of utilities that allow you to easily consume a [Redux](https://pub.dartlang.org/packages/redux) Store to build Flutter Widgets.

This package is built to work with [Redux.dart](https://pub.dartlang.org/packages/redux) 3.0.0+.

This library is based on [flutter_redux](https://github.com/brianegan/flutter_redux), it actually started as a fork of that project. The implementation of `StoreProvider` available here is the same you will find in that lib, I removed the rest of the widgets offered by it and replaced them with my hooks. Clearly, I aimed to replicate the behavior of the hooks you'll find in [react-redux](https://github.com/reduxjs/react-redux), if you think I succeeded let me know by leaving a star in the repo!

## Redux Widgets

* `StoreProvider` - The base Widget. It will pass the given Redux Store to all descendants that request it.

## Redux hooks

* `useStore` - Will return a reference to the store you provided via `StoreProvider`.
* `useDispatch` - Will return a reference to the dispatch function for the store you provided via `StoreProvider`.
* `useSelector` - Will return the result of applying a selector function to the state. To make these selectors I recommend either using `reselect` or `redux_toolkit` (`redux_toolkit` exports `reselect`).
  
### Companion Libraries

* [flipperkit_redux_middleware](https://pub.dartlang.org/packages/flipperkit_redux_middleware) - Redux Inspector (use [Flutter Debugger](https://github.com/blankapp/flutter-debugger)) for Flutter Redux apps
* [flutter_redux_dev_tools](https://pub.dartlang.org/packages/flutter_redux_dev_tools) - Time Travel Dev Tools for Flutter Redux apps
* [redux_persist](https://github.com/Cretezy/redux_persist) - Persist Redux State
* [flutter_redux_navigation](https://github.com/flutterings/flutter_redux_navigation) - Use redux events for navigation
* [redux_toolkit](https://github.com/mrnkr/redux_toolkit) - Dart port of the official, opinionated, batteries-included toolset for efficient Redux development.

## Usage

Let's demo the basic usage with the all-time favorite: A counter example!

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookWidget;
import 'package:flutter_redux_hooks/flutter_redux_hooks.dart';
import 'package:redux/redux.dart';

enum Actions { Increment }

int counterReducer(int state, dynamic action) {
  if (action == Actions.Increment) {
    return state + 1;
  }

  return state;
}

void main() {
  final store = Store<int>(counterReducer, initialState: 0);

  runApp(
    StoreProvider<int>(
      store: store,
      child: FlutterReduxApp(
        title: 'Flutter Redux Demo',
      ),
    ),
  );
}

class FlutterReduxApp extends HookWidget {
  final String title;

  FlutterReduxApp({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dispatch = useDispatch<int>();
    final count = useSelector<int, String>((state) => state.toString());

    return MaterialApp(
      theme: ThemeData.dark(),
      title: title,
      home: Scaffold(
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
              Text(
                count,
                style: TextStyle(color: Colors.white, fontSize: 36),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => dispatch(Actions.Increment),
          child: Icon(Icons.add),
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

Now, in this case, you could create a Testable `ShoppingCart` class as a Singleton or Create a Root `StatefulWidget` that passes the `ShoppingCart` *Down Down Down* through your widget hierarchy to the "add to cart" or "remove from cart" Widgets .

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

* [Alvaro Nicoli](https://github.com/mrnkr)
* [Brian Egan](https://github.com/brianegan)
* [Chris Bird](https://github.com/chrisabird)
