// Enum values use UPPER_CASE to match provider error code conventions.
// ignore_for_file: constant_identifier_names

/// An exception class representing various errors that can occur
/// during the captcha challenge process.
///
/// This exception supports both Cloudflare Turnstile and hCaptcha error codes,
/// mapping them to a unified [CaptchaError] type.
class CaptchaException implements Exception {
  const CaptchaException(
    this.message, {
    this.code = '-1',
    this.errorType = CaptchaError.UNKNOWN,
    this.retryable = false,
  });

  /// Creates from a Turnstile numeric error [code].
  ///
  /// See [Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/).
  factory CaptchaException.fromTurnstileCode(int code) {
    var message = 'unknown error';
    var retryable = false;
    var errorType = CaptchaError.UNKNOWN;

    switch (code) {
      case var _ when code >= 100000 && code < 102000:
        errorType = CaptchaError.INITIALIZATION_PROBLEM;
        message =
            'There was a problem initializing Turnstile before a challenge '
            'could be started.';
      case var _ when code >= 102000 && code < 103000:
      case var _ when code >= 103000 && code < 104000:
      case var _ when code >= 104000 && code < 105000:
      case var _ when code >= 106000 && code < 107000:
        retryable = true;
        errorType = CaptchaError.INVALID_PARAMETERS;
        message =
            'The visitor sent an invalid parameter as part of the challenge '
            'towards Turnstile.';
      case var _ when code >= 105000 && code < 106000:
        errorType = CaptchaError.API_COMPATIBILITY;
        message = 'Turnstile was invoked in a deprecated or invalid way.';
      case 110100:
      case 110110:
        errorType = CaptchaError.INVALID_SITEKEY;
        message =
            'Turnstile was invoked with an invalid sitekey or a sitekey that '
            'is no longer active.';
      case 110200:
        retryable = true;
        errorType = CaptchaError.UNKNOWN_DOMAIN;
        message = 'Domain not allowed.';
      case 110420:
        errorType = CaptchaError.INVALID_ACTION;
        message =
            'This error occurs when an unsupported or incorrectly formatted '
            'action is submitted.';
      case 110430:
        errorType = CaptchaError.INVALID_CDATA;
        message =
            'This error refers to an issue encountered when processing Custom '
            'Data (cData). This error occurs when the cData provided does not '
            'adhere to the expected format or contains invalid characters.';
      case 110500:
        errorType = CaptchaError.UNSUPPORTED_BROWSER;
        message = 'The visitor is using an unsupported browser.';
      case 110510:
        errorType = CaptchaError.INCONSISTENT_USER_AGENT;
        message =
            'The visitor provided an inconsistent user-agent throughout the '
            'process of solving Turnstile.';
      case var _ when code >= 110600 && code < 110620:
        retryable = true;
        errorType = CaptchaError.CHALLENGE_TIMED_OUT;
        message =
            'The visitor took too long to solve the challenge and the '
            'challenge timed out.';
      case var _ when code >= 110620 && code < 120000:
        retryable = true;
        errorType = CaptchaError.CHALLENGE_TIMED_OUT;
        message =
            'The visitor took too long to solve the interactive challenge and '
            'the challenge became outdated.';
      case var _ when code >= 120000 && code < 200010:
        errorType = CaptchaError.INTERNAL_ERROR;
        message = 'Internal Errors for Cloudflare Employees.';
      case 200010:
        errorType = CaptchaError.INVALID_CACHING;
        message = 'Some portion of Turnstile was accidentally cached.';
      case 200100:
        errorType = CaptchaError.TIME_PROBLEM;
        message = "The visitor's clock is incorrect.";
      case var _ when code >= 300000 && code < 301000:
        retryable = true;
        errorType = CaptchaError.GENERIC_CLIENT_EXECUTION;
        message =
            'An unspecified error occurred in the visitor while they were '
            'solving a challenge.';
      case var _ when code >= 400000 && code < 401000:
        errorType = CaptchaError.INCORRECT_CONFIGURATION;
        message =
            'The configuration for Turnstile is incorrect or incomplete. '
            'Check the site key, secret key, and domain setup.';
      case var _ when code >= 600000 && code < 601000:
        retryable = true;
        errorType = CaptchaError.CHALLENGE_EXECUTION_FAILURE;
        message =
            'A visitor failed to solve a Turnstile Challenge. Also used by '
            'failing testing sitekey.';
    }

    return CaptchaException(
      message,
      code: code.toString(),
      errorType: errorType,
      retryable: retryable,
    );
  }

