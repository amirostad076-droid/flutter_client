/// Path prefixes and mapping between mobile (/m) and desktop shell routes
/// so redirect can switch shells on resize without losing logical location.
abstract final class ShellRoutePaths {
  static const String mobilePrefix = '/m';

  static const List<String> mobileTabPaths = [
    '/m',
    '/m/notifications',
    '/m/profile',
  ];

  static bool isMobileShellPath(String location) =>
      location == mobilePrefix || location.startsWith('$mobilePrefix/');

  static bool isDesktopShellPath(String location) =>
      location.startsWith('/servers') || location.startsWith('/dms');

  /// Map current desktop path to equivalent mobile path (for resize to mobile).
  static String desktopPathToMobile(String desktop) {
    if (desktop == '/servers' || desktop.startsWith('/servers/')) {
      if (desktop == '/servers') {
        return mobilePrefix;
      }
      return '$mobilePrefix$desktop';
    }
    if (desktop == '/dms' || desktop.startsWith('/dms/')) {
      return '$mobilePrefix$desktop';
    }
    return mobilePrefix;
  }

  /// Map current mobile path to equivalent desktop path (for resize).
  static String mobilePathToDesktop(String mobile) {
    if (!isMobileShellPath(mobile)) {
      return '/servers';
    }
    if (mobile == mobilePrefix ||
        mobile == '$mobilePrefix/notifications' ||
        mobile == '$mobilePrefix/profile') {
      return '/servers';
    }
    if (mobile.startsWith('$mobilePrefix/servers')) {
      return mobile.substring(mobilePrefix.length);
    }
    if (mobile.startsWith('$mobilePrefix/dms')) {
      return mobile.substring(mobilePrefix.length);
    }
    return '/servers';
  }
}
