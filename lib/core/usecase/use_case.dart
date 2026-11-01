abstract interface class UseCase<Output, Input> {
  Future<Output> call(Input input);
}

final class NoParams {
  const NoParams();
}
