typedef FcmNotificationTapCallback = void Function(Map<String, String> payload);

abstract interface class FcmTapBindingHost {
  void setNotificationTapCallback(FcmNotificationTapCallback? callback);
}

class FcmTapBindingHostStub implements FcmTapBindingHost {
  @override
  void setNotificationTapCallback(FcmNotificationTapCallback? callback) {}
}