  /// Creates from an hCaptcha string error [code].
  factory CaptchaException.fromHCaptchaCode(String code) {
    var message = 'unknown error';
    var retryable = false;
    var errorType = CaptchaError.UNKNOWN;

    switch (code) {
      case 'rate-limited':
        retryable = false;
        errorType = CaptchaError.RATE_LIMITED;
        message = 'The user has been rate limited.';
      case 'network-error':
        retryable = true;
        errorType = CaptchaError.NETWORK_ERROR;
        message = 'A network error occurred during the challenge.';
      case 'invalid-data':
        errorType = CaptchaError.INVALID_PARAMETERS;
        message = 'Invalid data was submitted to hCaptcha.';
      case 'challenge-error':
        retryable = true;
        errorType = CaptchaError.CHALLENGE_EXECUTION_FAILURE;
        message = 'An error occurred during challenge execution.';
      case 'challenge-closed':
        errorType = CaptchaError.CHALLENGE_CLOSED;
        message = 'The challenge was closed by the user.';
      case 'challenge-expired':
        retryable = true;
        errorType = CaptchaError.CHALLENGE_TIMED_OUT;
        message = 'The challenge expired before completion.';
      case 'missing-captcha':
        errorType = CaptchaError.INITIALIZATION_PROBLEM;
        message = 'The captcha element is missing from the page.';
      case 'invalid-captcha-id':
        errorType = CaptchaError.INVALID_PARAMETERS;
        message = 'The captcha widget instance ID is invalid.';
      case 'internal-error':
        retryable = true;
        errorType = CaptchaError.INTERNAL_ERROR;
        message = 'An internal hCaptcha error occurred.';
      case 'script-error':
        errorType = CaptchaError.INITIALIZATION_PROBLEM;
        message = 'The hCaptcha script failed to load.';
    }

    return CaptchaException(
      message,
      code: code,
      errorType: errorType,
      retryable: retryable,
    );
  }

  /// Turnstile: numeric code as string. hCaptcha: string error code.
  final String code;

  final String message;

  /// The unified error type. Defaults to [CaptchaError.UNKNOWN].
  final CaptchaError errorType;

  /// Whether the operation can be retried to resolve this error.
  final bool retryable;

  @override
  String toString() {
    return 'CaptchaException $code: $message';
  }
}

/// Enum representing unified error types across captcha providers.
enum CaptchaError {
  /// There was an issue during captcha initialization.
  INITIALIZATION_PROBLEM,

  /// An invalid parameter was provided during the challenge.
  INVALID_PARAMETERS,

  /// Compatibility issue with the captcha API or deprecated usage.
  API_COMPATIBILITY,

  /// The provided sitekey is invalid or inactive.
  INVALID_SITEKEY,

  /// Domain is not allowed by the captcha provider.
  UNKNOWN_DOMAIN,

  /// An unsupported or incorrectly formatted action was submitted.
  INVALID_ACTION,

  /// Custom Data (cData) provided is invalid or incorrectly formatted.
  INVALID_CDATA,

  /// The visitor is using an unsupported browser.
  UNSUPPORTED_BROWSER,

  /// The user-agent provided by the visitor was inconsistent.
  INCONSISTENT_USER_AGENT,

  /// The configuration is incorrect or incomplete.
  INCORRECT_CONFIGURATION,

  /// The challenge timed out before the visitor could solve it.
  CHALLENGE_TIMED_OUT,

  /// The challenge was closed by the user.
  CHALLENGE_CLOSED,

  /// The visitor failed to solve the challenge.
  CHALLENGE_EXECUTION_FAILURE,

  /// Internal error within the captcha provider.
  INTERNAL_ERROR,

  /// Part of the captcha was accidentally cached, causing issues.
  INVALID_CACHING,

  /// The visitor's device clock is incorrect.
  TIME_PROBLEM,

  /// A generic error occurred on the client side during the challenge.
  GENERIC_CLIENT_EXECUTION,

  /// The user has been rate limited.
  RATE_LIMITED,

  /// A network error occurred during the challenge.
  NETWORK_ERROR,

  /// An unknown error occurred.
  UNKNOWN,
}
