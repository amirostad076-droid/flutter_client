/// Guild role colors from the API are 24-bit RGB values. Flutter [Color]
/// expects ARGB, so raw values render with zero alpha unless the high byte
/// is set.
int? opaqueRoleColorInt(int? color) {
  if (color == null || color == 0) {
    return null;
  }
  return color | 0xFF000000;
}
