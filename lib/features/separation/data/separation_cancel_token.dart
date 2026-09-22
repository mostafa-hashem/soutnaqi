import 'package:soutnaqi/core/errors/app_exception.dart';

/// Cooperative cancel signal for an in-flight [SeparationService.separate].
/// Checked between chunks / network steps — mid-inference work finishes first.
class SeparationCancelToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  void addCancelListener(void Function() listener) => _listeners.add(listener);

  void removeCancelListener(void Function() listener) =>
      _listeners.remove(listener);

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const AppException(messageKey: 'separationCancelled');
    }
  }
}
