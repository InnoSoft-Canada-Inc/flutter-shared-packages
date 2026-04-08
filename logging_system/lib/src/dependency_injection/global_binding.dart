import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get_it/get_it.dart';
import 'package:logging_system/src/logging/cloudwatch_logging_observer.dart';
import 'package:logging_system/src/logging/cloudwatch_logging_service.dart';
import 'package:logging_system/src/logging/firebase_crashlytics_observer.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Manages global dependencies for the logging system
class GlobalBinding {
  static final GetIt _getIt = GetIt.instance;
  static CloudwatchLoggerObserver? _cloudwatchObserver;

  /// Get the Talker logger instance
  static Talker get logger => _getIt.get<Talker>();

  /// Get the CloudWatch logging service instance
  static CloudWatchLoggingService get cloudwatchLogginService =>
      _getIt.get<CloudWatchLoggingService>();

  /// Get the CloudWatch logger observer instance
  static CloudwatchLoggerObserver? get cloudwatchObserver =>
      _cloudwatchObserver;

  /// Get the GetIt instance
  static GetIt get getIt => _getIt;

  /// Initialize core dependencies
  ///
  /// [isCloudWatchEnabled] - Whether CloudWatch logging is enabled
  /// [firebaseCrashlytics] - Optional Firebase Crashlytics instance
  /// [printToConsole] - Whether to print logs to console (defaults to true)
  ///
  /// Note: This method is idempotent and can be called multiple times safely.
  /// If Talker is already registered, it will be unregistered and re-registered
  /// with the new configuration to ensure consistency.
  static void initialize({
    required bool isCloudWatchEnabled,
    FirebaseCrashlytics? firebaseCrashlytics,
    bool printToConsole = true,
  }) {
    // Create appropriate observer based on configuration
    TalkerObserver? observer;
    if (isCloudWatchEnabled) {
      _cloudwatchObserver = CloudwatchLoggerObserver(firebaseCrashlytics);
      observer = _cloudwatchObserver;
    } else if (firebaseCrashlytics != null) {
      observer = FirebaseCrashlyticsObserver(firebaseCrashlytics);
    }

    // Initialize Talker with configured settings
    final talkerLogger = TalkerFlutter.init(
      observer: observer,
      settings: TalkerSettings(
        enabled: true,
        useHistory: true,
        useConsoleLogs: printToConsole,
      ),
    );

    // Register Talker instance as singleton
    // Defensive check: TalkerFlutter.init() may register the instance internally in GetIt,
    // or Talker may be registered from a previous partial initialization attempt.
    // Unregister it first to ensure we register our configured instance with the correct
    // observer and settings. This allows recovery from partial initialization failures.
    if (_getIt.isRegistered<Talker>()) {
      _getIt.unregister<Talker>();
    }
    // Now safe to register - the check above ensures it's not already registered
    _getIt.registerSingleton<Talker>(talkerLogger);
  }

  /// Initialize CloudWatch logging service
  ///
  /// Must be called after [initialize] if CloudWatch logging is enabled
  static void initCloudWatchObserver({
    required String accessKey,
    required String secretKey,
    required String region,
    required String logGroupName,
    required String logStreamName,
  }) {
    if (!_getIt.isRegistered<CloudWatchLoggingService>()) {
      _getIt.registerLazySingleton<CloudWatchLoggingService>(
        () => CloudWatchLoggingService(
          awsAccessKey: accessKey,
          awsSecretKey: secretKey,
          region: region,
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        ),
      );
    }
  }

  /// Dispose CloudWatch logging service and clean up resources
  /// This will cancel the flush timer and flush any pending logs
  static void disposeCloudWatchService() {
    if (_getIt.isRegistered<CloudWatchLoggingService>()) {
      try {
        final service = _getIt.get<CloudWatchLoggingService>();
        service.dispose();
        _getIt.unregister<CloudWatchLoggingService>();
      } catch (e) {
        // Silently fail if service is already disposed or not accessible
      }
    }
  }

  /// Dispose Talker logger instance and clean up resources
  /// This unregisters the Talker instance to allow re-initialization
  static void disposeTalker() {
    if (_getIt.isRegistered<Talker>()) {
      try {
        _getIt.unregister<Talker>();
      } catch (e) {
        // Silently fail if Talker is already disposed or not accessible
      }
    }
  }

  /// Dispose all logging system resources
  /// This will dispose both CloudWatch service and Talker instance
  /// Should be called to fully reset the logging system for re-initialization
  static void disposeAll() {
    disposeCloudWatchService();
    disposeTalker();
    _cloudwatchObserver = null; // Clear observer reference
  }
}
