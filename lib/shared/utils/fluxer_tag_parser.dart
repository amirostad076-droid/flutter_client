class FluxerTagParseResult {
  const FluxerTagParseResult({
    required this.username,
    required this.discriminator,
  });

  final String username;
  final String discriminator;
}

FluxerTagParseResult parseFluxerTagInput(String input) {
  final parts = input.split('#');
  if (parts.length > 1) {
    return FluxerTagParseResult(
      username: parts.first,
      discriminator: parts.sublist(1).join('#'),
    );
  }
  return FluxerTagParseResult(username: input, discriminator: '0000');
}

bool isValidFluxerTagDiscriminator(String discriminator) {
  return RegExp(r'^\d{4}$').hasMatch(discriminator);
}

bool isValidFluxerTagSubmission(String username, String discriminator) {
  return username.trim().isNotEmpty &&
      isValidFluxerTagDiscriminator(discriminator);
}
