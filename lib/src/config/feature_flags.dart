import 'package:flutter/foundation.dart';

class FeatureFlags {
  static const String SOCIAL_LOGIN = 'social_login';
  static const String LOGIN_REMEMBER_ME = 'login_remember_me';

  static const List<String> disabledFeatures = [
    SOCIAL_LOGIN,
    LOGIN_REMEMBER_ME,
  ];

  static bool isFeatureEnabled(String featureName) {
    return !disabledFeatures.contains(featureName);
  }
}