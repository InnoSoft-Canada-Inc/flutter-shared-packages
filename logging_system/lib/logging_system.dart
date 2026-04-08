import 'package:bloc/bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:logging_system/src/dependency_injection/global_binding.dart';
import 'package:logging_system/src/logging/cloudwatch_logging_service.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggingSystem {
  static TalkerDioLogger? _talkerDioLogger;
  static TalkerBlocObserver? _talkerBlocObserver;
  static bool _isInitialized = false;

  /// Check if the logging system is initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Logging System.
  /// Must be initialized before being utilized
  ///
  /// If already initialized, this method returns early without re-initializing.
  /// To re-initialize with different settings, call [dispose()] first.
  static void initialize({
    String? awsAccessKey,
    String? awsSecretKey,
    String? awsRegion,
    String? logGroupName,
    String? logStreamName,
    FirebaseCrashlytics? firebaseCrashlytics,
    bool printToConsole = true,
    bool printNetworkLogs = false,
    bool printBlocLogs = false,
  }) {
    // Prevent multiple initializations to avoid resource leaks
    if (_isInitialized) {
      return;
    }

    try {
      final bool enableCloudWatch =
          awsAccessKey != null &&
          awsSecretKey != null &&
          awsRegion != null &&
          logGroupName != null &&
          logStreamName != null;

      // Initialize GlobalBinding
      GlobalBinding.initialize(
        isCloudWatchEnabled: enableCloudWatch,
        firebaseCrashlytics: firebaseCrashlytics,
        printToConsole: printToConsole,
      );

      // Configure CloudWatch if enabled
      if (enableCloudWatch) {
        GlobalBinding.initCloudWatchObserver(
          accessKey: awsAccessKey,
          secretKey: awsSecretKey,
          region: awsRegion,
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
      }

      // Initialize loggers
      _initializeLoggers(printNetworkLogs, printBlocLogs);
      _isInitialized = true;
    } catch (e, stack) {
      // If initialization fails, at least try to log the error
      if (firebaseCrashlytics != null) {
        firebaseCrashlytics.recordError(
          e,
          stack,
          reason: 'Failed to initialize LoggingSystem',
          fatal: true,
        );
      }

      rethrow;
    }
  }

  /// Initialize Talker loggers
  static void _initializeLoggers(bool printNetworkLogs, bool printBlocLogs) {
    _talkerDioLogger = TalkerDioLogger(
      talker: _logger,
      settings: TalkerDioLoggerSettings(
        enabled: printNetworkLogs,
        printRequestHeaders: true,
        printResponseHeaders: true,
        printResponseData: true,
        printResponseMessage: true,
        printRequestData: true,
      ),
    );

    _talkerBlocObserver = TalkerBlocObserver(
      talker: _logger,
      settings: TalkerBlocLoggerSettings(
        enabled: printBlocLogs,
        printEventFullData: true,
        printStateFullData: true,
        printChanges: true,
        printClosings: true,
        printCreations: true,
        printEvents: true,
        printTransitions: true,
      ),
    );
  }

  /// Get the Talker instance
  static Talker get _logger => GlobalBinding.logger;

  /// Get the CloudWatch logging service
  static CloudWatchLoggingService get _cloudWatchLoggingService =>
      GlobalBinding.cloudwatchLogginService;

  /// Check initialization status (inline for performance)
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('LoggingSystem must be initialized before use');
    }
  }

  /// Log a message with optional exception and stack trace
  static void log({required String msg, Object? e, StackTrace? s}) {
    _checkInitialized();
    _logger.log(msg, exception: e, stackTrace: s);
  }

  /// Handle an exception with optional stack trace and message
  static void handle(Object e, [StackTrace? stackTrace, dynamic msg]) {
    _checkInitialized();
    _logger.handle(e, stackTrace, msg);
  }

  /// Log an error message
  static void error({String? msg, Object? e, StackTrace? s}) {
    _checkInitialized();
    _logger.error(msg, e, s);
  }

  /// Log an info message
  static void info({String? msg, Object? e, StackTrace? s}) {
    _checkInitialized();
    _logger.info(msg, e, s);
  }

  /// Log a warning message
  static void warning({String? msg, Object? e, StackTrace? s}) {
    _checkInitialized();
    _logger.warning(msg, e, s);
  }

  /// Log a critical message
  static void critical({String? msg, Object? e, StackTrace? s}) {
    _checkInitialized();
    _logger.critical(msg, e, s);
  }

  /// Get a route observer for navigation logging
  static TalkerRouteObserver get talkerRouteObserver {
    _checkInitialized();
    return TalkerRouteObserver(_logger);
  }

  /// Wrap a widget with Talker error handling
  static Widget talkerWrapper(Widget child) {
    _checkInitialized();
    return TalkerWrapper(
      talker: _logger,
      options: const TalkerWrapperOptions(
        enableErrorAlerts: true,
        enableExceptionAlerts: true,
      ),
      child: child,
    );
  }

  /// Configure and get the Dio logger
  static TalkerDioLogger? talkerDioLogger({
    bool? enabled,
    bool? printRequestHeaders,
    bool? printResponseHeaders,
    bool? printResponseData,
    bool? printResponseMessage,
    bool? printRequestData,
  }) {
    if (_talkerDioLogger == null) return null;

    // Modify settings based on user input before returning the instance
    _talkerDioLogger!.settings = TalkerDioLoggerSettings(
      enabled: enabled ?? _talkerDioLogger!.settings.enabled,
      printRequestHeaders:
          printRequestHeaders ?? _talkerDioLogger!.settings.printRequestHeaders,
      printResponseHeaders:
          printResponseHeaders ??
          _talkerDioLogger!.settings.printResponseHeaders,
      printResponseData:
          printResponseData ?? _talkerDioLogger!.settings.printResponseData,
      printResponseMessage:
          printResponseMessage ??
          _talkerDioLogger!.settings.printResponseMessage,
      printRequestData:
          printRequestData ?? _talkerDioLogger!.settings.printRequestData,
    );
    return _talkerDioLogger;
  }

  /// Get the Bloc observer
  static BlocObserver? get talkerBlocObserver => _talkerBlocObserver;

  /// Update the CloudWatch log stream name
  /// Only works if CloudWatch logging is enabled
  static void updateLogStreamName(String newLogStreamName) {
    _checkInitialized();
    // Check if CloudWatch service is registered before accessing
    if (GlobalBinding.getIt.isRegistered<CloudWatchLoggingService>()) {
      _cloudWatchLoggingService.updateLogStreamName(newLogStreamName);
    } else {
      throw StateError(
        'CloudWatch logging is not enabled. Cannot update log stream name.',
      );
    }
  }

  /// Force flush any pending CloudWatch logs
  /// Useful before app termination or when switching log streams
  /// This method calls the observer's flush() first to set the _isFlushing flag,
  /// which prevents recursive logging during error handling, then flushes the service.
  static Future<void> flushCloudWatchLogs() async {
    if (!_isInitialized) return;
    try {
      // Check if CloudWatch service is registered before accessing
      if (GlobalBinding.getIt.isRegistered<CloudWatchLoggingService>()) {
        // Call observer's flush() first to set _isFlushing flag and prevent recursive logging
        // The observer's flush() internally calls the service's flush()
        final observer = GlobalBinding.cloudwatchObserver;
        if (observer != null) {
          await observer.flush();
        } else {
          // Fallback: if observer is not available, flush service directly
          await _cloudWatchLoggingService.flush();
        }
      }
    } catch (e) {
      // Silently fail to prevent errors during flush
    }
  }

  /// Dispose and clean up logging system resources
  /// Should be called before app termination to ensure proper cleanup
  /// This will flush any pending CloudWatch logs and cancel the flush timer
  /// After calling this, the system can be re-initialized with new settings
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Flush any pending CloudWatch logs before disposing
      await flushCloudWatchLogs();

      // Set _isInitialized to false BEFORE disposing resources
      // This ensures that any concurrent checks will fail gracefully with StateError
      // instead of throwing GetIt exceptions when resources are unregistered
      _isInitialized = false;

      // Dispose all resources to allow re-initialization
      GlobalBinding.disposeAll();
    } catch (e) {
      // Silently fail to prevent errors during disposal
      // Ensure _isInitialized is still set to false even if disposal fails
      _isInitialized = false;
    }

    // Reset static state to allow re-initialization
    _talkerDioLogger = null;
    _talkerBlocObserver = null;
  }

  /// Get a Talker screen widget for displaying logs
  static Widget get talkerScreen {
    _checkInitialized();
    return TalkerScreen(talker: _logger, appBarTitle: 'App Logs');
  }
}
