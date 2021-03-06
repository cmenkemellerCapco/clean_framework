import 'dart:async';

import 'package:clean_framework/clean_framework.dart';
import 'package:flutter_test/flutter_test.dart';

class ViewModelPipeTester<V extends ViewModel> {
  Function _launch;
  final Pipe<V> _publisher;
  Completer<ViewModelPipeTester> completer;
  bool hasInitialViewModelBeenReceived = false;
  V receivedViewModel;
  StreamSubscription _pipeSubscription;

  ViewModelPipeTester._(Pipe<V> publisher) : _publisher = publisher {
    _pipeSubscription = _publisher.receive.listen((output) async {
      receivedViewModel = output;
      completer.complete();

      hasInitialViewModelBeenReceived = true;
    });
  }

  static ViewModelPipeTester forPipe<V extends ViewModel>(Pipe<V> publisher) {
    if (publisher.whenListenedDo == null)
      throw MissingListenedCallbackPipeTesterError();
    return ViewModelPipeTester._(publisher);
  }

  ViewModelPipeTester whenBeingListenedTo() {
    // This empty step exists to make the test code more verbose
    if (hasInitialViewModelBeenReceived)
      throw InitialViewModelAlreadySentPipeTesterError();
    return this;
  }

  ViewModelPipeTester whenDoing(Function launch) {
    _launch = launch;
    return this;
  }

  Future<void> thenExpectA(V item) async {
    if (hasInitialViewModelBeenReceived == false) {
      completer = Completer<ViewModelPipeTester>();
      await completer.future.timeout(const Duration(seconds: 3),
          onTimeout: () =>
              throw NeverReceivedInitialViewModelPipeTesterError());
    }

    if (_launch != null) {
      completer = Completer<ViewModelPipeTester>();
      _launch?.call();
      await completer.future.timeout(const Duration(seconds: 3),
          onTimeout: () =>
              throw NeverReceivedUpdatedViewModelPipeTesterError());
    }

    expect(item, receivedViewModel);
    return this;
  }

  void dispose() {
    _pipeSubscription.cancel();
    completer?.complete();
  }
}

class NeverReceivedInitialViewModelPipeTesterError extends StateError {
  NeverReceivedInitialViewModelPipeTesterError()
      : super('Test failed: view model pipe never received the initial model');
}

class NeverReceivedUpdatedViewModelPipeTesterError extends StateError {
  NeverReceivedUpdatedViewModelPipeTesterError()
      : super('Test failed: view model pipe never received the updated model');
}

class InitialViewModelAlreadySentPipeTesterError extends StateError {
  InitialViewModelAlreadySentPipeTesterError()
      : super('Test failed: view model pipe already sent an initial model');
}

class NeverReceivedPipeTesterError extends StateError {
  NeverReceivedPipeTesterError(dynamic item)
      : super('Test failed: pipe never received a ${item.toString()}');
}

class MissingListenedCallbackPipeTesterError
    extends NeverReceivedPipeTesterError {
  MissingListenedCallbackPipeTesterError()
      : super(
            'ViewModelPipeTester can only be used with pipes that implement the method whenListenedDo.');
}
