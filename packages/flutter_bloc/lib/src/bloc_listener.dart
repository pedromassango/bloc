import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Signature for the listener function which takes the [BuildContext] along with the bloc state
/// and is responsible for executing in response to state changes.
typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for the condition function which takes the previous state and the current state
/// and is responsible for returning a `bool` which determines whether or not to call [BlocWidgetListener]
/// of [BlocListener] with the current state.
typedef BlocListenerCondition<S> = bool Function(S previous, S current);

class BlocListener<E, S> extends BlocListenerBase<E, S>
    with SingleChildCloneableWidget {
  /// The [Bloc] whose state will be listened to.
  /// Whenever the bloc's state changes, `listener` will be invoked.
  final Bloc<E, S> bloc;

  /// The [BlocWidgetListener] which will be called on every state change (including the `initialState`).
  /// This listener should be used for any code which needs to execute
  /// in response to a state change ([Transition]).
  /// The state will be the `nextState` for the most recent [Transition].
  final BlocWidgetListener<S> listener;

  /// The `condition` function will be invoked on each bloc state change.
  /// The `condition` takes the previous state and current state and must return a `bool`
  /// which determines whether or not the `listener` function will be invoked.
  /// The previous state will be initialized to `currentState` when the [BlocListener] is initialized.
  /// `condition` is optional and if it isn't implemented, it will default to return `true`.
  ///
  /// ```dart
  /// BlocListener(
  ///   bloc: BlocProvider.of<BlocA>(context),
  ///   condition: (previousState, currentState) {
  ///     // return true/false to determine whether or not
  ///     // to invoke listener with currentState
  ///   },
  ///   listener: (context, state) {
  ///     // do stuff here based on BlocA's state
  ///   }
  ///)
  /// ```
  final BlocListenerCondition<S> condition;

  /// The [Widget] which will be rendered as a descendant of the [BlocListener].
  final Widget child;

  /// Takes a [Bloc] and a [BlocWidgetListener]
  /// and invokes the listener in response to state changes in the bloc.
  /// It should be used for functionality that needs to occur only in response to a state change
  /// such as navigation, showing a [SnackBar], showing a [Dialog], etc...
  /// The `listener` is guaranteed to only be called once for each state change unlike the
  /// `builder` in [BlocBuilder].
  const BlocListener({
    Key key,
    @required this.bloc,
    @required this.listener,
    this.condition,
    this.child,
  })  : assert(bloc != null),
        assert(listener != null),
        super(
          key: key,
          bloc: bloc,
          listener: listener,
          condition: condition,
        );

  /// Clones the current [BlocListener] with a new child [Widget].
  /// All other values, including `key`, `bloc` and `listener` are preserved.
  /// preserved.
  @override
  BlocListener<E, S> cloneWithChild(Widget child) {
    return BlocListener<E, S>(
      key: key,
      bloc: bloc,
      listener: listener,
      condition: condition,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => child;
}

abstract class BlocListenerBase<E, S> extends StatefulWidget {
  /// The [Bloc] whose state will be listened to.
  /// Whenever the bloc's state changes, `listener` will be invoked.
  final Bloc<E, S> bloc;

  /// The [BlocWidgetListener] which will be called on every state change.
  /// This listener should be used for any code which needs to execute
  /// in response to a state change ([Transition]).
  /// The state will be the `nextState` for the most recent [Transition].
  final BlocWidgetListener<S> listener;

  /// The [BlocListenerCondition] that the [BlocListenerBase] will invoke.
  final BlocListenerCondition<S> condition;

  /// Base class for widgets that listen to state changes in a specified [Bloc].
  ///
  /// A [BlocListenerBase] is stateful and maintains the state subscription.
  /// The type of the state and what happens with each state change
  /// is defined by sub-classes.
  const BlocListenerBase({
    Key key,
    @required this.bloc,
    @required this.listener,
    @required this.condition,
  }) : super(key: key);

  State<BlocListenerBase<E, S>> createState() => _BlocListenerBaseState<E, S>();

  /// Returns a [Widget] based on the [BuildContext].
  Widget build(BuildContext context);
}

class _BlocListenerBaseState<E, S> extends State<BlocListenerBase<E, S>> {
  StreamSubscription<S> _subscription;
  S _previousState;

  @override
  void initState() {
    super.initState();
    _previousState = widget.bloc.currentState;
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocListenerBase<E, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bloc.state != widget.bloc.state) {
      if (_subscription != null) {
        _unsubscribe();
        _previousState = widget.bloc.currentState;
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.bloc.state != null) {
      _subscription = widget.bloc.state.skip(1).listen((S state) {
        if (widget.condition?.call(_previousState, state) ?? true) {
          widget.listener(context, state);
        }
        _previousState = state;
      });
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}
