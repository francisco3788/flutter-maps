sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Object error, StackTrace stackTrace) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self.value);
    }
    if (self is Failure<T>) {
      return failure(self.error, self.stackTrace);
    }
    throw StateError('Invalid result state');
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
