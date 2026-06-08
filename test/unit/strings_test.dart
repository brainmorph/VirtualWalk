import 'package:flutter_test/flutter_test.dart';
import 'package:virtualwalker/constants/strings.dart';

void main() {
  group('AppStrings', () {
    test('appName is VirtualWalker', () {
      expect(AppStrings.appName, 'VirtualWalker');
    });

    test('osmAttribution is non-empty', () {
      expect(AppStrings.osmAttribution, isNotEmpty);
    });

    test('all strings are non-empty', () {
      expect(AppStrings.locationPermissionDenied, isNotEmpty);
      expect(AppStrings.locationPermissionPermanentlyDenied, isNotEmpty);
      expect(AppStrings.openSettings, isNotEmpty);
      expect(AppStrings.noWalksYet, isNotEmpty);
      expect(AppStrings.walkSaved, isNotEmpty);
      expect(AppStrings.confirmStopTitle, isNotEmpty);
      expect(AppStrings.confirmStopBody, isNotEmpty);
      expect(AppStrings.cancel, isNotEmpty);
      expect(AppStrings.stopAndSave, isNotEmpty);
      expect(AppStrings.waitingForGps, isNotEmpty);
    });
  });
}
