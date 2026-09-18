/// Single source of truth for app identity constants.
///
/// Version and build number are NOT hardcoded here — read them at runtime
/// via `package_info_plus` so they always match pubspec.yaml.
class AppInfo {
  AppInfo._();

  static const String appName = 'Water It';

  /// Must match the contact address published in PRIVACY_POLICY.md.
  static const String supportEmail = 'fromgames.dev@gmail.com';
}
