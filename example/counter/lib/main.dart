import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  runApp(new MyApp(
    items: new List<String>.generate(100, (i) => "Item ${i + 1}"),
    store: store,
  ));
}

class MyApp extends StatelessWidget {
  final Store<int> store;
  final List<String> items;

  MyApp({
    Key key,
    @required this.items,
    @required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = 'Dismissing Items';

    return new StoreProvider<int>(
      store: store,
      child: new InputDetector(
        onInput: () => store.dispatch('Input Detected'),
        child: new MaterialApp(
          title: title,
          home: new Scaffold(
            appBar: new AppBar(
              title: new Text(title),
            ),
            body: new StoreConnector<int, int>(
              converter: (store) => store.state,
              builder: (store, vm) {
                return new ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return new Dismissible(
                      // Each Dismissible must contain a Key. Keys allow Flutter to
                      // uniquely identify Widgets.
                      key: new Key(item),
                      // We also need to provide a function that will tell our app
                      // what to do after an item has been swiped away.
                      onDismissed: (direction) {
                        items.removeAt(index);

                        Scaffold.of(context).showSnackBar(
                            new SnackBar(content: new Text("$item dismissed")));
                      },
                      // Show a red background as the item is swiped away
                      background: new Container(color: Colors.red),
                      child: new ListTile(title: new Text('$item')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class InputDetector extends StatefulWidget {
  final VoidCallback onInput;
  final Widget child;

  InputDetector({@required this.child, @required this.onInput})
      : assert(child != null),
        assert(onInput != null);

  @override
  State<StatefulWidget> createState() => new _InputDetectorState();
}

class _InputDetectorState extends State<InputDetector> {
  @override
  void initState() {
    super.initState();

    // Detect raw input from the keyboard (alas, only the hardware keyboard).
    RawKeyboard.instance.addListener(_onRawKeyEvent);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onRawKeyEvent);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var touchDetector = new Listener(
      behavior: HitTestBehavior.translucent,
      child: widget.child,
      onPointerDown: (_) => widget.onInput(),
      onPointerMove: (_) => widget.onInput(),
      onPointerCancel: (_) => widget.onInput(),
      onPointerUp: (_) => widget.onInput(),
    );

    return touchDetector;
  }

  void _onRawKeyEvent(RawKeyEvent event) => widget.onInput();
}
