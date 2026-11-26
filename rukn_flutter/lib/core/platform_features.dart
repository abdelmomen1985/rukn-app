/// Features the iOS build leaves out for App Store review. Android and the web keep them.
library;

import 'package:flutter/foundation.dart';

bool get _isIosApp => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Customer reviews are user-generated content: guideline 1.2 needs report and block
/// controls the app doesn't have.
bool get reviewsEnabled => !_isIosApp;

/// Paid one-to-one consultations are switched off in the iOS app.
bool get consultationsEnabled => !_isIosApp;
