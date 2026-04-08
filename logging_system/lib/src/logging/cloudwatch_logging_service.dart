import 'dart:async';

import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:intl/intl.dart';

class CloudWatchLoggingService {
  CloudWatchLoggingService({
    required String awsAccessKey,
    required String awsSecretKey,
    required String region,
    required String logGroupName,
    required String logStreamName,
  }) : _logGroupName = logGroupName,
       _logStreamName = logStreamName {
    _loggingHandler = CloudWatchHandler(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
    );
    // Initialize date suffix on creation
    _updateLogStreamDateSuffix();
    // Start periodic flush timer
    _startFlushTimer();
  }

  final String _logGroupName;
  String _logStreamName;
  late final CloudWatchHandler _loggingHandler;
  DateTime? _lastLogDate;
  final List<String> _messageBuffer = [];
  static const int _maxBufferSize = 10;
  static const int _maxBufferSizeLimit =
      100; // Hard limit to prevent memory issues
  static const Duration _flushInterval = Duration(seconds: 5);
  Timer? _flushTimer;
  Future<void>?
  _currentFlush; // Track the current flush operation to prevent concurrent flushes
  bool _isDisposed = false; // Flag to prevent operations after disposal

  // Use lazy initialization for date suffix
  String? _logStreamDateSuffix;

