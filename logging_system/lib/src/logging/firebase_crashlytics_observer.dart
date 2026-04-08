import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:talker_flutter/talker_flutter.dart';

class FirebaseCrashlyticsObserver extends TalkerObserver {
  final FirebaseCrashlytics firebaseCrashlytics;

  FirebaseCrashlyticsObserver(this.firebaseCrashlytics);
  @override
  void onError(TalkerError err) {
    firebaseCrashlytics.recordError(
      err.error,
      err.stackTrace,
      reason: err.message,
    );

    super.onError(err);
  }

  @override
  void onException(TalkerException err) {
    // Log a human-readable message for better visibility in Crashlytics
    final msg = 'TalkerException: ${err.message ?? ''}';
    firebaseCrashlytics.log(msg);

    firebaseCrashlytics.recordError(
      err,
      err.stackTrace,
      printDetails: true,
      // Avoid marking as fatal here to prevent app termination when handled
      fatal: false,
      reason: err.message,
    );

    super.onException(err);
  }

  @override
  void onLog(TalkerData log) {
    firebaseCrashlytics.log(log.generateTextMessage());

    super.onLog(log);
  }
}
