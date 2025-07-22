// 錯誤層 的抽象類別

abstract class Failure {
  final String message;

  Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class DatabaseFailure extends Failure {
  DatabaseFailure(String message) : super('Database Error: $message');
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super('Network Error: $message');
}

class UnknownFailure extends Failure {
  UnknownFailure(String message) : super('Unknown Error: $message');
}