  /// Start periodic flush timer
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      // Only trigger flush if not disposed, buffer has content, and no flush is in progress
      if (!_isDisposed && _messageBuffer.isNotEmpty && _currentFlush == null) {
        // Attach error handler to prevent unhandled exceptions
        _flushBuffer().catchError((error) {
          // Silently handle errors to prevent unhandled exceptions
          // Errors are already handled in _performFlush (messages are put back in buffer)
        });
      }
    });
  }

  /// Dispose resources and clean up
  /// Cancels the flush timer and ensures no further operations occur
  /// Should be called before app termination to prevent resource leaks
  ///
  /// Note: This method should be called after [flush()] to ensure pending
  /// messages are sent before disposal. The timer is cancelled immediately,
  /// and any pending buffer is cleared to free memory.
  void dispose() {
    // Mark as disposed first to prevent new operations
    _isDisposed = true;

    // Cancel timer first to prevent new periodic flush operations
    _flushTimer?.cancel();
    _flushTimer = null;

    // Clear flush tracking to prevent new flushes
    // The _isDisposed flag ensures _flushBuffer() won't start new operations
    // Any ongoing flush will complete naturally
    _currentFlush = null;

    // Clear buffer to free memory (any pending messages will be lost)
    // This is acceptable since dispose() should only be called after flush()
    _messageBuffer.clear();

    // Note: We don't await the ongoing flush here because dispose() is synchronous
    // and we want to allow the flush to complete naturally in the background
    // The _isDisposed flag prevents new operations from starting
  }

  /// Updates the date suffix to current UTC date
  void _updateLogStreamDateSuffix() {
    _logStreamDateSuffix = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().toUtc());
  }

  /// Gets the formatted log stream name with date suffix
  String _getLogStreamName() {
    final now = DateTime.now().toUtc();

    // Check if we need to update the date suffix (only check date, not time)
    if (_lastLogDate == null ||
        _lastLogDate!.day != now.day ||
        _lastLogDate!.month != now.month ||
        _lastLogDate!.year != now.year) {
      _updateLogStreamDateSuffix();
      _lastLogDate = now;
    }

    // Use cached suffix to avoid repeated formatting
    return _logStreamName.isEmpty
        ? _logStreamDateSuffix!
        : '$_logStreamName#$_logStreamDateSuffix';
  }

  /// Updates the log stream name
  void updateLogStreamName(String newLogStreamName) {
    _logStreamName = newLogStreamName;
    // Force update of date suffix when stream name changes
    _updateLogStreamDateSuffix();
  }

  /// Flush buffered messages to CloudWatch
  ///
  /// Note: This method tracks the flush Future to prevent concurrent operations.
  /// The `_currentFlush` Future tracks the actual async operation to ensure
  /// only one flush runs at a time, even when called without await.
  /// The Future is assigned synchronously immediately after the null check to
  /// prevent race conditions where multiple calls could pass the check.
  Future<void> _flushBuffer() async {
    // If disposed, don't start new flushes
    if (_isDisposed) {
      return;
    }

    // If a flush is already in progress, return early
    if (_currentFlush != null) {
      return;
    }

    // If buffer is empty, nothing to flush
    if (_messageBuffer.isEmpty) {
      return;
    }

    // Assign the Future synchronously BEFORE any other operations
    // This prevents race conditions where another call could pass the null check
    // Use a Completer to ensure the Future is assigned immediately
    final completer = Completer<void>();
    _currentFlush = completer.future;

    // Now safely copy messages and clear buffer
    final messages = List<String>.from(_messageBuffer);
    _messageBuffer.clear();

    // Perform the actual flush and complete the Future
    _performFlush(messages).then(
      (_) => completer.complete(),
      onError: (error) => completer.completeError(error),
    );

    try {
      await _currentFlush;
    } finally {
      // Reset flush tracking only after the flush completes
      // This ensures no concurrent flushes can start while upload is in progress
      // Only reset if not disposed (dispose() handles cleanup)
      if (!_isDisposed) {
        _currentFlush = null;
      }
    }
  }

  /// Performs the actual CloudWatch upload operation
  /// This is separated to allow proper tracking of the async operation
  Future<void> _performFlush(List<String> messages) async {
    try {
      final logStreamName = _getLogStreamName();
      final message = messages.join('\n');

      // The CloudWatchHandler will automatically create the log stream if it doesn't exist
      await _loggingHandler.log(
        message: message,
        logGroupName: _logGroupName,
        logStreamName: logStreamName,
      );
    } catch (e) {
      // If flush fails, prioritize re-queuing the failed messages to prevent data loss
      // Never log CloudWatch errors back through Talker to prevent infinite loops
      // The error will be silently handled to prevent recursive logging

      // Calculate how much space we need for the failed messages
      final totalNeeded = _messageBuffer.length + messages.length;

      if (totalNeeded <= _maxBufferSizeLimit) {
        // Buffer has enough space, add all failed messages
        _messageBuffer.addAll(messages);
      } else {
        // Buffer would exceed limit - prioritize failed messages over newer ones
        // Remove newest messages (added during flush) to make room for failed messages
        // New messages can be re-logged, but failed messages must be preserved
        final spaceNeeded = messages.length;
        final currentSize = _messageBuffer.length;
        final targetSize = _maxBufferSizeLimit - spaceNeeded;

        if (targetSize >= 0) {
          // We can make room by removing newest messages
          if (currentSize > targetSize) {
            // Remove newest messages to make exact room for failed messages
            _messageBuffer.removeRange(targetSize, currentSize);
          }
          // Now add all failed messages (we've made room)
          _messageBuffer.addAll(messages);
        } else {
          // Failed messages alone exceed limit - keep only the most recent failed messages
          // This is a last resort to prevent unbounded growth
          final keepCount = _maxBufferSizeLimit;
          if (keepCount > 0) {
            _messageBuffer.clear();
            // Ensure we don't use negative index if messages.length < keepCount
            final startIndex = messages.length > keepCount
                ? messages.length - keepCount
                : 0;
            _messageBuffer.addAll(messages.sublist(startIndex));
          }
        }
      }
      // Re-throw to allow caller to handle if needed
      rethrow;
    }
  }

  /// Logs a message to CloudWatch
  Future<void> log(String logString) async {
    if (logString.isEmpty) return;

    // If disposed, don't accept new logs
    if (_isDisposed) {
      return;
    }

    // Prevent buffer from growing unbounded
    if (_messageBuffer.length >= _maxBufferSizeLimit) {
      // Remove oldest messages to make room
      _messageBuffer.removeRange(
        0,
        _messageBuffer.length - _maxBufferSizeLimit + 1,
      );
    }

    _messageBuffer.add(logString);

    // Flush if buffer is full (timer handles periodic flushing)
    // Check _currentFlush instead of _isLogging to ensure no concurrent operations
    if (_messageBuffer.length >= _maxBufferSize && _currentFlush == null) {
      // Don't await to avoid blocking, but attach error handler to prevent unhandled exceptions
      _flushBuffer().catchError((error) {
        // Silently handle errors to prevent unhandled exceptions
        // Errors are already handled in _performFlush (messages are put back in buffer)
      });
    }
  }

  /// Force flush any remaining messages
  Future<void> flush() async {
    await _flushBuffer();
  }
}
