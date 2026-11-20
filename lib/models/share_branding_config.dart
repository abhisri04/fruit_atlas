import 'app_branding.dart';

class ShareBrandingConfig {
  final String appName;
  final String tagline;
  final String? logoAsset;
  const ShareBrandingConfig({
    this.appName = AppBranding.appName,
    this.tagline = AppBranding.tagline,
    this.logoAsset,
  });
}
