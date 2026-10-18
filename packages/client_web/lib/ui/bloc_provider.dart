import "dart:async";

import "package:bloc/bloc.dart";
import "package:jaspr/jaspr.dart";

class BlocProvider<T extends BlocBase<Object?>> extends InheritedComponent {
  final T bloc;

  const BlocProvider({required this.bloc, required super.child, super.key});

  @override
  bool updateShouldNotify(BlocProvider<T> oldComponent) {
    return oldComponent.bloc != bloc;
  }

  static T of<T extends BlocBase<Object?>>(BuildContext context) {
    final provider = context
        .dependOnInheritedComponentOfExactType<BlocProvider<T>>();
    if (provider == null) {
      throw Exception("BlocProvider<$T> not found in context");
    }
    return provider.bloc;
  }

  static T? maybeOf<T extends BlocBase<Object?>>(BuildContext context) {
    final provider = context
        .dependOnInheritedComponentOfExactType<BlocProvider<T>>();
    return provider?.bloc;
  }
}

class BlocListener<B extends BlocBase<S>, S> extends StatefulComponent {
  final B? bloc;
  final void Function(BuildContext context, S state) listener;
  final Component child;

  const BlocListener({
    super.key,
    this.bloc,
    required this.listener,
    required this.child,
  });

  @override
  State<BlocListener<B, S>> createState() => _BlocListenerState<B, S>();
}

class _BlocListenerState<B extends BlocBase<S>, S>
    extends State<BlocListener<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? BlocProvider.of<B>(context);
    _subscribe();
  }

  @override
  void didUpdateComponent(BlocListener<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final oldBloc = oldComponent.bloc ?? BlocProvider.of<B>(context);
    final currentBloc = component.bloc ?? BlocProvider.of<B>(context);
    if (oldBloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      component.listener(context, state);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Component build(BuildContext context) {
    return component.child;
  }
}

class BlocBuilder<B extends BlocBase<S>, S> extends StatefulComponent {
  final B? bloc;
  final Component Function(BuildContext context, S state) builder;

  /// Whether to rebuild for a new state, given the previous one. Rebuilds for
  /// every state when null.
  final bool Function(S previous, S current)? buildWhen;

  const BlocBuilder({
    super.key,
    this.bloc,
    required this.builder,
    this.buildWhen,
  });

  @override
  State<BlocBuilder<B, S>> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends BlocBase<S>, S>
    extends State<BlocBuilder<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _bloc;
  late S _state;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? BlocProvider.of<B>(context);
    _state = _bloc.state;
    _subscribe();
  }

  @override
  void didUpdateComponent(BlocBuilder<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final currentBloc = component.bloc ?? BlocProvider.of<B>(context);
    if (_bloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _state = _bloc.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      final bool Function(S, S)? buildWhen = component.buildWhen;
      final S previous = _state;
      if (buildWhen != null && !buildWhen(previous, state)) {
        _state = state;
        return;
      }
      setState(() {
        _state = state;
      });
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _state);
  }
}

class BlocConsumer<B extends BlocBase<S>, S> extends StatefulComponent {
  final B? bloc;
  final void Function(BuildContext context, S state) listener;
  final Component Function(BuildContext context, S state) builder;

  const BlocConsumer({
    super.key,
    this.bloc,
    required this.listener,
    required this.builder,
  });

  @override
  State<BlocConsumer<B, S>> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends BlocBase<S>, S>
    extends State<BlocConsumer<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _bloc;
  late S _state;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? BlocProvider.of<B>(context);
    _state = _bloc.state;
    _subscribe();
  }

  @override
  void didUpdateComponent(BlocConsumer<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final currentBloc = component.bloc ?? BlocProvider.of<B>(context);
    if (_bloc != currentBloc) {
      _unsubscribe();
      _bloc = currentBloc;
      _state = _bloc.state;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = _bloc.stream.listen((state) {
      component.listener(context, state);
      setState(() {
        _state = state;
      });
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _state);
  }
}
