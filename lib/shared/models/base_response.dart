class BaseResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  const BaseResponse({
    this.data,
    this.message,
    this.success = true,
  });
}
