import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging_system/src/dependency_injection/global_binding.dart';
import 'package:logging_system/src/logging/cloudwatch_logging_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CloudwatchLoggerObserver extends TalkerObserver {
  final FirebaseCrashlytics? firebaseCrashlytics;
  bool _isFlushing = false; // Flag to prevent recursive logging

  CloudwatchLoggerObserver(this.firebaseCrashlytics);

  @override
  void onError(TalkerError err) {
    // Skip logging if this is a CloudWatch-related error to prevent loops
    if (_isCloudWatchError(err.error)) {
      // Only log to Firebase Crashlytics, skip CloudWatch
      firebaseCrashlytics?.recordError(
        err.error,
        err.stackTrace,
        reason: err.message,
      );
      super.onError(err);
      return;
    }

    final message = _formatLogMessage(
      err.message,
      err.error,
      err.stackTrace,
      level: 'ERROR',
    );
    _logToCloudWatch(message);

    firebaseCrashlytics?.recordError(
      err.error,
      err.stackTrace,
      reason: err.message,
    );

    super.onError(err);
  }

  @override
  void onException(TalkerException err) {
    // Skip logging if this is a CloudWatch-related error to prevent loops
    if (_isCloudWatchError(err)) {
      // Only log to Firebase Crashlytics, skip CloudWatch
      firebaseCrashlytics?.recordError(
        err,
        err.stackTrace,
        printDetails: true,
        fatal: false,
        reason: err.message ?? 'TalkerException',
      );
      super.onException(err);
      return;
    }

    try {
      final message = _formatLogMessage(
        err.message,
        err,
        err.stackTrace,
        level: 'EXCEPTION',
      );
      _logToCloudWatch(message);

      // Also log the formatted message to Crashlytics for better context
      firebaseCrashlytics?.log(message);

      firebaseCrashlytics?.recordError(
        err,
        err.stackTrace,
        printDetails: true,
        // Do not mark as fatal to avoid app termination when handled by Talker
        fatal: false,
        reason: err.message ?? 'TalkerException',
      );

      super.onException(err);
    } catch (e, stack) {
      // Prevent infinite loops by not logging CloudWatch errors
      if (!_isCloudWatchError(e)) {
        firebaseCrashlytics?.recordError(
          e,
          stack,
          reason: 'Error while handling TalkerException',
        );
      }
    }
  }

  @override
  void onLog(TalkerData log) {
    // Skip logging if this is a CloudWatch-related error to prevent loops
    if (log.exception != null && _isCloudWatchError(log.exception!)) {
      // Only log to Firebase Crashlytics, skip CloudWatch
      firebaseCrashlytics?.log(log.generateTextMessage());
      super.onLog(log);
      return;
    }

    final message = _formatLogMessage(
      log.message,
      log.exception,
      log.stackTrace,
      level: 'INFO',
    );
    _logToCloudWatch(message);

    firebaseCrashlytics?.log(message);

    super.onLog(log);
  }

  /// Format a log message with optional exception and stack trace
  String _formatLogMessage(
    String? msg,
    Object? e,
    StackTrace? s, {
    String level = 'LOG',
  }) {
    // Pre-allocate buffer with estimated size to reduce reallocations
    final buffer = StringBuffer();
    final timestamp = DateTime.now().toUtc().toIso8601String();
    buffer.writeln('[$level] $timestamp');
    if (msg != null && msg.isNotEmpty) {
      buffer.writeln('Message: $msg');
    }
    if (e != null) {
      buffer.writeln('Exception: $e');
    }
    if (s != null) {
      buffer.writeln('Stack trace:\n$s');
    }
    return buffer.toString();
  }

  /// Check if an error is related to CloudWatch logging
  /// Uses cached string comparison for better performance
  bool _isCloudWatchError(Object? error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    // Check most specific first for early exit
    return errorString.contains('cloudwatchhandler') ||
        errorString.contains('cloudwatchlogging') ||
        errorString.contains('cloudwatch') ||
        errorString.contains('aws');
  }

  /// Helper method to log messages to CloudWatch
  void _logToCloudWatch(String message) {
    if (_isFlushing) return; // Prevent recursive calls during flush

    try {
      // Check if service is registered before accessing to avoid exceptions
      if (!GlobalBinding.getIt.isRegistered<CloudWatchLoggingService>()) {
        return; // Service has been disposed, silently skip logging
      }

      // Directly log to service - it handles buffering internally
      GlobalBinding.cloudwatchLogginService.log(message).catchError((_) {
        // Silently fail to prevent infinite loops
      });
    } catch (e) {
      // Prevent potential infinite loops if CloudWatch logging fails
      // Just silently fail in this observer
    }
  }

  /// Force flush any remaining messages
  Future<void> flush() async {
    if (_isFlushing) return;

    // Check if service is registered before accessing to avoid exceptions
    if (!GlobalBinding.getIt.isRegistered<CloudWatchLoggingService>()) {
      return; // Service has been disposed, silently skip flush
    }

    _isFlushing = true;
    try {
      await GlobalBinding.cloudwatchLogginService.flush();
    } catch (e) {
      // Silently fail if service is disposed or inaccessible
    } finally {
      _isFlushing = false;
    }
  }
}
