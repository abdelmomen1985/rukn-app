import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukn_thamin/core/platform_features.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('iOS leaves out reviews and consultations', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(reviewsEnabled, isFalse);
    expect(consultationsEnabled, isFalse);
  });

  test('Android keeps reviews and consultations', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(reviewsEnabled, isTrue);
    expect(consultationsEnabled, isTrue);
  });
}
