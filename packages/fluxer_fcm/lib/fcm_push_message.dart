class FcmPushMessage {
  const FcmPushMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final String id;
  final String? title;
  final String? body;
  final Map<String, String> payload;
}
