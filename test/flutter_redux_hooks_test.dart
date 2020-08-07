import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show HookBuilder;
import 'package:flutter_redux_hooks/flutter_redux_hooks.dart';
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
      Widget widget(String state) {
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

  group('useStore', () {
    testWidgets('should yield the same store', (tester) async {
      Store<String> result;
      final store = Store<String>(
        identityReducer,
        initialState: 'init',
      );

      Widget Function(BuildContext) builder() {
        return (context) {
          result = useStore<String>();
          return Container();
        };
      }

      Widget widget() {
        return StoreProvider<String>(
          store: store,
          child: HookBuilder(builder: builder()),
        );
      }

      await tester.pumpWidget(widget());
      expect(result, store);
    });
  });

  group('useDispatch', () {
    testWidgets("should yield the store's dispatch function", (tester) async {
      Dispatch result;
      final store = Store<String>(
        identityReducer,
        initialState: 'init',
      );

      Widget Function(BuildContext) builder() {
        return (context) {
          result = useDispatch<String>();
          return Container();
        };
      }

      Widget widget() {
        return StoreProvider<String>(
          store: store,
          child: HookBuilder(builder: builder()),
        );
      }

      await tester.pumpWidget(widget());
      expect(result, store.dispatch);
    });
  });

  group('useSelector', () {
    Store<String> store;
    String state;

    Widget Function(BuildContext) builder() {
      return (context) {
        state = useSelector<String, String>((state) => state);
        return Container();
      };
    }

    Widget widget() {
      return StoreProvider<String>(
        store: store,
        child: HookBuilder(builder: builder()),
      );
    }

    setUp(() {
      store = Store<String>(
        identityReducer,
        initialState: 'init',
      );
    });

    tearDown(() {
      state = null;
    });

    testWidgets('should yield the initial state', (tester) async {
      await tester.pumpWidget(widget());
      expect(state, 'init');
    });

    testWidgets('should yield the state resulting from the last dispatch', (tester) async {
      await tester.pumpWidget(widget());
      store.dispatch('A');
      await tester.pumpWidget(widget());
      expect(state, 'A');
    });
  });
}

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
