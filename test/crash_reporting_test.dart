import 'package:fitness_app/modules/crash/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hlášení o pádech jen v release, s Firebase a se souhlasem', () {
    expect(
      shouldSendCrashReports(
          releaseBuild: true, firebaseReady: true, userEnabled: true),
      isTrue,
    );
    expect(
      shouldSendCrashReports(
          releaseBuild: false, firebaseReady: true, userEnabled: true),
      isFalse,
    );
    expect(
      shouldSendCrashReports(
          releaseBuild: true, firebaseReady: false, userEnabled: true),
      isFalse,
    );
    expect(
      shouldSendCrashReports(
          releaseBuild: true, firebaseReady: true, userEnabled: false),
      isFalse,
    );
  });
}
