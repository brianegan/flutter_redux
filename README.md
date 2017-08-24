# flutter_redux

[![build status](https://gitlab.com/brianegan/flutter_redux/badges/master/build.svg)](https://gitlab.com/brianegan/flutter_redux/commits/master)  [![coverage report](https://gitlab.com/brianegan/flutter_redux/badges/master/coverage.svg)](https://brianegan.gitlab.io/flutter_redux/coverage/)

A set of utilities that allow you to easily consume a [Redux](https://pub.dartlang.org/packages/redux) Store to build Flutter Widgets.

This package is built to work with [Redux.dart](https://pub.dartlang.org/packages/redux). If you use Greencat, check out [flutter_greencat](https://pub.dartlang.org/packages/flutter_greencat). 

## Redux Widgets 

  * `StoreProvider` - The base Widget. It will pass the given Redux Store to all descendants that request it.
  * `StoreBuilder` - A descendant Widget that gets the Store from a `StoreProvider` and passes it to a Widget `builder` function.
  * `StoreConnector` - A descendant Widget that gets the Store from the nearest `StoreProvider` ancestor, converts the `Store` into a `ViewModel` with the given `converter` function, and passes the `ViewModel` to a `builder` function. Any time the Store emits a change event, the Widget will automatically be rebuilt. No need to manage subscriptions!

## Usage

Let's demo the basic usage with the all-time favorite: A counter example!

```dart
// Start by creating your normal "Redux Setup." 
// 
// First, we'll create one action: Increment.  Second, we need a reducer which
// can take this action and update the current count in response.
enum Actions { Increment }

// The reducer, which takes the previous count and increments it in response
// to an Increment action.
class CounterReducer extends Reducer<int, Actions> {
  @override
  int reduce(int state, Actions action) {
    switch (action) {
      case Actions.Increment:
        return (state + 1);
      default:
        return state;
    }
  }
}

// This class represents the data that will be passed to the `builder` function.
//
// In our case, we need only two pieces of data: The current count and a
// callback function that we can attach to the increment button.
//
// The callback will be responsible for dispatching an Increment action.
//
// If you come from React, think of this as your PropTypes, but in a type-safe
// world!
class ViewModel {
  final int count;
  final VoidCallback onIncrementPressed;

  ViewModel(
    this.count,
    this.onIncrementPressed,
  );

  factory ViewModel.fromStore(Store<int, Actions> store) {
    return new ViewModel(
      store.state,
      () => store.dispatch(Actions.Increment),
    );
  }
}

void main() {
  runApp(new FlutterReduxApp());
}

class FlutterReduxApp extends StatelessWidget {
  // Create your store as a final variable in a base Widget. This works better
  // with Hot Reload than creating it directly in the `build` function.
  final store = new Store(new CounterReducer(), initialState: 0);

  @override
  Widget build(BuildContext context) {
    final title = 'Flutter Redux Demo';

    return new MaterialApp(
      theme: new ThemeData.dark(),
      title: title,
      home: new StoreProvider(
        // Pass the store to the StoreProvider. Any ancestor `StoreConnector`
        // Widgets will find and use this value as the `Store`.
        store: store,
        // Our child will be a `StoreConnector` Widget. The `StoreConnector`
        // will find the `Store` from the nearest `StoreProvider` ancestor,
        // convert it into a ViewModel, and pass that ViewModel to the
        // `builder` function.
        //
        // Every time the button is tapped, an action is dispatched and run
        // through the reducer. After the reducer updates the state, the Widget
        // will be automatically rebuilt. No need to manually manage
        // subscriptions or Streams!
        child: new StoreConnector<int, Actions, ViewModel>(
          // Convert the store into a ViewModel. This ViewModel will be passed
          // to the `builder` below as the second argument.
          converter: (store) => new ViewModel.fromStore(store),

          // Take the `ViewModel` created by the `converter` function above and
          // build a Widget with the data!
          builder: (context, viewModel) {
            return new Scaffold(
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
                    new Text(
                      // Grab the latest count from the ViewModel
                      viewModel.count.toString(),
                      style: Theme.of(context).textTheme.display1,
                    ),
                  ],
                ),
              ),
              floatingActionButton: new FloatingActionButton(
                // Attach the ViewModel's callback to the Floating Action Button
                // The callback simply dispatches the `Increment` action.
                onPressed: viewModel.onIncrementPressed,
                tooltip: 'Increment',
                child: new Icon(Icons.add),
              ),
            );
          },
        ),
      ),
    );
  }
}
```  
