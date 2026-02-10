// ignore_for_file: constant_identifier_names

enum SharedPreferenceKey {
  DASHBOARD_UI_TYPE("DASHBOARD_UI_TYPE"),
  GLASS_BACKGROUND_PATH("GLASS_BACKGROUND_PATH");

  final String? legacyKey;

  const SharedPreferenceKey(this.legacyKey);
}
