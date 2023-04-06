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

  FlutterReduxApp({Key? key, required this.title}) : super(key: key);

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
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                count!,
                style: const TextStyle(color: Colors.white, fontSize: 36),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => dispatch(Actions.Increment),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
